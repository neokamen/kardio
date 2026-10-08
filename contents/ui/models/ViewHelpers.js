.pragma library

// buildPopupGroups groups catalogue metrics into standard GNOME Vitals categories:
// Temperature, Fan, Memory, Processor, System, Network, Storage, GPU.
function buildPopupGroups(metricsList, orderedKeys) {
    if (!metricsList || metricsList.length === 0) return [];
    var available = metricsList.filter(function(m) {
        return m.status !== "unavailable";
    });

    var map = {};
    for (var i = 0; i < available.length; i++) {
        map[available[i].id] = available[i];
    }

    var categories = [];

    // 1. Temperature (all temperature sensors across devices)
    var tempMetrics = available.filter(function(m) {
        return m.subKey === "temp" || m.subKey === "hotspot" || m.subKey === "vramTemp" || m.group === "temp";
    }).map(function(m) {
        return Object.assign({}, m, {
            icon: "temperature-symbolic"
        });
    });
    if (tempMetrics.length > 0) {
        var tempAgg = map["temp/system"] || map["cpu/temp"] || tempMetrics[0];
        categories.push({
            key: "temperature",
            groupLabel: "Temperature",
            icon: "temperature-symbolic",
            aggregateValue: tempAgg ? tempAgg.displayValue : "",
            aggregateColor: tempAgg ? tempAgg.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: tempMetrics
                }
            ]
        });
    }

    // 2. Fan
    var fanMetrics = available.filter(function(m) { return m.group === "fan"; });
    if (fanMetrics.length > 0) {
        categories.push({
            key: "fan",
            groupLabel: "Fan",
            icon: fanMetrics[0].icon || "fan-symbolic",
            aggregateValue: fanMetrics[0].displayValue,
            aggregateColor: fanMetrics[0].color,
            sections: [
                {
                    sectionLabel: "",
                    metrics: fanMetrics
                }
            ]
        });
    }

    // 3. Memory (RAM + Swap)
    var ramMetrics = available.filter(function(m) { return m.group === "ram" && m.subKey !== "temp"; });
    var swapMetrics = available.filter(function(m) { return m.group === "swap"; });
    if (ramMetrics.length > 0 || swapMetrics.length > 0) {
        var ramPct = map["ram/percentage"];
        var memSections = [];
        if (ramMetrics.length > 0 && swapMetrics.length > 0) {
            memSections.push({ sectionLabel: "RAM", metrics: ramMetrics });
            memSections.push({ sectionLabel: "Swap", metrics: swapMetrics });
        } else {
            memSections.push({ sectionLabel: "", metrics: ramMetrics.concat(swapMetrics) });
        }

        categories.push({
            key: "memory",
            groupLabel: "Memoria & SWAP",
            icon: "memory-symbolic",
            aggregateValue: ramPct ? ramPct.displayValue : (ramMetrics[0] ? ramMetrics[0].displayValue : ""),
            aggregateColor: ramPct ? ramPct.color : (ramMetrics[0] ? ramMetrics[0].color : ""),
            sections: memSections
        });
    }

    // 4. Processor (CPU)
    var cpuMetrics = available.filter(function(m) { return m.group === "cpu" && m.subKey !== "temp"; });
    if (cpuMetrics.length > 0) {
        var cpuUsage = map["cpu/usage"] || cpuMetrics[0];
        var coreMetrics = cpuMetrics.filter(function(m) { return m.subKey === "core"; });
        var nonCoreMetrics = cpuMetrics.filter(function(m) { return m.subKey !== "core"; });

        var cpuSections = [];
        if (coreMetrics.length > 0 && nonCoreMetrics.length > 0) {
            cpuSections.push({ sectionLabel: "", metrics: nonCoreMetrics });
            cpuSections.push({ sectionLabel: "Cores", metrics: coreMetrics });
        } else {
            cpuSections.push({ sectionLabel: "", metrics: cpuMetrics });
        }

        categories.push({
            key: "processor",
            groupLabel: "Processor",
            icon: "cpu-symbolic",
            aggregateValue: cpuUsage ? cpuUsage.displayValue : "",
            aggregateColor: cpuUsage ? cpuUsage.color : "",
            sections: cpuSections
        });
    }

    // 5. Battery (when present on laptops)
    var batMetrics = available.filter(function(m) { return m.group === "bat"; });
    if (batMetrics.length > 0) {
        var batPct = map["bat/percentage"] || batMetrics[0];
        categories.push({
            key: "battery",
            groupLabel: "Battery",
            icon: "battery-symbolic",
            aggregateValue: batPct ? batPct.displayValue : "",
            aggregateColor: batPct ? batPct.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: batMetrics
                }
            ]
        });
    }

    // 6. System (Uptime)
    var sysMetrics = available.filter(function(m) { return m.group === "uptime"; });
    if (sysMetrics.length > 0) {
        var uptimeMetric = map["uptime/uptime"] || sysMetrics[0];
        categories.push({
            key: "system",
            groupLabel: "System",
            icon: "system-symbolic",
            aggregateValue: uptimeMetric ? uptimeMetric.displayValue : "",
            aggregateColor: uptimeMetric ? uptimeMetric.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: sysMetrics
                }
            ]
        });
    }

    // 7. Network
    var netMetrics = available.filter(function(m) { return m.group === "net" && m.subKey !== "temp"; });
    if (netMetrics.length > 0) {
        var netDown = map["net/down"] || netMetrics[0];
        categories.push({
            key: "network",
            groupLabel: "Network",
            icon: "network-symbolic",
            aggregateValue: netDown ? netDown.displayValue : "",
            aggregateColor: netDown ? netDown.color : "",
            sections: [
                {
                    sectionLabel: "",
                    metrics: netMetrics
                }
            ]
        });
    }

    // 8. Storage (Disks)
    var diskMetrics = available.filter(function(m) { return m.group === "disk" && m.subKey !== "temp"; });
    if (diskMetrics.length > 0) {
        var diskDeviceIds = [];
        for (var di = 0; di < diskMetrics.length; di++) {
            var dev = diskMetrics[di].deviceId;
            if (dev && diskDeviceIds.indexOf(dev) === -1) diskDeviceIds.push(dev);
        }

        var diskSections = [];
        if (diskDeviceIds.length > 1) {
            var globalDiskItems = diskMetrics.filter(function(m) { return !m.deviceId; });
            if (globalDiskItems.length > 0) {
                diskSections.push({
                    sectionLabel: "Overall",
                    metrics: globalDiskItems
                });
            }
            for (var dIdx = 0; dIdx < diskDeviceIds.length; dIdx++) {
                var dId = diskDeviceIds[dIdx];
                var dItems = diskMetrics.filter(function(m) { return m.deviceId === dId; });
                var dLabel = dItems[0].deviceName || dItems[0].groupLabel || ("Disk " + (dIdx + 1));
                diskSections.push({
                    sectionLabel: dLabel,
                    metrics: dItems
                });
            }
        } else {
            diskSections.push({
                sectionLabel: "",
                metrics: diskMetrics
            });
        }

        var diskAgg = map["disk/usage"] || diskMetrics[0];
        categories.push({
            key: "storage",
            groupLabel: "Storage",
            icon: "storage-symbolic",
            aggregateValue: diskAgg ? diskAgg.displayValue : "",
            aggregateColor: diskAgg ? diskAgg.color : "",
            sections: diskSections
        });
    }

    // 8. GPU
    var gpuMetrics = available.filter(function(m) { return m.group === "gpu"; });
    if (gpuMetrics.length > 0) {
        var gpuDeviceIds = [];
        for (var gi = 0; gi < gpuMetrics.length; gi++) {
            var gDev = gpuMetrics[gi].deviceId;
            if (gDev && gpuDeviceIds.indexOf(gDev) === -1) gpuDeviceIds.push(gDev);
        }

        var gpuSections = [];
        if (gpuDeviceIds.length > 1) {
            for (var gIdx = 0; gIdx < gpuDeviceIds.length; gIdx++) {
                var gId = gpuDeviceIds[gIdx];
                var gItems = gpuMetrics.filter(function(m) { return m.deviceId === gId; });
                var gLabel = gItems[0].deviceName || gItems[0].groupLabel || ("GPU " + (gIdx + 1));
                gpuSections.push({
                    sectionLabel: gLabel,
                    metrics: gItems
                });
            }
        } else {
            gpuSections.push({
                sectionLabel: "",
                metrics: gpuMetrics
            });
        }

        var gpuUsage = gpuMetrics.filter(function(m){ return m.subKey === "usage"; })[0] || gpuMetrics[0];
        categories.push({
            key: "gpu",
            groupLabel: "GPU",
            icon: "gpu-symbolic",
            aggregateValue: gpuUsage ? gpuUsage.displayValue : "",
            aggregateColor: gpuUsage ? gpuUsage.color : "",
            sections: gpuSections
        });
    }

    return categories;
}

