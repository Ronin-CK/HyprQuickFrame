import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

FreezeScreen {
    id: root

    property var activeScreen: null
    property var hyprlandMonitor: Hyprland.focusedMonitor
    property string tempPath
    property string mode: "region"
    property var modes: ["region", "window", "screen"]
    property bool editorMode: Quickshell.env("HYPRQUICKFRAME_EDITOR") === "1"

    function saveScreenshot(x, y, width, height) {
        // Calculate global bounds (grim captures the whole desktop starting from top-left-most point)
        let minX = 0;
        let minY = 0;
        const monitors = Hyprland.monitors.values;
        for (const m of monitors) {
            minX = Math.min(minX, m.lastIpcObject.x);
            minY = Math.min(minY, m.lastIpcObject.y);
        }
        const scale = hyprlandMonitor.scale;
        const monitorX = root.hyprlandMonitor.lastIpcObject.x;
        const monitorY = root.hyprlandMonitor.lastIpcObject.y;
        const globalX = Math.round((x + monitorX) * scale);
        const globalY = Math.round((y + monitorY) * scale);
        const cropX = globalX - Math.round(minX * scale);
        const cropY = globalY - Math.round(minY * scale);
        const scaledWidth = Math.round(width * scale);
        const scaledHeight = Math.round(height * scale);
        const picturesDir = Quickshell.env("XDG_PICTURES_DIR") || (Quickshell.env("HOME") + "/Pictures/Screenshots");
        const now = new Date();
        const timestamp = Qt.formatDateTime(now, "yyyy-MM-dd_hh-mm-ss");
        const outputPath = `${picturesDir}/screenshot-${timestamp}.png`;
        const sattyCommand = `magick "${tempPath}" -crop ${scaledWidth}x${scaledHeight}+${cropX}+${cropY} png:- | satty --filename - --fullscreen --output-filename "${outputPath}" --early-exit --init-tool brush --copy-command wl-copy && rm "${tempPath}"`;
        const defaultCommand = `magick "${tempPath}" -crop ${scaledWidth}x${scaledHeight}+${cropX}+${cropY} "${outputPath}" && wl-copy --type image/png < "${outputPath}" && notify-send -a "HyprQuickFrame" -i "${outputPath}" -h string:image-path:"${outputPath}" "Screenshot Saved" "Saved to Pictures/Screenshots" && rm "${tempPath}"`;
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
        captureProcess.command = ["grim", "-l", "0", path];
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
        height: 50
        width: 300
        radius: height / 2
        color: Qt.rgba(0.15, 0.15, 0.15, 0.9)
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        Rectangle {
            id: highlight

            height: parent.height - 8
            width: (parent.width - 8) / root.modes.length
            y: 4
            radius: height / 2
            color: "#3478F6"
            x: 4 + (root.modes.indexOf(root.mode) * width)

            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }

            }

        }

        Row {
            anchors.fill: parent
            anchors.margins: 4

            Repeater {
                model: root.modes

                Item {
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
                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        color: "white"
                        font.weight: root.mode === modelData ? Font.DemiBold : Font.Normal
                        font.pixelSize: 14
                    }

                }

            }

        }

    }

}
