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
    readonly property color barBackground: _get("bar.background", Qt.rgba(0.15, 0.15, 0.15, 0.4))
    readonly property color barBorder: _get("bar.border", Qt.rgba(1, 1, 1, 0.15))
    readonly property color barText: _get("bar.text", "#AAFFFFFF")
    readonly property color barShadow: _get("bar.shadow", "#80000000")
    readonly property color toggleBackground: _get("toggle.background", "white")
    readonly property color toggleShadow: _get("toggle.shadow", "#80000000")
    readonly property color toggleEdit: _get("toggle.edit", "#1ABC9C")
    readonly property color toggleTemp: _get("toggle.temp", "#2C66D8")
    readonly property color shareConnected: _get("share.connected", "#3498DB")
    readonly property color sharePending: _get("share.pending", "#95A5A6")
    readonly property color shareErrorIcon: _get("share.errorIcon", "white")
    readonly property color shareErrorBackground: _get("share.errorBackground", "#E74C3C")

    function _get(path, fallback) {
        const parts = path.split(".");
        let obj = source;
        for (const p of parts) {
            if (obj === undefined || obj === null || typeof obj !== "object")
                return fallback;

            obj = obj[p];
        }
        return (obj !== undefined && obj !== null) ? obj : fallback;
    }

}