function _isIndicatorDisabled(metric, disabledList) {
    if (!disabledList || disabledList.length === 0 || !metric) return false;
    var id = metric.id || "";
    if (id && disabledList.indexOf(id) !== -1) return true;
    if (metric.group && disabledList.indexOf(metric.group) !== -1) return true;
    if (metric.subKey && disabledList.indexOf(metric.group + "/" + metric.subKey) !== -1) return true;
    if (id.indexOf(":") !== -1 && id.indexOf("/") !== -1) {
        var norm = metric.group + "/" + metric.subKey;
        if (disabledList.indexOf(norm) !== -1) return true;
    }
    return false;
}

function _resolveSegmentLabel(metric, disabledList) {
    if (_isIndicatorDisabled(metric, disabledList)) return "";
    if (metric.prefix) return metric.prefix;
    if (metric.group === "swap") return "SWAP";
    if (metric.group === "ram" && metric.subKey === "temp") return "";
    if (metric.subKey === "temp") return "";
    if (metric.subKey === "hotspot") return "HS";
    if (metric.subKey === "vramTemp") return "VRAM";
    if (metric.subKey === "freq" || metric.subKey === "coreFrequency") return "CLK";
    if (metric.subKey === "memFreq" || metric.subKey === "memoryFrequency") return "MEM";
    if (metric.subKey === "power" && metric.group === "gpu") return "PWR";
    if (metric.subKey === "voltage") return "VOLT";
    if (metric.group === "fan" || metric.subKey === "core") return metric.subLabel || "";
    return "";
}

