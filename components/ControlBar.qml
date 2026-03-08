import QtQuick

Rectangle {
    id: root

    property var modes: []
    property string mode: "region"
    property bool tempActive: false
    property bool editActive: false
    property var theme: null
    property real tabItemSize: 100
    property real targetMenuWidth: (modes.length - (editActive ? 1 : 0) - (tempActive ? 1 : 0)) * tabItemSize + 8

    signal modeSelected(string mode)
    signal tempToggled()
    signal editToggled()

    height: 50
    width: targetMenuWidth
    radius: height / 2
    color: theme ? theme.barBackground : "transparent"
    border.color: theme ? theme.barBorder : "transparent"
    border.width: 1

    Rectangle {
        id: highlight

        width: root.tabItemSize
        height: parent.height - 8
        y: 4
        radius: height / 2
        color: theme ? theme.accent : "transparent"
        x: 4 + (root.modes.slice(0, root.modes.indexOf(root.mode)).filter((m) => {
            if (m === "edit")
                return !root.editActive;

            if (m === "temp")
                return !root.tempActive;

            return true;
        }).length * root.tabItemSize)

        Behavior on x {
            SpringAnimation {
                spring: 4
                damping: 0.25
                mass: 1
            }

        }

    }

    Row {
        anchors.fill: parent
        anchors.margins: 4

        Repeater {
            model: root.modes

            Item {
                id: tabItem

                property bool isTemp: modelData === "temp"
                property bool isEdit: modelData === "edit"
                property bool collapsed: (isTemp && root.tempActive) || (isEdit && root.editActive)

                width: collapsed ? 0 : root.tabItemSize
                height: root.height - 8
                visible: width > 0

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData === "temp")
                            root.tempToggled();
                        else if (modelData === "edit")
                            root.editToggled();
                        else
                            root.modeSelected(modelData);
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: {
                        const icons = {
                            "region": "󰒉",
                            "window": "󱂬",
                            "temp": "󰅇",
                            "edit": "󰏫"
                        };
                        const labels = {
                            "region": "Region",
                            "window": "Window",
                            "temp": "Temp",
                            "edit": "Edit"
                        };
                        return icons[modelData] + "  " + labels[modelData];
                    }
                    color: (modelData === "temp" || modelData === "edit") ? (theme ? theme.barText : "white") : (root.mode === modelData ? (theme ? theme.accentText : "black") : (theme ? theme.barText : "white"))
                    font.weight: (modelData === "temp" || modelData === "edit") ? Font.Medium : (root.mode === modelData ? Font.Bold : Font.Medium)
                    font.pixelSize: 15
                    opacity: tabItem.collapsed ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }

                    }

                }

                Behavior on width {
                    SpringAnimation {
                        spring: 4
                        damping: 0.25
                        mass: 1
                    }

                }

            }

        }

    }

    Behavior on width {
        SpringAnimation {
            spring: 4
            damping: 0.25
            mass: 1
        }

    }

}
