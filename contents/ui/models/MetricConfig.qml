import QtQuick
import org.kde.plasma.plasmoid
import "./MetricDefinitions.js" as Defs

QtObject {
    id: root

    property var target: Plasmoid.configuration
    property string propertyPrefix: ""

    // Icon fallback resolver
    function resolveIcon(name) {
        if (!name) return "configure";
        var str = String(name);
        if (Defs.isBundledIcon(str)) {
            return Qt.resolvedUrl("../../icons/" + str + ".svg");
        }
        return name;
    }

    // Pinned metrics on Plasma panel
    readonly property string pinnedMetrics: (target && target[propertyPrefix + "pinnedMetrics"] !== undefined)
        ? target[propertyPrefix + "pinnedMetrics"]
        : "cpu/usage,ram/percentage,temp/system,bat/percentage,net/down,net/up"

    readonly property var pinnedList: {
        if (!pinnedMetrics) return [];
        return pinnedMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    }

    readonly property var _pinnedSet: {
        var s = new Set();
        for (var i = 0; i < pinnedList.length; i++) {
            s.add(pinnedList[i]);
        }
        return s;
    }

    function isPinned(instanceId) {
        if (!instanceId) return false;
        return _pinnedSet.has(instanceId);
    }

    function togglePin(instanceId) {
        if (!instanceId) return;
        var list = pinnedList.slice();
        var idx = list.indexOf(instanceId);
        if (idx >= 0) {
            list.splice(idx, 1);
        } else {
            list.push(instanceId);
        }
        var prop = propertyPrefix + "pinnedMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = list.join(",");
        }
    }

    function setPinned(instanceId, shouldPin) {
        if (!instanceId) return;
        var list = pinnedList.slice();
        var idx = list.indexOf(instanceId);
        if (shouldPin && idx < 0) {
            list.push(instanceId);
        } else if (!shouldPin && idx >= 0) {
            list.splice(idx, 1);
        } else {
            return;
        }
        var prop = propertyPrefix + "pinnedMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = list.join(",");
        }
    }

    function movePinnedMetric(fromIndex, toIndex) {
        var list = pinnedList.slice();
        if (fromIndex < 0 || fromIndex >= list.length || toIndex < 0 || toIndex >= list.length) return;
        var item = list.splice(fromIndex, 1)[0];
        list.splice(toIndex, 0, item);
        var prop = propertyPrefix + "pinnedMetrics";
        if (target && target[prop] !== undefined) {
            target[prop] = list.join(",");
        }
    }

    // Dynamic Hardware Group Labels
    function parseGpuLabels() {
        return _parseJsonSafe((target && target[propertyPrefix + "gpuLabels"]) || "{}");
    }

    function saveGpuLabel(deviceId, label) {
        var map = parseGpuLabels();
        map[deviceId] = label;
        var prop = propertyPrefix + "gpuLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = JSON.stringify(map);
        }
    }

    function isGpuSelected(deviceId) {
        var raw = (target && target[propertyPrefix + "gpuSelection"]) || "";
        if (raw === "none") return false;
        if (!raw) return true; // all enabled by default
        var list = raw.split(",").map(function(s){ return s.trim(); });
        return list.indexOf(deviceId) !== -1;
    }

    function setGpuSelected(deviceId, enabled, allDiscoveredGpuIds) {
        var raw = (target && target[propertyPrefix + "gpuSelection"]) || "";
        var current;
        if (raw === "none") {
            current = [];
        } else if (!raw) {
            current = allDiscoveredGpuIds ? allDiscoveredGpuIds.slice() : [];
        } else {
            current = raw.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
        }
        var idx = current.indexOf(deviceId);
        if (enabled && idx === -1) {
            current.push(deviceId);
        } else if (!enabled && idx !== -1) {
            current.splice(idx, 1);
        }
        var prop = propertyPrefix + "gpuSelection";
        if (target && target[prop] !== undefined) {
            target[prop] = current.length === 0 ? "none" : current.join(",");
        }
    }

    function parseDiskLabels() {
        return _parseJsonSafe((target && target[propertyPrefix + "diskLabels"]) || "{}");
    }

    function saveDiskLabel(deviceId, label) {
        var map = parseDiskLabels();
        map[deviceId] = label;
        var prop = propertyPrefix + "diskLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = JSON.stringify(map);
        }
    }

    function parseFanLabels() {
        return _parseJsonSafe((target && target[propertyPrefix + "fanLabels"]) || "{}");
    }

    function saveFanLabel(deviceId, label) {
        var map = parseFanLabels();
        map[deviceId] = label;
        var prop = propertyPrefix + "fanLabels";
        if (target && target[prop] !== undefined) {
            target[prop] = JSON.stringify(map);
        }
    }

    function _parseJsonSafe(str) {
        if (!str) return {};
        if (typeof str === "object") return str;
        var trimmed = String(str).trim();
        if (trimmed.startsWith("{")) {
            try {
                return JSON.parse(trimmed);
            } catch (e) {}
        }
        var res = {};
        trimmed.split("|").forEach(function(pair) {
            var sep = pair.indexOf(":");
            if (sep > 0) res[pair.substring(0, sep).trim()] = pair.substring(sep + 1).trim();
        });
        return res;
    }

    // Static Group Labels
    readonly property string cpuLabel:  (target && target[propertyPrefix + "cpuLabel"])  || "CPU"
    readonly property string ramLabel:  (target && target[propertyPrefix + "ramLabel"])  || "RAM"
    readonly property string swapLabel: (target && target[propertyPrefix + "swapLabel"]) || "SWAP"
    readonly property string tempLabel: (target && target[propertyPrefix + "tempLabel"]) || "System"
    readonly property string netLabel:  (target && target[propertyPrefix + "netLabel"])  || "NET"
    readonly property string diskLabel: (target && target[propertyPrefix + "diskLabel"]) || "DSK"
    readonly property string fanLabel:  (target && target[propertyPrefix + "fanLabel"])  || "FAN"
    readonly property string batLabel:  (target && target[propertyPrefix + "batLabel"])  || "BAT"

    readonly property var _labelMap: ({
        cpu: cpuLabel, ram: ramLabel, swap: swapLabel, temp: tempLabel,
        net: netLabel, disk: diskLabel, fan: fanLabel, bat: batLabel, uptime: "Uptime"
    })

    function getGroupLabel(group) {
        return _labelMap[group] || (group ? group.toUpperCase() : "");
    }

    function setGroupLabel(group, val) {
        var prop = propertyPrefix + group + "Label";
        if (target && target[prop] !== undefined) {
            target[prop] = val;
        }
    }

    // Disabled icons list (comma-separated metric or group keys)
    readonly property string disabledIcons: (target && target[propertyPrefix + "disabledIcons"] !== undefined)
        ? String(target[propertyPrefix + "disabledIcons"])
        : ""

    function isIconEnabled(id, group) {
        if (!disabledIcons) return true;
        var list = disabledIcons.split(",").map(function(s){ return s.trim(); });
        if (id && list.indexOf(id) !== -1) return false;
        if (group && list.indexOf(group) !== -1) return false;
        return true;
    }

    function toggleIcon(id) {
        if (!id || !target) return;
        var list = disabledIcons ? disabledIcons.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; }) : [];
        var idx = list.indexOf(id);
        if (idx !== -1) {
            list.splice(idx, 1);
        } else {
            list.push(id);
        }
        var next = list.join(",");
        var prop = propertyPrefix + "disabledIcons";
        if (target[prop] !== undefined) {
            target[prop] = next;
        }
    }

    // Icons
    readonly property string cpuIcon:     isIconEnabled("cpu", "cpu")         ? resolveIcon((target && target[propertyPrefix + "cpuIcon"])     || "cpu-symbolic") : ""
    readonly property string ramIcon:     isIconEnabled("ram", "ram")         ? resolveIcon((target && target[propertyPrefix + "ramIcon"])     || "memory-symbolic") : ""
    readonly property string swapIcon:    isIconEnabled("swap", "swap")       ? resolveIcon((target && target[propertyPrefix + "swapIcon"])    || "swap-symbolic") : ""
    readonly property string tempIcon:    isIconEnabled("temp", "temp")       ? resolveIcon((target && target[propertyPrefix + "tempIcon"])    || "temperature-symbolic") : ""
    readonly property string gpuIcon:     isIconEnabled("gpu", "gpu")         ? resolveIcon((target && target[propertyPrefix + "gpuIcon"])     || "gpu-symbolic") : ""
    readonly property string batteryIcon: isIconEnabled("bat", "bat")         ? resolveIcon((target && target[propertyPrefix + "batteryIcon"]) || "battery-symbolic") : ""
    readonly property string powerIcon:   isIconEnabled("power", "bat")       ? resolveIcon((target && target[propertyPrefix + "powerIcon"])   || "voltage-symbolic") : ""
    readonly property string networkIcon: isIconEnabled("net", "net")         ? resolveIcon((target && target[propertyPrefix + "networkIcon"]) || "network-symbolic") : ""
    readonly property string netDownIcon: isIconEnabled("net/down", "net")    ? resolveIcon((target && target[propertyPrefix + "netDownIcon"]) || "network-download-symbolic") : ""
    readonly property string netUpIcon:   isIconEnabled("net/up", "net")      ? resolveIcon((target && target[propertyPrefix + "netUpIcon"])   || "network-upload-symbolic") : ""
    readonly property string diskIcon:    isIconEnabled("disk", "disk")       ? resolveIcon((target && target[propertyPrefix + "diskIcon"])    || "storage-symbolic") : ""
    readonly property string fanIcon:     isIconEnabled("fan", "fan")         ? resolveIcon((target && target[propertyPrefix + "fanIcon"])     || "fan-symbolic") : ""
    readonly property string uptimeIcon:  isIconEnabled("uptime", "uptime")   ? resolveIcon((target && target[propertyPrefix + "uptimeIcon"])  || "system-symbolic") : ""

    readonly property var _iconMap: ({
        cpu: cpuIcon, ram: ramIcon, swap: swapIcon, temp: tempIcon, gpu: gpuIcon,
        bat: batteryIcon, net: networkIcon, disk: diskIcon, fan: fanIcon, uptime: uptimeIcon
    })

    function getGroupIcon(group) {
        return _iconMap[group] || "";
    }

    // Threshold colors
    readonly property bool enableThresholdColors: Boolean(target && target[propertyPrefix + "enableThresholdColors"])
    readonly property string warningColor:        (target && target[propertyPrefix + "warningColor"])  || "#e5a50a"
    readonly property string criticalColor:       (target && target[propertyPrefix + "criticalColor"]) || "#da4453"

    readonly property int cpuWarningThreshold:      (target && target[propertyPrefix + "cpuWarningThreshold"])      || 70
    readonly property int cpuCriticalThreshold:     (target && target[propertyPrefix + "cpuCriticalThreshold"])     || 90
    readonly property int tempWarningThreshold:     (target && target[propertyPrefix + "tempWarningThreshold"])     || 60
    readonly property int tempCriticalThreshold:    (target && target[propertyPrefix + "tempCriticalThreshold"])    || 85
    readonly property int systemWarningThreshold:   (target && target[propertyPrefix + "systemWarningThreshold"])   || 60
    readonly property int systemCriticalThreshold:  (target && target[propertyPrefix + "systemCriticalThreshold"])  || 85
    readonly property int ramWarningThreshold:      (target && target[propertyPrefix + "ramWarningThreshold"])      || 70
    readonly property int ramCriticalThreshold:     (target && target[propertyPrefix + "ramCriticalThreshold"])     || 90
    readonly property int swapWarningThreshold:     (target && target[propertyPrefix + "swapWarningThreshold"])     || 70
    readonly property int swapCriticalThreshold:    (target && target[propertyPrefix + "swapCriticalThreshold"])    || 90
    readonly property int ramTempWarningThreshold:  (target && target[propertyPrefix + "ramTempWarningThreshold"])  || 60
    readonly property int ramTempCriticalThreshold: (target && target[propertyPrefix + "ramTempCriticalThreshold"]) || 85
    readonly property int gpuWarningThreshold:      (target && target[propertyPrefix + "gpuWarningThreshold"])      || 70
    readonly property int gpuCriticalThreshold:     (target && target[propertyPrefix + "gpuCriticalThreshold"])     || 90
    readonly property int gpuTempWarningThreshold:  (target && target[propertyPrefix + "gpuTempWarningThreshold"])  || 60
    readonly property int gpuTempCriticalThreshold: (target && target[propertyPrefix + "gpuTempCriticalThreshold"]) || 85
    readonly property int gpuHotspotTempWarningThreshold:  (target && target[propertyPrefix + "gpuHotspotTempWarningThreshold"])  || 85
    readonly property int gpuHotspotTempCriticalThreshold: (target && target[propertyPrefix + "gpuHotspotTempCriticalThreshold"]) || 100
    readonly property int gpuVramTempWarningThreshold:  (target && target[propertyPrefix + "gpuVramTempWarningThreshold"])  || 80
    readonly property int gpuVramTempCriticalThreshold: (target && target[propertyPrefix + "gpuVramTempCriticalThreshold"]) || 95
    readonly property int batteryWarningThreshold:  (target && target[propertyPrefix + "batteryWarningThreshold"])  || 30
    readonly property int batteryCriticalThreshold: (target && target[propertyPrefix + "batteryCriticalThreshold"]) || 15
    readonly property int diskWarningThreshold:     (target && target[propertyPrefix + "diskWarningThreshold"])     || 80
    readonly property int diskCriticalThreshold:    (target && target[propertyPrefix + "diskCriticalThreshold"])    || 90
    readonly property int diskTempWarningThreshold: (target && target[propertyPrefix + "diskTempWarningThreshold"]) || 45
    readonly property int diskTempCriticalThreshold: (target && target[propertyPrefix + "diskTempCriticalThreshold"]) || 60

    function getWarningThreshold(key) {
        var prop = propertyPrefix + key + "WarningThreshold";
        var val = target ? target[prop] : undefined;
        if (val !== undefined) return val;
        var direct = root[key + "WarningThreshold"];
        return direct !== undefined ? direct : 70;
    }

    function getCriticalThreshold(key) {
        var prop = propertyPrefix + key + "CriticalThreshold";
        var val = target ? target[prop] : undefined;
        if (val !== undefined) return val;
        var direct = root[key + "CriticalThreshold"];
        return direct !== undefined ? direct : 90;
    }

    // Units & hardware preferences
    readonly property int updateInterval:         (target && target[propertyPrefix + "updateInterval"])    || 2000
    readonly property string tempUnit:            (target && target[propertyPrefix + "tempUnit"])          || "C"
    readonly property string networkUnit:         (target && target[propertyPrefix + "networkUnit"])       || "bytes"
    readonly property string fanUnit:             (target && target[propertyPrefix + "fanUnit"])           || "rpm"
    readonly property int fanMaxRpm:              (target && target[propertyPrefix + "fanMaxRpm"])         || 2000
    readonly property string batteryDevice:       (target && target[propertyPrefix + "batteryDevice"])     || "auto"
    readonly property string networkInterface:    (target && target[propertyPrefix + "networkInterface"])  || "auto"
    readonly property bool showNetworkIp:         Boolean(target && target[propertyPrefix + "showNetworkIp"])
    readonly property string gpuSelection:        (target && target[propertyPrefix + "gpuSelection"])      || ""
    readonly property string gpuLabels:           (target && target[propertyPrefix + "gpuLabels"])          || ""
    readonly property string diskLabels:          (target && target[propertyPrefix + "diskLabels"])         || ""
    readonly property string fanLabels:           (target && target[propertyPrefix + "fanLabels"])          || ""
    readonly property string gpuSubMetrics:       (target && target[propertyPrefix + "gpuSubMetrics"])      || "usage,vram,temp"
    readonly property string diskSubMetrics:      (target && target[propertyPrefix + "diskSubMetrics"])     || "read,write"
    readonly property string paddedMetrics:       (target && target[propertyPrefix + "paddedMetrics"] !== undefined) ? target[propertyPrefix + "paddedMetrics"] : ""
    readonly property string netDownMinUnit:      (target && target[propertyPrefix + "netDownMinUnit"] !== undefined) ? target[propertyPrefix + "netDownMinUnit"] : "auto"
    readonly property string netMinUnit:          (target && target[propertyPrefix + "netMinUnit"] !== undefined && target[propertyPrefix + "netMinUnit"] !== "") ? target[propertyPrefix + "netMinUnit"] : netDownMinUnit

    function isMetricPadded(id, group) {
        if (!paddedMetrics || paddedMetrics === "") return false;
        var list = paddedMetrics.split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
        if (id && list.indexOf(id) !== -1) return true;
        if (group && list.indexOf(group) !== -1) return true;
        if (id && id.indexOf("/") !== -1) {
            var g = id.split("/")[0];
            if (list.indexOf(g) !== -1) return true;
        }
        return false;
    }

    // Group order in popup catalogue
    readonly property string metricOrder: (target && target[propertyPrefix + "metricOrder"]) || "cpu,ram,temp,gpu,bat,net,disk,fan,uptime"
    readonly property var orderedKeys: {
        var all = Defs.ALL_GROUP_KEYS;
        var keys = metricOrder.split(",").map(function(k){ return k.trim(); }).filter(function(k){ return k.length > 0 && all.indexOf(k) >= 0; });
        for (var i = 0; i < all.length; i++) {
            if (keys.indexOf(all[i]) === -1) keys.push(all[i]);
        }
        return keys;
    }

    function moveMetric(fromIndex, toIndex) {
        var keys = orderedKeys.slice();
        if (fromIndex < 0 || fromIndex >= keys.length || toIndex < 0 || toIndex >= keys.length) return;
        var item = keys.splice(fromIndex, 1)[0];
        keys.splice(toIndex, 0, item);
        var prop = propertyPrefix + "metricOrder";
        if (target && target[prop] !== undefined) {
            target[prop] = keys.join(",");
        }
    }
}