function _resolveSegmentIcon(metric, disabledList) {
    if (_isIndicatorDisabled(metric, disabledList)) return "";
    if (metric.group === "swap") {
        return metric.icon || "swap-symbolic";
    }
    if (metric.subKey === "temp" || metric.subKey === "hotspot" || metric.subKey === "vramTemp" || (metric.group === "ram" && metric.subKey === "temp")) {
        return metric.icon || "temperature-symbolic";
    }
    if (metric.subKey === "voltage" || (metric.subKey === "power" && metric.group === "gpu")) {
        return "voltage-symbolic";
    }
    if (metric.subKey === "down" || metric.subKey === "up" || metric.subKey === "totalDown" || metric.subKey === "totalUp"
        || metric.subKey === "read" || metric.subKey === "write" || metric.subKey === "signal") {
        return metric.icon || "";
    }
    return "";
}

function _getPinnedIndex(pinnedList, metricId) {
    if (!pinnedList || !metricId) return 999;
    var idx = pinnedList.indexOf(metricId);
    if (idx !== -1) return idx;
    for (var p = 0; p < pinnedList.length; p++) {
        var pk = pinnedList[p];
        if (pk === metricId) return p;
        if (metricId.indexOf(pk + "/") === 0 || pk.indexOf(metricId + "/") === 0) return p;
    }
    return 999;
}

