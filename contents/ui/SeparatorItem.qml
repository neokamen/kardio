import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: sepRoot

    property string style: "line"
    property color color: Kirigami.Theme.textColor
    property real separatorOpacity: 0.4
    property int referenceSize: 14

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: {
        switch (sepRoot.style) {
            case "dot": return 6;
            case "colon": return 6;
            case "pill": return 6;
            case "slash": return 8;
            case "chevron": return 8;
            case "doubleLine": return 6;
            case "diamond": return 8;
            case "dash": return 8;
            case "line":
            default: return 4;
        }
    }
    implicitHeight: Math.max(14, referenceSize)
    opacity: separatorOpacity

    // 1. Classic Single Line
    Rectangle {
        id: lineRect
        visible: sepRoot.style === "line" || (sepRoot.style !== "doubleLine" && sepRoot.style !== "dot" && sepRoot.style !== "pill" && sepRoot.style !== "slash" && sepRoot.style !== "diamond" && sepRoot.style !== "dash" && sepRoot.style !== "colon" && sepRoot.style !== "chevron")
        anchors.centerIn: parent
        width: 1
        height: Math.max(10, Math.round((sepRoot.height > 0 ? Math.min(sepRoot.height, 28) : sepRoot.referenceSize) * 0.7))
        color: sepRoot.color
        antialiasing: true
    }

    // 2. Double Line
    Row {
        id: doubleLineRow
        visible: sepRoot.style === "doubleLine"
        anchors.centerIn: parent
        spacing: 2
        height: Math.max(10, Math.round((sepRoot.height > 0 ? Math.min(sepRoot.height, 28) : sepRoot.referenceSize) * 0.7))

        Rectangle {
            width: 1
            height: parent.height
            color: sepRoot.color
            antialiasing: true
        }
        Rectangle {
            width: 1
            height: parent.height
            color: sepRoot.color
            antialiasing: true
        }
    }

    // 3. Dot (Circle)
    Rectangle {
        id: dotCircle
        visible: sepRoot.style === "dot"
        anchors.centerIn: parent
        width: 4
        height: 4
        radius: 2
        color: sepRoot.color
        antialiasing: true
    }

    // 4. Pill / Capsule
    Rectangle {
        id: pillRect
        visible: sepRoot.style === "pill"
        anchors.centerIn: parent
        width: 3
        height: Math.max(8, Math.round((sepRoot.height > 0 ? Math.min(sepRoot.height, 26) : sepRoot.referenceSize) * 0.55))
        radius: 1.5
        color: sepRoot.color
        antialiasing: true
    }

    // 5. Slash / Diagonal
    Rectangle {
        id: slashRect
        visible: sepRoot.style === "slash"
        anchors.centerIn: parent
        width: 1.5
        height: Math.max(10, Math.round((sepRoot.height > 0 ? Math.min(sepRoot.height, 28) : sepRoot.referenceSize) * 0.65))
        radius: 0.75
        rotation: 20
        color: sepRoot.color
        antialiasing: true
    }

    // 6. Diamond
    Rectangle {
        id: diamondRect
        visible: sepRoot.style === "diamond"
        anchors.centerIn: parent
        width: 5
        height: 5
        radius: 0.5
        rotation: 45
        color: sepRoot.color
        antialiasing: true
    }

    // 7. Dash
    Rectangle {
        id: dashRect
        visible: sepRoot.style === "dash"
        anchors.centerIn: parent
        width: 6
        height: 2
        radius: 1
        color: sepRoot.color
        antialiasing: true
    }

    // 8. Colon / Double Dot (Vertical)
    Column {
        id: colonCol
        visible: sepRoot.style === "colon"
        anchors.centerIn: parent
        spacing: 3

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 3
            height: 3
            radius: 1.5
            color: sepRoot.color
            antialiasing: true
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 3
            height: 3
            radius: 1.5
            color: sepRoot.color
            antialiasing: true
        }
    }

    // 9. Chevron / Angle (›)
    Canvas {
        id: chevronCanvas
        visible: sepRoot.style === "chevron"
        anchors.centerIn: parent
        width: 6
        height: Math.max(10, Math.round((sepRoot.height > 0 ? Math.min(sepRoot.height, 26) : sepRoot.referenceSize) * 0.7))
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = sepRoot.color;
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            var midY = height / 2;
            ctx.moveTo(1.5, 2);
            ctx.lineTo(width - 1.5, midY);
            ctx.lineTo(1.5, height - 2);
            ctx.stroke();
        }
        Connections {
            target: sepRoot
            function onColorChanged() { chevronCanvas.requestPaint(); }
            function onHeightChanged() { chevronCanvas.requestPaint(); }
        }
    }
}

