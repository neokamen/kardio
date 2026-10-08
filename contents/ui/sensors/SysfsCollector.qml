import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: root

    property int updateInterval: 2000
    property var telemetry: ({})
    property int _tick: 0

    readonly property string _scriptPath: {
        var base = Qt.resolvedUrl("../../scripts/gpu_sysfs.py").toString();
        return base.replace(/^file:\/\//, "");
    }

    Timer {
        id: pollTimer
        interval: Math.max(1000, root.updateInterval)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (sysfsLoader.item && root._scriptPath) {
                root._tick++;
                var cmd = "python3 " + root._scriptPath + " #" + root._tick;
                sysfsLoader.item.connectSource(cmd);
            }
        }
    }

    Loader {
        id: sysfsLoader
        active: true
        sourceComponent: P5Support.DataSource {
            engine: "executable"
            connectedSources: []
            onNewData: function(sourceName, data) {
                if (data && data["stdout"]) {
                    try {
                        var parsed = JSON.parse(data["stdout"]);
                        if (parsed && typeof parsed === "object") {
                            root.telemetry = parsed;
                        }
                    } catch(e) {}
                }
                disconnectSource(sourceName);
            }
        }
    }
}