function buildCompactItems(metricsList, pinnedList, mergeSameFamily, disabledIcons, showBlockLeadingIcon) {
    if (!metricsList || metricsList.length === 0 || !pinnedList || pinnedList.length === 0) return [];
    if (mergeSameFamily === undefined) mergeSameFamily = true;
    if (showBlockLeadingIcon === undefined) showBlockLeadingIcon = true;

    var disabledList = [];
    if (disabledIcons) {
        disabledList = String(disabledIcons).split(",").map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
    }

    var metricMap = {};
    for (var mIdx = 0; mIdx < metricsList.length; mIdx++) {
        var m = metricsList[mIdx];
        if (m.status === "ready") {
            metricMap[m.id] = m;
        }
    }

    // Check if any RAM metric is pinned
    var hasRamPinned = false;
    for (var pIdx = 0; pIdx < pinnedList.length; pIdx++) {
        var pMetric = metricMap[pinnedList[pIdx]];
        if (pMetric && pMetric.group === "ram") {
            hasRamPinned = true;
            break;
        }
    }

    var items = [];
    var groupIndexMap = {};

    for (var i = 0; i < pinnedList.length; i++) {
        var id = pinnedList[i];
        var metric = metricMap[id];
        if (!metric) continue;

        // When mergeSameFamily is enabled and RAM is pinned, group SWAP and RAM Temp into the RAM block
        var isRamOrSwap = (metric.group === "ram" || metric.group === "swap");
        var groupKey;
        if (mergeSameFamily && hasRamPinned && isRamOrSwap) {
            groupKey = "ram";
        } else {
            groupKey = metric.deviceId ? (metric.group + ":" + metric.deviceId) : metric.group;
        }

        if (mergeSameFamily && groupIndexMap[groupKey] !== undefined) {
            var existingItem = items[groupIndexMap[groupKey]];
            if (!existingItem.segments) {
                var firstSegIcon = existingItem._firstSubIcon || "";
                var firstSegDisabled = _isIndicatorDisabled(existingItem._firstMetric || {}, disabledList);
                existingItem.segments = [
                    {
                        id: existingItem.id,
                        value: existingItem.value,
                        color: existingItem.color,
                        label: existingItem._firstSubLabel || "",
                        icon: firstSegIcon,
                        key: existingItem._firstSubKey || "",
                        isIconDisabled: firstSegDisabled
                    }
                ];
                existingItem.value = null;
                existingItem.label = existingItem._groupBaseLabel + ":";

                // Retain or configure block leading icon according to showBlockLeadingIcon
                if (showBlockLeadingIcon && disabledList.indexOf(metric.group) === -1) {
                    existingItem.icon = existingItem._groupIcon || metric.groupIcon || "";
                } else {
                    existingItem.icon = "";
                }
            }
            var segIcon = _resolveSegmentIcon(metric, disabledList);
            var segDisabled = _isIndicatorDisabled(metric, disabledList);
            existingItem.segments.push({
                id: metric.id,
                value: metric.displayValue,
                color: metric.color,
                label: _resolveSegmentLabel(metric, disabledList),
                icon: segIcon,
                key: metric.subKey || metric.id,
                isIconDisabled: segDisabled
            });

            // Respect user's sequence from pinnedList so segments follow the order configured in pinnedList
            existingItem.segments.sort(function(a, b) {
                var idxA = _getPinnedIndex(pinnedList, a.id);
                var idxB = _getPinnedIndex(pinnedList, b.id);
                return idxA - idxB;
            });
            if (groupKey === "ram") {
                if (showBlockLeadingIcon && hasRamPinned && disabledList.indexOf("ram") === -1 && disabledList.indexOf("memory") === -1) {
                    existingItem.icon = existingItem._groupIcon || "memory-symbolic";
                }
            }
        } else {
            var baseLabel = metric.groupLabel || metric.deviceName || metric.group.toUpperCase();
            var singleLabel = metric.label;
            var itemIcon = metric.icon || metric.groupIcon;
            var isItemIconDis = _isIndicatorDisabled(metric, disabledList);
            if (isItemIconDis) {
                itemIcon = "";
            }
            var initialSegIcon = _resolveSegmentIcon(metric, disabledList);
            var groupIcon = metric.groupIcon || "";
            if (disabledList.indexOf(metric.group) !== -1 || !showBlockLeadingIcon) {
                groupIcon = "";
            }

            var newItem = {
                id: metric.id,
                icon: itemIcon,
                label: singleLabel + ":",
                value: metric.displayValue,
                color: metric.color,
                key: groupKey,
                segments: null,
                _groupBaseLabel: baseLabel,
                _groupIcon: groupIcon,
                _firstSubLabel: _resolveSegmentLabel(metric, disabledList),
                _firstSubIcon: initialSegIcon,
                _firstSubKey: metric.subKey || metric.id,
                _firstMetric: metric,
                isIconDisabled: isItemIconDis
            };
            if (mergeSameFamily) {
                groupIndexMap[groupKey] = items.length;
            }
            items.push(newItem);
        }
    }

    return items;
}

