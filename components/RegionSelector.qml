/*
 * This file contains code based on "HyprQuickshot"
 * Original Author: JamDon2 (Copyright 2025)
 * Licensed under the MIT License.
 *
 * Modifications and other code: Copyright (c) 2026 Ronin-CK
 *
 * Copyright (c) 2025 JamDon2
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real dimOpacity: 0.6
    property real borderRadius: 10
    property real outlineThickness: 2
    property url fragmentShader: Qt.resolvedUrl("../shaders/dimming.frag.qsb")
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
    property bool globalAnimations: true
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

    Item {
        id: guides
        anchors.fill: parent
        z: 2

        function requestPaint() {}

        readonly property color guideColor: Qt.rgba(1, 1, 1, 0.5)

        Shape {
            anchors.fill: parent
            visible: !root.selecting

            ShapePath {
                strokeWidth: 1
                strokeColor: guides.guideColor
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: root.mouseX; startY: 0
                PathLine { x: root.mouseX; y: guides.height }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: guides.guideColor
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: 0; startY: root.mouseY
                PathLine { x: guides.width; y: root.mouseY }
            }
        }

        Shape {
            anchors.fill: parent
            visible: root.selecting

            ShapePath {
                strokeWidth: 1
                strokeColor: guides.guideColor
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: root.selectionX; startY: 0
                PathLine { x: root.selectionX; y: guides.height }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: guides.guideColor
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: root.selectionX + root.selectionWidth; startY: 0
                PathLine { x: root.selectionX + root.selectionWidth; y: guides.height }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: guides.guideColor
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: 0; startY: root.selectionY
                PathLine { x: guides.width; y: root.selectionY }
            }
            ShapePath {
                strokeWidth: 1
                strokeColor: guides.guideColor
                strokeStyle: ShapePath.DashLine
                dashPattern: [4, 4]
                fillColor: "transparent"
                startX: 0; startY: root.selectionY + root.selectionHeight
                PathLine { x: guides.width; y: root.selectionY + root.selectionHeight }
            }
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
        x: Math.max(10, Math.min(root.width - width - 10, root.selectionX + root.selectionWidth / 2 - width / 2))
        y: {
            const labelHeight = height;
            if (root.selectionY - labelHeight - 10 > 10)
                return root.selectionY - labelHeight - 10;
            
            if (root.selectionY + root.selectionHeight + labelHeight + 10 < root.height - 10)
                return root.selectionY + root.selectionHeight + 10;
                
            return root.selectionY + 10; // Fallback to inside top if no space above or below
        }
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
        enabled: root.animateSelection && root.globalAnimations && !root.selecting

        // Selection animations using spring dynamics
        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

    Behavior on selectionY {
        enabled: root.animateSelection && root.globalAnimations && !root.selecting

        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

    Behavior on selectionWidth {
        enabled: root.animateSelection && root.globalAnimations && !root.selecting

        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

    Behavior on selectionHeight {
        enabled: root.animateSelection && root.globalAnimations && !root.selecting

        SpringAnimation {
            spring: 4
            damping: 0.4
        }

    }

}
