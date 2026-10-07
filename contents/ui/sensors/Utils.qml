pragma Singleton
import QtQuick
import org.kde.ksysguard.sensors as Sensors

QtObject {
    function formatBytes(bytes) {
        if (typeof bytes !== "number" || isNaN(bytes))
            return "...";
        var gb = bytes / (1024 * 1024 * 1024);
        return gb.toFixed(1);
    }

    function formatMemoryBytes(bytes, dynamicUnits) {
        if (typeof bytes !== "number" || isNaN(bytes))
            return "...";
        if (dynamicUnits && bytes < 1024 * 1024 * 1024) {
            var mb = bytes / (1024 * 1024);
            return Math.round(mb) + "MB";
        }
        var gb = bytes / (1024 * 1024 * 1024);
        return gb.toFixed(1) + "GB";
    }

    function formatData(bytes) {
        if (typeof bytes !== "number" || isNaN(bytes) || bytes < 0)
            return "...";
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MB";
        if (bytes < 1024 * 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB";
        return (bytes / (1024 * 1024 * 1024 * 1024)).toFixed(2) + " TB";
    }

    // unit: "bytes" (default, KB/MB) or "bits" (Kb/Mb)
    // padNumbers: boolean, whether to pad to 6 chars
    // minUnit: "auto" (default, B), "KB", or "MB"
    function formatRate(bytesPerSec, unit, padNumbers, minUnit) {
        if (typeof bytesPerSec !== "number" || isNaN(bytesPerSec))
            return padNumbers ? "...".padStart(6) : "...";
        var val, divisor, suffixes;
        if (unit === "bits") {
            val = Math.max(0, bytesPerSec * 8);
            divisor = 1000;
            suffixes = ["b", "Kb", "Mb", "Gb", "Tb"];
        } else {
            val = Math.max(0, bytesPerSec);
            divisor = 1024;
            suffixes = ["B", "KB", "MB", "GB", "TB"];
        }
        var absVal = val;
        var si = 0;

        var minIndex = 0;
        if (minUnit === "KB" || minUnit === "Kb") {
            minIndex = 1;
        } else if (minUnit === "MB" || minUnit === "Mb") {
            minIndex = 2;
        }

        var scaled = absVal;
        while (scaled >= divisor && si < suffixes.length - 1) {
            scaled /= divisor;
            si++;
        }

        if (si < minIndex) {
            while (si < minIndex) {
                scaled /= divisor;
                si++;
            }
        }

        var num;
        if (scaled < 10) {
            if (scaled === 0 && minIndex > 0) {
                num = (minIndex === 2) ? "0.00" : "0.0";
            } else {
                num = scaled.toFixed(scaled < 1 && scaled > 0 ? 2 : 1);
            }
        } else if (scaled < 100) {
            num = scaled.toFixed(1);
        } else {
            num = String(Math.round(scaled));
        }

        var res = num + suffixes[si];
        return padNumbers ? res.padStart(6) : res;
    }

    // celsiusValue: raw °C number from sensor; unit: "C" or "F"
    function formatTemp(celsiusValue, unit) {
        if (typeof celsiusValue !== "number" || isNaN(celsiusValue))
            return "";
        if (unit === "F")
            return Math.round(celsiusValue * 9 / 5 + 32) + "°F";
        return Math.round(celsiusValue) + "°C";
    }

    function sensorValueOrNaN(sensor) {
        if (!sensor || sensor.status !== Sensors.Sensor.Ready)
            return NaN;
        if (typeof sensor.value !== "number" || isNaN(sensor.value))
            return NaN;
        return sensor.value;
    }

    function firstReadyNumber(sensors, requirePositive) {
        for (var i = 0; i < sensors.length; i++) {
            var value = sensorValueOrNaN(sensors[i]);
            if (isNaN(value))
                continue;
            if (requirePositive && value <= 0)
                continue;
            return value;
        }
        return NaN;
    }

    function maxReadyNumber(sensors, requirePositive) {
        var maxValue = NaN;
        for (var i = 0; i < sensors.length; i++) {
            var value = sensorValueOrNaN(sensors[i]);
            if (isNaN(value))
                continue;
            if (requirePositive && value <= 0)
                continue;
            if (isNaN(maxValue) || value > maxValue)
                maxValue = value;
        }
        return maxValue;
    }

    function firstReadyVramPair(pairs) {
        for (var i = 0; i < pairs.length; i++) {
            var used = sensorValueOrNaN(pairs[i].used);
            var total = sensorValueOrNaN(pairs[i].total);
            if (isNaN(used) || isNaN(total))
                continue;
            if (total <= 0 || used < 0)
                continue;
            return { used: used, total: total };
        }
        return null;
    }

    function resolveColor(numericValue, warningThreshold, criticalThreshold,
                          warningColor, criticalColor, baseColor, inverted) {
        if (typeof numericValue !== "number" || isNaN(numericValue) || !isFinite(numericValue))
            return baseColor;
        if (inverted) {
            if (numericValue <= criticalThreshold) return criticalColor;
            if (numericValue <= warningThreshold)  return warningColor;
        } else {
            if (numericValue >= criticalThreshold) return criticalColor;
            if (numericValue >= warningThreshold)  return warningColor;
        }
        return baseColor;
    }
}
