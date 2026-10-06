import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.0 as Platform
import org.kde.kirigami 2.19 as Kirigami
import org.kde.kcmutils as KCM
import "./sensors"

KCM.SimpleKCM {
    id: colorsPage

    property alias cfg_useCustomColors: useCustomColorsSwitch.checked
    property string cfg_fontColor
    property string cfg_labelColor
    property string cfg_iconColor
    property alias cfg_enableThresholdColors: enableThresholdSwitch.checked
    property string cfg_warningColor: "#e5a50a"
    property string cfg_criticalColor: "#da4453"

    property alias cfg_cpuWarningThreshold: cpuWarnSlider.value
    property alias cfg_cpuCriticalThreshold: cpuCritSlider.value
    property alias cfg_tempWarningThreshold: tempWarnSlider.value
    property alias cfg_tempCriticalThreshold: tempCritSlider.value
    property alias cfg_systemWarningThreshold: systemWarnSlider.value
    property alias cfg_systemCriticalThreshold: systemCritSlider.value
    property alias cfg_ramWarningThreshold: ramWarnSlider.value
    property alias cfg_ramCriticalThreshold: ramCritSlider.value
    property alias cfg_swapWarningThreshold: swapWarnSlider.value
    property alias cfg_swapCriticalThreshold: swapCritSlider.value
    property alias cfg_ramTempWarningThreshold: ramTempWarnSlider.value
    property alias cfg_ramTempCriticalThreshold: ramTempCritSlider.value
    property alias cfg_gpuWarningThreshold: gpuWarnSlider.value
    property alias cfg_gpuCriticalThreshold: gpuCritSlider.value
    property alias cfg_gpuTempWarningThreshold: gpuTempWarnSlider.value
    property alias cfg_gpuTempCriticalThreshold: gpuTempCritSlider.value
    property alias cfg_gpuHotspotTempWarningThreshold: gpuHotspotTempWarnSlider.value
    property alias cfg_gpuHotspotTempCriticalThreshold: gpuHotspotTempCritSlider.value
    property alias cfg_gpuVramTempWarningThreshold: gpuVramTempWarnSlider.value
    property alias cfg_gpuVramTempCriticalThreshold: gpuVramTempCritSlider.value
    property alias cfg_batteryWarningThreshold: batWarnSlider.value
    property alias cfg_batteryCriticalThreshold: batCritSlider.value
    property alias cfg_diskWarningThreshold: diskWarnSlider.value
    property alias cfg_diskCriticalThreshold: diskCritSlider.value
    property alias cfg_diskTempWarningThreshold: diskTempWarnSlider.value
    property alias cfg_diskTempCriticalThreshold: diskTempCritSlider.value

    readonly property string defaultWarningColor: "#e5a50a"
    readonly property string defaultCriticalColor: "#da4453"

    property string cfg_tempUnit: "C"

    function isRgbHex(value) {
        return /^#[0-9A-Fa-f]{6}$/.test(value)
    }

    function colorToRgbHex(colorValue) {
        if (!colorValue || colorValue.r === undefined || colorValue.g === undefined || colorValue.b === undefined) return ""
        function channelToHex(channel) {
            const value = Math.max(0, Math.min(255, Math.round(channel * 255)))
            return value.toString(16).padStart(2, "0")
        }
        return "#" + channelToHex(colorValue.r) + channelToHex(colorValue.g) + channelToHex(colorValue.b)
    }

    function openColorDialog(dialog, value, fallbackColor) {
        const initialColor = isRgbHex(value) ? value : fallbackColor
        dialog.color = initialColor
        dialog.currentColor = initialColor
        dialog.open()
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        Layout.fillWidth: true

        // ═══════════════════════════════════════════════════════════════════
        // 1. LIVE THERMAL SPECTRUM SIMULATOR
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: Kirigami.Heading {
                text: i18n("Simulador de Espectro Térmico y Alertas en Vivo")
                level: 3
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                Label {
                    text: i18n("Visualización de las 3 zonas térmicas según los umbrales de aviso y peligro configurados:")
                    opacity: 0.75
                }

                // Spectrum Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    clip: true
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Safe Zone
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: Math.max(10, parent.width * (cfg_tempWarningThreshold / 100.0))
                            color: Qt.rgba(46/255, 204/255, 113/255, 0.35)
                            Label {
                                anchors.centerIn: parent
                                text: i18n("Normal (< %1°C)", cfg_tempWarningThreshold)
                                font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                                font.bold: true
                                visible: parent.width > 90
                            }
                        }

                        // Warning Zone
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: Math.max(10, parent.width * ((cfg_tempCriticalThreshold - cfg_tempWarningThreshold) / 100.0))
                            color: isRgbHex(cfg_warningColor) ? cfg_warningColor : "#e5a50a"
                            opacity: 0.7
                            Label {
                                anchors.centerIn: parent
                                text: i18n("Aviso (%1°C)", cfg_tempWarningThreshold)
                                font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                                font.bold: true
                                color: "#000000"
                                visible: parent.width > 80
                            }
                        }

                        // Critical Zone
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            color: isRgbHex(cfg_criticalColor) ? cfg_criticalColor : "#da4453"
                            opacity: 0.85
                            Label {
                                anchors.centerIn: parent
                                text: i18n("Crítico (≥ %1°C)", cfg_tempCriticalThreshold)
                                font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                                font.bold: true
                                color: "#ffffff"
                                visible: parent.width > 80
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 2. PALETA BASE DE INTERFAZ (TEXTO, ETIQUETAS Y GLIFOS)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: Kirigami.Heading {
                text: i18n("Paleta Base de la Interfaz")
                level: 3
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Switch {
                        id: useCustomColorsSwitch
                    }
                    Label {
                        text: i18n("Usar colores personalizados (reemplaza los colores del tema de Plasma)")
                        font.weight: Font.DemiBold
                    }
                }

                // Quick Palette Presets
                RowLayout {
                    enabled: cfg_useCustomColors
                    spacing: Kirigami.Units.smallSpacing
                    Label { text: i18n("Paletas rápidas:"); opacity: 0.7; Layout.preferredWidth: 120 }

                    Button {
                        text: "Cyan Cyberpunk"
                        onClicked: { cfg_fontColor = "#00f0ff"; cfg_labelColor = "#00b8d4"; cfg_iconColor = "#00e5ff"; }
                    }
                    Button {
                        text: "Neon Purple"
                        onClicked: { cfg_fontColor = "#e056fd"; cfg_labelColor = "#be2edd"; cfg_iconColor = "#f0932b"; }
                    }
                    Button {
                        text: "Emerald Matrix"
                        onClicked: { cfg_fontColor = "#2ecc71"; cfg_labelColor = "#27ae60"; cfg_iconColor = "#1abc9c"; }
                    }
                    Button {
                        text: "Restablecer"
                        onClicked: { cfg_fontColor = ""; cfg_labelColor = ""; cfg_iconColor = ""; }
                    }
                }

                GridLayout {
                    columns: 3
                    enabled: cfg_useCustomColors
                    columnSpacing: Kirigami.Units.mediumSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    // Font Color
                    Label { text: i18n("Color de Fuente:"); font.weight: Font.DemiBold }
                    RowLayout {
                        Button {
                            text: ""
                            implicitWidth: 32; implicitHeight: 24
                            onClicked: colorsPage.openColorDialog(fontColorDialog, cfg_fontColor, Kirigami.Theme.textColor)
                            background: Rectangle {
                                radius: 4
                                color: colorsPage.isRgbHex(cfg_fontColor) ? cfg_fontColor : Kirigami.Theme.textColor
                                border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
                            }
                        }
                        TextField {
                            id: fontColorField
                            text: cfg_fontColor
                            placeholderText: "#ffffff"
                            maximumLength: 7
                            implicitWidth: 90
                            onTextChanged: if (colorsPage.isRgbHex(text)) cfg_fontColor = text
                        }
                    }
                    Button { icon.name: "edit-undo"; text: i18n("Auto"); onClicked: { fontColorField.text = ""; cfg_fontColor = "" } }

                    // Label Color
                    Label { text: i18n("Color de Etiquetas:"); font.weight: Font.DemiBold }
                    RowLayout {
                        Button {
                            text: ""
                            implicitWidth: 32; implicitHeight: 24
                            onClicked: colorsPage.openColorDialog(labelColorDialog, cfg_labelColor, Kirigami.Theme.textColor)
                            background: Rectangle {
                                radius: 4
                                color: colorsPage.isRgbHex(cfg_labelColor) ? cfg_labelColor : Kirigami.Theme.textColor
                                border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
                            }
                        }
                        TextField {
                            id: labelColorField
                            text: cfg_labelColor
                            placeholderText: "#cccccc"
                            maximumLength: 7
                            implicitWidth: 90
                            onTextChanged: if (colorsPage.isRgbHex(text)) cfg_labelColor = text
                        }
                    }
                    Button { icon.name: "edit-undo"; text: i18n("Auto"); onClicked: { labelColorField.text = ""; cfg_labelColor = "" } }

                    // Icon Color
                    Label { text: i18n("Color de Iconos:"); font.weight: Font.DemiBold }
                    RowLayout {
                        Button {
                            text: ""
                            implicitWidth: 32; implicitHeight: 24
                            onClicked: colorsPage.openColorDialog(iconColorDialog, cfg_iconColor, Kirigami.Theme.textColor)
                            background: Rectangle {
                                radius: 4
                                color: colorsPage.isRgbHex(cfg_iconColor) ? cfg_iconColor : Kirigami.Theme.textColor
                                border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
                            }
                        }
                        TextField {
                            id: iconColorField
                            text: cfg_iconColor
                            placeholderText: "#ffffff"
                            maximumLength: 7
                            implicitWidth: 90
                            onTextChanged: if (colorsPage.isRgbHex(text)) cfg_iconColor = text
                        }
                    }
                    Button { icon.name: "edit-undo"; text: i18n("Auto"); onClicked: { iconColorField.text = ""; cfg_iconColor = "" } }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 3. MOTOR DE COLORES DE ALERTA DINÁMICA
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: Kirigami.Heading {
                text: i18n("Colores de Alerta por Umbral")
                level: 3
            }

            contentItem: ColumnLayout {
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Switch {
                        id: enableThresholdSwitch
                    }
                    Label {
                        text: i18n("Activar coloreado dinámico según nivel de carga y temperaturas")
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    enabled: cfg_enableThresholdColors
                    spacing: Kirigami.Units.largeSpacing

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Label { text: i18n("Color de Aviso (Warning):"); font.weight: Font.DemiBold }
                        Button {
                            implicitWidth: 32; implicitHeight: 24
                            onClicked: colorsPage.openColorDialog(warningColorDialog, cfg_warningColor, colorsPage.defaultWarningColor)
                            background: Rectangle {
                                radius: 4
                                color: colorsPage.isRgbHex(cfg_warningColor) ? cfg_warningColor : colorsPage.defaultWarningColor
                                border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
                            }
                        }
                        TextField {
                            text: cfg_warningColor
                            maximumLength: 7
                            implicitWidth: 90
                            onTextChanged: if (colorsPage.isRgbHex(text)) cfg_warningColor = text
                        }
                    }

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Label { text: i18n("Color Crítico (Critical):"); font.weight: Font.DemiBold }
                        Button {
                            implicitWidth: 32; implicitHeight: 24
                            onClicked: colorsPage.openColorDialog(criticalColorDialog, cfg_criticalColor, colorsPage.defaultCriticalColor)
                            background: Rectangle {
                                radius: 4
                                color: colorsPage.isRgbHex(cfg_criticalColor) ? cfg_criticalColor : colorsPage.defaultCriticalColor
                                border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
                            }
                        }
                        TextField {
                            text: cfg_criticalColor
                            maximumLength: 7
                            implicitWidth: 90
                            onTextChanged: if (colorsPage.isRgbHex(text)) cfg_criticalColor = text
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 4. UMBRALES: CPU & GRÁFICOS (GPU)
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: Kirigami.Heading {
                text: i18n("Umbrales de Carga y Temperatura: CPU & GPU")
                level: 3
            }

            contentItem: GridLayout {
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.mediumSpacing

                // CPU Load
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("CPU: Uso (%) [Aviso: %1% · Crítico: %2%]", cpuWarnSlider.value, cpuCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: cpuWarnSlider; from: 10; to: 95; stepSize: 5; value: 75; Layout.fillWidth: true }
                        Slider { id: cpuCritSlider; from: 20; to: 100; stepSize: 5; value: 90; Layout.fillWidth: true }
                    }
                }

                // CPU Temp
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("CPU: Temp (°C) [Aviso: %1°C · Crítico: %2°C]", tempWarnSlider.value, tempCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: tempWarnSlider; from: 40; to: 95; stepSize: 2; value: 75; Layout.fillWidth: true }
                        Slider { id: tempCritSlider; from: 50; to: 105; stepSize: 2; value: 85; Layout.fillWidth: true }
                    }
                }

                // GPU Load
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("GPU: Uso (%) [Aviso: %1% · Crítico: %2%]", gpuWarnSlider.value, gpuCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: gpuWarnSlider; from: 10; to: 95; stepSize: 5; value: 85; Layout.fillWidth: true }
                        Slider { id: gpuCritSlider; from: 20; to: 100; stepSize: 5; value: 95; Layout.fillWidth: true }
                    }
                }

                // GPU Core Temp
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("GPU: Núcleo Temp (°C) [Aviso: %1°C · Crítico: %2°C]", gpuTempWarnSlider.value, gpuTempCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: gpuTempWarnSlider; from: 40; to: 95; stepSize: 2; value: 75; Layout.fillWidth: true }
                        Slider { id: gpuTempCritSlider; from: 50; to: 105; stepSize: 2; value: 85; Layout.fillWidth: true }
                    }
                }

                // GPU Hotspot
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("GPU: Punto Caliente Hotspot (°C) [Aviso: %1°C · Crítico: %2°C]", gpuHotspotTempWarnSlider.value, gpuHotspotTempCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: gpuHotspotTempWarnSlider; from: 50; to: 110; stepSize: 2; value: 85; Layout.fillWidth: true }
                        Slider { id: gpuHotspotTempCritSlider; from: 60; to: 120; stepSize: 2; value: 98; Layout.fillWidth: true }
                    }
                }

                // GPU VRAM Temp
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("GPU: Memoria VRAM Temp (°C) [Aviso: %1°C · Crítico: %2°C]", gpuVramTempWarnSlider.value, gpuVramTempCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: gpuVramTempWarnSlider; from: 45; to: 105; stepSize: 2; value: 80; Layout.fillWidth: true }
                        Slider { id: gpuVramTempCritSlider; from: 55; to: 115; stepSize: 2; value: 95; Layout.fillWidth: true }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 5. UMBRALES: MEMORIA, DISCOS & BATERÍA
        // ═══════════════════════════════════════════════════════════════════
        Kirigami.Card {
            Layout.fillWidth: true
            header: Kirigami.Heading {
                text: i18n("Umbrales: Memoria, Discos & Batería")
                level: 3
            }

            contentItem: GridLayout {
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.mediumSpacing

                // RAM Load
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("RAM: Ocupación (%) [Aviso: %1% · Crítico: %2%]", ramWarnSlider.value, ramCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: ramWarnSlider; from: 20; to: 95; stepSize: 5; value: 80; Layout.fillWidth: true }
                        Slider { id: ramCritSlider; from: 30; to: 100; stepSize: 5; value: 92; Layout.fillWidth: true }
                    }
                }

                // Swap Load
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("SWAP: Ocupación (%) [Aviso: %1% · Crítico: %2%]", swapWarnSlider.value, swapCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: swapWarnSlider; from: 10; to: 90; stepSize: 5; value: 50; Layout.fillWidth: true }
                        Slider { id: swapCritSlider; from: 20; to: 100; stepSize: 5; value: 80; Layout.fillWidth: true }
                    }
                }

                // Disk Temp
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("Discos: Temp (°C) [Aviso: %1°C · Crítico: %2°C]", diskTempWarnSlider.value, diskTempCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: diskTempWarnSlider; from: 35; to: 75; stepSize: 1; value: 55; Layout.fillWidth: true }
                        Slider { id: diskTempCritSlider; from: 45; to: 85; stepSize: 1; value: 68; Layout.fillWidth: true }
                    }
                }

                // Battery (Inverted)
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: i18n("Batería: Nivel Bajo (%) [Aviso: %1% · Crítico: %2%]", batWarnSlider.value, batCritSlider.value); font.weight: Font.DemiBold }
                    RowLayout {
                        Slider { id: batWarnSlider; from: 5; to: 40; stepSize: 5; value: 20; Layout.fillWidth: true }
                        Slider { id: batCritSlider; from: 2; to: 25; stepSize: 1; value: 10; Layout.fillWidth: true }
                    }
                }

                // Hidden compatibility sliders
                Slider { id: systemWarnSlider; from: 30; to: 90; value: 70; visible: false }
                Slider { id: systemCritSlider; from: 40; to: 100; value: 85; visible: false }
                Slider { id: ramTempWarnSlider; from: 40; to: 90; value: 65; visible: false }
                Slider { id: ramTempCritSlider; from: 50; to: 100; value: 75; visible: false }
                Slider { id: diskWarnSlider; from: 50; to: 95; value: 85; visible: false }
                Slider { id: diskCritSlider; from: 60; to: 100; value: 95; visible: false }
            }
        }
    }

    // Platform Color Dialogs
    Platform.ColorDialog {
        id: fontColorDialog
        title: i18n("Elige Color de Fuente")
        onAccepted: cfg_fontColor = colorsPage.colorToRgbHex(color)
    }

    Platform.ColorDialog {
        id: labelColorDialog
        title: i18n("Elige Color de Etiquetas")
        onAccepted: cfg_labelColor = colorsPage.colorToRgbHex(color)
    }

    Platform.ColorDialog {
        id: iconColorDialog
        title: i18n("Elige Color de Iconos")
        onAccepted: cfg_iconColor = colorsPage.colorToRgbHex(color)
    }

    Platform.ColorDialog {
        id: warningColorDialog
        title: i18n("Elige Color de Aviso")
        onAccepted: cfg_warningColor = colorsPage.colorToRgbHex(color)
    }

    Platform.ColorDialog {
        id: criticalColorDialog
        title: i18n("Elige Color Crítico")
        onAccepted: cfg_criticalColor = colorsPage.colorToRgbHex(color)
    }
}
