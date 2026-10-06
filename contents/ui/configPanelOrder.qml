import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "./models"
import "./models/MetricDefinitions.js" as MetricDefinitions

KCM.SimpleKCM {
    id: panelOrderPage

    property string cfg_pinnedMetrics: "cpu/usage,ram/percentage,temp/system,net/down,net/up"
    property string cfg_cpuLabel: "CPU"
    property string cfg_ramLabel: "RAM"
    property string cfg_swapLabel: "SWAP"
    property string cfg_tempLabel: "System"
    property string cfg_netLabel: "NET"
    property string cfg_diskLabel: "DSK"
    property string cfg_diskLabels: "{}"
    property string cfg_fanLabel: "FAN"
    property string cfg_batLabel: "BAT"

    HardwareDiscovery {
        id: discovery
    }

    property string activeCatalogCategory: "all"
    property string catalogSearchQuery: ""
    property string previewOrientation: "horizontal"

    function resolveIcon(name) {
        if (!name) return "configure";
        var str = String(name);
        if (MetricDefinitions.isBundledIcon(str)) {
            return Qt.resolvedUrl("../icons/" + str + ".svg");
        }
        return name;
    }

    function getDiskDisplayName(did) {
        if (!did) return "";
        var disks = discovery.discoveredDisks || [];
        for (var i = 0; i < disks.length; i++) {
            if (disks[i].id === did) return disks[i].name || did;
        }
        return did;
    }

    // Computed list of pinned items
    readonly property var currentList: {
        if (!cfg_pinnedMetrics) return [];
        return cfg_pinnedMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    }

    function isPinned(id) {
        return currentList.indexOf(id) !== -1;
    }

    function toggleItem(id) {
        if (!id) return;
        var list = currentList.slice();
        var idx = list.indexOf(id);
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(id);
        }
        cfg_pinnedMetrics = list.join(",");
    }

    function removeItem(index) {
        if (index < 0 || index >= currentList.length) return;
        var list = currentList.slice();
        list.splice(index, 1);
        cfg_pinnedMetrics = list.join(",");
    }

    function moveItem(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= currentList.length || toIdx < 0 || toIdx >= currentList.length || fromIdx === toIdx) return;
        var list = currentList.slice();
        var item = list.splice(fromIdx, 1)[0];
        list.splice(toIdx, 0, item);
        cfg_pinnedMetrics = list.join(",");
    }

    function reverseOrder() {
        var list = currentList.slice().reverse();
        cfg_pinnedMetrics = list.join(",");
    }

    function autoOrganizeByHierarchy() {
        var priority = ["cpu", "gpu", "ram", "swap", "disk", "net", "temp", "bat", "fan", "uptime"];
        var list = currentList.slice();
        list.sort(function(a, b) {
            var groupA = a.indexOf(":") !== -1 ? a.substring(0, a.indexOf(":")) : (a.indexOf("/") !== -1 ? a.substring(0, a.indexOf("/")) : a);
            var groupB = b.indexOf(":") !== -1 ? b.substring(0, b.indexOf(":")) : (b.indexOf("/") !== -1 ? b.substring(0, b.indexOf("/")) : b);
            var idxA = priority.indexOf(groupA);
            var idxB = priority.indexOf(groupB);
            if (idxA === -1) idxA = 99;
            if (idxB === -1) idxB = 99;
            if (idxA !== idxB) return idxA - idxB;
            return a.localeCompare(b);
        });
        cfg_pinnedMetrics = list.join(",");
    }

    function getCategoryColor(group) {
        switch (group) {
            case "cpu": return "#3498db";
            case "gpu": return "#9b59b6";
            case "ram":
            case "swap": return "#2ecc71";
            case "disk": return "#e67e22";
            case "net": return "#f1c40f";
            case "temp": return "#e74c3c";
            case "bat": return "#1abc9c";
            case "fan": return "#00cec9";
            default: return Kirigami.Theme.highlightColor;
        }
    }

    function describeMetric(instanceId) {
        if (!instanceId) return { id: "", label: "", icon: "configure", preview: "", group: "other", color: Kirigami.Theme.highlightColor };
        var colonIdx = instanceId.indexOf(":");
        var slashIdx = instanceId.indexOf("/");
        var group = "";
        var devId = "";
        var subKey = "";

        if (colonIdx !== -1) {
            group = instanceId.substring(0, colonIdx);
            devId = instanceId.substring(colonIdx + 1, slashIdx !== -1 ? slashIdx : instanceId.length);
            subKey = slashIdx !== -1 ? instanceId.substring(slashIdx + 1) : "";
        } else if (slashIdx !== -1) {
            group = instanceId.substring(0, slashIdx);
            subKey = instanceId.substring(slashIdx + 1);
        } else {
            group = instanceId;
        }

        var defKey = group + "." + subKey;
        var def = MetricDefinitions.DEFINITIONS[defKey] || {};
        var grp = MetricDefinitions.GROUPS[group] || {};

        var icon = (subKey === "temp" || group === "temp") ? "temperature-symbolic" : (grp.defaultIcon || "configure");
        var groupTitle = grp.name || group.toUpperCase();
        var subLabel = def.label || subKey;
        var displayName = (devId ? devId + " " : "") + subLabel;

        // Preview sample values
        var previewVal = "";
        if (group === "cpu") {
            if (subKey === "core") {
                var cNum = parseInt(devId.replace("cpu", ""), 10);
                displayName = "Core " + (!isNaN(cNum) ? (cNum + 1) : devId);
                previewVal = "28%";
            } else if (subKey === "maxFreq") {
                displayName = i18n("CPU Peak Freq");
                previewVal = "4.20 GHz";
            } else if (subKey === "power") {
                icon = "voltage-symbolic";
                displayName = i18n("CPU Watts");
                previewVal = "28.5 W";
            } else {
                previewVal = subKey === "usage" ? "18%" : (subKey === "freq" ? "3.20 GHz" : (subKey === "temp" ? "52°C" : "1.20"));
            }
        } else if (group === "ram") {
            previewVal = subKey === "percentage" ? "42%" : (subKey === "used" ? "6.8/16G" : "45°C");
            if (subKey === "temp") {
                icon = "temperature-symbolic";
                displayName = i18n("RAM Temp");
            }
        } else if (group === "swap") {
            previewVal = subKey === "percent" ? "0%" : "0 MB";
        } else if (group === "temp") {
            previewVal = "48°C";
        } else if (group === "bat") {
            previewVal = subKey === "percentage" ? "92%" : (subKey === "power" ? "12.5W" : "96%");
        } else if (group === "net") {
            if (subKey === "signal") {
                icon = "network-wireless-symbolic";
                previewVal = "85%";
            } else if (subKey === "temp") {
                icon = "network-wireless-symbolic";
                displayName = i18n("Wi-Fi Temp");
                previewVal = "44°C";
            } else if (subKey === "totalDown") {
                icon = "network-download-symbolic";
                previewVal = "2.1 GB";
            } else if (subKey === "totalUp") {
                icon = "network-upload-symbolic";
                previewVal = "380 MB";
            } else {
                previewVal = subKey === "down" ? "↓ 1.4MB" : (subKey === "up" ? "↑ 320KB" : "192.168.1.15");
            }
        } else if (group === "disk") {
            if (devId) {
                displayName = panelOrderPage.getDiskDisplayName(devId) + " " + subLabel;
            }
            previewVal = subKey === "read" ? "↓ 42MB" : (subKey === "write" ? "↑ 18MB" : (subKey === "usage" ? "38%" : "42°C"));
        } else if (group === "fan") {
            previewVal = "1850 RPM";
        } else if (group === "uptime") {
            previewVal = "3h 12m";
        } else if (group === "gpu") {
            if (subKey === "hotspot") {
                icon = "temperature-symbolic";
                previewVal = "64°C";
            } else if (subKey === "vramTemp") {
                icon = "temperature-symbolic";
                previewVal = "58°C";
            } else if (subKey === "memFreq") {
                previewVal = "2000 MHz";
            } else if (subKey === "temp") {
                icon = "temperature-symbolic";
                previewVal = "50°C";
            } else if (subKey === "power") {
                icon = "voltage-symbolic";
                previewVal = "35.0W";
            } else if (subKey === "voltage") {
                icon = "voltage-symbolic";
                displayName = "GPU Volt";
                previewVal = "0.92 V";
            } else if (subKey === "usage") {
                previewVal = "28%";
            } else if (subKey === "vram") {
                previewVal = "1.8/8G";
            } else {
                previewVal = "1500 MHz";
            }
        }

        return {
            id: instanceId,
            group: group,
            deviceId: devId,
            subKey: subKey,
            icon: icon,
            groupTitle: groupTitle,
            label: displayName,
            preview: previewVal,
            color: getCategoryColor(group)
        };
    }

    // Palette categories
    readonly property var paletteCategories: {
        var cats = [];

        // 1. CPU
        var cores = discovery.discoveredCores || [];
        var cpuItems = [
            { id: "cpu/usage", label: i18n("CPU Uso (%)"), icon: "cpu-symbolic", group: "cpu" },
            { id: "cpu/freq", label: i18n("CPU Frecuencia Media"), icon: "cpu-symbolic", group: "cpu" },
            { id: "cpu/maxFreq", label: i18n("⚡ CPU Frecuencia Pico (Turbo)"), icon: "cpu-symbolic", group: "cpu" },
            { id: "cpu/power", label: i18n("🔌 CPU Consumo (Watts)"), icon: "voltage-symbolic", group: "cpu" },
            { id: "cpu/temp", label: i18n("🌡️ CPU Temperatura"), icon: "temperature-symbolic", group: "cpu" },
            { id: "cpu/load1", label: i18n("CPU Carga (1m)"), icon: "cpu-symbolic", group: "cpu" }
        ];
        for (var ci = 0; ci < Math.min(cores.length, 8); ci++) {
            cpuItems.push({ id: "cpu:" + cores[ci].id + "/core", label: cores[ci].name, icon: "cpu-symbolic", group: "cpu" });
        }
        cats.push({
            id: "cpu",
            title: i18n("Procesador (CPU)"),
            icon: "cpu-symbolic",
            color: "#3498db",
            items: cpuItems
        });

        // 2. GPU
        var gpus = discovery.discoveredGpus || [];
        var gpuItems = [];
        for (var gi = 0; gi < gpus.length; gi++) {
            var gid = gpus[gi].id;
            var gName = gpus[gi].name;
            gpuItems.push({ id: "gpu:" + gid + "/usage", label: gName + " Uso (%)", icon: "gpu-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/vram", label: gName + " VRAM", icon: "gpu-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/temp", label: gName + " Temp", icon: "temperature-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/hotspot", label: gName + " Hotspot", icon: "temperature-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/vramTemp", label: gName + " VRAM Temp", icon: "temperature-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/freq", label: gName + " Reloj Núcleo", icon: "gpu-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/memFreq", label: gName + " Reloj VRAM", icon: "gpu-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/power", label: gName + " Watts", icon: "voltage-symbolic", group: "gpu" });
            gpuItems.push({ id: "gpu:" + gid + "/voltage", label: gName + " Voltaje", icon: "voltage-symbolic", group: "gpu" });
        }
        if (gpuItems.length > 0) {
            cats.push({
                id: "gpu",
                title: i18n("Gráficos (GPU & VRAM)"),
                icon: "gpu-symbolic",
                color: "#9b59b6",
                items: gpuItems
            });
        }

        // 3. RAM & Swap
        cats.push({
            id: "ram",
            title: i18n("Memoria (RAM & SWAP)"),
            icon: "memory-symbolic",
            color: "#2ecc71",
            items: [
                { id: "ram/percentage", label: i18n("RAM Porcentaje (%)"), icon: "memory-symbolic", group: "ram" },
                { id: "ram/used", label: i18n("RAM Usado / Total"), icon: "memory-symbolic", group: "ram" },
                { id: "ram/temp", label: i18n("🌡️ RAM Temp (DDR5)"), icon: "temperature-symbolic", group: "ram" },
                { id: "swap/percent", label: i18n("SWAP Porcentaje (%)"), icon: "memory-symbolic", group: "ram" },
                { id: "swap/used", label: i18n("SWAP Usado"), icon: "memory-symbolic", group: "ram" }
            ]
        });

        // 4. Storage
        var disks = discovery.discoveredDisks || [];
        var diskItems = [
            { id: "disk/usage", label: i18n("Discos Uso Global (%)"), icon: "storage-symbolic", group: "disk" },
            { id: "disk/space", label: i18n("Espacio Global Usado/Total"), icon: "storage-symbolic", group: "disk" }
        ];
        for (var di = 0; di < disks.length; di++) {
            var did = disks[di].id;
            var dName = panelOrderPage.getDiskDisplayName(did);
            diskItems.push({ id: "disk:" + did + "/read", label: dName + " Lectura", icon: "network-download-symbolic", group: "disk" });
            diskItems.push({ id: "disk:" + did + "/write", label: dName + " Escritura", icon: "network-upload-symbolic", group: "disk" });
            diskItems.push({ id: "disk:" + did + "/temp", label: dName + " Temp", icon: "temperature-symbolic", group: "disk" });
        }
        cats.push({
            id: "disk",
            title: i18n("Almacenamiento (Discos)"),
            icon: "storage-symbolic",
            color: "#e67e22",
            items: diskItems
        });

        // 5. Network
        var netItems = [
            { id: "net/down", label: i18n("Descarga (↓)"), icon: "network-download-symbolic", group: "net" },
            { id: "net/up", label: i18n("Subida (↑)"), icon: "network-upload-symbolic", group: "net" },
            { id: "net/totalDown", label: i18n("Total Descargado"), icon: "network-download-symbolic", group: "net" },
            { id: "net/totalUp", label: i18n("Total Subido"), icon: "network-upload-symbolic", group: "net" },
            { id: "net/signal", label: i18n("📶 Señal Wi-Fi"), icon: "network-wireless-symbolic", group: "net" },
            { id: "net/temp", label: i18n("🌡️ Wi-Fi Temperatura"), icon: "network-wireless-symbolic", group: "net" },
            { id: "net/ip", label: i18n("IP Local"), icon: "network-symbolic", group: "net" }
        ];
        cats.push({
            id: "net",
            title: i18n("Red & Conectividad"),
            icon: "network-symbolic",
            color: "#f1c40f",
            items: netItems
        });

        // 6. System & Cooling
        var otherItems = [
            { id: "temp/system", label: i18n("🌡️ Sistema Temp"), icon: "temperature-symbolic", group: "system" },
            { id: "bat/percentage", label: i18n("Batería (%)"), icon: "battery-symbolic", group: "system" },
            { id: "bat/power", label: i18n("Batería Watts"), icon: "voltage-symbolic", group: "system" },
            { id: "uptime/uptime", label: i18n("Tiempo Encendido (Uptime)"), icon: "system-symbolic", group: "system" }
        ];
        var fans = discovery.discoveredFans || [];
        for (var fi = 0; fi < fans.length; fi++) {
            otherItems.push({ id: "fan:" + fans[fi].id + "/speed", label: i18n("Ventilador %1 RPM", (fi + 1)), icon: "fan-symbolic", group: "system" });
        }
        cats.push({
            id: "system",
            title: i18n("Refrigeración, Batería & Sistema"),
            icon: "system-symbolic",
            color: "#1abc9c",
            items: otherItems
        });

        return cats;
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.fillWidth: true

        // ═══════════════════════════════════════════════════════════════════
        // 1. KARDIO VIRTUAL DOCK SIMULATOR (SIMULADOR DE BARRA PLASMA)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true

            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "video-display"
                    implicitWidth: 20; implicitHeight: 20
                    color: Kirigami.Theme.highlightColor
                }

                Kirigami.Heading {
                    text: i18n("Simulador del Panel Plasma (Previsualización en Vivo)")
                    level: 3
                    Layout.fillWidth: true
                }

                Rectangle {
                    radius: 10
                    implicitHeight: 22
                    implicitWidth: countBadgeLabel.implicitWidth + 14
                    color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                    border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)
                    border.width: 1

                    QQC2.Label {
                        id: countBadgeLabel
                        anchors.centerIn: parent
                        text: i18n("%1 métricas activas", panelOrderPage.currentList.length)
                        font.bold: true
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        color: Kirigami.Theme.highlightColor
                    }
                }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                QQC2.Label {
                    text: i18n("Así es exactamente como se renderiza Kardio en tu panel de KDE. Puedes previsualizarlo en orientación horizontal o vertical:")
                    opacity: 0.75
                }

                // Orientation switch pills
                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Button {
                        text: i18n("⬌ Vista Horizontal (Panel Superior/Inferior)")
                        icon.name: "view-list-icons"
                        highlighted: panelOrderPage.previewOrientation === "horizontal"
                        onClicked: panelOrderPage.previewOrientation = "horizontal"
                    }

                    QQC2.Button {
                        text: i18n("⬍ Vista Vertical (Panel Lateral)")
                        icon.name: "view-list-details"
                        highlighted: panelOrderPage.previewOrientation === "vertical"
                        onClicked: panelOrderPage.previewOrientation = "vertical"
                    }
                }

                // Simulated Plasma Panel Container
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: panelOrderPage.previewOrientation === "horizontal" ? 64 : 140
                    radius: 12
                    color: Qt.rgba(20/255, 24/255, 30/255, 0.92)
                    border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.35)
                    border.width: 1.5

                    // Empty indicator
                    QQC2.Label {
                        anchors.centerIn: parent
                        visible: panelOrderPage.currentList.length === 0
                        text: i18n("El panel está vacío. Selecciona métricas del catálogo inferior para añadirlas.")
                        opacity: 0.5
                        font.italic: true
                    }

                    // Horizontal Panel Simulation
                    QQC2.ScrollView {
                        anchors.fill: parent
                        anchors.margins: 10
                        visible: panelOrderPage.previewOrientation === "horizontal" && panelOrderPage.currentList.length > 0
                        clip: true
                        contentHeight: availableHeight
                        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff

                        RowLayout {
                            spacing: 12
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: panelOrderPage.currentList

                                delegate: RowLayout {
                                    id: simItemH
                                    required property var modelData
                                    required property int index
                                    spacing: 6

                                    property var info: panelOrderPage.describeMetric(simItemH.modelData)

                                    Kirigami.Icon {
                                        source: panelOrderPage.resolveIcon(simItemH.info.icon)
                                        implicitWidth: 15; implicitHeight: 15
                                        color: simItemH.info.color
                                    }

                                    QQC2.Label {
                                        text: simItemH.info.label
                                        font.bold: false
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        color: Kirigami.Theme.textColor
                                        opacity: 0.7
                                    }

                                    QQC2.Label {
                                        text: simItemH.info.preview
                                        font.bold: true
                                        font.family: "monospace"
                                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                        color: Kirigami.Theme.textColor
                                    }

                                    // Pipe separator
                                    Rectangle {
                                        visible: simItemH.index < panelOrderPage.currentList.length - 1
                                        implicitWidth: 1; implicitHeight: 14
                                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
                                        Layout.leftMargin: 4
                                    }
                                }
                            }
                        }
                    }

                    // Vertical Panel Simulation
                    QQC2.ScrollView {
                        anchors.fill: parent
                        anchors.margins: 10
                        visible: panelOrderPage.previewOrientation === "vertical" && panelOrderPage.currentList.length > 0
                        clip: true
                        contentWidth: availableWidth

                        ColumnLayout {
                            spacing: 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            Repeater {
                                model: panelOrderPage.currentList

                                delegate: RowLayout {
                                    id: simItemV
                                    required property var modelData
                                    required property int index
                                    spacing: 8

                                    property var info: panelOrderPage.describeMetric(simItemV.modelData)

                                    Kirigami.Icon {
                                        source: panelOrderPage.resolveIcon(simItemV.info.icon)
                                        implicitWidth: 16; implicitHeight: 16
                                        color: simItemV.info.color
                                    }

                                    QQC2.Label {
                                        text: simItemV.info.label
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        opacity: 0.7
                                    }

                                    QQC2.Label {
                                        text: simItemV.info.preview
                                        font.bold: true
                                        font.family: "monospace"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 2. INTERACTIVE SEQUENCE DECK (BANDEJA DE ORDENACIÓN VISUAL)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true

            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "edit-list-order"
                    implicitWidth: 20; implicitHeight: 20
                    color: Kirigami.Theme.highlightColor
                }

                Kirigami.Heading {
                    text: i18n("Secuencia y Posición en el Panel")
                    level: 3
                    Layout.fillWidth: true
                }

                // Batch reordering tools
                QQC2.Button {
                    icon.name: "view-sort-ascending"
                    text: i18n("Jerarquía Lógica")
                    QQC2.ToolTip.text: i18n("Auto-organiza por orden óptimo: CPU ➔ GPU ➔ RAM ➔ Discos ➔ Red ➔ Sistema")
                    QQC2.ToolTip.visible: hovered
                    onClicked: panelOrderPage.autoOrganizeByHierarchy()
                }

                QQC2.Button {
                    icon.name: "reverse"
                    text: i18n("Invertir")
                    QQC2.ToolTip.text: i18n("Invierte la secuencia de izquierda a derecha")
                    QQC2.ToolTip.visible: hovered
                    onClicked: panelOrderPage.reverseOrder()
                }

                QQC2.Button {
                    icon.name: "edit-clear"
                    text: i18n("Vaciar")
                    enabled: panelOrderPage.currentList.length > 0
                    onClicked: panelOrderPage.cfg_pinnedMetrics = ""
                }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                QQC2.Label {
                    text: i18n("Arrastra o pulsa las flechas para desplazar cada elemento a la posición exacta que desees:")
                    opacity: 0.75
                }

                // Flow of sequence cards
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Repeater {
                        model: panelOrderPage.currentList

                        delegate: Rectangle {
                            id: sequenceChip
                            required property var modelData
                            required property int index

                            property var info: panelOrderPage.describeMetric(sequenceChip.modelData)

                            implicitWidth: chipInnerRow.implicitWidth + 16
                            implicitHeight: 46
                            radius: 8
                            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.7)
                            border.color: sequenceChip.info.color
                            border.width: 1.5

                            RowLayout {
                                id: chipInnerRow
                                anchors.centerIn: parent
                                spacing: 8

                                // Position Badge
                                Rectangle {
                                    implicitWidth: 24; implicitHeight: 24
                                    radius: 12
                                    color: sequenceChip.info.color

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        text: "#" + (sequenceChip.index + 1)
                                        font.bold: true
                                        font.pixelSize: 10
                                        color: "#ffffff"
                                    }
                                }

                                // Metric Icon
                                Kirigami.Icon {
                                    source: panelOrderPage.resolveIcon(sequenceChip.info.icon)
                                    implicitWidth: 16; implicitHeight: 16
                                    color: sequenceChip.info.color
                                }

                                // Label & Preview
                                ColumnLayout {
                                    spacing: 0
                                    QQC2.Label {
                                        text: sequenceChip.info.label
                                        font.bold: true
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 140
                                    }
                                    QQC2.Label {
                                        text: sequenceChip.info.preview
                                        font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                                        opacity: 0.65
                                    }
                                }

                                // Reorder actions
                                RowLayout {
                                    spacing: 1

                                    QQC2.ToolButton {
                                        icon.name: "go-previous"
                                        implicitWidth: 24; implicitHeight: 24
                                        enabled: sequenceChip.index > 0
                                        onClicked: panelOrderPage.moveItem(sequenceChip.index, sequenceChip.index - 1)
                                        QQC2.ToolTip.text: i18n("Mover hacia la izquierda")
                                        QQC2.ToolTip.visible: hovered
                                    }

                                    QQC2.ToolButton {
                                        icon.name: "go-next"
                                        implicitWidth: 24; implicitHeight: 24
                                        enabled: sequenceChip.index < panelOrderPage.currentList.length - 1
                                        onClicked: panelOrderPage.moveItem(sequenceChip.index, sequenceChip.index + 1)
                                        QQC2.ToolTip.text: i18n("Mover hacia la derecha")
                                        QQC2.ToolTip.visible: hovered
                                    }

                                    QQC2.ToolButton {
                                        icon.name: "dialog-close"
                                        implicitWidth: 24; implicitHeight: 24
                                        onClicked: panelOrderPage.removeItem(sequenceChip.index)
                                        QQC2.ToolTip.text: i18n("Desanclar de la barra")
                                        QQC2.ToolTip.visible: hovered
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 3. STUDIO THEMATIC PRESETS (PLANTILLAS EN 1-CLICK)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true

            header: Kirigami.Heading {
                text: i18n("Plantillas Rápidas de Panel")
                level: 3
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    text: i18n("Configura tu barra con un solo clic según tu actividad:")
                    opacity: 0.75
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Button {
                        text: i18n("🚀 Gaming Beast")
                        icon.name: "games-config-options"
                        onClicked: {
                            var gId = (discovery.discoveredGpus.length > 0) ? discovery.discoveredGpus[0].id : "gpu0";
                            panelOrderPage.cfg_pinnedMetrics = "cpu/usage,cpu/maxFreq,cpu/power,gpu:" + gId + "/usage,gpu:" + gId + "/temp,gpu:" + gId + "/vram,ram/percentage";
                        }
                    }

                    QQC2.Button {
                        text: i18n("❄️ Vigilancia Térmica Extrema")
                        icon.name: "preferences-system-hardware"
                        onClicked: {
                            var gId = (discovery.discoveredGpus.length > 0) ? discovery.discoveredGpus[0].id : "gpu0";
                            panelOrderPage.cfg_pinnedMetrics = "cpu/temp,gpu:" + gId + "/temp,gpu:" + gId + "/hotspot,gpu:" + gId + "/vramTemp,net/temp,temp/system";
                        }
                    }

                    QQC2.Button {
                        text: i18n("🌐 Red y Almacenamiento")
                        icon.name: "network-workgroup"
                        onClicked: {
                            var dId = (discovery.discoveredDisks.length > 0) ? discovery.discoveredDisks[0].id : "nvme0n1";
                            panelOrderPage.cfg_pinnedMetrics = "net/down,net/up,net/signal,disk:" + dId + "/read,disk:" + dId + "/write";
                        }
                    }

                    QQC2.Button {
                        text: i18n("🍃 Modo Minimalista")
                        icon.name: "view-restore"
                        onClicked: {
                            panelOrderPage.cfg_pinnedMetrics = "cpu/usage,ram/percentage,temp/system";
                        }
                    }

                    QQC2.Button {
                        text: i18n("Restablecer Estándar")
                        icon.name: "edit-undo"
                        onClicked: {
                            panelOrderPage.cfg_pinnedMetrics = "cpu/usage,ram/percentage,temp/system,bat/percentage,net/down,net/up";
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 4. SENSOR CATALOG & BUILDER (EL CATÁLOGO VISUAL DE SENSORES)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true

            header: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "view-list-details"
                    implicitWidth: 20; implicitHeight: 20
                    color: Kirigami.Theme.highlightColor
                }

                Kirigami.Heading {
                    text: i18n("Catálogo de Sensores Disponibles")
                    level: 3
                    Layout.fillWidth: true
                }
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                // Search Bar & Filter Chips
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.TextField {
                        id: catSearchInput
                        Layout.fillWidth: true
                        placeholderText: i18n("Filtrar métricas por nombre o palabra clave...")
                        onTextChanged: panelOrderPage.catalogSearchQuery = text.trim().toLowerCase()

                        QQC2.ToolButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: catSearchInput.text.length > 0
                            icon.name: "edit-clear"
                            implicitWidth: 24; implicitHeight: 24
                            onClicked: catSearchInput.text = ""
                        }
                    }
                }

                // Category Tabs
                RowLayout {
                    spacing: 6

                    QQC2.Button {
                        text: i18n("Todos")
                        highlighted: panelOrderPage.activeCatalogCategory === "all"
                        onClicked: panelOrderPage.activeCatalogCategory = "all"
                    }
                    QQC2.Button {
                        text: "CPU"
                        icon.name: "cpu-symbolic"
                        highlighted: panelOrderPage.activeCatalogCategory === "cpu"
                        onClicked: panelOrderPage.activeCatalogCategory = "cpu"
                    }
                    QQC2.Button {
                        text: "GPU"
                        icon.name: "gpu-symbolic"
                        highlighted: panelOrderPage.activeCatalogCategory === "gpu"
                        onClicked: panelOrderPage.activeCatalogCategory = "gpu"
                    }
                    QQC2.Button {
                        text: "RAM"
                        icon.name: "memory-symbolic"
                        highlighted: panelOrderPage.activeCatalogCategory === "ram"
                        onClicked: panelOrderPage.activeCatalogCategory = "ram"
                    }
                    QQC2.Button {
                        text: i18n("Discos")
                        icon.name: "storage-symbolic"
                        highlighted: panelOrderPage.activeCatalogCategory === "disk"
                        onClicked: panelOrderPage.activeCatalogCategory = "disk"
                    }
                    QQC2.Button {
                        text: i18n("Red")
                        icon.name: "network-symbolic"
                        highlighted: panelOrderPage.activeCatalogCategory === "net"
                        onClicked: panelOrderPage.activeCatalogCategory = "net"
                    }
                    QQC2.Button {
                        text: i18n("Sistema")
                        icon.name: "system-symbolic"
                        highlighted: panelOrderPage.activeCatalogCategory === "system"
                        onClicked: panelOrderPage.activeCatalogCategory = "system"
                    }
                }

                // Catalog Grid
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing

                    Repeater {
                        model: panelOrderPage.paletteCategories

                        delegate: ColumnLayout {
                            id: catalogGroup
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            readonly property bool matchesCategory: panelOrderPage.activeCatalogCategory === "all" || panelOrderPage.activeCatalogCategory === catalogGroup.modelData.id
                            visible: matchesCategory

                            RowLayout {
                                spacing: 6
                                Kirigami.Icon {
                                    source: panelOrderPage.resolveIcon(catalogGroup.modelData.icon)
                                    implicitWidth: 16; implicitHeight: 16
                                    color: catalogGroup.modelData.color
                                }
                                QQC2.Label {
                                    text: catalogGroup.modelData.title
                                    font.bold: true
                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                    color: catalogGroup.modelData.color
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: catalogGroup.modelData.items

                                    delegate: Rectangle {
                                        id: itemCard
                                        required property var modelData

                                        readonly property bool isSelected: panelOrderPage.isPinned(itemCard.modelData.id)
                                        readonly property bool matchesSearch: {
                                            if (!panelOrderPage.catalogSearchQuery || panelOrderPage.catalogSearchQuery.length === 0) return true;
                                            var q = panelOrderPage.catalogSearchQuery;
                                            return (itemCard.modelData.label || "").toLowerCase().indexOf(q) !== -1 || (itemCard.modelData.id || "").toLowerCase().indexOf(q) !== -1;
                                        }

                                        visible: matchesSearch
                                        implicitWidth: itemCardRow.implicitWidth + 20
                                        implicitHeight: 38
                                        radius: 6

                                        color: isSelected
                                               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                                               : (itemHover.hovered
                                                  ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                                                  : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04))
                                        border.color: isSelected ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                        border.width: isSelected ? 1.5 : 1

                                        HoverHandler { id: itemHover }
                                        TapHandler { onTapped: panelOrderPage.toggleItem(itemCard.modelData.id) }

                                        RowLayout {
                                            id: itemCardRow
                                            anchors.centerIn: parent
                                            spacing: 8

                                            Kirigami.Icon {
                                                source: panelOrderPage.resolveIcon(itemCard.modelData.icon)
                                                implicitWidth: 15; implicitHeight: 15
                                                color: isSelected ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                            }

                                            QQC2.Label {
                                                text: itemCard.modelData.label
                                                font.bold: isSelected
                                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                            }

                                            Rectangle {
                                                implicitHeight: 20
                                                implicitWidth: 20
                                                radius: 10
                                                color: isSelected ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)

                                                Kirigami.Icon {
                                                    anchors.centerIn: parent
                                                    source: isSelected ? "dialog-ok-apply" : "list-add"
                                                    implicitWidth: 11; implicitHeight: 11
                                                    color: isSelected ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
