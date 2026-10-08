#!/usr/bin/env python3
import os, glob, struct, json, subprocess, shutil

def collect_telemetry():
    result = {}
    gpus = {}
    cards = sorted(glob.glob("/sys/class/drm/card[0-9]"))
    
    # 1. GPU COLLECTION
    for idx, card in enumerate(cards):
        dev = os.path.join(card, "device")
        if not os.path.exists(dev):
            continue
            
        gid = f"gpu{idx}"
        data = {"id": gid}
        
        sclk = 0
        mclk = 0
        
        # Hwmon search
        for hw in glob.glob(os.path.join(dev, "hwmon", "hwmon*")):
            freq_f = os.path.join(hw, "freq1_input")
            if os.path.exists(freq_f):
                try:
                    f_val = int(open(freq_f).read().strip())
                    if f_val > 0:
                        sclk = round(f_val / 1000000.0)
                except Exception: pass
                
            for pf in [os.path.join(hw, "power1_average"), os.path.join(hw, "power1_input")]:
                if os.path.exists(pf):
                    try:
                        p_val = int(open(pf).read().strip()) / 1000000.0
                        if p_val > 0:
                            data["power"] = round(p_val, 1)
                            break
                    except Exception: pass
                    
            in0_f = os.path.join(hw, "in0_input")
            if os.path.exists(in0_f):
                try:
                    v_val = int(open(in0_f).read().strip()) / 1000.0
                    if v_val > 0:
                        data["voltage"] = round(v_val, 2)
                except Exception: pass
                
            for tf in glob.glob(os.path.join(hw, "temp*_input")):
                lf = tf.replace("_input", "_label")
                lbl = open(lf).read().strip().lower() if os.path.exists(lf) else ""
                try:
                    t_val = int(open(tf).read().strip()) / 1000.0
                    if 0 < t_val < 140:
                        if "junction" in lbl or "hotspot" in lbl:
                            data["hotspot"] = round(t_val, 1)
                        elif "mem" in lbl or "vram" in lbl:
                            data["vramTemp"] = round(t_val, 1)
                        elif not data.get("temp"):
                            data["temp"] = round(t_val, 1)
                except Exception: pass
                
            for fan_f in glob.glob(os.path.join(hw, "fan*_input")):
                try:
                    fan_val = int(open(fan_f).read().strip())
                    if fan_val >= 0:
                        data["fan"] = fan_val
                        break
                except Exception: pass

        # AMD DPM clocks
        if sclk <= 0 and os.path.exists(os.path.join(dev, "pp_dpm_sclk")):
            try:
                for line in open(os.path.join(dev, "pp_dpm_sclk")):
                    if "*" in line:
                        part = line.split(":")[-1].replace("*", "").strip()
                        num = int("".join(c for c in part if c.isdigit()))
                        if num > 0:
                            sclk = num
                            break
            except Exception: pass

        if mclk <= 0 and os.path.exists(os.path.join(dev, "pp_dpm_mclk")):
            try:
                for line in open(os.path.join(dev, "pp_dpm_mclk")):
                    if "*" in line:
                        part = line.split(":")[-1].replace("*", "").strip()
                        num = int("".join(c for c in part if c.isdigit()))
                        if num > 0:
                            mclk = num
                            break
            except Exception: pass

        # AMD gpu_metrics binary parsing
        gm_f = os.path.join(dev, "gpu_metrics")
        if os.path.exists(gm_f):
            try:
                with open(gm_f, "rb") as f:
                    buf = f.read()
                if len(buf) >= 70:
                    struct_size, fmt_rev, cnt_rev = struct.unpack_from("<HBB", buf, 0)
                    if fmt_rev == 2:  # APUs: Phoenix / Rembrandt / VanGogh
                        tsoc = struct.unpack_from("<H", buf, 6)[0] / 100.0
                        if 0 < tsoc < 140 and not data.get("hotspot"):
                            data["hotspot"] = round(tsoc, 1)
                        if sclk <= 0:
                            gfxclk = struct.unpack_from("<H", buf, 64)[0]
                            if gfxclk > 0: sclk = gfxclk
                        if mclk <= 0:
                            uclk = struct.unpack_from("<H", buf, 68)[0]
                            if uclk > 0: mclk = uclk
                    elif fmt_rev == 1:  # dGPUs: RDNA1 / RDNA2 / RDNA3
                        thot = struct.unpack_from("<H", buf, 6)[0] / 100.0
                        tmem = struct.unpack_from("<H", buf, 8)[0] / 100.0
                        if 0 < thot < 140 and not data.get("hotspot"):
                            data["hotspot"] = round(thot, 1)
                        if 0 < tmem < 140 and not data.get("vramTemp"):
                            data["vramTemp"] = round(tmem, 1)
                        if sclk <= 0 and len(buf) >= 28:
                            gfxclk = struct.unpack_from("<H", buf, 24)[0]
                            if gfxclk > 0: sclk = gfxclk
                        if mclk <= 0 and len(buf) >= 30:
                            uclk = struct.unpack_from("<H", buf, 28)[0]
                            if uclk > 0: mclk = uclk
            except Exception: pass

        # Intel frequency
        for gt_f in glob.glob(os.path.join(card, "gt_cur_freq_mhz")) + glob.glob(os.path.join(card, "gt", "gt*", "rps_cur_freq_mhz")):
            if sclk <= 0 and os.path.exists(gt_f):
                try:
                    f_val = int(open(gt_f).read().strip())
                    if f_val > 0: sclk = f_val
                except Exception: pass

        if sclk > 0:
            data["freq"] = sclk
        if mclk > 0:
            data["memFreq"] = mclk
            
        gpus[gid] = data

    # NVIDIA fallback via nvidia-smi
    if shutil.which("nvidia-smi"):
        try:
            res = subprocess.run(
                ["nvidia-smi", "--query-gpu=index,clocks.gr,clocks.mem,power.draw,temperature.gpu", "--format=csv,noheader,nounits"],
                capture_output=True, text=True, timeout=1.0
            )
            if res.returncode == 0:
                for line in res.stdout.strip().splitlines():
                    parts = [p.strip() for p in line.split(",")]
                    if len(parts) >= 5:
                        n_idx = f"gpu{parts[0]}"
                        if n_idx not in gpus:
                            gpus[n_idx] = {"id": n_idx}
                        if "freq" not in gpus[n_idx] and parts[1].isdigit():
                            gpus[n_idx]["freq"] = int(parts[1])
                        if "memFreq" not in gpus[n_idx] and parts[2].isdigit():
                            gpus[n_idx]["memFreq"] = int(parts[2])
                        if "power" not in gpus[n_idx]:
                            try: gpus[n_idx]["power"] = round(float(parts[3]), 1)
                            except: pass
                        if "temp" not in gpus[n_idx]:
                            try: gpus[n_idx]["temp"] = round(float(parts[4]), 1)
                            except: pass
        except Exception: pass

    # 2. CPU TELEMETRY
    cpu = {}
    c_freqs = []
    for f in sorted(glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq")):
        try:
            val = int(open(f).read().strip())
            c_freqs.append(round(val / 1000.0))
        except Exception: pass
    if c_freqs:
        cpu["freq"] = round(sum(c_freqs) / len(c_freqs))
        cpu["peakFreq"] = max(c_freqs)
        cpu["cores"] = c_freqs

    # 3. HWMON SCAN (CPU Temp, Power, Voltage, Fans, Disks, RAM)
    disks = {}
    ram_temps = []
    fans = {}
    
    for hw in glob.glob("/sys/class/hwmon/hwmon*"):
        name = open(f"{hw}/name").read().strip().lower() if os.path.exists(f"{hw}/name") else ""
        
        # CPU hardware monitor (k10temp, coretemp, zenpower, etc.)
        if any(k in name for k in ["k10temp", "coretemp", "zenpower", "acpitz", "cpu"]):
            for tf in glob.glob(f"{hw}/temp*_input"):
                try:
                    t = int(open(tf).read().strip()) / 1000.0
                    if 0 < t < 125 and "temp" not in cpu:
                        cpu["temp"] = round(t, 1)
                except Exception: pass
            for pf in glob.glob(f"{hw}/power*_input") + glob.glob(f"{hw}/power*_average"):
                try:
                    p = int(open(pf).read().strip()) / 1000000.0
                    if p > 0 and "power" not in cpu:
                        cpu["power"] = round(p, 1)
                except Exception: pass
            for vf in glob.glob(f"{hw}/in*_input"):
                try:
                    v = int(open(vf).read().strip()) / 1000.0
                    if 0.1 < v < 3.5 and "voltage" not in cpu:
                        cpu["voltage"] = round(v, 3)
                except Exception: pass
            for ff in glob.glob(f"{hw}/fan*_input"):
                try:
                    f_rpm = int(open(ff).read().strip())
                    if f_rpm >= 0 and "fan" not in cpu:
                        cpu["fan"] = f_rpm
                except Exception: pass
                
        # Motherboard generic sensors (e.g. nct6775, it87)
        elif any(k in name for k in ["nct67", "it87", "w83", "asusec"]):
            for vf in glob.glob(f"{hw}/in*_input"):
                lbl_f = vf.replace("_input", "_label")
                lbl = open(lbl_f).read().strip().lower() if os.path.exists(lbl_f) else ""
                if "vcore" in lbl or "cpu" in lbl:
                    try:
                        v = int(open(vf).read().strip()) / 1000.0
                        if 0.1 < v < 3.5:
                            cpu["voltage"] = round(v, 3)
                    except Exception: pass
            for ff in glob.glob(f"{hw}/fan*_input"):
                lbl_f = ff.replace("_input", "_label")
                lbl = open(lbl_f).read().strip().lower() if os.path.exists(lbl_f) else ""
                if "cpu" in lbl and "fan" not in cpu:
                    try:
                        f_rpm = int(open(ff).read().strip())
                        if f_rpm >= 0: cpu["fan"] = f_rpm
                    except Exception: pass

        # Disks (NVMe, SATA drivetemp via hwmon)
        if any(k in name for k in ["nvme", "drivetemp"]):
            t_f = f"{hw}/temp1_input"
            if os.path.exists(t_f):
                try:
                    t_val = round(int(open(t_f).read().strip()) / 1000.0, 1)
                    if 0 < t_val < 110:
                        disks[name] = t_val
                        dev_path = os.path.realpath(f"{hw}/device")
                        # Match block device name (e.g. nvme0n1, sda)
                        for blk in glob.glob("/sys/class/block/*"):
                            try:
                                if os.path.exists(f"{blk}/device") and os.path.realpath(f"{blk}/device") == dev_path:
                                    disks[os.path.basename(blk)] = t_val
                            except Exception: pass
                except Exception: pass

    # UDisks2 SMART DBus Query for HDDs (e.g. /dev/sda) and all storage drives
    try:
        import dbus
        bus = dbus.SystemBus()
        u_obj = bus.get_object("org.freedesktop.UDisks2", "/org/freedesktop/UDisks2")
        u_mgr = dbus.Interface(u_obj, "org.freedesktop.DBus.ObjectManager")
        u_objs = u_mgr.GetManagedObjects()

        drive_to_dev = {}
        for path, ifaces in u_objs.items():
            if "org.freedesktop.UDisks2.Block" in ifaces:
                blk = ifaces["org.freedesktop.UDisks2.Block"]
                dr_path = str(blk.get("Drive", ""))
                is_part = bool(blk.get("HintPartition", False))
                if dr_path and dr_path != "/" and not is_part:
                    dev_val = blk.get("Device")
                    if dev_val:
                        dev_str = bytes(bytearray(dev_val)).decode("utf-8", "ignore").strip("\x00")
                        dev_name = os.path.basename(dev_str)
                        if dev_name:
                            drive_to_dev[dr_path] = dev_name

        for path, ifaces in u_objs.items():
            p_str = str(path)
            t_c = None
            if "org.freedesktop.UDisks2.Drive.Ata" in ifaces:
                ata = ifaces["org.freedesktop.UDisks2.Drive.Ata"]
                if "SmartTemperature" in ata:
                    k = float(ata["SmartTemperature"])
                    if k > 200: t_c = round(k - 273.15, 1)
            if t_c is None and "org.freedesktop.UDisks2.NVMe.Controller" in ifaces:
                nv = ifaces["org.freedesktop.UDisks2.NVMe.Controller"]
                if "SmartTemperature" in nv:
                    k = float(nv["SmartTemperature"])
                    if k > 200: t_c = round(k - 273.15, 1)
            if t_c is None and "org.freedesktop.UDisks2.Drive" in ifaces:
                dr = ifaces["org.freedesktop.UDisks2.Drive"]
                for k in ["SmartTemperature", "Temperature"]:
                    if k in dr:
                        val = float(dr[k])
                        if val > 200: t_c = round(val - 273.15, 1); break
                        elif 0 < val < 120: t_c = round(val, 1); break

            if t_c is not None:
                dev_name = drive_to_dev.get(p_str)
                if dev_name:
                    disks[dev_name] = t_c
                    if dev_name.startswith("sd"):
                        disks["hdd"] = t_c
    except Exception:
        pass

        # DDR5 SPD RAM Temp (spd5118)
        if "spd5118" in name:
            t_f = f"{hw}/temp1_input"
            if os.path.exists(t_f):
                try:
                    t_val = round(int(open(t_f).read().strip()) / 1000.0, 1)
                    if 0 < t_val < 110:
                        ram_temps.append(t_val)
                except Exception: pass

        # All fan inputs
        for ff in glob.glob(f"{hw}/fan*_input"):
            try:
                f_rpm = int(open(ff).read().strip())
                if f_rpm >= 0:
                    lbl_f = ff.replace("_input", "_label")
                    lbl = open(lbl_f).read().strip() if os.path.exists(lbl_f) else f"{name}_{os.path.basename(ff)}"
                    fans[lbl] = f_rpm
            except Exception: pass

    # 4. BATTERIES
    batteries = {}
    for b in glob.glob("/sys/class/power_supply/BAT*"):
        bid = os.path.basename(b)
        binfo = {}
        for prop in ["capacity", "status", "voltage_now", "power_now", "current_now"]:
            fp = f"{b}/{prop}"
            if os.path.exists(fp):
                try: binfo[prop] = open(fp).read().strip()
                except Exception: pass
        if binfo:
            bdata = {}
            if "capacity" in binfo:
                try: bdata["capacity"] = int(binfo["capacity"])
                except Exception: pass
            if "status" in binfo:
                bdata["status"] = binfo["status"]
            if "power_now" in binfo:
                try: bdata["power"] = round(int(binfo["power_now"]) / 1000000.0, 1)
                except Exception: pass
            elif "voltage_now" in binfo and "current_now" in binfo:
                try:
                    v = int(binfo["voltage_now"]) / 1000000.0
                    c = int(binfo["current_now"]) / 1000000.0
                    bdata["power"] = round(v * c, 1)
                except Exception: pass
            if "voltage_now" in binfo:
                try: bdata["voltage"] = round(int(binfo["voltage_now"]) / 1000000.0, 2)
                except Exception: pass
            batteries[bid] = bdata

    # Assemble combined output
    # Populate root with gpu0, gpu1... for backward-compatibility
    result.update(gpus)
    result["gpus"] = gpus
    result["cpu"] = cpu
    result["disks"] = disks
    result["ram"] = {"temps": ram_temps}
    result["fans"] = fans
    result["batteries"] = batteries

    print(json.dumps(result))

if __name__ == "__main__":
    collect_telemetry()
