/*
 * Copyright (c) 2026 Ronin-CK
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

import Qt5Compat.GraphicalEffects
import QtQuick

Rectangle {
    id: root

    property bool active: false
    property string icon: ""
    property color iconColor: "black"
    property color backgroundColor: "white"
    property real targetX: 0
    property real targetY: 0
    property real sourceX: 0
    property bool hovered: false
    property bool pulse: false
    property color shadowColor: "#80000000"
    readonly property real buttonSize: 44
    readonly property real inactiveScale: 0.4
    readonly property real activeIconSize: 18
    readonly property real inactiveIconSize: 15
    readonly property real pulseMinOpacity: 0.3
    readonly property int springAnimDuration: 350
    readonly property int fadeAnimDuration: 250
    readonly property int pulseStepDuration: 600

    signal clicked()

    onActiveChanged: {
        if (!active)
            hovered = false;

    }
    visible: active || opacity > 0
    width: buttonSize
    height: buttonSize
    radius: buttonSize / 2
    color: backgroundColor
    x: active ? targetX : sourceX
    y: targetY - height / 2
    scale: active ? (hovered ? 1.1 : 1) : inactiveScale
    opacity: active ? 1 : 0
    layer.enabled: true

    Text {
        id: iconText

        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.active ? root.activeIconSize : root.inactiveIconSize
        font.weight: root.active ? Font.Bold : Font.Medium

        Behavior on font.pixelSize {
            NumberAnimation {
                duration: root.springAnimDuration
                easing.type: Easing.OutQuad
            }

        }

        SequentialAnimation on opacity {
            id: pulseAnim

            running: root.active && root.pulse
            loops: Animation.Infinite
            onRunningChanged: {
                if (!running)
                    iconText.opacity = 1;

            }

            NumberAnimation {
                to: root.pulseMinOpacity
                duration: root.pulseStepDuration
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                to: 1
                duration: root.pulseStepDuration
                easing.type: Easing.InOutQuad
            }

        }

    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        enabled: root.active
        onClicked: root.clicked()
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    layer.effect: DropShadow {
        transparentBorder: true
        radius: 12
        samples: 25
        color: root.pulse ? Qt.rgba(root.iconColor.r, root.iconColor.g, root.iconColor.b, 0.25) : root.shadowColor
        verticalOffset: 4
    }

    Behavior on x {
        // Configuration for spring-based transitions
        SpringAnimation {
            spring: 4
            damping: 0.4
            mass: 0.8
        }

    }

    Behavior on y {
        SpringAnimation {
            spring: 4
            damping: 0.4
            mass: 0.8
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.fadeAnimDuration
            easing.type: Easing.OutQuad
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: root.springAnimDuration
            easing.type: Easing.OutBack
        }

    }

}
