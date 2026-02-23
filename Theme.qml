/*
 * Copyright (c) 2026 Ronin-CK
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import QtQuick

QtObject {
    id: root

    property var source: ({
    })
    readonly property color accent: _get("accent", "#cba6f7")
    readonly property color accentText: _get("accentText", "#11111b")
    readonly property real dimOpacity: _get("dimOpacity", 0.6)
    readonly property int borderRadius: _get("borderRadius", 10)
    readonly property int outlineThickness: _get("outlineThickness", 2)
    readonly property real bottomMargin: _get("bottomMargin", 60)
    readonly property bool animations: _get("animations", true)
    readonly property color barBackground: _get("barBackground", Qt.rgba(0.15, 0.15, 0.15, 0.4))
    readonly property color barBorder: _get("barBorder", Qt.rgba(1, 1, 1, 0.15))
    readonly property color barText: _get("barText", "#AAFFFFFF")
    readonly property color barShadow: _get("barShadow", "#80000000")
    readonly property color toggleBackground: _get("toggleBackground", "white")
    readonly property color toggleShadow: _get("toggleShadow", "#80000000")
    readonly property color toggleEdit: _get("toggleEdit", "#1ABC9C")
    readonly property color toggleTemp: _get("toggleTemp", "#2C66D8")
    readonly property color shareConnected: _get("shareConnected", "#3498DB")
    readonly property color sharePending: _get("sharePending", "#95A5A6")
    readonly property color shareErrorIcon: _get("shareErrorIcon", "white")
    readonly property color shareErrorBackground: _get("shareErrorBackground", "#E74C3C")
    readonly property string postSaveHook: source.hooksPostSaveHook || ""

    function _get(key, fallback) {
        let val = source[key];
        val = (val !== undefined && val !== null) ? val : fallback;
        // Support CSS-style rgba(r, g, b, a)
        if (typeof val === "string") {
            // Check for 8-digit hex (RRGGBBAA) - commonly used in web/CSS
            if (val.match(/^#[0-9a-fA-F]{8}$/)) {
                let r = parseInt(val.substring(1, 3), 16) / 255;
                let g = parseInt(val.substring(3, 5), 16) / 255;
                let b = parseInt(val.substring(5, 7), 16) / 255;
                let a = parseInt(val.substring(7, 9), 16) / 255;
                return Qt.rgba(r, g, b, a);
            }
            const rgbaMatch = val.match(/rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)/);
            if (rgbaMatch)
                return Qt.rgba(parseInt(rgbaMatch[1]) / 255, parseInt(rgbaMatch[2]) / 255, parseInt(rgbaMatch[3]) / 255, parseFloat(rgbaMatch[4]));

        }
        return val;
    }

}
