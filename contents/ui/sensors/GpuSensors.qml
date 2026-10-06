import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: root

    property var discovery: null
    property int updateInterval: 2000

    // Comma-separated selected GPU IDs e.g. "gpu0,gpu1". Empty = all discovered.
    property string gpuSelection: ""

    // User-defined labels: "gpu0:My iGPU|gpu1:dGPU". Empty string = use default "GPU N" name.
    property string gpuLabels: ""

    // Temperature unit: "C" (default) or "F"
    property string tempUnit: "C"

    // Global GPU sub-metric visibility e.g. "usage,vram,temp" or "usage,temp"
    property string gpuSubMetrics: MetricDefinitions.GROUPS.gpu.defaultSubMetrics

    // Legacy per-GPU sub-metric visibility (fallback compatibility)
    property string gpuMetrics: ""

    // List of { id: "gpu0", name: "GPU 1" } derived from HardwareDiscovery
    readonly property var discoveredGpus: _discovered
    property var _discovered: []

    // Aggregated display (single-GPU compat)
    readonly property real gpuUsageNumber: _usageNum
    readonly property real gpuTempNumber:  _tempNum
    readonly property real gpuHotspotNumber: _hotspotNum
    readonly property real gpuVramTempNumber: _vramTempNum
    readonly property string gpuValue:     _usageStr
    readonly property string gpuRamValue:  _vramStr
    readonly property string gpuTempValue: _tempStr
    readonly property string gpuHotspotValue: _hotspotStr
    readonly property string gpuVramTempValue: _vramTempStr
    readonly property string gpuDisplayValue:
        [_usageStr, _vramStr, _tempStr].filter(function(v){return v;}).join(" ")
    readonly property bool hasGpuData:      gpuDisplayValue.length > 0
    readonly property bool hasGpuUsageData: _usageStr.length > 0
    readonly property bool hasGpuVramData:  _vramStr.length  > 0
    readonly property bool hasGpuTempData:  _tempStr.length  > 0
    readonly property bool hasGpuHotspotData: _hotspotStr.length > 0
    readonly property bool hasGpuVramTempData: _vramTempStr.length > 0

    // Per-GPU list for multi display: [{ id, name, usage, vram, temp, hotspot, vramTemp, freq, memFreq, power, ... }]
    readonly property var gpuDataList: _dataList
    property var _dataList: []

    property real _usageNum: NaN
    property real _tempNum:  NaN
    property real _hotspotNum: NaN
    property real _vramTempNum: NaN
    property string _usageStr: ""
    property string _vramStr:  ""
    property string _tempStr:  ""
    property string _hotspotStr: ""
    property string _vramTempStr: ""

    // -------------------------------------------------------------------------
    // Step 1: Discover available GPUs via HardwareDiscovery
    // -------------------------------------------------------------------------

    function parseGpuLabels(str) {
        if (!str) return {};
        if (typeof str === "object") return str;
        var trimmed = String(str).trim();
        if (trimmed.startsWith("{")) {
            try {
                return JSON.parse(trimmed);
            } catch (e) {}
        }
        var result = {};
        var pairs = trimmed.split("|");
        for (var i = 0; i < pairs.length; i++) {
            var sep = pairs[i].indexOf(":");
            if (sep > 0)
                result[pairs[i].substring(0, sep).trim()] = pairs[i].substring(sep + 1).trim();
        }
        return result;
    }

    // Parse sub-metrics string e.g. "gpu0:usage,vram,temp|gpu1:usage,temp" or global "usage,vram,temp"
    function parseGpuSubMetrics(str, gpuId) {
        var defaultList = MetricDefinitions.GROUPS.gpu.defaultSubMetrics.split(",").map(function(s){ return s.trim(); });
        if (!str || str.length === 0) return defaultList;
        if (str.indexOf(":") >= 0) {
            var pairs = str.split("|");
            for (var i = 0; i < pairs.length; i++) {
                var sep = pairs[i].indexOf(":");
                if (sep > 0 && pairs[i].substring(0, sep) === gpuId) {
                    var subs = pairs[i].substring(sep + 1).split(",").map(function(s){ return s.trim(); }).filter(function(m){
                        return m.length > 0;
                    });
                    return subs.length > 0 ? subs : defaultList;
                }
            }
            return defaultList;
        }
        var list = str.split(",").map(function(s){ return s.trim(); }).filter(function(s){
            return s.length > 0;
        });
        return list.length > 0 ? list : defaultList;
    }

    function refreshDiscovered() {
        if (!discovery) return;
        var found = discovery.discoveredGpus || [];
        if (JSON.stringify(found) !== JSON.stringify(_discovered)) {
            _discovered = found;
        }
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root.refreshDiscovered(); }
    }

    onDiscoveryChanged: refreshDiscovered()

    Component.onCompleted: {
        refreshDiscovered();
    }

    // -------------------------------------------------------------------------
    // Step 2: Compute active sensor IDs — per GPU, only poll enabled sub-metrics
    // -------------------------------------------------------------------------

    readonly property var _activeIds: {
        if (!gpuSelection || gpuSelection === "")
            return _discovered.map(function(g){ return g.id; });
        if (gpuSelection === "none")
            return [];
        return gpuSelection.split(",")
            .map(function(s){ return s.trim(); })
            .filter(function(s){ return s.length > 0; });
    }

    readonly property var _activeSensorIds: {
        var ids = [];
        var rawStr = gpuSubMetrics || gpuMetrics;
        for (var i = 0; i < _activeIds.length; i++) {
            var g = _activeIds[i];
            var m = parseGpuSubMetrics(rawStr, g);
            var gpuInfo = null;
            for (var gi = 0; gi < _discovered.length; gi++) {
                if (_discovered[gi].id === g) { gpuInfo = _discovered[gi]; break; }
            }
            var hotspotSensor = (gpuInfo && gpuInfo.hotspotSensor) ? gpuInfo.hotspotSensor : ("gpu/" + g + "/temp2");
            var vramTempSensor = (gpuInfo && gpuInfo.vramTempSensor) ? gpuInfo.vramTempSensor : ("gpu/" + g + "/temp3");
            var memFreqSensor = (gpuInfo && gpuInfo.memFreqSensor) ? gpuInfo.memFreqSensor : ("gpu/" + g + "/memoryFrequency");

            if (m.indexOf("usage") >= 0) ids.push("gpu/" + g + "/usage");
            if (m.indexOf("vram")  >= 0) {
                ids.push("gpu/" + g + "/usedVram");
                ids.push("gpu/" + g + "/totalVram");
            }
            if (m.indexOf("temp")     >= 0) ids.push("gpu/" + g + "/temperature");
            if (m.indexOf("hotspot")  >= 0) ids.push(hotspotSensor);
            if (m.indexOf("vramTemp") >= 0) ids.push(vramTempSensor);
            if (m.indexOf("freq")     >= 0) ids.push("gpu/" + g + "/coreFrequency");
            if (m.indexOf("memFreq")  >= 0) ids.push(memFreqSensor);
            if (m.indexOf("power")    >= 0) ids.push("gpu/" + g + "/power");
        }
        return ids;
    }

    // -------------------------------------------------------------------------
    // Step 3: Single SensorDataModel — polls ONLY the selected sensors
    // -------------------------------------------------------------------------

    Sensors.SensorDataModel {
        id: gpuData
        sensors: root._activeSensorIds
        updateRateLimit: root.updateInterval
        enabled: root._activeSensorIds.length > 0

        onDataChanged: root.aggregate()
        onReadyChanged: { if (ready) root.aggregate(); }
        onRowsInserted: root.aggregate()
        onColumnsInserted: root.aggregate()
        onModelReset: root.aggregate()
        onLayoutChanged: root.aggregate()
    }

    // -------------------------------------------------------------------------
    // Step 4: Aggregate values — label resolution: custom label > default name > "GPU N"
    // -------------------------------------------------------------------------

    function _modelValue(sensorId) {
        var col = gpuData.column(sensorId);
        if (col < 0) return NaN;
        var idx = gpuData.index(0, col);
        if (!idx.valid) return NaN;
        var val = gpuData.data(idx, Sensors.SensorDataModel.Value);
        return (val === undefined || val === null) ? NaN : val;
    }

    function aggregate() {
        var ids = _activeIds;
        var customLabels = parseGpuLabels(gpuLabels);
        var rawStr = gpuSubMetrics || gpuMetrics;
        var newList = [];
        var totalUsage = 0, usageCount = 0;
        var totalVramUsed = 0, totalVramTotal = 0, hasVram = false;
        var maxTemp = NaN;
        var maxHotspot = NaN;
        var maxVramTemp = NaN;

        for (var i = 0; i < ids.length; i++) {
            var g = ids[i];
            var m = parseGpuSubMetrics(rawStr, g);
            var showU  = m.indexOf("usage") >= 0;
            var showV  = m.indexOf("vram")  >= 0;
            var showT  = m.indexOf("temp")  >= 0;
            var showHS = m.indexOf("hotspot") >= 0;
            var showVT = m.indexOf("vramTemp") >= 0;
            var showF  = m.indexOf("freq")  >= 0;
            var showMF = m.indexOf("memFreq") >= 0;
            var showP  = m.indexOf("power") >= 0;

            // Resolve display name: custom label > default name > fallback
            var gpuInfo = null;
            for (var j = 0; j < _discovered.length; j++) {
                if (_discovered[j].id === g) { gpuInfo = _discovered[j]; break; }
            }
            var hwName = gpuInfo ? gpuInfo.name : ("GPU " + (i + 1));
            var name = customLabels[g] || hwName;

            var hotspotSensor = (gpuInfo && gpuInfo.hotspotSensor) ? gpuInfo.hotspotSensor : ("gpu/" + g + "/temp2");
            var vramTempSensor = (gpuInfo && gpuInfo.vramTempSensor) ? gpuInfo.vramTempSensor : ("gpu/" + g + "/temp3");
            var memFreqSensor = (gpuInfo && gpuInfo.memFreqSensor) ? gpuInfo.memFreqSensor : ("gpu/" + g + "/memoryFrequency");

            var uVal   = showU  ? _modelValue("gpu/" + g + "/usage")         : NaN;
            var vuVal  = showV  ? _modelValue("gpu/" + g + "/usedVram")       : NaN;
            var vtVal  = showV  ? _modelValue("gpu/" + g + "/totalVram")      : NaN;
            var tVal   = showT  ? _modelValue("gpu/" + g + "/temperature")    : NaN;
            var hsVal  = showHS ? _modelValue(hotspotSensor)                  : NaN;
            var vt2Val = showVT ? _modelValue(vramTempSensor)                 : NaN;
            var fVal   = showF  ? _modelValue("gpu/" + g + "/coreFrequency")  : NaN;
            var mfVal  = showMF ? _modelValue(memFreqSensor)                  : NaN;
            var pVal   = showP  ? _modelValue("gpu/" + g + "/power")          : NaN;

            var uStr = !isNaN(uVal) ? Math.round(uVal).toString().padStart(3) + "%" : "";
            var vStr = "";
            if (!isNaN(vuVal) && !isNaN(vtVal) && vtVal > 0 && vuVal >= 0)
                vStr = Utils.formatBytes(vuVal) + "/" + Utils.formatBytes(vtVal) + "G";
            // tVal === 0 is ksystemstats' null sentinel for iGPU (no hwmon node)
            var tStr = (!isNaN(tVal) && tVal > 0) ? Utils.formatTemp(tVal, tempUnit) : "";
            var hsStr = (!isNaN(hsVal) && hsVal > 0) ? Utils.formatTemp(hsVal, tempUnit) : "";
            var vt2Str = (!isNaN(vt2Val) && vt2Val > 0) ? Utils.formatTemp(vt2Val, tempUnit) : "";
            var fStr = "";
            if (!isNaN(fVal) && fVal > 0) {
                if (fVal >= 1000) fStr = (fVal / 1000).toFixed(2) + " GHz";
                else fStr = Math.round(fVal) + " MHz";
            }
            var mfStr = "";
            if (!isNaN(mfVal) && mfVal > 0) {
                if (mfVal >= 1000) mfStr = (mfVal / 1000).toFixed(2) + " GHz";
                else mfStr = Math.round(mfVal) + " MHz";
            }
            var pStr = (!isNaN(pVal) && pVal > 0) ? pVal.toFixed(1) + "W" : "";

            newList.push({ id: g, name: name,
                           usage: uStr, vram: vStr, temp: tStr, hotspot: hsStr, vramTemp: vt2Str,
                           freq: fStr, memFreq: mfStr, power: pStr,
                           usageNumber: !isNaN(uVal) ? uVal : NaN,
                           tempNumber:  (!isNaN(tVal) && tVal > 0) ? tVal : NaN,
                           hotspotNumber: (!isNaN(hsVal) && hsVal > 0) ? hsVal : NaN,
                           vramTempNumber: (!isNaN(vt2Val) && vt2Val > 0) ? vt2Val : NaN,
                           freqNumber:  (!isNaN(fVal) && fVal > 0) ? fVal : NaN,
                           memFreqNumber: (!isNaN(mfVal) && mfVal > 0) ? mfVal : NaN,
                           powerNumber: (!isNaN(pVal) && pVal > 0) ? pVal : NaN });

            if (!isNaN(uVal)) { totalUsage += uVal; usageCount++; }
            if (!isNaN(vuVal) && !isNaN(vtVal) && vtVal > 0 && vuVal >= 0) {
                totalVramUsed  += vuVal;
                totalVramTotal += vtVal;
                hasVram = true;
            }
            if (!isNaN(tVal) && tVal > 0 && (isNaN(maxTemp) || tVal > maxTemp)) maxTemp = tVal;
            if (!isNaN(hsVal) && hsVal > 0 && (isNaN(maxHotspot) || hsVal > maxHotspot)) maxHotspot = hsVal;
            if (!isNaN(vt2Val) && vt2Val > 0 && (isNaN(maxVramTemp) || vt2Val > maxVramTemp)) maxVramTemp = vt2Val;
        }

        _dataList = newList;

        _usageNum = usageCount > 0 ? totalUsage / usageCount : NaN;
        _usageStr = usageCount > 0 ? Math.round(_usageNum).toString().padStart(3) + "%" : "";
        
        _vramStr  = (hasVram && totalVramTotal > 0)
                    ? Utils.formatBytes(totalVramUsed) + "/" + Utils.formatBytes(totalVramTotal) + "G" : "";
        _tempNum  = !isNaN(maxTemp) ? maxTemp : NaN;
        _tempStr  = !isNaN(maxTemp) ? Utils.formatTemp(maxTemp, tempUnit) : "";
        _hotspotNum = !isNaN(maxHotspot) ? maxHotspot : NaN;
        _hotspotStr = !isNaN(maxHotspot) ? Utils.formatTemp(maxHotspot, tempUnit) : "";
        _vramTempNum = !isNaN(maxVramTemp) ? maxVramTemp : NaN;
        _vramTempStr = !isNaN(maxVramTemp) ? Utils.formatTemp(maxVramTemp, tempUnit) : "";
    }

    // Re-aggregate when sub-metrics, labels, selection, or unit change
    onGpuSubMetricsChanged: aggregate()
    onGpuMetricsChanged:    aggregate()
    onGpuLabelsChanged:     aggregate()
    onGpuSelectionChanged:  aggregate()
    onTempUnitChanged:      aggregate()
}
