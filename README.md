# Kardio - the plasma monitor

<p align="center">
  <img src="kardio-banner.svg" alt="Kardio - the plasma monitor" width="100%" />
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
  - Expandable popup: Clean categorized breakdown with per-metric pinning and live hardware scanner.
  - Individual whitespace alignment / padding per sensor for fixed-width, jitter-free readouts.
  - Network unit options: configurable minimum unit (Auto, force KB, force MB) for download and upload.
  - Dynamic memory units (MB up to 1024 MB, then GB) with group-level sequence sorting.
  - Individual icon toggles and customizable symbolic icons per sensor.
- **Profiles & Presets**: Switch between custom setups on the fly or create new presets directly from the widget (shortcut: `Meta+Shift+K`).
- **Alerts & Thresholds**: Color indicators for warning and critical thresholds per sensor with built-in thermal spectrum simulator.
- **Internationalization (i18n)**:
  - Full native multi-language support: **English**, **Català**, and **Español**.
  - Automatic system language detection (`LANG` / `LC_MESSAGES`).
  - Automatic fallback to **English** for any other system language.

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

## Author & Repository

- **Author**: AlexMC "neokamen"
- **GitHub**: [https://github.com/neokamen/kardio](https://github.com/neokamen/kardio)

---

## License

GPL-3.0 License. See [LICENSE](LICENSE) for details.


