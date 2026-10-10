import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_updateInterval: intervalSlider.value
    property alias cfg_iconSize: iconSizeSlider.value
    property alias cfg_fontSize: fontSizeSlider.value
    property alias cfg_fontBold: fontBoldSwitch.checked
    property alias cfg_labelOpacity: labelOpacitySlider.value
    property alias cfg_separatorOpacity: separatorOpacitySlider.value
    property string cfg_displayMode: "icons+text"
    property string cfg_fontFamily: "monospace"
    property string cfg_layoutType: "horizontal"
    property string cfg_backgroundType: "default"
    property string cfg_tempUnit: "C"
    property string cfg_networkUnit: "bytes"
    property string cfg_fanUnit: "rpm"
    property bool cfg_mergeFamilyMetrics: true
    property bool cfg_showSeparators: true
    property bool cfg_showBlockLeadingIcon: true
    property string cfg_separatorStyle: "line"
    property bool cfg_enableNumberPadding: false
    property string cfg_paddedMetrics: ""
    property string cfg_smallSuffixMetrics: ""
    property string cfg_netDownMinUnit: "auto"
    property string cfg_netMinUnit: "auto"
    property bool cfg_swapDynamicUnits: true

    function isMetricPadded(id) {
        if (!cfg_paddedMetrics) return false;
        var list = cfg_paddedMetrics.split(",").map(function(s){ return s.trim(); });
        return list.indexOf(id) !== -1;
    }

    function setMetricPadded(id, active) {
        var list = cfg_paddedMetrics ? cfg_paddedMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; }) : [];
        var idx = list.indexOf(id);
        if (active && idx === -1) {
            list.push(id);
        } else if (!active && idx !== -1) {
            list.splice(idx, 1);
        }
        cfg_paddedMetrics = list.join(",");
    }

    function isMetricSmallSuffix(id) {
        if (!cfg_smallSuffixMetrics) return false;
        var list = cfg_smallSuffixMetrics.split(",").map(function(s){ return s.trim(); });
        return list.indexOf(id) !== -1;
    }

    function setMetricSmallSuffix(id, active) {
        var list = cfg_smallSuffixMetrics ? cfg_smallSuffixMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; }) : [];
        var idx = list.indexOf(id);
        if (active && idx === -1) {
            list.push(id);
        } else if (!active && idx !== -1) {
            list.splice(idx, 1);
        }
        cfg_smallSuffixMetrics = list.join(",");
    }

    readonly property bool iconsEnabled: cfg_displayMode === "icons" || cfg_displayMode === "icons+text"
    readonly property bool textEnabled: cfg_displayMode === "text" || cfg_displayMode === "icons+text"

    ColumnLayout {
        id: mainLayout
        spacing: Kirigami.Units.largeSpacing
        Layout.fillWidth: true

        // ═══════════════════════════════════════════════════════════════════
        // 1. HERO BRAND BANNER: Kardio Pulse & Live Preview
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: heroCol.implicitHeight + (Kirigami.Units.largeSpacing * 2)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.08)
            border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.3)
            border.width: 1

            ColumnLayout {
                id: heroCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.mediumSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing

                    Rectangle {
                        width: Kirigami.Units.iconSizes.large
                        height: Kirigami.Units.iconSizes.large
                        radius: Math.round(width * 0.3)
                        color: Kirigami.Theme.highlightColor

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.medium
                            height: Kirigami.Units.iconSizes.medium
                            source: Qt.resolvedUrl("../icons/kardio-symbolic.svg")
                            color: Kirigami.Theme.highlightedTextColor
                            isMask: true
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            Label {
                                text: "Kardio"
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 4
                                font.weight: Font.Bold
                                color: Kirigami.Theme.textColor
                            }
                            Rectangle {
                                radius: 4
                                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.2)
                                implicitWidth: versionLabel.implicitWidth + 10
                                implicitHeight: versionLabel.implicitHeight + 4
                                Label {
                                    id: versionLabel
                                    anchors.centerIn: parent
                                    text: "v0.5.1"
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                                    font.weight: Font.Bold
                                    color: Kirigami.Theme.highlightColor
                                }
                            }
                        }

                        Label {
                            text: i18n("The Next-Gen Plasma Telemetry Monitor")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.75
                        }
                    }
                }

                // Live Simulator Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Label {
                        text: i18n("VISTA PREVIA EN VIVO (SIMULADOR DE PANEL):")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                        font.weight: Font.Bold
                        opacity: 0.6
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(38, Kirigami.Units.gridUnit * 2.2)
                        radius: Kirigami.Units.smallSpacing
                        color: {
                            if (cfg_backgroundType === "transparent") return "transparent";
                            if (cfg_backgroundType === "translucent") return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.45);
                            return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.85);
                        }
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Kirigami.Units.mediumSpacing

                            // Simulated CPU Metric Tile
                            RowLayout {
                                spacing: 4
                                Kirigami.Icon {
                                    visible: configPage.iconsEnabled
                                    source: Qt.resolvedUrl("../icons/cpu-symbolic.svg")
                                    width: cfg_iconSize
                                    height: cfg_iconSize
                                    isMask: true
                                    color: Kirigami.Theme.textColor
                                }
                                Label {
                                    visible: configPage.textEnabled
                                    text: "CPU"
                                    font.family: cfg_fontFamily
                                    font.bold: cfg_fontBold
                                    font.pixelSize: cfg_fontSize > 0 ? cfg_fontSize : Kirigami.Theme.defaultFont.pixelSize
                                    opacity: cfg_labelOpacity
                                }
                                Label {
                                    text: "18%"
                                    font.family: cfg_fontFamily
                                    font.bold: cfg_fontBold
                                    font.pixelSize: cfg_fontSize > 0 ? cfg_fontSize : Kirigami.Theme.defaultFont.pixelSize
                                    color: Kirigami.Theme.textColor
                                }
                            }

                            SeparatorItem {
                                visible: cfg_showSeparators
                                style: cfg_separatorStyle
                                color: Kirigami.Theme.textColor
                                separatorOpacity: cfg_separatorOpacity
                                referenceSize: cfg_iconSize
                            }

                            // Simulated Temp Metric Tile
                            RowLayout {
                                spacing: 4
                                Kirigami.Icon {
                                    visible: configPage.iconsEnabled
                                    source: Qt.resolvedUrl("../icons/temperature-symbolic.svg")
                                    width: cfg_iconSize
                                    height: cfg_iconSize
                                    isMask: true
                                    color: Kirigami.Theme.textColor
                                }
                                Label {
                                    text: cfg_tempUnit === "F" ? "125°F" : "52°C"
                                    font.family: cfg_fontFamily
                                    font.bold: cfg_fontBold
                                    font.pixelSize: cfg_fontSize > 0 ? cfg_fontSize : Kirigami.Theme.defaultFont.pixelSize
                                    color: Kirigami.Theme.textColor
                                }
                            }

                            SeparatorItem {
                                visible: cfg_showSeparators
                                style: cfg_separatorStyle
                                color: Kirigami.Theme.textColor
                                separatorOpacity: cfg_separatorOpacity
                                referenceSize: cfg_iconSize
                            }

                            // Simulated GPU Tile
                            RowLayout {
                                spacing: 4
                                Kirigami.Icon {
                                    visible: configPage.iconsEnabled
                                    source: Qt.resolvedUrl("../icons/gpu-symbolic.svg")
                                    width: cfg_iconSize
                                    height: cfg_iconSize
                                    isMask: true
                                    color: Kirigami.Theme.textColor
                                }
                                Label {
                                    visible: configPage.textEnabled
                                    text: "GPU"
                                    font.family: cfg_fontFamily
                                    font.bold: cfg_fontBold
                                    font.pixelSize: cfg_fontSize > 0 ? cfg_fontSize : Kirigami.Theme.defaultFont.pixelSize
                                    opacity: cfg_labelOpacity
                                }
                                Label {
                                    text: "34%"
                                    font.family: cfg_fontFamily
                                    font.bold: cfg_fontBold
                                    font.pixelSize: cfg_fontSize > 0 ? cfg_fontSize : Kirigami.Theme.defaultFont.pixelSize
                                    color: Kirigami.Theme.textColor
                                }
                            }

                            SeparatorItem {
                                visible: cfg_showSeparators
                                style: cfg_separatorStyle
                                color: Kirigami.Theme.textColor
                                separatorOpacity: cfg_separatorOpacity
                                referenceSize: cfg_iconSize
                            }

                            // Simulated Net Tile
                            RowLayout {
                                spacing: 4
                                Kirigami.Icon {
                                    visible: configPage.iconsEnabled
                                    source: Qt.resolvedUrl("../icons/network-download-symbolic.svg")
                                    width: cfg_iconSize
                                    height: cfg_iconSize
                                    isMask: true
                                    color: Kirigami.Theme.textColor
                                }
                                Label {
                                    text: cfg_networkUnit === "bits" ? "11.2 Mb/s" : "1.4 MB/s"
                                    font.family: cfg_fontFamily
                                    font.bold: cfg_fontBold
                                    font.pixelSize: cfg_fontSize > 0 ? cfg_fontSize : Kirigami.Theme.defaultFont.pixelSize
                                    color: Kirigami.Theme.textColor
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 2. VISUAL DISPLAY MODE STUDIO
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: displayModeCol.implicitHeight + (Kirigami.Units.largeSpacing * 2)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            border.width: 1

            ColumnLayout {
                id: displayModeCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Heading {
                    text: i18n("Modo de Visualización en Panel")
                    level: 3
                }

                Label {
                    text: i18n("Elige cómo se presentan las métricas ancladas en la barra o panel de Plasma:")
                    opacity: 0.75
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                GridLayout {
                    columns: width > 520 ? 2 : 1
                    Layout.fillWidth: true
                    columnSpacing: Kirigami.Units.mediumSpacing
                    rowSpacing: Kirigami.Units.mediumSpacing

                    // Option: Icons + Text (Hybrid)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(72, tileRow1.implicitHeight + (Kirigami.Units.mediumSpacing * 2))
                        radius: Kirigami.Units.smallSpacing
                        color: cfg_displayMode === "icons+text"
                               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                               : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                        border.color: cfg_displayMode === "icons+text" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: cfg_displayMode === "icons+text" ? 2 : 1

                        TapHandler { onTapped: cfg_displayMode = "icons+text" }

                        RowLayout {
                            id: tileRow1
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Kirigami.Units.mediumSpacing
                            spacing: Kirigami.Units.mediumSpacing

                            Rectangle {
                                width: 36; height: 36; radius: 6
                                color: cfg_displayMode === "icons+text" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "view-list-details"
                                    width: 20; height: 20
                                    color: cfg_displayMode === "icons+text" ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Label { text: i18n("Híbrido (Iconos + Texto)"); font.weight: Font.Bold }
                                Label { text: i18n("Equilibrio ideal: etiqueta, glifo y valor numérico"); font: Kirigami.Theme.smallFont; opacity: 0.65; wrapMode: Text.WordWrap }
                            }
                            Kirigami.Icon {
                                visible: cfg_displayMode === "icons+text"
                                source: "checkmark"
                                color: Kirigami.Theme.highlightColor
                                width: 18; height: 18
                            }
                        }
                    }

                    // Option: Text Only
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(72, tileRow2.implicitHeight + (Kirigami.Units.mediumSpacing * 2))
                        radius: Kirigami.Units.smallSpacing
                        color: cfg_displayMode === "text"
                               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                               : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                        border.color: cfg_displayMode === "text" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: cfg_displayMode === "text" ? 2 : 1

                        TapHandler { onTapped: cfg_displayMode = "text" }

                        RowLayout {
                            id: tileRow2
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Kirigami.Units.mediumSpacing
                            spacing: Kirigami.Units.mediumSpacing

                            Rectangle {
                                width: 36; height: 36; radius: 6
                                color: cfg_displayMode === "text" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "draw-text"
                                    width: 20; height: 20
                                    color: cfg_displayMode === "text" ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Label { text: i18n("Solo Texto (Clásico)"); font.weight: Font.Bold }
                                Label { text: i18n("Mínimo consumo visual en formato tradicional"); font: Kirigami.Theme.smallFont; opacity: 0.65; wrapMode: Text.WordWrap }
                            }
                            Kirigami.Icon {
                                visible: cfg_displayMode === "text"
                                source: "checkmark"
                                color: Kirigami.Theme.highlightColor
                                width: 18; height: 18
                            }
                        }
                    }

                    // Option: Icons Only
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(72, tileRow3.implicitHeight + (Kirigami.Units.mediumSpacing * 2))
                        radius: Kirigami.Units.smallSpacing
                        color: cfg_displayMode === "icons"
                               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                               : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                        border.color: cfg_displayMode === "icons" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: cfg_displayMode === "icons" ? 2 : 1

                        TapHandler { onTapped: cfg_displayMode = "icons" }

                        RowLayout {
                            id: tileRow3
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Kirigami.Units.mediumSpacing
                            spacing: Kirigami.Units.mediumSpacing

                            Rectangle {
                                width: 36; height: 36; radius: 6
                                color: cfg_displayMode === "icons" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "preferences-desktop-icons"
                                    width: 20; height: 20
                                    color: cfg_displayMode === "icons" ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Label { text: i18n("Solo Iconos (Ultra Compacto)"); font.weight: Font.Bold }
                                Label { text: i18n("Máximo ahorro de espacio horizontal en el panel"); font: Kirigami.Theme.smallFont; opacity: 0.65; wrapMode: Text.WordWrap }
                            }
                            Kirigami.Icon {
                                visible: cfg_displayMode === "icons"
                                source: "checkmark"
                                color: Kirigami.Theme.highlightColor
                                width: 18; height: 18
                            }
                        }
                    }

                    // Option: None
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(72, tileRow4.implicitHeight + (Kirigami.Units.mediumSpacing * 2))
                        radius: Kirigami.Units.smallSpacing
                        color: cfg_displayMode === "none"
                               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                               : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
                        border.color: cfg_displayMode === "none" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                        border.width: cfg_displayMode === "none" ? 2 : 1

                        TapHandler { onTapped: cfg_displayMode = "none" }

                        RowLayout {
                            id: tileRow4
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Kirigami.Units.mediumSpacing
                            spacing: Kirigami.Units.mediumSpacing

                            Rectangle {
                                width: 36; height: 36; radius: 6
                                color: cfg_displayMode === "none" ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "view-hidden"
                                    width: 20; height: 20
                                    color: cfg_displayMode === "none" ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                }
                            }
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Label { text: i18n("Oculto en Barra"); font.weight: Font.Bold }
                                Label { text: i18n("Solo abre el popup informativo al pulsar el icono"); font: Kirigami.Theme.smallFont; opacity: 0.65; wrapMode: Text.WordWrap }
                            }
                            Kirigami.Icon {
                                visible: cfg_displayMode === "none"
                                source: "checkmark"
                                color: Kirigami.Theme.highlightColor
                                width: 18; height: 18
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 3. LAYOUT & DESKTOP SURFACE CARDS
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: surfaceCol.implicitHeight + (Kirigami.Units.largeSpacing * 2)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            border.width: 1

            ColumnLayout {
                id: surfaceCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    text: i18n("Orientación y Fondo de Superficie")
                    level: 3
                }

                // Layout Selector Pills
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Label { text: i18n("Orientación de lectura del panel:"); font.weight: Font.DemiBold }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 460 ? 2 : 1
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        Button {
                            Layout.fillWidth: true
                            icon.name: "distribute-horizontal"
                            text: i18n("Horizontal (Barra superior / inferior)")
                            highlighted: cfg_layoutType === "horizontal"
                            onClicked: cfg_layoutType = "horizontal"
                        }
                        Button {
                            Layout.fillWidth: true
                            icon.name: "distribute-vertical"
                            text: i18n("Vertical (Dock lateral)")
                            highlighted: cfg_layoutType === "vertical"
                            onClicked: cfg_layoutType = "vertical"
                        }
                    }
                }

                // Desktop Surface Style
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Label { text: i18n("Estilo de fondo en Escritorio (Modo Widget Libre):"); font.weight: Font.DemiBold }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 540 ? 4 : 2
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        Button {
                            Layout.fillWidth: true
                            text: i18n("Plasma Theme")
                            highlighted: cfg_backgroundType === "default"
                            onClicked: cfg_backgroundType = "default"
                        }
                        Button {
                            Layout.fillWidth: true
                            text: i18n("🧊 Translúcido")
                            highlighted: cfg_backgroundType === "translucent"
                            onClicked: cfg_backgroundType = "translucent"
                        }
                        Button {
                            Layout.fillWidth: true
                            text: i18n("🌘 Sombra Sutil")
                            highlighted: cfg_backgroundType === "shadow"
                            onClicked: cfg_backgroundType = "shadow"
                        }
                        Button {
                            Layout.fillWidth: true
                            text: i18n("🪟 Transparente Puro")
                            highlighted: cfg_backgroundType === "transparent"
                            onClicked: cfg_backgroundType = "transparent"
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 4. TYPOGRAPHY & PROPORTIONS STUDIO
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: typoCol.implicitHeight + (Kirigami.Units.largeSpacing * 2)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            border.width: 1

            ColumnLayout {
                id: typoCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Heading {
                    text: i18n("Estudio Tipográfico y Escala")
                    level: 3
                }

                // Font Search and Selection with System Dropdown
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Label {
                        text: i18n("Familia de Fuente:")
                        Layout.preferredWidth: 140
                        font.weight: Font.DemiBold
                    }

                    TextField {
                        id: fontInput
                        Layout.fillWidth: true
                        text: cfg_fontFamily
                        placeholderText: i18n("Haz clic o escribe para buscar fuentes...")
                        onEditingFinished: {
                            if (text.trim().length > 0) cfg_fontFamily = text.trim();
                        }

                        onPressed: {
                            if (!fontDropdownPopup.visible) {
                                fontDropdownPopup.open();
                            }
                        }

                        Popup {
                            id: fontDropdownPopup
                            y: fontInput.height + 4
                            width: Math.max(340, fontInput.width)
                            height: 280
                            padding: 6
                            closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

                            property var allFonts: Qt.fontFamilies()
                            property string filterText: ""

                            readonly property var filteredList: {
                                var q = filterText.toLowerCase().trim();
                                var res = [];
                                for (var i = 0; i < allFonts.length; i++) {
                                    if (q.length === 0 || allFonts[i].toLowerCase().indexOf(q) !== -1) {
                                        res.push(allFonts[i]);
                                        if (res.length >= 100) break;
                                    }
                                }
                                return res;
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 4

                                TextField {
                                    id: fontSearchInPopup
                                    Layout.fillWidth: true
                                    placeholderText: i18n("Filtrar fuente (ej: Nerd, Mono, Sans)...")
                                    onTextChanged: fontDropdownPopup.filterText = text
                                }

                                ListView {
                                    id: fontListInPopup
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    model: fontDropdownPopup.filteredList
                                    ScrollBar.vertical: ScrollBar { active: true }

                                    delegate: ItemDelegate {
                                        width: fontListInPopup.width
                                        highlighted: cfg_fontFamily === modelData
                                        contentItem: RowLayout {
                                            spacing: 8
                                            Label {
                                                text: modelData
                                                font.family: modelData
                                                font.pixelSize: 13
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Label {
                                                text: "123 58°C"
                                                font.family: modelData
                                                opacity: 0.6
                                                font.pixelSize: 11
                                            }
                                        }
                                        onClicked: {
                                            cfg_fontFamily = modelData;
                                            fontInput.text = modelData;
                                            fontDropdownPopup.close();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ToolButton {
                        icon.name: fontDropdownPopup.visible ? "arrow-up" : "arrow-down"
                        onClicked: {
                            if (fontDropdownPopup.visible) fontDropdownPopup.close();
                            else fontDropdownPopup.open();
                        }
                        ToolTip.text: i18n("Ver todas las fuentes del sistema")
                        ToolTip.visible: hovered
                    }

                    Button {
                        text: "⚡ Nerd Font"
                        icon.name: "font"
                        highlighted: cfg_fontFamily.toLowerCase().indexOf("nerd") !== -1
                        onClicked: {
                            var families = Qt.fontFamilies();
                            var found = "";
                            for (var i = 0; i < families.length; i++) {
                                if (families[i].toLowerCase().indexOf("nerd font mono") !== -1 || families[i].toLowerCase().indexOf("nerd font") !== -1) {
                                    found = families[i];
                                    break;
                                }
                            }
                            var target = found || "JetBrainsMono Nerd Font Mono";
                            cfg_fontFamily = target;
                            fontInput.text = target;
                        }
                    }

                    Button {
                        text: "Hack"
                        onClicked: { cfg_fontFamily = "Hack"; fontInput.text = "Hack"; }
                    }
                    Button {
                        text: "Mono"
                        onClicked: { cfg_fontFamily = "monospace"; fontInput.text = "monospace"; }
                    }
                    Button {
                        text: "Sans"
                        onClicked: { cfg_fontFamily = "Sans Serif"; fontInput.text = "Sans Serif"; }
                    }
                }

                // Bold & Font Size Controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Switch {
                            id: fontBoldSwitch
                        }
                        Label {
                            text: i18n("Texto en Negrita (Bold)")
                            font.weight: fontBoldSwitch.checked ? Font.Bold : Font.Normal
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        Label { text: i18n("Tamaño de Fuente:"); Layout.preferredWidth: 120 }
                        Slider {
                            id: fontSizeSlider
                            Layout.fillWidth: true
                            from: 0; to: 24; stepSize: 1; value: 0
                        }
                        Label {
                            text: fontSizeSlider.value === 0 ? i18n("Auto (Sistema)") : fontSizeSlider.value + " px"
                            font.bold: true
                            Layout.preferredWidth: 90
                        }
                    }
                }

                // Icon Size
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    visible: configPage.iconsEnabled
                    Label { text: i18n("Tamaño de Glifos:"); Layout.preferredWidth: 140 }
                    Slider {
                        id: iconSizeSlider
                        Layout.fillWidth: true
                        from: 8; to: 28; stepSize: 2; value: 12
                    }
                    Label {
                        text: iconSizeSlider.value + " px"
                        font.bold: true
                        Layout.preferredWidth: 60
                    }
                }

                // Opacities & Separators
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        Label { text: i18n("Opacidad de Etiquetas:"); Layout.preferredWidth: 140 }
                        Slider {
                            id: labelOpacitySlider
                            Layout.fillWidth: true
                            from: 0.1; to: 1.0; stepSize: 0.05; value: 0.65
                        }
                        Label {
                            text: Math.round(labelOpacitySlider.value * 100) + "%"
                            font.bold: true
                            Layout.preferredWidth: 45
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        Label { text: i18n("Opacidad Separadores:"); Layout.preferredWidth: 140 }
                        Slider {
                            id: separatorOpacitySlider
                            Layout.fillWidth: true
                            from: 0.0; to: 1.0; stepSize: 0.05; value: 0.40
                        }
                        Label {
                            text: Math.round(separatorOpacitySlider.value * 100) + "%"
                            font.bold: true
                            Layout.preferredWidth: 45
                        }
                    }
                }

                // Toggles for grouping & separators
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    Switch {
                        id: showSeparatorsSwitch
                        text: i18n("Mostrar barras separadoras entre métricas")
                        checked: cfg_showSeparators
                        onToggled: cfg_showSeparators = checked
                    }

                    Switch {
                        id: mergeFamilyMetricsSwitch
                        text: i18n("Agrupar métricas del mismo hardware en un solo bloque")
                        checked: cfg_mergeFamilyMetrics
                        onToggled: cfg_mergeFamilyMetrics = checked
                    }

                    Switch {
                        id: showBlockLeadingIconSwitch
                        text: i18n("Mostrar icono temático delantero de cada bloque")
                        checked: cfg_showBlockLeadingIcon
                        onToggled: cfg_showBlockLeadingIcon = checked
                    }
                }

                // Separator Style Selector Gallery
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    visible: cfg_showSeparators

                    Label {
                        text: i18n("Estilo Visual del Separador:")
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width > 650 ? 5 : (width > 440 ? 3 : 2)
                        rowSpacing: Kirigami.Units.smallSpacing
                        columnSpacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: [
                                { key: "line",       name: i18n("Línea") },
                                { key: "doubleLine", name: i18n("Doble") },
                                { key: "dot",        name: i18n("Punto") },
                                { key: "colon",      name: i18n("Dos Puntos") },
                                { key: "pill",       name: i18n("Píldora") },
                                { key: "slash",      name: i18n("Diagonal") },
                                { key: "chevron",    name: i18n("Chevrón") },
                                { key: "diamond",    name: i18n("Rombo") },
                                { key: "dash",       name: i18n("Guión") }
                            ]

                            delegate: Rectangle {
                                id: styleChip
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 36
                                radius: 6
                                color: cfg_separatorStyle === modelData.key
                                       ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                                       : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                                border.color: cfg_separatorStyle === modelData.key ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                border.width: cfg_separatorStyle === modelData.key ? 2 : 1

                                TapHandler {
                                    onTapped: cfg_separatorStyle = styleChip.modelData.key
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    SeparatorItem {
                                        anchors.verticalCenter: parent.verticalCenter
                                        style: styleChip.modelData.key
                                        color: cfg_separatorStyle === styleChip.modelData.key ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                        separatorOpacity: 1.0
                                        referenceSize: 16
                                    }

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: styleChip.modelData.name
                                        font.bold: cfg_separatorStyle === styleChip.modelData.key
                                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                        color: cfg_separatorStyle === styleChip.modelData.key ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // 5. UNITS & TELEMETRY ENGINE INTERVAL
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: unitsCol.implicitHeight + (Kirigami.Units.largeSpacing * 2)
            radius: Kirigami.Units.smallSpacing * 1.5
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
            border.width: 1

            ColumnLayout {
                id: unitsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.mediumSpacing

                Kirigami.Heading {
                    text: i18n("Motor de Muestreo y Preferencias de Unidades")
                    level: 3
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Label {
                        text: i18n("Frecuencia de Actualización:")
                        Layout.preferredWidth: 180
                        font.weight: Font.DemiBold
                    }

                    Slider {
                        id: intervalSlider
                        Layout.fillWidth: true
                        from: 500
                        to: 6000
                        stepSize: 250
                        value: 2000
                    }

                    Label {
                        text: (intervalSlider.value / 1000).toFixed(2) + " seg"
                        font.bold: true
                        color: Kirigami.Theme.highlightColor
                        Layout.preferredWidth: 70
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: width > 600 ? 3 : 1
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: i18n("Unidad de Temperatura:"); font.weight: Font.DemiBold }
                        RowLayout {
                            Button {
                                text: "°C Celsius"
                                highlighted: cfg_tempUnit === "C"
                                onClicked: cfg_tempUnit = "C"
                            }
                            Button {
                                text: "°F Fahrenheit"
                                highlighted: cfg_tempUnit === "F"
                                onClicked: cfg_tempUnit = "F"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: i18n("Unidad de Red e I/O:"); font.weight: Font.DemiBold }
                        RowLayout {
                            Button {
                                text: "Bytes (KB/s, MB/s)"
                                highlighted: cfg_networkUnit === "bytes"
                                onClicked: cfg_networkUnit = "bytes"
                            }
                            Button {
                                text: "Bits (Kb/s, Mb/s)"
                                highlighted: cfg_networkUnit === "bits"
                                onClicked: cfg_networkUnit = "bits"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label { text: i18n("Unidad de Ventilador:"); font.weight: Font.DemiBold }
                        RowLayout {
                            Button {
                                text: "RPM Absoluto"
                                highlighted: cfg_fanUnit === "rpm"
                                onClicked: cfg_fanUnit = "rpm"
                            }
                            Button {
                                text: "% Porcentaje"
                                highlighted: cfg_fanUnit === "percent"
                                onClicked: cfg_fanUnit = "percent"
                            }
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    Label {
                        text: i18n("Formato Numérico y Relleno de Espacios:")
                        font.weight: Font.DemiBold
                    }

                    CheckBox {
                        id: swapDynamicUnitsCheck
                        text: i18n("Unidades dinámicas en Memoria y SWAP (mostrar en MB hasta 1024 MB, luego pasar a GB)")
                        checked: cfg_swapDynamicUnits
                        onToggled: cfg_swapDynamicUnits = checked
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing

                        Label {
                            text: i18n("Red (Descarga y Subida) - Unidad mínima:")
                        }

                        ComboBox {
                            id: netMinUnitCombo
                            model: [
                                { text: i18n("Automático (Bytes / KB / MB)"), value: "auto" },
                                { text: i18n("Forzar mínimo KB (descartar Bytes: ej. 0.0 KB)"), value: "KB" },
                                { text: i18n("Forzar mínimo MB (descartar Bytes y KB: ej. 0.00 MB)"), value: "MB" }
                            ]
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: {
                                var val = (cfg_netMinUnit && cfg_netMinUnit !== "auto") ? cfg_netMinUnit : cfg_netDownMinUnit;
                                for (var i = 0; i < model.length; i++) {
                                    if (model[i].value === val) return i;
                                }
                                return 0;
                            }
                            onActivated: {
                                cfg_netMinUnit = model[currentIndex].value;
                                cfg_netDownMinUnit = model[currentIndex].value;
                            }
                        }
                    }

                    Kirigami.Separator { Layout.fillWidth: true }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Label {
                            text: i18n("Relleno de espacios en blanco (Padding numérico individual):")
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: i18n("Selecciona individualmente qué parámetros alinean números con espacios delante para ancho fijo:")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.75
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Button {
                                text: i18n("Marcar todos")
                                icon.name: "checkbox"
                                onClicked: {
                                    cfg_paddedMetrics = "cpu,ram,swap,temp,gpu,bat,net/down,net/up,disk,fan,uptime";
                                }
                            }

                            Button {
                                text: i18n("Desmarcar todos")
                                icon.name: "edit-clear"
                                onClicked: {
                                    cfg_paddedMetrics = "";
                                }
                            }
                        }
                    }

                    GridLayout {
                        columns: width > 600 ? 3 : (width > 380 ? 2 : 1)
                        rowSpacing: Kirigami.Units.smallSpacing
                        columnSpacing: Kirigami.Units.largeSpacing
                        Layout.fillWidth: true

                        CheckBox {
                            text: i18n("CPU (uso, núcleos)")
                            checked: isMetricPadded("cpu")
                            onToggled: setMetricPadded("cpu", checked)
                        }

                        CheckBox {
                            text: i18n("RAM (porcentaje)")
                            checked: isMetricPadded("ram")
                            onToggled: setMetricPadded("ram", checked)
                        }

                        CheckBox {
                            text: i18n("SWAP (porcentaje, uso)")
                            checked: isMetricPadded("swap")
                            onToggled: setMetricPadded("swap", checked)
                        }

                        CheckBox {
                            text: i18n("Temperatura")
                            checked: isMetricPadded("temp")
                            onToggled: setMetricPadded("temp", checked)
                        }

                        CheckBox {
                            text: i18n("GPU (uso)")
                            checked: isMetricPadded("gpu")
                            onToggled: setMetricPadded("gpu", checked)
                        }

                        CheckBox {
                            text: i18n("Batería (porcentaje)")
                            checked: isMetricPadded("bat")
                            onToggled: setMetricPadded("bat", checked)
                        }

                        CheckBox {
                            text: i18n("Red Descarga (↓)")
                            checked: isMetricPadded("net/down")
                            onToggled: setMetricPadded("net/down", checked)
                        }

                        CheckBox {
                            text: i18n("Red Subida (↑)")
                            checked: isMetricPadded("net/up")
                            onToggled: setMetricPadded("net/up", checked)
                        }

                        CheckBox {
                            text: i18n("Disco (tasa, uso)")
                            checked: isMetricPadded("disk")
                            onToggled: setMetricPadded("disk", checked)
                        }

                        CheckBox {
                            text: i18n("Ventiladores (RPM)")
                            checked: isMetricPadded("fan")
                            onToggled: setMetricPadded("fan", checked)
                        }

                        CheckBox {
                            text: i18n("Tiempo encendido (Uptime)")
                            checked: isMetricPadded("uptime")
                            onToggled: setMetricPadded("uptime", checked)
                        }
                    }

                    Kirigami.Separator { Layout.fillWidth: true }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Label {
                            text: i18n("Estilo MangoHud / Sufijo en letra pequeña individual:")
                            font.weight: Font.DemiBold
                        }

                        Label {
                            text: i18n("Muestra unidades y etiquetas secundarias en formato superíndice pequeño detrás del número (ej. 49°C Jnc, 1435 MHz, 35.5 W, 743 mV, 118 RPM):")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.75
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Button {
                                text: i18n("Marcar todos")
                                icon.name: "checkbox"
                                onClicked: {
                                    cfg_smallSuffixMetrics = "gpu/freq,gpu/memFreq,gpu/hotspot,gpu/vramTemp,gpu/temp,gpu/power,gpu/voltage,cpu/freq,cpu/power,cpu/voltage,cpu/temp,fan,bat/power,net/down,net/up,disk/read,disk/write,disk/temp,ram/used,swap/used,ram/temp";
                                }
                            }

                            Button {
                                text: i18n("Desmarcar todos")
                                icon.name: "edit-clear"
                                onClicked: {
                                    cfg_smallSuffixMetrics = "";
                                }
                            }
                        }
                    }

                    GridLayout {
                        columns: width > 600 ? 3 : (width > 380 ? 2 : 1)
                        rowSpacing: Kirigami.Units.smallSpacing
                        columnSpacing: Kirigami.Units.largeSpacing
                        Layout.fillWidth: true

                        CheckBox {
                            text: i18n("GPU Reloj (MHz)")
                            checked: isMetricSmallSuffix("gpu/freq")
                            onToggled: setMetricSmallSuffix("gpu/freq", checked)
                        }

                        CheckBox {
                            text: i18n("GPU VRAM Reloj (MHz)")
                            checked: isMetricSmallSuffix("gpu/memFreq")
                            onToggled: setMetricSmallSuffix("gpu/memFreq", checked)
                        }

                        CheckBox {
                            text: i18n("GPU Hotspot (°C + Jnc)")
                            checked: isMetricSmallSuffix("gpu/hotspot")
                            onToggled: setMetricSmallSuffix("gpu/hotspot", checked)
                        }

                        CheckBox {
                            text: i18n("GPU VRAM Temp (°C + Mem)")
                            checked: isMetricSmallSuffix("gpu/vramTemp")
                            onToggled: setMetricSmallSuffix("gpu/vramTemp", checked)
                        }

                        CheckBox {
                            text: i18n("GPU Temperatura (°C)")
                            checked: isMetricSmallSuffix("gpu/temp")
                            onToggled: setMetricSmallSuffix("gpu/temp", checked)
                        }

                        CheckBox {
                            text: i18n("GPU Potencia (W)")
                            checked: isMetricSmallSuffix("gpu/power")
                            onToggled: setMetricSmallSuffix("gpu/power", checked)
                        }

                        CheckBox {
                            text: i18n("GPU Voltaje (mV / V)")
                            checked: isMetricSmallSuffix("gpu/voltage")
                            onToggled: setMetricSmallSuffix("gpu/voltage", checked)
                        }

                        CheckBox {
                            text: i18n("CPU Frecuencia (MHz / GHz)")
                            checked: isMetricSmallSuffix("cpu/freq")
                            onToggled: setMetricSmallSuffix("cpu/freq", checked)
                        }

                        CheckBox {
                            text: i18n("CPU Potencia (W)")
                            checked: isMetricSmallSuffix("cpu/power")
                            onToggled: setMetricSmallSuffix("cpu/power", checked)
                        }

                        CheckBox {
                            text: i18n("CPU Voltaje (mV / V)")
                            checked: isMetricSmallSuffix("cpu/voltage")
                            onToggled: setMetricSmallSuffix("cpu/voltage", checked)
                        }

                        CheckBox {
                            text: i18n("CPU Temperatura (°C)")
                            checked: isMetricSmallSuffix("cpu/temp")
                            onToggled: setMetricSmallSuffix("cpu/temp", checked)
                        }

                        CheckBox {
                            text: i18n("Ventiladores (RPM)")
                            checked: isMetricSmallSuffix("fan")
                            onToggled: setMetricSmallSuffix("fan", checked)
                        }

                        CheckBox {
                            text: i18n("Batería Consumo (W)")
                            checked: isMetricSmallSuffix("bat/power")
                            onToggled: setMetricSmallSuffix("bat/power", checked)
                        }

                        CheckBox {
                            text: i18n("Red Descarga y Subida (KB/s, MB/s)")
                            checked: isMetricSmallSuffix("net/down") || isMetricSmallSuffix("net/up")
                            onToggled: {
                                setMetricSmallSuffix("net/down", checked);
                                setMetricSmallSuffix("net/up", checked);
                            }
                        }

                        CheckBox {
                            text: i18n("Disco Lectura / Escritura (MB/s)")
                            checked: isMetricSmallSuffix("disk/read") || isMetricSmallSuffix("disk/write")
                            onToggled: {
                                setMetricSmallSuffix("disk/read", checked);
                                setMetricSmallSuffix("disk/write", checked);
                            }
                        }

                        CheckBox {
                            text: i18n("Disco Temperatura (°C)")
                            checked: isMetricSmallSuffix("disk/temp")
                            onToggled: setMetricSmallSuffix("disk/temp", checked)
                        }

                        CheckBox {
                            text: i18n("RAM y SWAP Usado (GB / MB)")
                            checked: isMetricSmallSuffix("ram/used") || isMetricSmallSuffix("swap/used")
                            onToggled: {
                                setMetricSmallSuffix("ram/used", checked);
                                setMetricSmallSuffix("swap/used", checked);
                            }
                        }

                        CheckBox {
                            text: i18n("RAM Temperatura DDR5 (°C)")
                            checked: isMetricSmallSuffix("ram/temp")
                            onToggled: setMetricSmallSuffix("ram/temp", checked)
                        }
                    }
                }
            }
        }
    }
}
