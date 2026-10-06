# Kardio - the plasma monitor

<p align="center">
  <img src="contents/icons/kardio.svg" width="128" height="128" alt="Kardio Icon" />
</p>

**Kardio** is a modular, high-performance system vitals monitor applet designed for **KDE Plasma 6**.

Built with love for Linux power users, Kardio gives you real-time insight into your system's heartbeat directly from your Plasma panel or desktop, featuring extensive GPU telemetry (including Hotspot, VRAM temperature, and memory clocks), CPU per-core tracking, NVMe/disk stats, network bandwidth, fan speeds, and DDR5 RAM thermal sensors.

---

## Features

- **Extensive Telemetry**:
  - **CPU**: Total load, per-core utilization, clock frequency, temperature, 1m/5m/15m load averages.
  - **GPU**: Core usage, VRAM used/total, Core temperature, **GPU Hotspot / Junction temperature**, **VRAM / Memory temperature**, Core clock, **VRAM clock**, and power draw (W).
  - **Memory (RAM & Swap)**: Used, free, percentage, DDR5 SPD5118 temperature sensors.
  - **Disks / Storage**: Per-drive read/write throughput, usage percentages, NVMe drive temperatures.
  - **Network**: Real-time download/upload speed, total session traffic, local IP address, Wi-Fi signal strength.
  - **Cooling & Power**: Fan RPMs with dynamic scaling, battery health & charge rates.
  - **System**: Uptime and chipset/motherboard sensors.
- **Customizable Compact & Expanded Views**:
  - Compact panel widget: Display icons, text, or both. Customize font, sizes, spacing, opacity, and delimiters.
  - Expandable popup: Clean categorized breakdown with per-metric pinning.
- **Profiles**: Switch between gaming, coding, or minimalist layouts on the fly (shortcut: `Meta+Shift+K`).
- **Alerts & Thresholds**: Color indicators for warning and critical thresholds per sensor.

---

## Installation

### Quick Install (Local)

Run the included install script:

```bash
./install.sh
```

Then:
1. Right-click on your KDE Plasma panel or desktop.
2. Select **Add Widgets...**
3. Search for **Kardio**.
4. Drag and drop it onto your panel!

### Testing in a Window

You can test the applet immediately without restarting Plasma using `plasmawindowed`:

```bash
plasmawindowed org.kde.plasma.kardio
```

---

## License

GPL-3.0 License. See [LICENSE](LICENSE) for details.
