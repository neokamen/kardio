#!/usr/bin/env python3
import os, glob, struct, json, subprocess, shutil

def collect_gpu():
    gpus = {}
    cards = sorted(glob.glob("/sys/class/drm/card[0-9]"))
    
    for idx, card in enumerate(cards):
        dev = os.path.join(card, "device")
        if not os.path.exists(dev):
            continue
            
        gid = f"gpu{idx}"
        data = {"id": gid}
        
        sclk = 0
        mclk = 0
        
        # 1. Hwmon search
        for hw in glob.glob(os.path.join(dev, "hwmon", "hwmon*")):
            # SCLK frequency (freq1_input is in Hz)
            freq_f = os.path.join(hw, "freq1_input")
            if os.path.exists(freq_f):
                try:
                    f_val = int(open(freq_f).read().strip())
                    if f_val > 0:
                        sclk = round(f_val / 1000000.0)
                except Exception: pass
                
            # Power in watts (power1_average/input is in microWatts)
            for pf in [os.path.join(hw, "power1_average"), os.path.join(hw, "power1_input")]:
                if os.path.exists(pf):
                    try:
                        p_val = int(open(pf).read().strip()) / 1000000.0
                        if p_val > 0:
                            data["power"] = round(p_val, 1)
                            break
                    except Exception: pass
                    
            # Voltage in Volts (in0_input is in mV)
            in0_f = os.path.join(hw, "in0_input")
            if os.path.exists(in0_f):
                try:
                    v_val = int(open(in0_f).read().strip()) / 1000.0
                    if v_val > 0:
                        data["voltage"] = round(v_val, 2)
                except Exception: pass
                
            # Temperatures (temp*_input is in millidegrees C)
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
                
            # Fan RPM
            for fan_f in glob.glob(os.path.join(hw, "fan*_input")):
                try:
                    fan_val = int(open(fan_f).read().strip())
                    if fan_val >= 0:
                        data["fan"] = fan_val
                        break
                except Exception: pass

        # 2. AMD DPM clocks (pp_dpm_sclk / pp_dpm_mclk)
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

        # 3. AMD gpu_metrics binary parsing
        gm_f = os.path.join(dev, "gpu_metrics")
        if os.path.exists(gm_f):
            try:
                with open(gm_f, "rb") as f:
                    buf = f.read()
                if len(buf) >= 70:
                    struct_size, fmt_rev, cnt_rev = struct.unpack_from("<HBB", buf, 0)
                    if fmt_rev == 2:  # APUs: Phoenix / Rembrandt / VanGogh
                        tgfx = struct.unpack_from("<H", buf, 4)[0] / 100.0
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
                        tedge = struct.unpack_from("<H", buf, 4)[0] / 100.0
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

        # 4. Intel frequency (gt_cur_freq_mhz)
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

    # 5. NVIDIA fallback via nvidia-smi if no DRM cards or missing metrics
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

    print(json.dumps(gpus))

if __name__ == "__main__":
    collect_gpu()
