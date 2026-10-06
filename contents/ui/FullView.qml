import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "models/MetricDefinitions.js" as MetricDefinitions

ColumnLayout {
    id: fullView
    spacing: 8
    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.preferredHeight: Kirigami.Units.gridUnit * 26
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.maximumWidth: Kirigami.Units.gridUnit * 28
    Layout.minimumHeight: Kirigami.Units.gridUnit * 16
    Layout.maximumHeight: Kirigami.Units.gridUnit * 38

    required property var groupsModel
    required property color baseTextColor
    required property color labelColor
    required property color iconColor
    required property bool fontBold
    required property bool pinned
    property var profileSummaries: []
    property string activeProfileId: ""
    property string activeProfileName: ""
    signal togglePinned()
    signal toggleMetricPin(string metricId)
    signal refreshRequested()
    signal activateProfile(string id)
    signal savePreset(string name)

    property string filterCategory: "all"
    property string searchQuery: ""

    function resolveIcon(name) {
        if (!name) return "configure";
        var str = String(name);
        if (MetricDefinitions.isBundledIcon(str)) {
            return Qt.resolvedUrl("../icons/" + str + ".svg");
        }
        return name;
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
        function exec(cmd) {
            connectSource(cmd);
        }
    }

    // Count pinned metrics across groups
    readonly property int totalPinnedCount: {
        var count = 0;
        if (!groupsModel) return 0;
        for (var i = 0; i < groupsModel.length; i++) {
            var g = groupsModel[i];
            if (!g || !g.sections) continue;
            for (var s = 0; s < g.sections.length; s++) {
                var sec = g.sections[s];
                if (!sec || !sec.metrics) continue;
                for (var m = 0; m < sec.metrics.length; m++) {
                    if (sec.metrics[m] && sec.metrics[m].isPinned) count++;
                }
            }
        }
        return count;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 1. KARDIO MODERN DASHBOARD HEADER
    // ═══════════════════════════════════════════════════════════════════════
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + (Kirigami.Units.smallSpacing * 2)
        radius: Kirigami.Units.smallSpacing * 1.5
        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.10)
        border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.28)
        border.width: 1

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            // Kardio Logo & Pulse Identity
            Rectangle {
                implicitWidth: 32; implicitHeight: 32
                radius: 16
                color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.22)
                border.color: Kirigami.Theme.highlightColor
                border.width: 1

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: fullView.resolveIcon("kardio-symbolic")
                    implicitWidth: 18; implicitHeight: 18
                    color: Kirigami.Theme.highlightColor
                }
            }

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true

                RowLayout {
                    spacing: 6
                    PlasmaComponents.Label {
                        text: "KARDIO"
                        font.bold: true
                        font.weight: Font.Black
                        font.letterSpacing: 1.2
                        color: Kirigami.Theme.highlightColor
                    }

                    Rectangle {
                        radius: 8
                        implicitHeight: 18
                        implicitWidth: pinnedCountText.implicitWidth + 12
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

                        PlasmaComponents.Label {
                            id: pinnedCountText
                            anchors.centerIn: parent
                            text: i18n("%1 en panel", fullView.totalPinnedCount)
                            font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                            font.bold: true
                            opacity: 0.85
                        }
                    }
                }

                PlasmaComponents.Label {
                    text: i18n("Gestión rápida de métricas al vuelo")
                    font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                    opacity: 0.65
                }
            }

            // Quick Action Toolbar (Refrescar y Fijar únicamente)
            RowLayout {
                spacing: 4

                QQC2.ToolButton {
                    icon.name: "view-refresh-symbolic"
                    implicitWidth: 28; implicitHeight: 28
                    QQC2.ToolTip.text: i18n("Reescanear sensores de hardware")
                    QQC2.ToolTip.visible: hovered
                    onClicked: fullView.refreshRequested()
                }

                QQC2.ToolButton {
                    icon.name: fullView.pinned ? "window-unpin" : "window-pin"
                    implicitWidth: 28; implicitHeight: 28
                    QQC2.ToolTip.text: fullView.pinned ? i18n("Desanclar ventana") : i18n("Fijar ventana abierta")
                    QQC2.ToolTip.visible: hovered
                    highlighted: fullView.pinned
                    onClicked: fullView.togglePinned()
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 2. SEARCH & CATEGORY FILTER CHIPS (DESPLAZABLE HORIZONTALMENTE)
    // ═══════════════════════════════════════════════════════════════════════
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        QQC2.TextField {
            id: quickSearchInput
            Layout.fillWidth: true
            placeholderText: i18n("Buscar métrica al vuelo (ej: temp, wifi, cpu)...")
            onTextChanged: fullView.searchQuery = text.trim().toLowerCase()

            QQC2.ToolButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: quickSearchInput.text.length > 0
                icon.name: "edit-clear"
                implicitWidth: 24; implicitHeight: 24
                onClicked: quickSearchInput.text = ""
            }
        }
    }

    // Category Filter Chips (Horizontal ListView con desplazamiento suave y barra separada)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        ListView {
            id: categoryFilterList
            Layout.fillWidth: true
            implicitHeight: 30
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            model: [
                { id: "all", label: i18n("Todos"), icon: "system-run" },
                { id: "cpu", label: "CPU", icon: "cpu-symbolic" },
                { id: "gpu", label: "GPU", icon: "gpu-symbolic" },
                { id: "memory", label: "RAM & SWAP", icon: "memory-symbolic" },
                { id: "disk", label: i18n("Discos"), icon: "storage-symbolic" },
                { id: "net", label: i18n("Red"), icon: "network-wireless-symbolic" },
                { id: "temp", label: i18n("Térmico"), icon: "temperature-symbolic" },
                { id: "bat", label: i18n("Batería"), icon: "battery-symbolic" },
                { id: "fan", label: i18n("Fans"), icon: "fan-symbolic" }
            ]

            delegate: QQC2.Button {
                required property var modelData
                text: modelData.label
                icon.name: fullView.resolveIcon(modelData.icon)
                highlighted: fullView.filterCategory === modelData.id
                implicitHeight: 28
                onClicked: {
                    fullView.filterCategory = modelData.id;
                }
            }
        }

        QQC2.ScrollBar {
            id: categoryFilterScrollBar
            Layout.fillWidth: true
            implicitHeight: 6
            orientation: Qt.Horizontal
            visible: categoryFilterList.contentWidth > categoryFilterList.width
            size: categoryFilterList.contentWidth > 0 ? Math.min(1.0, categoryFilterList.width / categoryFilterList.contentWidth) : 1.0
            position: categoryFilterList.contentWidth > 0 ? Math.max(0, Math.min(1.0 - size, categoryFilterList.contentX / categoryFilterList.contentWidth)) : 0
            active: categoryFilterList.moving || categoryFilterList.flicking || hovered || pressed
            onPositionChanged: {
                if (pressed && categoryFilterList.contentWidth > 0) {
                    categoryFilterList.contentX = position * categoryFilterList.contentWidth;
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 3. INTERACTIVE METRIC TILES DECK
    // ═══════════════════════════════════════════════════════════════════════
    QQC2.ScrollView {
        id: metricScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: metricScroll.availableWidth
            spacing: 8

            Repeater {
                model: fullView.groupsModel

                delegate: ColumnLayout {
                    id: groupSection
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 4

                    readonly property string catKey: modelData.key
                    readonly property bool matchesCat: {
                        if (fullView.filterCategory === "all") return true;
                        var fc = fullView.filterCategory;
                        if (fc === "cpu" && (catKey === "processor" || catKey === "cpu")) return true;
                        if (fc === "gpu" && catKey === "gpu") return true;
                        if (fc === "memory" && (catKey === "memory" || catKey === "ram" || catKey === "swap")) return true;
                        if (fc === "disk" && (catKey === "storage" || catKey === "disk")) return true;
                        if (fc === "net" && (catKey === "network" || catKey === "net")) return true;
                        if (fc === "temp" && (catKey === "temperature" || catKey === "temp")) return true;
                        if (fc === "bat" && (catKey === "battery" || catKey === "bat")) return true;
                        if (fc === "fan" && catKey === "fan") return true;
                        if (fc === "system" && (catKey === "system" || catKey === "uptime")) return true;
                        return fc === catKey;
                    }
                    visible: matchesCat

                    // Category Banner Card
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 6
                        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Kirigami.Icon {
                                source: fullView.resolveIcon(groupSection.modelData.icon)
                                implicitWidth: 14; implicitHeight: 14
                                color: Kirigami.Theme.highlightColor
                            }

                            PlasmaComponents.Label {
                                text: groupSection.modelData.groupLabel
                                font.bold: true
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                color: fullView.labelColor
                                Layout.fillWidth: true
                            }

                            PlasmaComponents.Label {
                                visible: !!groupSection.modelData.aggregateValue
                                text: groupSection.modelData.aggregateValue || ""
                                font.bold: true
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                color: groupSection.modelData.aggregateColor || Kirigami.Theme.highlightColor
                            }
                        }
                    }

                    // Metrics Grid / Rows inside this category
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: groupSection.modelData.sections

                            delegate: ColumnLayout {
                                id: sectionBlock
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: sectionBlock.modelData.metrics

                                    delegate: Rectangle {
                                        id: metricCard
                                        required property var modelData
                                        required property int index

                                        readonly property bool isMatched: {
                                            if (!fullView.searchQuery || fullView.searchQuery.length === 0) return true;
                                            var q = fullView.searchQuery;
                                            var lbl = (modelData.label || "").toLowerCase();
                                            var sub = (modelData.subLabel || "").toLowerCase();
                                            var mid = (modelData.id || "").toLowerCase();
                                            return lbl.indexOf(q) !== -1 || sub.indexOf(q) !== -1 || mid.indexOf(q) !== -1;
                                        }

                                        visible: isMatched
                                        Layout.fillWidth: true
                                        implicitHeight: 40
                                        radius: 6

                                        color: modelData.isPinned
                                               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.14)
                                               : (hoverHandler.hovered
                                                  ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                                                  : Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.40))
                                        border.color: modelData.isPinned
                                                      ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.50)
                                                      : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                                        border.width: modelData.isPinned ? 1.5 : 1

                                        HoverHandler {
                                            id: hoverHandler
                                        }

                                        TapHandler {
                                            onTapped: fullView.toggleMetricPin(metricCard.modelData.id)
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            // Icon Badge
                                            Rectangle {
                                                implicitWidth: 24; implicitHeight: 24
                                                radius: 12
                                                color: metricCard.modelData.isPinned
                                                       ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
                                                       : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10)

                                                Kirigami.Icon {
                                                    anchors.centerIn: parent
                                                    source: fullView.resolveIcon(metricCard.modelData.icon)
                                                    implicitWidth: 14; implicitHeight: 14
                                                    color: metricCard.modelData.isPinned ? Kirigami.Theme.highlightColor : fullView.iconColor
                                                }
                                            }

                                            // Label & Subtitle
                                            ColumnLayout {
                                                spacing: 0
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter

                                                PlasmaComponents.Label {
                                                    text: metricCard.modelData.subLabel || metricCard.modelData.label
                                                    font.bold: metricCard.modelData.isPinned
                                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                PlasmaComponents.Label {
                                                    text: metricCard.modelData.label !== metricCard.modelData.subLabel ? metricCard.modelData.label : metricCard.modelData.id
                                                    font.pixelSize: Math.max(8, Kirigami.Theme.smallFont.pixelSize - 2)
                                                    opacity: 0.55
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            // Live Value Display
                                            PlasmaComponents.Label {
                                                text: metricCard.modelData.displayValue || "..."
                                                font.bold: true
                                                font.family: "monospace"
                                                color: metricCard.modelData.color || fullView.baseTextColor
                                                horizontalAlignment: Text.AlignRight
                                            }

                                            // Interactive Pin Toggle Chip
                                            Rectangle {
                                                implicitHeight: 24
                                                implicitWidth: pinChipRow.implicitWidth + 12
                                                radius: 12
                                                color: metricCard.modelData.isPinned
                                                       ? Kirigami.Theme.highlightColor
                                                       : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                                                border.color: metricCard.modelData.isPinned
                                                              ? Kirigami.Theme.highlightColor
                                                              : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.20)
                                                border.width: 1

                                                RowLayout {
                                                    id: pinChipRow
                                                    anchors.centerIn: parent
                                                    spacing: 4

                                                    Kirigami.Icon {
                                                        source: metricCard.modelData.isPinned ? "dialog-ok-apply" : "list-add"
                                                        implicitWidth: 12; implicitHeight: 12
                                                        color: metricCard.modelData.isPinned ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                                    }

                                                    PlasmaComponents.Label {
                                                        text: metricCard.modelData.isPinned ? i18n("Panel") : i18n("Anclar")
                                                        font.bold: true
                                                        font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                                                        color: metricCard.modelData.isPinned ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
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

    // ═══════════════════════════════════════════════════════════════════════
    // 4. BOTTOM PROFILE & STATUS BAR
    // ═══════════════════════════════════════════════════════════════════════
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: footerRow.implicitHeight + (Kirigami.Units.smallSpacing * 1.5)
        radius: Kirigami.Units.smallSpacing
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
        border.width: 1

        RowLayout {
            id: footerRow
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                id: profileSelectorBtn
                icon.name: "bookmarks"
                text: i18n("Perfil: %1", fullView.activeProfileName || "Predeterminado")
                implicitHeight: 26
                onClicked: profileFlyoutMenu.open()

                QQC2.Menu {
                    id: profileFlyoutMenu
                    y: profileSelectorBtn.height

                    Instantiator {
                        model: fullView.profileSummaries
                        delegate: QQC2.MenuItem {
                            text: modelData.name
                            icon.name: modelData.id === fullView.activeProfileId ? "dialog-ok-apply" : ""
                            checkable: true
                            checked: modelData.id === fullView.activeProfileId
                            onClicked: fullView.activateProfile(modelData.id)
                        }
                        onObjectAdded: (idx, obj) => profileFlyoutMenu.insertItem(idx, obj)
                        onObjectRemoved: (idx, obj) => profileFlyoutMenu.removeItem(obj)
                    }

                    QQC2.MenuSeparator {}

                    QQC2.MenuItem {
                        text: i18n("Guardar configuración actual...")
                        icon.name: "document-save"
                        onClicked: {
                            profileFlyoutMenu.close();
                            savePresetPopup.open();
                        }
                    }
                }
            }

            QQC2.ToolButton {
                icon.name: "document-save"
                implicitWidth: 26; implicitHeight: 26
                QQC2.ToolTip.text: i18n("Guardar configuración como nuevo preset")
                QQC2.ToolTip.visible: hovered
                onClicked: savePresetPopup.open()
            }

            Item { Layout.fillWidth: true }

            // Live status pulse indicator
            RowLayout {
                spacing: 5
                Rectangle {
                    implicitWidth: 8; implicitHeight: 8; radius: 4
                    color: "#2ecc71"
                }
                PlasmaComponents.Label {
                    text: i18n("Monitorización activa")
                    font.pixelSize: Math.max(9, Kirigami.Theme.smallFont.pixelSize - 1)
                    opacity: 0.65
                }
            }
        }
    }

    QQC2.Popup {
        id: savePresetPopup
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        width: Math.min(parent.width - 32, Kirigami.Units.gridUnit * 16)
        padding: Kirigami.Units.smallSpacing * 2

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: i18n("Guardar Preset")
                font.bold: true
                color: Kirigami.Theme.highlightColor
            }

            PlasmaComponents.Label {
                text: i18n("Introduce un nombre para el nuevo preset:")
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.8
            }

            QQC2.TextField {
                id: presetNameInput
                Layout.fillWidth: true
                placeholderText: i18n("Nombre del preset...")
                onAccepted: {
                    if (text.trim().length > 0) {
                        fullView.savePreset(text.trim());
                        savePresetPopup.close();
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 6

                QQC2.Button {
                    text: i18n("Cancelar")
                    onClicked: savePresetPopup.close()
                }

                QQC2.Button {
                    text: i18n("Guardar")
                    highlighted: true
                    enabled: presetNameInput.text.trim().length > 0
                    onClicked: {
                        fullView.savePreset(presetNameInput.text.trim());
                        savePresetPopup.close();
                    }
                }
            }
        }

        onOpened: {
            presetNameInput.text = i18n("Preset %1", (fullView.profileSummaries ? fullView.profileSummaries.length : 0) + 1);
            presetNameInput.selectAll();
            presetNameInput.forceActiveFocus();
        }
    }
}
