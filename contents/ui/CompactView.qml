import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: compactRoot

    required property var metricsModel
    required property bool useIcons
    required property bool useText
    required property int effectiveFontSize
    required property string fontFamily
    required property bool fontBold
    required property int iconSize
    required property color baseTextColor
    required property color labelColor
    required property color iconColor
    required property string layoutType
    required property real labelOpacity
    required property real separatorOpacity
    property string separatorStyle: "line"
    property bool enableNumberPadding: false
    property string paddedMetrics: ""
    property string smallSuffixMetrics: ""
    required property bool showSeparators
    required property string backgroundType
    required property bool isPlanar

    readonly property bool isVertical: layoutType === "vertical"
    readonly property bool customFont: effectiveFontSize > 0

    readonly property int hPadding: (isPlanar && backgroundType !== "transparent" && backgroundType !== "shadow") ? Math.round(Kirigami.Units.gridUnit * 0.75) : 0
    readonly property int vPadding: (isPlanar && backgroundType !== "transparent" && backgroundType !== "shadow") ? Math.round(Kirigami.Units.smallSpacing * 0.75) : 0

    implicitWidth: compactRow.implicitWidth + (hPadding * 2)
    implicitHeight: compactRow.implicitHeight + (vPadding * 2)

    signal toggleExpanded()

    Rectangle {
        id: desktopBg
        visible: compactRoot.isPlanar && compactRoot.backgroundType !== "transparent" && compactRoot.backgroundType !== "shadow"
        anchors.centerIn: compactRow
        width: compactRow.implicitWidth + (compactRoot.hPadding * 2)
        height: compactRow.implicitHeight + (compactRoot.vPadding * 2)
        radius: Math.round(height * 0.5)
        color: {
            if (compactRoot.backgroundType === "translucent") {
                return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.45);
            }
            return Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.80);
        }
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
        border.width: 1
    }

    TapHandler {
        onTapped: compactRoot.toggleExpanded()
    }

    RowLayout {
        id: compactRow
        anchors.centerIn: parent
        spacing: Math.round(Kirigami.Units.gridUnit * 0.65)

        readonly property var metricsModel: compactRoot.metricsModel
        readonly property bool useIcons: compactRoot.useIcons
        readonly property bool useText: compactRoot.useText
        readonly property int effectiveFontSize: compactRoot.effectiveFontSize
        readonly property string fontFamily: compactRoot.fontFamily
        readonly property bool fontBold: compactRoot.fontBold
        readonly property int iconSize: compactRoot.iconSize
        readonly property color baseTextColor: compactRoot.baseTextColor
        readonly property color labelColor: compactRoot.labelColor
        readonly property color iconColor: compactRoot.iconColor
        readonly property string layoutType: compactRoot.layoutType
        readonly property real labelOpacity: compactRoot.labelOpacity
        readonly property real separatorOpacity: compactRoot.separatorOpacity
        readonly property string separatorStyle: compactRoot.separatorStyle
        readonly property bool enableNumberPadding: compactRoot.enableNumberPadding
        readonly property string paddedMetrics: compactRoot.paddedMetrics
        readonly property string smallSuffixMetrics: compactRoot.smallSuffixMetrics
        readonly property bool showSeparators: compactRoot.showSeparators
        readonly property bool isVertical: compactRoot.isVertical
        readonly property bool customFont: compactRoot.customFont

        function isItemPadded(key) {
            if (!compactRow.paddedMetrics || compactRow.paddedMetrics === "") {
                return compactRow.enableNumberPadding;
            }
            if (!key) return false;
            var list = compactRow.paddedMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
            if (list.indexOf(key) !== -1) return true;
            var group = key.indexOf("/") !== -1 ? key.split("/")[0] : (key.indexOf(":") !== -1 ? key.split(":")[0] : key);
            return list.indexOf(group) !== -1;
        }

        function isItemSmallSuffix(key) {
            if (!compactRow.smallSuffixMetrics || compactRow.smallSuffixMetrics === "") {
                return false;
            }
            if (!key) return false;
            var list = compactRow.smallSuffixMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
            if (list.indexOf(key) !== -1) return true;
            var group = key.indexOf("/") !== -1 ? key.split("/")[0] : (key.indexOf(":") !== -1 ? key.split(":")[0] : key);
            return list.indexOf(group) !== -1;
        }

        function splitValueAndSuffix(valueStr, key) {
            if (!valueStr || typeof valueStr !== "string") {
                return { main: valueStr || "", suffix: "" };
            }
            var str = valueStr.trim();
            if (!str) return { main: "", suffix: "" };

            if (key && (key.indexOf("hotspot") !== -1 || key === "gpu.hotspot")) {
                return { main: str, suffix: "Jnc" };
            }
            if (key && (key.indexOf("vramTemp") !== -1 || key === "gpu.vramTemp")) {
                return { main: str, suffix: "Mem" };
            }
            if (key && (key.indexOf("ram.temp") !== -1 || key === "ram/temp")) {
                return { main: str, suffix: "DDR" };
            }

            var m = str.match(/^([\d.,/]+(?:\s*°[CF])?)\s*([A-Za-z/%]+(?:[A-Za-z0-9/._-]+)*)$/);
            if (m) {
                return { main: m[1].trim(), suffix: m[2].trim() };
            }

            var lastSpace = str.lastIndexOf(" ");
            if (lastSpace > 0) {
                var first = str.substring(0, lastSpace).trim();
                var second = str.substring(lastSpace + 1).trim();
                if (second.length > 0 && isNaN(Number(second))) {
                    return { main: first, suffix: second };
                }
            }

            return { main: str, suffix: "" };
        }

        // Defers isMask+color on Kirigami.Icon items until after the Plasma startup
        // window-attachment sequence (ShellCorona::addOutput) completes. This prevents
        // PlatformThemeData::setColor from being called while uninitialized (SIGSEGV #41).
        property bool _themeReady: false
        Timer {
            interval: 0
            repeat: false
            running: true
            onTriggered: compactRow._themeReady = true
        }

        // Sticky width cache
        property var _stickyWidths: ({})

        function resetStickyWidths() {
            _stickyWidths = ({});
        }

        onEffectiveFontSizeChanged: resetStickyWidths()
        onFontFamilyChanged: resetStickyWidths()
        onIconSizeChanged: resetStickyWidths()
        onLayoutTypeChanged: resetStickyWidths()
        onUseIconsChanged: resetStickyWidths()
        onUseTextChanged: resetStickyWidths()

        function _stickyWidth(key, w) {
            var cur = _stickyWidths[key] || 0;
            if (w > cur) {
                _stickyWidths[key] = w;
                cur = w;
            }
            return cur;
        }

    function resolveIcon(name) {
        if (!name) return "";
        var str = String(name);
        if (MetricDefinitions.isBundledIcon(str)) {
            return Qt.resolvedUrl("../icons/" + str + ".svg");
        }
        return name;
    }

    // Shared segments renderer
    component SegmentsRow: Row {
        id: segRoot
        required property var segments
        property string parentKey: ""
        spacing: 2

        Repeater {
            model: segments
            delegate: Row {
                required property var modelData
                required property int index
                spacing: 2

                PlasmaComponents.Label {
                    visible: index > 0
                    text: "·"
                    font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: compactRow.baseTextColor
                    opacity: compactRow.separatorOpacity
                    anchors.verticalCenter: parent.verticalCenter
                }

                Kirigami.Icon {
                    visible: !!modelData.icon && compactRow.useIcons
                    source: compactRow.resolveIcon(modelData.icon)
                    isMask: compactRow._themeReady
                    color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
                    width: Math.round(compactRow.iconSize * 0.85)
                    height: Math.round(compactRow.iconSize * 0.85)
                    anchors.verticalCenter: parent.verticalCenter
                }

                PlasmaComponents.Label {
                    visible: !!modelData.label && (compactRow.useText || (compactRow.useIcons && !modelData.icon && !modelData.isIconDisabled))
                    text: modelData.label || ""
                    font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: compactRow.labelColor
                    opacity: compactRow.labelOpacity
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    id: segValRow
                    spacing: 1
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property var parsed: compactRow.splitValueAndSuffix(modelData.value, modelData.key || segRoot.parentKey)
                    readonly property bool hasSuffix: compactRow.isItemSmallSuffix(modelData.key || segRoot.parentKey) && parsed.suffix.length > 0

                    PlasmaComponents.Label {
                        text: segValRow.hasSuffix ? segValRow.parsed.main : (modelData.value || "")
                        font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                        font.family: compactRow.fontFamily
                        font.bold: compactRow.fontBold
                        color: modelData.color
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        width: compactRow.isItemPadded(modelData.key || segRoot.parentKey)
                            ? compactRow._stickyWidth(
                                segRoot.parentKey + ":" + (modelData.key !== undefined ? modelData.key : index),
                                implicitWidth)
                            : implicitWidth
                    }

                    PlasmaComponents.Label {
                        visible: segValRow.hasSuffix
                        text: segValRow.parsed.suffix
                        font.pixelSize: Math.max(7, Math.round((compactRow.customFont ? compactRow.effectiveFontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.70))
                        font.family: compactRow.fontFamily
                        font.bold: false
                        color: modelData.color
                        opacity: 0.85
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Math.max(1, Math.round((compactRow.customFont ? compactRow.effectiveFontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.22))
                    }
                }
            }
        }
    }

    RowLayout {
        visible: !compactRow.metricsModel || compactRow.metricsModel.length === 0
        spacing: Kirigami.Units.smallSpacing
        Layout.fillHeight: true

        Kirigami.Icon {
            source: Qt.resolvedUrl("../icons/kardio-symbolic.svg")
            isMask: compactRow._themeReady
            color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
            width: compactRow.iconSize
            height: compactRow.iconSize
        }

        PlasmaComponents.Label {
            text: "Kardio"
            font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
            font.family: compactRow.fontFamily
            color: compactRow.labelColor
            opacity: compactRow.labelOpacity
        }
    }

    Repeater {
        model: compactRow.metricsModel
        delegate: compactRow.isVertical ? verticalDelegate : horizontalDelegate
    }

    Component {
        id: horizontalDelegate

        RowLayout {
            required property var modelData
            required property int index

            spacing: Kirigami.Units.smallSpacing
            Layout.fillHeight: true

            SeparatorItem {
                visible: index > 0 && compactRow.showSeparators && !modelData.hideSeparator
                style: compactRow.separatorStyle
                color: compactRow.baseTextColor
                separatorOpacity: compactRow.separatorOpacity
                referenceSize: compactRow.iconSize
                Layout.fillHeight: true
            }

            Row {
                visible: compactRow.useIcons && !!modelData.icon && (typeof modelData.icon === "string" ? modelData.icon.length > 0 : modelData.icon.length > 0)
                spacing: 1
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: {
                        var src = modelData.icon;
                        if (!src) return [];
                        return typeof src === "string" ? [src] : src;
                    }
                    delegate: Kirigami.Icon {
                        source: compactRow.resolveIcon(modelData)
                        isMask: compactRow._themeReady
                        color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
                        width: compactRow.iconSize
                        height: compactRow.iconSize
                    }
                }
            }

            PlasmaComponents.Label {
                visible: compactRow.useText
                text: modelData.label
                font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                font.family: compactRow.fontFamily
                color: compactRow.labelColor
                opacity: compactRow.labelOpacity
                Layout.alignment: Qt.AlignVCenter
            }

            Row {
                id: mainValRow
                visible: !modelData.segments
                spacing: 1
                Layout.alignment: Qt.AlignVCenter
                readonly property var parsed: compactRow.splitValueAndSuffix(modelData.value, modelData.key)
                readonly property bool hasSuffix: compactRow.isItemSmallSuffix(modelData.key) && parsed.suffix.length > 0
                Layout.preferredWidth: compactRow.isItemPadded(modelData.key) ? compactRow._stickyWidth(modelData.key || ("idx:" + index), implicitWidth) : implicitWidth

                PlasmaComponents.Label {
                    text: mainValRow.hasSuffix ? mainValRow.parsed.main : (modelData.value || "")
                    font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                    font.family: compactRow.fontFamily
                    font.bold: compactRow.fontBold
                    color: modelData.color || compactRow.baseTextColor
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }

                PlasmaComponents.Label {
                    visible: mainValRow.hasSuffix
                    text: mainValRow.parsed.suffix
                    font.pixelSize: Math.max(7, Math.round((compactRow.customFont ? compactRow.effectiveFontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.70))
                    font.family: compactRow.fontFamily
                    font.bold: false
                    color: modelData.color || compactRow.baseTextColor
                    opacity: 0.85
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.max(1, Math.round((compactRow.customFont ? compactRow.effectiveFontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.22))
                }
            }

            SegmentsRow {
                visible: !!modelData.segments
                segments: modelData.segments || []
                parentKey: modelData.key || ("idx:" + index)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Component {
        id: verticalDelegate

        RowLayout {
            required property var modelData
            required property int index

            spacing: Kirigami.Units.smallSpacing
            Layout.fillHeight: true

            SeparatorItem {
                visible: index > 0 && compactRow.showSeparators && !modelData.hideSeparator
                style: compactRow.separatorStyle
                color: compactRow.baseTextColor
                separatorOpacity: compactRow.separatorOpacity
                referenceSize: compactRow.iconSize
                Layout.fillHeight: true
            }

            ColumnLayout {
                spacing: 1
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignHCenter

                    Row {
                        id: vertValRow
                        visible: !modelData.segments
                        spacing: 1
                        Layout.alignment: Qt.AlignHCenter
                        readonly property var parsed: compactRow.splitValueAndSuffix(modelData.value, modelData.key)
                        readonly property bool hasSuffix: compactRow.isItemSmallSuffix(modelData.key) && parsed.suffix.length > 0
                        Layout.preferredWidth: compactRow.enableNumberPadding ? compactRow._stickyWidth(modelData.key || ("idx:" + index), implicitWidth) : implicitWidth

                        PlasmaComponents.Label {
                            text: vertValRow.hasSuffix ? vertValRow.parsed.main : (modelData.value || "")
                            font.pixelSize: compactRow.customFont ? compactRow.effectiveFontSize : -1
                            font.family: compactRow.fontFamily
                            font.bold: compactRow.fontBold
                            color: modelData.color || compactRow.baseTextColor
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        PlasmaComponents.Label {
                            visible: vertValRow.hasSuffix
                            text: vertValRow.parsed.suffix
                            font.pixelSize: Math.max(7, Math.round((compactRow.customFont ? compactRow.effectiveFontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.70))
                            font.family: compactRow.fontFamily
                            font.bold: false
                            color: modelData.color || compactRow.baseTextColor
                            opacity: 0.85
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Math.max(1, Math.round((compactRow.customFont ? compactRow.effectiveFontSize : Kirigami.Theme.defaultFont.pixelSize) * 0.22))
                        }
                    }

                    SegmentsRow {
                        visible: !!modelData.segments
                        segments: modelData.segments || []
                        parentKey: modelData.key || ("idx:" + index)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                RowLayout {
                    visible: compactRow.useIcons || compactRow.useText
                    spacing: 2
                    Layout.alignment: Qt.AlignHCenter

                    Row {
                        visible: compactRow.useIcons && !!modelData.icon && (typeof modelData.icon === "string" ? modelData.icon.length > 0 : modelData.icon.length > 0)
                        spacing: 1
                        Layout.alignment: Qt.AlignVCenter
                        Repeater {
                            model: {
                                var src = modelData.icon;
                                if (!src) return [];
                                return typeof src === "string" ? [src] : src;
                            }
                            delegate: Kirigami.Icon {
                                source: compactRow.resolveIcon(modelData)
                                isMask: compactRow._themeReady
                                color: compactRow._themeReady ? compactRow.iconColor : Qt.rgba(0, 0, 0, 0)
                                width:  Math.round(compactRow.iconSize * 0.85)
                                height: Math.round(compactRow.iconSize * 0.85)
                            }
                        }
                    }

                    PlasmaComponents.Label {
                        visible: compactRow.useText
                        text: {
                            var lbl = modelData.label || "";
                            return lbl.endsWith(":") ? lbl.slice(0, -1) : lbl;
                        }
                        font.pixelSize: compactRow.customFont
                            ? Math.max(8, compactRow.effectiveFontSize - 2)
                            : -1
                        font.family: compactRow.fontFamily
                        color: compactRow.labelColor
                        opacity: compactRow.labelOpacity
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
}
