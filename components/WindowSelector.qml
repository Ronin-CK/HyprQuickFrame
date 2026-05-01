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
import Quickshell.Hyprland

Item {  
    id: root

    property var monitor: Hyprland.focusedMonitor
    property var workspace: monitor?.activeWorkspace
    property var windows: workspace?.toplevels ?? []

    signal regionSelected(real x, real y, real width, real height)
    property alias pressed: mouseArea.pressed

    property real mouseX: 0
    property real mouseY: 0
    onMouseXChanged: updateHovered()
    onMouseYChanged: updateHovered()

    property real dimOpacity: 0.6
    property real borderRadius: 10.0
    property real outlineThickness: 2.0
    property url fragmentShader: Qt.resolvedUrl("../shaders/dimming.frag.qsb")

    property real selectionX: 0
    property real selectionY: 0
    property real selectionWidth: 0
    property real selectionHeight: 0

    property bool animateSelection: true

    function hitWindow(mx, my) {
        if (!monitor || !monitor.lastIpcObject)
            return null;
        const mx0 = monitor.lastIpcObject.x;
        const my0 = monitor.lastIpcObject.y;
        const list = windows;
        for (let i = list.length - 1; i >= 0; i--) {
            const w = list[i];
            if (!w || !w.lastIpcObject) continue;
            const wx = w.lastIpcObject.at[0] - mx0;
            const wy = w.lastIpcObject.at[1] - my0;
            const ww = w.lastIpcObject.size[0];
            const wh = w.lastIpcObject.size[1];
            if (mx >= wx && mx <= wx + ww && my >= wy && my <= wy + wh) {
                return { x: wx, y: wy, w: ww, h: wh };
            }
        }
        return null;
    }

    function updateHovered() {
        const hit = hitWindow(mouseX, mouseY);
        if (!hit) return;
        selectionX = hit.x;
        selectionY = hit.y;
        selectionWidth = hit.w;
        selectionHeight = hit.h;
    }

    Behavior on selectionX { enabled: root.animateSelection; SpringAnimation { spring: 4; damping: 0.4 } }
    Behavior on selectionY { enabled: root.animateSelection; SpringAnimation { spring: 4; damping: 0.4 } }
    Behavior on selectionHeight { enabled: root.animateSelection; SpringAnimation { spring: 4; damping: 0.4 } }
    Behavior on selectionWidth { enabled: root.animateSelection; SpringAnimation { spring: 4; damping: 0.4 } }


    ShaderEffect {
        anchors.fill: parent
        z: 0

        property vector4d selectionRect: Qt.vector4d(
            root.selectionX,
            root.selectionY,
            root.selectionWidth,
            root.selectionHeight
        )
        property real dimOpacity: root.dimOpacity
        property vector2d screenSize: Qt.vector2d(root.width, root.height)
        property real borderRadius: root.borderRadius
        property real outlineThickness: root.outlineThickness

        fragmentShader: root.fragmentShader
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        z: 3
        hoverEnabled: true

        onPositionChanged: (mouse) => {
            root.mouseX = mouse.x;
            root.mouseY = mouse.y;
        }

        onReleased: (mouse) => {
            const hit = root.hitWindow(mouse.x, mouse.y);
            if (!hit) return;
            root.regionSelected(
                Math.round(hit.x),
                Math.round(hit.y),
                Math.round(hit.w),
                Math.round(hit.h)
            );
        }
    }
}
