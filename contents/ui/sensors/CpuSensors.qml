import QtQuick
import org.kde.ksysguard.sensors as Sensors
import "../models/MetricDefinitions.js" as MetricDefinitions

Item {
    id: root

    property var discovery: null
    property int updateInterval: 2000
    property bool popupExpanded: false
    property bool hasPinnedCores: false

    readonly property real cpuNumericValue: {
        if (cpuSensor.status !== Sensors.Sensor.Ready)
            return NaN;
        return cpuSensor.value;
    }

    property bool padNumbers: false

    property var sysfsData: null

    readonly property string cpuValue: {
        if (isNaN(cpuNumericValue))
            return "...";
        var str = Math.round(cpuNumericValue).toString();
        return padNumbers ? str.padStart(3) + "%" : str + "%";
    }

    // Frequency in MHz from KSysGuard with sysfs fallback
    readonly property string cpuFreqValue: {
        var mhz = (freqSensor.status === Sensors.Sensor.Ready && freqSensor.value != null) ? Number(freqSensor.value) : NaN;
        if ((isNaN(mhz) || mhz <= 0) && sysfsData && sysfsData.cpu && sysfsData.cpu.freq) {
            mhz = sysfsData.cpu.freq;
        }
        if (isNaN(mhz) || mhz <= 0)
            return "...";
        if (mhz >= 1000)
            return (mhz / 1000).toFixed(2) + " GHz";
        return Math.round(mhz) + " MHz";
    }

    // Peak Frequency in MHz from KSysGuard with sysfs fallback
    readonly property real cpuPeakFreqRaw: {
        var val = (maxFreqSensor.status === Sensors.Sensor.Ready && maxFreqSensor.value != null) ? Number(maxFreqSensor.value) : NaN;
        if ((isNaN(val) || val <= 0) && sysfsData && sysfsData.cpu && sysfsData.cpu.peakFreq) {
            val = sysfsData.cpu.peakFreq;
        }
        return val;
    }
    readonly property string cpuPeakFreqValue: {
        if (isNaN(cpuPeakFreqRaw) || cpuPeakFreqRaw <= 0)
            return "...";
        if (cpuPeakFreqRaw >= 1000)
            return (cpuPeakFreqRaw / 1000).toFixed(2) + " GHz";
        return Math.round(cpuPeakFreqRaw) + " MHz";
    }

    // CPU Package Power in Watts with sysfs fallback
    readonly property string cpuPowerSensorId: (discovery && discovery.cpuPowerSensor) ? discovery.cpuPowerSensor : "cpu/all/power"
    readonly property real cpuPowerRaw: {
        var p = (cpuPowerSensor.status === Sensors.Sensor.Ready && cpuPowerSensor.value != null && Number(cpuPowerSensor.value) > 0) ? Number(cpuPowerSensor.value) : NaN;
        if ((isNaN(p) || p <= 0) && sysfsData && sysfsData.cpu && sysfsData.cpu.power) {
            p = sysfsData.cpu.power;
        }
        return p;
    }
    readonly property string cpuPowerValue: isNaN(cpuPowerRaw) ? "" : cpuPowerRaw.toFixed(1) + " W"

    // CPU Voltage in Volts/mV from sysfs
    readonly property real cpuVoltageRaw: {
        if (sysfsData && sysfsData.cpu && sysfsData.cpu.voltage) {
            return sysfsData.cpu.voltage;
        }
        return NaN;
    }
    readonly property string cpuVoltageValue: {
        if (isNaN(cpuVoltageRaw) || cpuVoltageRaw <= 0) return "";
        if (cpuVoltageRaw < 1.0) return Math.round(cpuVoltageRaw * 1000) + " mV";
        return cpuVoltageRaw.toFixed(2) + " V";
    }

    // CPU Fan RPM from sysfs
    readonly property int cpuFanRaw: {
        if (sysfsData && sysfsData.cpu && sysfsData.cpu.fan !== undefined) {
            return sysfsData.cpu.fan;
        }
        return -1;
    }
    readonly property string cpuFanValue: (cpuFanRaw >= 0) ? (cpuFanRaw + " RPM") : ""

    readonly property real cpuLoad1Raw: (load1Sensor.status === Sensors.Sensor.Ready && load1Sensor.value != null) ? Number(load1Sensor.value) : NaN
    readonly property real cpuLoad5Raw: (load5Sensor.status === Sensors.Sensor.Ready && load5Sensor.value != null) ? Number(load5Sensor.value) : NaN
    readonly property real cpuLoad15Raw: (load15Sensor.status === Sensors.Sensor.Ready && load15Sensor.value != null) ? Number(load15Sensor.value) : NaN

    readonly property string cpuLoad1Value: isNaN(cpuLoad1Raw) ? "..." : cpuLoad1Raw.toFixed(2)
    readonly property string cpuLoad5Value: isNaN(cpuLoad5Raw) ? "..." : cpuLoad5Raw.toFixed(2)
    readonly property string cpuLoad15Value: isNaN(cpuLoad15Raw) ? "..." : cpuLoad15Raw.toFixed(2)

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: freqSensor
        sensorId: "cpu/all/averageFrequency"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: maxFreqSensor
        sensorId: "cpu/all/maximumFrequency"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: cpuPowerSensor
        sensorId: root.cpuPowerSensorId
        updateRateLimit: root.updateInterval
        enabled: root.cpuPowerSensorId !== ""
    }

    Sensors.Sensor {
        id: load1Sensor
        sensorId: "cpu/loadaverages/loadaverage1"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: load5Sensor
        sensorId: "cpu/loadaverages/loadaverage5"
        updateRateLimit: root.updateInterval
    }

    Sensors.Sensor {
        id: load15Sensor
        sensorId: "cpu/loadaverages/loadaverage15"
        updateRateLimit: root.updateInterval
    }

    // CPU core discovery
    readonly property var discoveredCores: _discoveredCores
    property var _discoveredCores: []

    readonly property var coreDataList: _dataList
    property var _dataList: []

    function refreshDiscovered() {
        if (!discovery) return;
        var found = discovery.discoveredCores || [];
        if (JSON.stringify(found) !== JSON.stringify(_discoveredCores)) {
            _discoveredCores = found;
            aggregateCores();
        }
    }

    Connections {
        target: discovery
        function onRevisionChanged() { root.refreshDiscovered(); }
    }

    onDiscoveryChanged: refreshDiscovered()
    Component.onCompleted: refreshDiscovered()

    readonly property var _activeSensorIds: _discoveredCores.map(function(c){ return "cpu/" + c.id + "/usage"; })

    onPopupExpandedChanged: {
        if (popupExpanded && coreData.enabled) {
            aggregateCores();
        }
    }

    Sensors.SensorDataModel {
        id: coreData
        sensors: root._activeSensorIds
        updateRateLimit: root.updateInterval
        enabled: (root.popupExpanded || root.hasPinnedCores) && root._activeSensorIds.length > 0
        onDataChanged: root.aggregateCores()
        onReadyChanged: { if (ready) root.aggregateCores(); }
        onRowsInserted: root.aggregateCores()
        onColumnsInserted: root.aggregateCores()
        onModelReset: root.aggregateCores()
        onLayoutChanged: root.aggregateCores()
    }

    function _modelValue(sensorId) {
        var col = coreData.column(sensorId);
        if (col < 0) return NaN;
        var idx = coreData.index(0, col);
        if (!idx.valid) return NaN;
        var val = coreData.data(idx, Sensors.SensorDataModel.Value);
        return (val === undefined || val === null) ? NaN : val;
    }

    function aggregateCores() {
        var newList = [];
        for (var i = 0; i < _discoveredCores.length; i++) {
            var c = _discoveredCores[i];
            var val = _modelValue("cpu/" + c.id + "/usage");
            var num = (typeof val === "number" && !isNaN(val)) ? val : NaN;
            var str = !isNaN(num) ? (padNumbers ? Math.round(num).toString().padStart(3) + "%" : Math.round(num).toString() + "%") : "...";
            newList.push({
                id: c.id,
                name: c.name,
                number: c.number,
                usageNumber: num,
                usage: str
            });
        }
        _dataList = newList;
    }
}
