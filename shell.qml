import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io

FreezeScreen {
    id: root
    visible: false

    property var activeScreen: null

    Connections {
        target: Hyprland
        enabled: activeScreen === null

        function onFocusedMonitorChanged() {
            const monitor = Hyprland.focusedMonitor
            if(!monitor) return

                for (const screen of Quickshell.screens) {
                    if (screen.name === monitor.name) {
                        activeScreen = screen
                    }
                }
        }
    }

    targetScreen: activeScreen
    property var hyprlandMonitor: Hyprland.focusedMonitor
    property string tempPath

    // Default mode
    property string mode: "region"
    property var modes: ["region", "window", "screen"]

    Shortcut {
        sequence: "Escape"
        onActivated: () => {
            Quickshell.execDetached(["rm", tempPath])
            Qt.quit()
        }
    }

    Timer {
        id: showTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: root.visible = true
    }

    Component.onCompleted: {
        const timestamp = Date.now()
        const path = Quickshell.cachePath(`screenshot-${timestamp}.png`)
        tempPath = path
        Quickshell.execDetached(["grim", path])
        showTimer.start()
    }

    Process {
        id: screenshotProcess
        running: false

        onExited: () => {
            Qt.quit()
        }

        stdout: StdioCollector {
            onStreamFinished: console.log(this.text)
        }
        stderr: StdioCollector {
            onStreamFinished: console.log(this.text)
        }
    }

    function saveScreenshot(x, y, width, height) {
        const scale = hyprlandMonitor.scale
        const scaledX = Math.round((x + root.hyprlandMonitor.x) * scale)
        const scaledY = Math.round((y + root.hyprlandMonitor.y) * scale)
        const scaledWidth = Math.round(width * scale)
        const scaledHeight = Math.round(height * scale)

        const picturesDir = Quickshell.env("XDG_PICTURES_DIR") || (Quickshell.env("HOME") + "/Pictures/Screenshots")
        const now = new Date()
        const timestamp = Qt.formatDateTime(now, "yyyy-MM-dd_hh-mm-ss")
        const outputPath = `${picturesDir}/screenshot-${timestamp}.png`

        screenshotProcess.command = ["sh", "-c",
        `magick "${tempPath}" -crop ${scaledWidth}x${scaledHeight}+${scaledX}+${scaledY} "${outputPath}" && ` +
        `wl-copy < "${outputPath}" && ` +
        `rm "${tempPath}"`
        ]

        screenshotProcess.running = true
        root.visible = false
    }

    RegionSelector {
        visible: mode === "region"
        id: regionSelector
        anchors.fill: parent
        dimOpacity: 0.6
        borderRadius: 10.0
        outlineThickness: 2.0
        onRegionSelected: (x, y, width, height) => saveScreenshot(x, y, width, height)
    }

    WindowSelector {
        visible: mode === "window"
        id: windowSelector
        anchors.fill: parent
        monitor: root.hyprlandMonitor
        dimOpacity: 0.6
        borderRadius: 10.0
        outlineThickness: 2.0
        onRegionSelected: (x, y, width, height) => saveScreenshot(x, y, width, height)
    }

    // --- SEGMENTED CONTROL UI ---

    Rectangle {
        id: segmentedControl
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60

        // Dimensions
        height: 50
        width: 300
        radius: height / 2

        // Visuals: Dark Glass Effect
        color: Qt.rgba(0.15, 0.15, 0.15, 0.9)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        // The Sliding Blue Highlight (The "Pill")
        Rectangle {
            id: highlight
            height: parent.height - 8
            width: (parent.width - 8) / root.modes.length
            y: 4
            radius: height / 2
            color: "#3478F6" // System Blue

            // Calculate X position based on the current mode index
            x: 4 + (root.modes.indexOf(root.mode) * width)

            // Smooth sliding animation
            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        // The Text Labels
        Row {
            anchors.fill: parent
            anchors.margins: 4 // Match highlight margins

            Repeater {
                model: root.modes

                Item {
                    // Divide available width equally among items
                    width: (segmentedControl.width - 8) / root.modes.length
                    height: segmentedControl.height - 8

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.mode = modelData
                            if (modelData === "screen") {
                                saveScreenshot(0, 0, root.targetScreen.width, root.targetScreen.height)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1) // Capitalize

                        // White text, slightly bolder when selected
                        color: "white"
                        font.weight: root.mode === modelData ? Font.DemiBold : Font.Normal
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
