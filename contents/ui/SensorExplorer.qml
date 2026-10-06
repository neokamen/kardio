import QtQuick
import QtQuick.Controls
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.ksysguard.sensors as Sensors
import "./models"
import "./models/MetricDefinitions.js" as MetricDefinitions

KCM.SimpleKCM {
    id: explorerRoot

    property string cfg_pinnedMetrics: ""
    HardwareDiscovery {
        id: defaultDiscovery
    }
    property var discovery: defaultDiscovery
    property string pinnedMetrics: ""
    signal togglePinnedMetric(string sensorId)

    property string searchQuery: ""
    property string activeCategory: "all"

    readonly property var allSensors: (discovery && discovery.allSensorsList && discovery.allSensorsList.length > 0)
                                      ? discovery.allSensorsList
                                      : []

    readonly property var filteredSensors: {
        var query = searchQuery.trim().toLowerCase();
        var cat = activeCategory;
        var list = allSensors;
        var result = [];

        var pTemp = /temp|temperature|hotspot|junction/i;
        var pFreq = /frequency|clock/i;
        var pPower = /power|energy|voltage|in\d+|ppt|tdp|charge/i;
        var pDisk = /^disk\/|nvme|sda|scsi|drivetemp|drive/i;
        var pNet = /^network\/|wifi|wlan|iwl|signal|download|upload/i;
        var pFan = /fan\d+|fan_speed|rpm/i;
        var pCpu = /^cpu\//i;
        var pGpu = /^gpu\//i;

        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            var sid = item.id;
            var sname = item.name || sid;

            // Category filter
            if (cat === "temp" && !pTemp.test(sid) && !pTemp.test(sname)) continue;
            if (cat === "freq" && !pFreq.test(sid) && !pFreq.test(sname)) continue;
            if (cat === "power" && !pPower.test(sid) && !pPower.test(sname)) continue;
            if (cat === "disk" && !pDisk.test(sid) && !pDisk.test(sname)) continue;
            if (cat === "net" && !pNet.test(sid) && !pNet.test(sname)) continue;
            if (cat === "fan" && !pFan.test(sid) && !pFan.test(sname)) continue;
            if (cat === "cpu" && !pCpu.test(sid)) continue;
            if (cat === "gpu" && !pGpu.test(sid)) continue;

            // Search query filter
            if (query.length > 0) {
                if (sid.toLowerCase().indexOf(query) === -1 && sname.toLowerCase().indexOf(query) === -1) {
                    continue;
                }
            }

            result.push(item);
            if (result.length >= 150) break; // Keep list snappy
        }

        return result;
    }

    // Active sensor sampling via KSysGuard SensorDataModel
    readonly property var sampledIds: filteredSensors.slice(0, 40).map(function(s){ return s.id; })

    Sensors.SensorDataModel {
        id: liveSensorModel
        sensors: explorerRoot.sampledIds
        updateRateLimit: 2000
        enabled: explorerRoot.sampledIds.length > 0
    }

    function getLiveValue(sensorId) {
        var col = liveSensorModel.column(sensorId);
        if (col < 0) return "--";
        var idx = liveSensorModel.index(0, col);
        if (!idx.valid) return "--";
        var val = liveSensorModel.data(idx, Sensors.SensorDataModel.Value);
        if (val === undefined || val === null) return "--";
        if (typeof val === "number") {
            if (isNaN(val)) return "--";
            if (/temp/i.test(sensorId)) return val.toFixed(1) + " °C";
            if (/frequency/i.test(sensorId)) {
                if (val >= 1000) return (val / 1000).toFixed(2) + " GHz";
                return Math.round(val) + " MHz";
            }
            if (/in\d+|voltage/i.test(sensorId)) {
                return (val > 50 ? (val / 1000).toFixed(2) : val.toFixed(2)) + " V";
            }
            if (/power/i.test(sensorId)) return val.toFixed(1) + " W";
            if (/percentage|usage|signal/i.test(sensorId)) return Math.round(val) + " %";
            if (/fan/i.test(sensorId)) return Math.round(val) + " RPM";
            if (val > 1000000) return (val / 1048576).toFixed(1) + " MB/s";
            return val.toFixed(2);
        }
        return String(val);
    }

    function copyToClipboard(text) {
        dummyClipboardHelper.text = text;
        dummyClipboardHelper.selectAll();
        dummyClipboardHelper.copy();
    }

    TextEdit {
        id: dummyClipboardHelper
        visible: false
    }

    function generateDiagnosticReport() {
        var report = "=== INFORME DE DIAGNÓSTICO DE SENSORES KARDIO ===\n";
        report += "Fecha: " + new Date().toLocaleString() + "\n";
        report += "Total Sensores en el Sistema: " + allSensors.length + "\n\n";

        report += "-- RESUMEN DE HARDWARE DETECTADO --\n";
        if (discovery) {
            report += "Núcleos CPU: " + (discovery.discoveredCores ? discovery.discoveredCores.length : 0) + "\n";
            report += "Sensor Potencia CPU: " + (discovery.cpuPowerSensor || "No detectado") + "\n";
            report += "GPUs: " + (discovery.discoveredGpus ? discovery.discoveredGpus.map(function(g){ return g.name + " (" + g.id + ")"; }).join(", ") : "Ninguna") + "\n";
            report += "Discos: " + (discovery.discoveredDisks ? discovery.discoveredDisks.map(function(d){ return d.name + " (" + d.id + ")"; }).join(", ") : "Ninguno") + "\n";
            report += "Interfaces de Red: " + (discovery.discoveredNetworkIfaces ? discovery.discoveredNetworkIfaces.join(", ") : "Ninguna") + "\n";
            report += "Sensores Térmicos Wi-Fi: " + (discovery.discoveredWifiTemps ? discovery.discoveredWifiTemps.join(", ") : "Ninguno") + "\n";
            report += "Sensores Térmicos Disco: " + (discovery.discoveredDiskTemps ? discovery.discoveredDiskTemps.join(", ") : "Ninguno") + "\n\n";
        }

        report += "-- LISTADO DE SENSORES ACTIVOS MUESTREADOS --\n";
        for (var i = 0; i < Math.min(allSensors.length, 100); i++) {
            var s = allSensors[i];
            report += s.id + " [" + (s.name || "") + "]\n";
        }
        report += "\n=== FIN DEL INFORME ===";

        copyToClipboard(report);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.mediumSpacing

        // Top Header Banner
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + (Kirigami.Units.mediumSpacing * 2)
            radius: Kirigami.Units.smallSpacing
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.08)
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
            border.width: 1

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: Kirigami.Units.mediumSpacing
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Icon {
                    source: "system-search"
                    width: 32; height: 32
                    color: Kirigami.Theme.highlightColor
                }

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Label {
                        text: i18n("Explorador de Sensores y Hardware (Estilo KDE System Monitor)")
                        font.weight: Font.Bold
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                    }

                    Label {
                        text: i18n("Inspecciona todos los nodos hwmon, sysfs y ksystemstats de tu ordenador en tiempo real (%1 sensores disponibles)", allSensors.length)
                        font: Kirigami.Theme.smallFont
                        opacity: 0.75
                    }
                }

                QQC2.Button {
                    icon.name: "edit-copy"
                    text: i18n("Copiar Diagnóstico Completo")
                    onClicked: {
                        explorerRoot.generateDiagnosticReport();
                        diagnosticFeedback.visible = true;
                        diagnosticTimer.restart();
                    }
                }
            }
        }

        // Diagnostic copied badge
        Rectangle {
            id: diagnosticFeedback
            visible: false
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 4
            color: Qt.rgba(46/255, 204/255, 113/255, 0.2)
            border.color: "#2ecc71"
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Kirigami.Icon { source: "checkmark"; width: 14; height: 14; color: "#2ecc71" }
                Label {
                    text: i18n("¡Informe de diagnóstico copiado al portapapeles con éxito!")
                    font.bold: true
                    color: "#2ecc71"
                }
            }

            Timer {
                id: diagnosticTimer
                interval: 3500
                onTriggered: diagnosticFeedback.visible = false
            }
        }

        // Search Bar & Filter Row
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: i18n("Buscar sensores por nombre o ruta (ej: wifi, temp, watt, nvme, sda, in0, fan)...")
                text: explorerRoot.searchQuery
                onTextChanged: explorerRoot.searchQuery = text
            }

            QQC2.ToolButton {
                icon.name: searchInput.text.length > 0 ? "edit-clear" : "system-search"
                onClicked: searchInput.text = ""
            }
        }

        // Category Filter Chips
        Flow {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: i18n("Todos (%1)", allSensors.length)
                highlighted: explorerRoot.activeCategory === "all"
                onClicked: explorerRoot.activeCategory = "all"
            }
            QQC2.Button {
                text: i18n("🌡️ Temperaturas")
                highlighted: explorerRoot.activeCategory === "temp"
                onClicked: explorerRoot.activeCategory = "temp"
            }
            QQC2.Button {
                text: i18n("⚡ Frecuencias / Relojes")
                highlighted: explorerRoot.activeCategory === "freq"
                onClicked: explorerRoot.activeCategory = "freq"
            }
            QQC2.Button {
                text: i18n("🔌 Energía / Watts / Voltaje")
                highlighted: explorerRoot.activeCategory === "power"
                onClicked: explorerRoot.activeCategory = "power"
            }
            QQC2.Button {
                text: i18n("💻 CPU")
                highlighted: explorerRoot.activeCategory === "cpu"
                onClicked: explorerRoot.activeCategory = "cpu"
            }
            QQC2.Button {
                text: i18n("🎮 GPU")
                highlighted: explorerRoot.activeCategory === "gpu"
                onClicked: explorerRoot.activeCategory = "gpu"
            }
            QQC2.Button {
                text: i18n("💾 Discos")
                highlighted: explorerRoot.activeCategory === "disk"
                onClicked: explorerRoot.activeCategory = "disk"
            }
            QQC2.Button {
                text: i18n("🌐 Red")
                highlighted: explorerRoot.activeCategory === "net"
                onClicked: explorerRoot.activeCategory = "net"
            }
            QQC2.Button {
                text: i18n("🌀 Ventiladores")
                highlighted: explorerRoot.activeCategory === "fan"
                onClicked: explorerRoot.activeCategory = "fan"
            }
        }

        // Results Summary
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: i18n("Mostrando %1 sensores coincidentes:", explorerRoot.filteredSensors.length)
                font.bold: true
                opacity: 0.7
            }
            Item { Layout.fillWidth: true }
            Label {
                text: i18n("Valores en vivo actualizándose cada 2s")
                font: Kirigami.Theme.smallFont
                opacity: 0.5
            }
        }

        // Sensors Scroll List
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Kirigami.Units.smallSpacing
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.4)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            border.width: 1
            clip: true

            ListView {
                id: sensorListView
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                model: explorerRoot.filteredSensors

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    active: true
                }

                delegate: Rectangle {
                    id: sensorRow
                    required property var modelData
                    required property int index

                    width: sensorListView.width - 12
                    implicitHeight: 46
                    radius: 6
                    color: index % 2 === 0
                           ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                           : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: Kirigami.Units.mediumSpacing

                        Kirigami.Icon {
                            source: {
                                var sid = sensorRow.modelData.id;
                                if (/temp|temperature/i.test(sid)) return "temperature-symbolic";
                                if (/frequency|clock/i.test(sid)) return "cpu-symbolic";
                                if (/power|voltage|in\d+/i.test(sid)) return "voltage-symbolic";
                                if (/disk|sda|nvme/i.test(sid)) return "storage-symbolic";
                                if (/network|wifi|signal/i.test(sid)) return "network-wireless-symbolic";
                                if (/fan/i.test(sid)) return "fan-symbolic";
                                if (/gpu/i.test(sid)) return "gpu-symbolic";
                                return "sensor";
                            }
                            width: 18; height: 18
                            color: Kirigami.Theme.highlightColor
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 6
                                Label {
                                    text: sensorRow.modelData.name || sensorRow.modelData.id
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 350
                                }
                            }

                            Label {
                                text: sensorRow.modelData.id
                                font.family: "monospace"
                                font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                                opacity: 0.65
                                elide: Text.ElideMiddle
                                Layout.maximumWidth: 380
                            }
                        }

                        // Live Value Pill
                        Rectangle {
                            radius: 4
                            implicitHeight: 24
                            implicitWidth: Math.max(70, liveValLabel.implicitWidth + 14)
                            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)
                            border.width: 1

                            Label {
                                id: liveValLabel
                                anchors.centerIn: parent
                                text: explorerRoot.getLiveValue(sensorRow.modelData.id)
                                font.bold: true
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                color: Kirigami.Theme.highlightColor
                            }
                        }

                        // Copy ID Button
                        QQC2.ToolButton {
                            icon.name: "edit-copy"
                            implicitWidth: 26; implicitHeight: 26
                            onClicked: explorerRoot.copyToClipboard(sensorRow.modelData.id)
                            QQC2.ToolTip.text: i18n("Copiar ID de sensor: %1", sensorRow.modelData.id)
                            QQC2.ToolTip.visible: hovered
                        }
                    }
                }
            }
        }
    }
}
