import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

FreezeScreen {
    // --- SEGMENTED CONTROL UI ---

    id: root

    property var activeScreen: null
    property var hyprlandMonitor: Hyprland.focusedMonitor
    property string tempPath
    // Default mode
    property string mode: "region"
    property var modes: ["region", "window", "screen"]
    // Check for editor mode environment variable
    property bool editorMode: Quickshell.env("HYPRQUICKFRAME_EDITOR") === "1"

    function saveScreenshot(x, y, width, height) {
        const scale = hyprlandMonitor.scale;
        const scaledX = Math.round((x + root.hyprlandMonitor.x) * scale);
        const scaledY = Math.round((y + root.hyprlandMonitor.y) * scale);
        const scaledWidth = Math.round(width * scale);
        const scaledHeight = Math.round(height * scale);
        const picturesDir = Quickshell.env("XDG_PICTURES_DIR") || (Quickshell.env("HOME") + "/Pictures/Screenshots");
        const now = new Date();
        const timestamp = Qt.formatDateTime(now, "yyyy-MM-dd_hh-mm-ss");
        const outputPath = `${picturesDir}/screenshot-${timestamp}.png`;
        // Commands
        const sattyCommand = `magick "${tempPath}" -crop ${scaledWidth}x${scaledHeight}+${scaledX}+${scaledY} png:- | satty --filename - --output-filename "${outputPath}" --early-exit --init-tool brush && rm "${tempPath}"`;
        const defaultCommand = `magick "${tempPath}" -crop ${scaledWidth}x${scaledHeight}+${scaledX}+${scaledY} "${outputPath}" && wl-copy < "${outputPath}" && notify-send -a "HyprQuickFrame" -i "${outputPath}" -h string:image-path:"${outputPath}" "Screenshot Saved" "Saved to Pictures/Screenshots" && rm "${tempPath}"`;
        screenshotProcess.command = ["sh", "-c", root.editorMode ? sattyCommand : defaultCommand];
        screenshotProcess.running = true;
        root.visible = false;
    }

    visible: false
    targetScreen: activeScreen
    Component.onCompleted: {
        const timestamp = Date.now();
        const path = Quickshell.cachePath(`screenshot-${timestamp}.png`);
        tempPath = path;
        captureProcess.command = ["grim", path];
        captureProcess.running = true;
    }

    Process {
        id: captureProcess

        running: false
        onExited: showTimer.start()
    }

    Connections {
        function onFocusedMonitorChanged() {
            const monitor = Hyprland.focusedMonitor;
            if (!monitor)
                return ;

            for (const screen of Quickshell.screens) {
                if (screen.name === monitor.name)
                    activeScreen = screen;

            }
        }

        target: Hyprland
        enabled: activeScreen === null
    }

    Shortcut {
        sequence: "Escape"
        onActivated: () => {
            Quickshell.execDetached(["rm", tempPath]);
            Qt.quit();
        }
    }

    Shortcut {
        sequence: "r"
        onActivated: root.mode = "region"
    }

    Shortcut {
        sequence: "w"
        onActivated: root.mode = "window"
    }

    Shortcut {
        sequence: "s"
        onActivated: {
            root.mode = "screen";
            saveScreenshot(0, 0, root.targetScreen.width, root.targetScreen.height);
        }
    }

    Timer {
        id: showTimer

        interval: 50
        running: false
        repeat: false
        onTriggered: root.visible = true
    }

    Process {
        id: screenshotProcess

        running: false
        onExited: () => {
            Qt.quit();
        }

        stdout: StdioCollector {
            onStreamFinished: console.log(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: console.log(this.text)
        }

    }

    RegionSelector {
        id: regionSelector

        visible: mode === "region"
        anchors.fill: parent
        dimOpacity: 0.6
        borderRadius: 10
        outlineThickness: 2
        onRegionSelected: (x, y, width, height) => {
            return saveScreenshot(x, y, width, height);
        }
    }

    WindowSelector {
        id: windowSelector

        visible: mode === "window"
        anchors.fill: parent
        monitor: root.hyprlandMonitor
        dimOpacity: 0.6
        borderRadius: 10
        outlineThickness: 2
        onRegionSelected: (x, y, width, height) => {
            return saveScreenshot(x, y, width, height);
        }
    }

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
                            root.mode = modelData;
                            if (modelData === "screen")
                                saveScreenshot(0, 0, root.targetScreen.width, root.targetScreen.height);

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
