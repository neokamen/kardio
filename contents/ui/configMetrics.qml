import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.ksysguard.sensors as Sensors
import "./models"
import "./models/MetricDefinitions.js" as MetricDefinitions

KCM.SimpleKCM {
    id: metricsPage

    // ── cfg_ bindings ──────────────────────────────────────────────────────
    property string cfg_pinnedMetrics: ""
    property string cfg_cpuLabel: "CPU"
    property string cfg_cpuSubMetrics: "usage,freq,temp"
    property string cfg_ramLabel: "RAM"
    property string cfg_ramSubMetrics: "percentage"
    property string cfg_swapLabel: "SWAP"
    property string cfg_swapSubMetrics: "percent,used"
    property string cfg_tempLabel: "System"
    property string cfg_gpuSelection: ""
    property string cfg_gpuLabels: ""
    property string cfg_gpuSubMetrics: "usage,vram,temp"
    property string cfg_netLabel: "NET"
    property string cfg_netSubMetrics: "down,up"
    property string cfg_networkInterface: "auto"
    property bool cfg_showNetworkIp: false
    property string cfg_diskLabel: "DSK"
    property string cfg_diskLabels: ""
    property string cfg_diskSubMetrics: "read,write"
    property string cfg_diskTempIcon: "temperature-symbolic"
    property string cfg_fanLabel: "FAN"
    property string cfg_fanLabels: ""
    property int cfg_fanMaxRpm: 2000
    property string cfg_batteryDevice: "auto"
    property string cfg_batLabel: "BAT"
    property string cfg_batSubMetrics: "percentage,power"

    HardwareDiscovery {
        id: discovery
    }

    function hasSub(metricStr, key) {
        if (!metricStr) return false;
        var parts = metricStr.split(",").map(function(s){ return s.trim(); });
        return parts.indexOf(key) !== -1;
    }

    function toggleSub(metricStr, key) {
        var parts = metricStr ? metricStr.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; }) : [];
        var idx = parts.indexOf(key);
        if (idx !== -1) {
            parts.splice(idx, 1);
        } else {
            parts.push(key);
        }
        return parts.join(",");
    }

    ColumnLayout {
        id: mainMetricsCol
        spacing: Kirigami.Units.largeSpacing
        Layout.fillWidth: true

        // ═══════════════════════════════════════════════════════════════════
        // 1. HARDWARE RADAR BAR (RESUMEN EN TIEMPO REAL)
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: radarCol.implicitHeight + (Kirigami.Units.mediumSpacing * 2)
            radius: Kirigami.Units.smallSpacing
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.07)
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
            border.width: 1

            ColumnLayout {
                id: radarCol
                anchors.fill: parent
                anchors.margins: Kirigami.Units.mediumSpacing
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        source: "preferences-system-hardware"
                        width: 18; height: 18
                        color: Kirigami.Theme.highlightColor
                    }
                    Label {
                        text: i18n("RADAR DE SENSORES Y HARDWARE DETECTADO EN EL SISTEMA:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.weight: Font.Bold
                        color: Kirigami.Theme.highlightColor
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    // CPU Badge
                    Rectangle {
                        radius: 12
                        implicitHeight: 26
                        implicitWidth: cpuRow.implicitWidth + 16
                        color: Qt.rgba(52/255, 152/255, 219/255, 0.15)
                        border.color: Qt.rgba(52/255, 152/255, 219/255, 0.4)
                        RowLayout {
                            id: cpuRow
                            anchors.centerIn: parent
                            spacing: 6
                            Kirigami.Icon { source: "cpu-symbolic"; width: 14; height: 14; color: "#3498db" }
                            Label {
                                text: i18n("CPU: %1 núcleos detectados", discovery.discoveredCores.length > 0 ? discovery.discoveredCores.length : "Multi")
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.bold: true
                            }
                        }
                    }

                    // GPU Badge
                    Rectangle {
                        radius: 12
                        implicitHeight: 26
                        implicitWidth: gpuBadgeRow.implicitWidth + 16
                        color: Qt.rgba(155/255, 89/255, 182/255, 0.15)
                        border.color: Qt.rgba(155/255, 89/255, 182/255, 0.4)
                        RowLayout {
                            id: gpuBadgeRow
                            anchors.centerIn: parent
                            spacing: 6
                            Kirigami.Icon { source: "gpu-symbolic"; width: 14; height: 14; color: "#9b59b6" }
                            Label {
                                text: i18n("GPU: %1 unidad(es)", discovery.discoveredGpus.length)
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.bold: true
                            }
                        }
                    }

                    // Storage Badge
                    Rectangle {
                        radius: 12
                        implicitHeight: 26
                        implicitWidth: diskBadgeRow.implicitWidth + 16
                        color: Qt.rgba(230/255, 126/255, 34/255, 0.15)
                        border.color: Qt.rgba(230/255, 126/255, 34/255, 0.4)
                        RowLayout {
                            id: diskBadgeRow
                            anchors.centerIn: parent
                            spacing: 6
                            Kirigami.Icon { source: "storage-symbolic"; width: 14; height: 14; color: "#e67e22" }
                            Label {
                                text: i18n("Discos: %1 detectados (%2)", discovery.discoveredDisks.length, discovery.discoveredDisks.map(function(d){ return d.id; }).join(", "))
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.bold: true
                            }
                        }
                    }

                    // Wi-Fi Badge
                    Rectangle {
                        radius: 12
                        implicitHeight: 26
                        implicitWidth: wifiBadgeRow.implicitWidth + 16
                        color: Qt.rgba(46/255, 204/255, 113/255, 0.15)
                        border.color: Qt.rgba(46/255, 204/255, 113/255, 0.4)
                        RowLayout {
                            id: wifiBadgeRow
                            anchors.centerIn: parent
                            spacing: 6
                            Kirigami.Icon { source: "network-wireless-symbolic"; width: 14; height: 14; color: "#2ecc71" }
                            Label {
                                text: discovery.discoveredWifiTemps.length > 0
                                      ? i18n("Wi-Fi Sensor Térmico: Activo (%1)", discovery.discoveredWifiTemps[0])
                                      : i18n("Wi-Fi: Sin sensor térmico hwmon")
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 2. AVISO INFORMATIVO: DISCOS MECÁNICOS & DRIVETEMP
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            visible: true
            text: i18n("¿No ves la temperatura de tu disco duro mecánico (SATA/HDD)? En Linux, los discos mecánicos requieren el módulo drivetemp para exponer sus sensores de temperatura. Abre tu terminal y ejecuta: sudo modprobe drivetemp (o guárdalo en /etc/modules-load.d/drivetemp.conf para el arranque).")
            showCloseButton: false
        }

        // ═══════════════════════════════════════════════════════════════════
        // 3. SUBSISTEMA: PROCESADOR (CPU & FRECUENCIAS)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: Qt.rgba(52/255, 152/255, 219/255, 0.2)
                    Kirigami.Icon { anchors.centerIn: parent; source: "cpu-symbolic"; width: 16; height: 16; color: "#3498db" }
                }
                Kirigami.Heading { text: i18n("Procesador (CPU & Energía)"); level: 3; Layout.fillWidth: true }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing
                    Label { text: i18n("Etiqueta en panel:"); font.weight: Font.DemiBold; Layout.preferredWidth: 150 }
                    TextField {
                        text: cfg_cpuLabel
                        placeholderText: "CPU"
                        Layout.preferredWidth: 200
                        onTextEdited: cfg_cpuLabel = text.trim() || "CPU"
                    }
                }

                Label { text: i18n("Sub-métricas y telemetrías disponibles:"); font.weight: Font.DemiBold }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Button {
                        text: i18n("Uso de CPU (%)")
                        highlighted: hasSub(cfg_cpuSubMetrics, "usage")
                        onClicked: cfg_cpuSubMetrics = toggleSub(cfg_cpuSubMetrics, "usage")
                    }
                    Button {
                        text: i18n("Frecuencia Media (GHz)")
                        highlighted: hasSub(cfg_cpuSubMetrics, "freq")
                        onClicked: cfg_cpuSubMetrics = toggleSub(cfg_cpuSubMetrics, "freq")
                    }
                    Button {
                        text: i18n("⚡ Frecuencia Pico / Max (Turbo)")
                        highlighted: hasSub(cfg_cpuSubMetrics, "maxFreq")
                        onClicked: cfg_cpuSubMetrics = toggleSub(cfg_cpuSubMetrics, "maxFreq")
                    }
                    Button {
                        text: i18n("🔌 Consumo Paquete (Watts)")
                        highlighted: hasSub(cfg_cpuSubMetrics, "power")
                        onClicked: cfg_cpuSubMetrics = toggleSub(cfg_cpuSubMetrics, "power")
                    }
                    Button {
                        text: i18n("🌡️ Temperatura (°C)")
                        highlighted: hasSub(cfg_cpuSubMetrics, "temp")
                        onClicked: cfg_cpuSubMetrics = toggleSub(cfg_cpuSubMetrics, "temp")
                    }
                    Button {
                        text: i18n("Cargas (1m, 5m, 15m)")
                        highlighted: hasSub(cfg_cpuSubMetrics, "load1")
                        onClicked: {
                            var s = cfg_cpuSubMetrics;
                            s = toggleSub(s, "load1");
                            s = toggleSub(s, "load5");
                            s = toggleSub(s, "load15");
                            cfg_cpuSubMetrics = s;
                        }
                    }
                    Button {
                        text: i18n("Desglose Núcleos Cores")
                        highlighted: hasSub(cfg_cpuSubMetrics, "core")
                        onClicked: cfg_cpuSubMetrics = toggleSub(cfg_cpuSubMetrics, "core")
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 4. SUBSISTEMA: GRÁFICOS (GPU, VRAM & VOLTAJE)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: Qt.rgba(155/255, 89/255, 182/255, 0.2)
                    Kirigami.Icon { anchors.centerIn: parent; source: "gpu-symbolic"; width: 16; height: 16; color: "#9b59b6" }
                }
                Kirigami.Heading { text: i18n("Tarjeta Gráfica (GPU & VRAM)"); level: 3; Layout.fillWidth: true }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Label { text: i18n("GPUs Seleccionadas:"); font.weight: Font.DemiBold }

                    Flow {
                        Layout.fillWidth: true
                        width: parent.width
                        spacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: discovery.discoveredGpus
                            delegate: Button {
                                required property var modelData
                                text: modelData.name + " (" + modelData.id + ")"
                                highlighted: cfg_gpuSelection === "" || cfg_gpuSelection.indexOf(modelData.id) !== -1
                                onClicked: {
                                    var cur = cfg_gpuSelection ? cfg_gpuSelection.split(",") : [];
                                    var idx = cur.indexOf(modelData.id);
                                    if (idx !== -1) cur.splice(idx, 1);
                                    else cur.push(modelData.id);
                                    cfg_gpuSelection = cur.join(",");
                                }
                            }
                        }
                    }
                }

                Label { text: i18n("Sub-métricas avanzadas de GPU:"); font.weight: Font.DemiBold }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Button {
                        text: i18n("Carga GPU (%)")
                        highlighted: hasSub(cfg_gpuSubMetrics, "usage")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "usage")
                    }
                    Button {
                        text: i18n("Memoria VRAM")
                        highlighted: hasSub(cfg_gpuSubMetrics, "vram")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "vram")
                    }
                    Button {
                        text: i18n("🌡️ Temperatura Núcleo")
                        highlighted: hasSub(cfg_gpuSubMetrics, "temp")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "temp")
                    }
                    Button {
                        text: i18n("🔥 Punto Caliente (Hotspot)")
                        highlighted: hasSub(cfg_gpuSubMetrics, "hotspot")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "hotspot")
                    }
                    Button {
                        text: i18n("🧠 Temperatura de VRAM")
                        highlighted: hasSub(cfg_gpuSubMetrics, "vramTemp")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "vramTemp")
                    }
                    Button {
                        text: i18n("Reloj Núcleo (MHz/GHz)")
                        highlighted: hasSub(cfg_gpuSubMetrics, "freq")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "freq")
                    }
                    Button {
                        text: i18n("Reloj Memoria VRAM")
                        highlighted: hasSub(cfg_gpuSubMetrics, "memFreq")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "memFreq")
                    }
                    Button {
                        text: i18n("🔌 Potencia PPT (Watts)")
                        highlighted: hasSub(cfg_gpuSubMetrics, "power")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "power")
                    }
                    Button {
                        text: i18n("⚡ Voltaje Núcleo (Vddgfx)")
                        highlighted: hasSub(cfg_gpuSubMetrics, "voltage")
                        onClicked: cfg_gpuSubMetrics = toggleSub(cfg_gpuSubMetrics, "voltage")
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 5. SUBSISTEMA: MEMORIA (RAM & SWAP)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: Qt.rgba(46/255, 204/255, 113/255, 0.2)
                    Kirigami.Icon { anchors.centerIn: parent; source: "memory-symbolic"; width: 16; height: 16; color: "#2ecc71" }
                }
                Kirigami.Heading { text: i18n("Memoria (RAM & Archivo Swap)"); level: 3; Layout.fillWidth: true }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                GridLayout {
                    Layout.fillWidth: true
                    width: parent.width
                    columns: width > 520 ? 4 : 2
                    columnSpacing: Kirigami.Units.mediumSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    Label { text: i18n("Etiqueta RAM:"); font.weight: Font.DemiBold }
                    TextField {
                        text: cfg_ramLabel
                        placeholderText: "RAM"
                        Layout.fillWidth: true
                        onTextEdited: cfg_ramLabel = text.trim() || "RAM"
                    }
                    Label { text: i18n("Etiqueta Swap:"); font.weight: Font.DemiBold }
                    TextField {
                        text: cfg_swapLabel
                        placeholderText: "SWAP"
                        Layout.fillWidth: true
                        onTextEdited: cfg_swapLabel = text.trim() || "SWAP"
                    }
                }

                Label { text: i18n("Opciones de telemetría de memoria:"); font.weight: Font.DemiBold }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Button {
                        text: i18n("RAM: Porcentaje (%)")
                        highlighted: hasSub(cfg_ramSubMetrics, "percentage")
                        onClicked: cfg_ramSubMetrics = toggleSub(cfg_ramSubMetrics, "percentage")
                    }
                    Button {
                        text: i18n("RAM: Usado / Total (GB)")
                        highlighted: hasSub(cfg_ramSubMetrics, "used")
                        onClicked: cfg_ramSubMetrics = toggleSub(cfg_ramSubMetrics, "used")
                    }
                    Button {
                        text: i18n("🌡️ RAM: Temperatura (DDR5 SPD)")
                        highlighted: hasSub(cfg_ramSubMetrics, "temp")
                        onClicked: cfg_ramSubMetrics = toggleSub(cfg_ramSubMetrics, "temp")
                    }
                    Button {
                        text: i18n("SWAP: Porcentaje (%)")
                        highlighted: hasSub(cfg_swapSubMetrics, "percent")
                        onClicked: cfg_swapSubMetrics = toggleSub(cfg_swapSubMetrics, "percent")
                    }
                    Button {
                        text: i18n("SWAP: Usado (GB)")
                        highlighted: hasSub(cfg_swapSubMetrics, "used")
                        onClicked: cfg_swapSubMetrics = toggleSub(cfg_swapSubMetrics, "used")
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 6. SUBSISTEMA: ALMACENAMIENTO (DISCOS)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: Qt.rgba(230/255, 126/255, 34/255, 0.2)
                    Kirigami.Icon { anchors.centerIn: parent; source: "storage-symbolic"; width: 16; height: 16; color: "#e67e22" }
                }
                Kirigami.Heading { text: i18n("Almacenamiento (Discos & I/O)"); level: 3; Layout.fillWidth: true }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing
                    Label { text: i18n("Etiqueta principal:"); font.weight: Font.DemiBold; Layout.preferredWidth: 150 }
                    TextField {
                        text: cfg_diskLabel
                        placeholderText: "DSK"
                        Layout.preferredWidth: 200
                        onTextEdited: cfg_diskLabel = text.trim() || "DSK"
                    }
                }

                Label { text: i18n("Métricas de transferencia y estado de disco:"); font.weight: Font.DemiBold }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Button {
                        text: i18n("Velocidad de Lectura (↓)")
                        highlighted: hasSub(cfg_diskSubMetrics, "read")
                        onClicked: cfg_diskSubMetrics = toggleSub(cfg_diskSubMetrics, "read")
                    }
                    Button {
                        text: i18n("Velocidad de Escritura (↑)")
                        highlighted: hasSub(cfg_diskSubMetrics, "write")
                        onClicked: cfg_diskSubMetrics = toggleSub(cfg_diskSubMetrics, "write")
                    }
                    Button {
                        text: i18n("Porcentaje de Ocupación (%)")
                        highlighted: hasSub(cfg_diskSubMetrics, "usage")
                        onClicked: cfg_diskSubMetrics = toggleSub(cfg_diskSubMetrics, "usage")
                    }
                    Button {
                        text: i18n("Espacio Usado / Total")
                        highlighted: hasSub(cfg_diskSubMetrics, "space")
                        onClicked: cfg_diskSubMetrics = toggleSub(cfg_diskSubMetrics, "space")
                    }
                    Button {
                        text: i18n("🌡️ Temperatura de Discos")
                        highlighted: hasSub(cfg_diskSubMetrics, "temp")
                        onClicked: cfg_diskSubMetrics = toggleSub(cfg_diskSubMetrics, "temp")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    visible: hasSub(cfg_diskSubMetrics, "temp")

                    Label {
                        text: i18n("Icono de temperatura:")
                        font.weight: Font.DemiBold
                        Layout.preferredWidth: 150
                    }

                    Button {
                        text: i18n("Termómetro (🌡️)")
                        icon.name: "temperature-symbolic"
                        highlighted: cfg_diskTempIcon === "temperature-symbolic"
                        onClicked: cfg_diskTempIcon = "temperature-symbolic"
                    }

                    Button {
                        text: i18n("Disco Duro (🖴)")
                        icon.name: "storage-symbolic"
                        highlighted: cfg_diskTempIcon === "storage-symbolic"
                        onClicked: cfg_diskTempIcon = "storage-symbolic"
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 7. SUBSISTEMA: RED & CONEXIONES
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: Qt.rgba(241/255, 196/255, 15/255, 0.2)
                    Kirigami.Icon { anchors.centerIn: parent; source: "network-symbolic"; width: 16; height: 16; color: "#f1c40f" }
                }
                Kirigami.Heading { text: i18n("Red y Telemetría Inalámbrica"); level: 3; Layout.fillWidth: true }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing
                    Label { text: i18n("Interfaz activa:"); font.weight: Font.DemiBold; Layout.preferredWidth: 150 }
                    ComboBox {
                        model: discovery.discoveredNetworkIfaces
                        currentIndex: {
                            var idx = discovery.discoveredNetworkIfaces.indexOf(cfg_networkInterface);
                            return idx >= 0 ? idx : 0;
                        }
                        onActivated: cfg_networkInterface = discovery.discoveredNetworkIfaces[currentIndex]
                    }
                }

                Label { text: i18n("Telemetría de tráfico y hardware de red:"); font.weight: Font.DemiBold }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Button {
                        text: i18n("Descarga en vivo (↓)")
                        highlighted: hasSub(cfg_netSubMetrics, "down")
                        onClicked: cfg_netSubMetrics = toggleSub(cfg_netSubMetrics, "down")
                    }
                    Button {
                        text: i18n("Subida en vivo (↑)")
                        highlighted: hasSub(cfg_netSubMetrics, "up")
                        onClicked: cfg_netSubMetrics = toggleSub(cfg_netSubMetrics, "up")
                    }
                    Button {
                        text: i18n("Total Descargado Sesión")
                        highlighted: hasSub(cfg_netSubMetrics, "totalDown")
                        onClicked: cfg_netSubMetrics = toggleSub(cfg_netSubMetrics, "totalDown")
                    }
                    Button {
                        text: i18n("Total Subido Sesión")
                        highlighted: hasSub(cfg_netSubMetrics, "totalUp")
                        onClicked: cfg_netSubMetrics = toggleSub(cfg_netSubMetrics, "totalUp")
                    }
                    Button {
                        text: i18n("📶 Señal Wi-Fi (%)")
                        highlighted: hasSub(cfg_netSubMetrics, "signal")
                        onClicked: cfg_netSubMetrics = toggleSub(cfg_netSubMetrics, "signal")
                    }
                    Button {
                        text: i18n("🌡️ Temperatura Wi-Fi")
                        highlighted: hasSub(cfg_netSubMetrics, "temp")
                        onClicked: cfg_netSubMetrics = toggleSub(cfg_netSubMetrics, "temp")
                    }
                    Button {
                        text: i18n("Dirección IP Local")
                        highlighted: hasSub(cfg_netSubMetrics, "ip")
                        onClicked: cfg_netSubMetrics = toggleSub(cfg_netSubMetrics, "ip")
                    }
                }
            }
        }
    }
}