// Sync compact values
function syncCompactValues(existingItems, newItems) {
    if (!existingItems || !newItems || existingItems.length !== newItems.length) {
        return false;
    }
    for (var i = 0; i < existingItems.length; i++) {
        var existing = existingItems[i];
        var incoming = newItems[i];

        if (!existing || !incoming) return false;
        if (existing.key !== incoming.key || existing.label !== incoming.label) {
            return false;
        }
        if (Boolean(existing.hideSeparator) !== Boolean(incoming.hideSeparator)) {
            return false;
        }
        if (Boolean(existing.isIconDisabled) !== Boolean(incoming.isIconDisabled)) {
            return false;
        }
        if (JSON.stringify(existing.icon) !== JSON.stringify(incoming.icon)) {
            return false;
        }

        var hasExistingSegs = Boolean(existing.segments && existing.segments.length);
        var hasIncomingSegs = Boolean(incoming.segments && incoming.segments.length);
        if (hasExistingSegs !== hasIncomingSegs) {
            return false;
        }

        if (hasExistingSegs) {
            if (existing.segments.length !== incoming.segments.length) {
                return false;
            }
            for (var s = 0; s < existing.segments.length; s++) {
                var eSeg = existing.segments[s];
                var iSeg = incoming.segments[s];
                if (!eSeg || !iSeg) return false;
                if (eSeg.key !== iSeg.key || eSeg.label !== iSeg.label || eSeg.icon !== iSeg.icon || Boolean(eSeg.isIconDisabled) !== Boolean(iSeg.isIconDisabled)) {
                    return false;
                }
                if (eSeg.value !== iSeg.value) eSeg.value = iSeg.value;
                if (eSeg.color !== iSeg.color) eSeg.color = iSeg.color;
            }
        } else {
            if (existing.value !== incoming.value) existing.value = incoming.value;
            if (existing.color !== incoming.color) existing.color = incoming.color;
        }
    }
    return true;
}

// Sync popup groups
function syncPopupGroups(existingGroups, newGroups) {
    if (!existingGroups || !newGroups || existingGroups.length !== newGroups.length) {
        return false;
    }
    for (var i = 0; i < existingGroups.length; i++) {
        var eGrp = existingGroups[i];
        var nGrp = newGroups[i];

        if (!eGrp || !nGrp) return false;
        if (eGrp.key !== nGrp.key || eGrp.groupLabel !== nGrp.groupLabel) {
            return false;
        }
        if (eGrp.icon !== nGrp.icon) {
            return false;
        }
        if (eGrp.aggregateValue !== nGrp.aggregateValue) {
            eGrp.aggregateValue = nGrp.aggregateValue;
        }
        if (eGrp.aggregateColor !== nGrp.aggregateColor) {
            eGrp.aggregateColor = nGrp.aggregateColor;
        }

        var eSections = eGrp.sections;
        var nSections = nGrp.sections;
        if (!eSections || !nSections || eSections.length !== nSections.length) {
            return false;
        }

        for (var s = 0; s < eSections.length; s++) {
            var eSec = eSections[s];
            var nSec = nSections[s];
            if (!eSec || !nSec) return false;
            if (eSec.sectionLabel !== nSec.sectionLabel) {
                return false;
            }

            var eMetrics = eSec.metrics;
            var nMetrics = nSec.metrics;
            if (!eMetrics || !nMetrics || eMetrics.length !== nMetrics.length) {
                return false;
            }

            for (var m = 0; m < eMetrics.length; m++) {
                var eMet = eMetrics[m];
                var nMet = nMetrics[m];
                if (!eMet || !nMet) return false;
                if (eMet.id !== nMet.id || eMet.subLabel !== nMet.subLabel || eMet.icon !== nMet.icon) {
                    return false;
                }
                if (eMet.displayValue !== nMet.displayValue) {
                    eMet.displayValue = nMet.displayValue;
                }
                if (eMet.color !== nMet.color) {
                    eMet.color = nMet.color;
                }
                if (Boolean(eMet.isPinned) !== Boolean(nMet.isPinned)) {
                    eMet.isPinned = Boolean(nMet.isPinned);
                }
            }
        }
    }
    return true;
}
