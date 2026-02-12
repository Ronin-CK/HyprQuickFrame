import QtQuick

Item {
    id: root

    property real dimOpacity: 0.6
    property real borderRadius: 10
    property real outlineThickness: 2
    property url fragmentShader: Qt.resolvedUrl("dimming.frag.qsb")
    property point startPos
    property real selectionX: 0
    property real selectionY: 0
    property real selectionWidth: 0
    property real selectionHeight: 0
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0
    property real mouseX: 0
    property real mouseY: 0
    property bool canceled: false
    property bool selecting: false
    property bool animateSelection: true
    property alias pressed: mouseArea.pressed

    signal regionSelected(real x, real y, real width, real height)

    function clearSelection() {
        root.animateSelection = false;
        root.targetX = 0;
        root.targetY = 0;
        root.targetWidth = 0;
        root.targetHeight = 0;
        root.selectionX = 0;
        root.selectionY = 0;
        root.selectionWidth = 0;
        root.selectionHeight = 0;
        root.selecting = false;
        root.animateSelection = true;
        guides.requestPaint();
    }

    onSelectionXChanged: guides.requestPaint()
    onSelectionYChanged: guides.requestPaint()
    onSelectionWidthChanged: guides.requestPaint()
    onSelectionHeightChanged: guides.requestPaint()
    onMouseXChanged: guides.requestPaint()
    onMouseYChanged: guides.requestPaint()

    ShaderEffect {
        property vector4d selectionRect: Qt.vector4d(root.selectionX, root.selectionY, root.selectionWidth, root.selectionHeight)
        property real dimOpacity: root.dimOpacity
        property vector2d screenSize: Qt.vector2d(root.width, root.height)
        property real borderRadius: root.borderRadius
        property real outlineThickness: root.outlineThickness

        anchors.fill: parent
        z: 0
        fragmentShader: root.fragmentShader
    }

    Canvas {
        id: guides

        anchors.fill: parent
        z: 2
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.beginPath();
            ctx.strokeStyle = "rgba(255, 255, 255, 0.5)";
            ctx.lineWidth = 1;
            ctx.setLineDash([5, 5]);
            if (!root.selecting) {
                ctx.moveTo(root.mouseX, 0);
                ctx.lineTo(root.mouseX, root.height);
                ctx.moveTo(0, root.mouseY);
                ctx.lineTo(root.width, root.mouseY);
            } else {
                ctx.moveTo(root.selectionX, 0);
                ctx.lineTo(root.selectionX, root.height);
                ctx.moveTo(root.selectionX + root.selectionWidth, 0);
                ctx.lineTo(root.selectionX + root.selectionWidth, root.height);
                ctx.moveTo(0, root.selectionY);
                ctx.lineTo(root.width, root.selectionY);
                ctx.moveTo(0, root.selectionY + root.selectionHeight);
                ctx.lineTo(root.width, root.selectionY + root.selectionHeight);
            }
            ctx.stroke();
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        z: 3
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor
        onPressed: (mouse) => {
            // Right-click to cancel selection
            if (mouse.button === Qt.RightButton) {
                root.canceled = true;
                root.clearSelection();
                return ;
            }
            root.canceled = false;
            root.selecting = true;
            root.startPos = Qt.point(mouse.x, mouse.y);
            root.targetX = mouse.x;
            root.targetY = mouse.y;
            root.targetWidth = 0;
            root.targetHeight = 0;
            guides.requestPaint();
        }
        onPositionChanged: (mouse) => {
            root.mouseX = mouse.x;
            root.mouseY = mouse.y;
            if (root.selecting && !root.canceled && (mouse.buttons & Qt.LeftButton)) {
                root.targetX = Math.min(root.startPos.x, mouse.x);
                root.targetY = Math.min(root.startPos.y, mouse.y);
                root.targetWidth = Math.abs(mouse.x - root.startPos.x);
                root.targetHeight = Math.abs(mouse.y - root.startPos.y);
            }
        }
        onReleased: (mouse) => {
            // Default to full-screen selection on zero-size input
            if (mouse.button === Qt.RightButton || root.canceled) {
                if (mouse.buttons === 0)
                    root.canceled = false;

                root.clearSelection();
                return ;
            }
            if (root.targetWidth < 5 && root.targetHeight < 5)
                root.regionSelected(0, 0, root.width, root.height);
            else
                root.regionSelected(Math.round(root.selectionX), Math.round(root.selectionY), Math.round(root.selectionWidth), Math.round(root.selectionHeight));
            root.selecting = false;
        }

        Timer {
            id: updateTimer

            interval: 16
            repeat: true
            running: root.selecting && !root.canceled
            onTriggered: {
                root.selectionX = root.targetX;
                root.selectionY = root.targetY;
                root.selectionWidth = root.targetWidth;
                root.selectionHeight = root.targetHeight;
            }
        }

    }

    Rectangle {
        id: dimLabel

        visible: root.selecting && !root.canceled && root.selectionWidth > 20
        z: 4
        x: root.selectionX + root.selectionWidth / 2 - width / 2
        y: root.selectionY < 40 ? root.selectionY + 10 : root.selectionY - 35
        width: labelText.implicitWidth + 16
        height: labelText.implicitHeight + 8
        radius: 6
        color: Qt.rgba(0, 0, 0, 0.7)

        Text {
            id: labelText

            anchors.centerIn: parent
            text: `${Math.round(root.selectionWidth)} × ${Math.round(root.selectionHeight)}`
            color: "white"
            font.pixelSize: 12
            font.family: "monospace"
        }

    }

    Behavior on selectionX {
        enabled: root.animateSelection

        // Selection animations using spring dynamics
        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

    Behavior on selectionY {
        enabled: root.animateSelection

        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

    Behavior on selectionWidth {
        enabled: root.animateSelection

        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

    Behavior on selectionHeight {
        enabled: root.animateSelection

        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

}
