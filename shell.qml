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
    property string tempPath: ""
    property string mode: "region"
    property var modes: ["edit", "region", "window", "temp"]
    property bool tempActive: false
    property bool editActive: false
    property bool shareActive: false
    property int connectivityStatus: 0
    readonly property real tabItemSize: 100
    readonly property real controlHeight: 50
    readonly property real targetMenuWidth: (modes.length - (editActive ? 1 : 0) - (tempActive ? 1 : 0)) * tabItemSize + 8

    function parseTOML(text) {
        let result = {
        };
        let section = "";
        const lines = text.split(/\r?\n/);
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line || line.startsWith("#"))
                continue;

            const secMatch = line.match(/^\[(\w+)\]$/);
            if (secMatch) {
                section = secMatch[1];
                continue;
            }
            const quotedMatch = line.match(/^(\w+)\s*=\s*"([^"]*)"/);
            if (quotedMatch) {
                const rawKey = quotedMatch[1];
                const key = section ? section + rawKey.charAt(0).toUpperCase() + rawKey.slice(1) : rawKey;
                result[key] = quotedMatch[2];
                continue;
            }
            const unquotedMatch = line.match(/^(\w+)\s*=\s*([^\s#]+)/);
            if (unquotedMatch) {
                const rawKey = unquotedMatch[1];
                const key = section ? section + rawKey.charAt(0).toUpperCase() + rawKey.slice(1) : rawKey;
                let val = unquotedMatch[2];
                if (val === "true") {
                    val = true;
                } else if (val === "false") {
                    val = false;
                } else {
                    const num = parseFloat(val);
                    if (!isNaN(num))
                        val = num;
                }
                result[key] = val;
                continue;
            }
        }
        return result;
    }

    function shellEscape(s) {
        return "'" + s.replace(/'/g, "'\\''") + "'";
    }

    function calculateCrop(x, y, width, height) {
        let minX = Infinity;
        let minY = Infinity;
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
        return {
            "cropX": globalX - Math.round(minX * scale),
            "cropY": globalY - Math.round(minY * scale),
            "scaledWidth": Math.round(width * scale),
            "scaledHeight": Math.round(height * scale)
        };
    }

    function cleanup() {
        Quickshell.execDetached(["rm", "-f", tempPath]);
    }

    function saveScreenshot(x, y, width, height) {
        const crop = calculateCrop(x, y, width, height);
        const picturesBase = Quickshell.env("XDG_PICTURES_DIR") || (Quickshell.env("HOME") + "/Pictures");
        const picturesDir = picturesBase + "/Screenshots";
        const now = new Date();
        const timestamp = Qt.formatDateTime(now, "yyyy-MM-dd_hh-mm-ss");
        const outputPath = `${picturesDir}/screenshot-${timestamp}.png`;
        const tempSnip = Quickshell.cachePath(`snip-${timestamp}.png`);
        const ePicturesDir = shellEscape(picturesDir);
        const eOutputPath = shellEscape(outputPath);
        const eTempPath = shellEscape(tempPath);
        const eTempSnip = shellEscape(tempSnip);
        const shareCmd = "kdeconnect-cli -l | grep 'reachable' | grep -oP '[a-f0-9-]{8,}'" + " | head -1 | xargs -I{} sh -c" + " 'kdeconnect-cli -d {} --share \"$1\" && sleep 0.2" + " && kdeconnect-cli -d {} --send-clipboard' --";
        const maybeShare = (escapedPath) => {
            return root.shareActive ? ` && ${shareCmd} ${escapedPath}` : "";
        };
        const shareTag = root.shareActive ? " & phone" : "";
        const mkdirCmd = `mkdir -p ${ePicturesDir}`;
        const cropCmd = `magick ${eTempPath} -crop ` + `${crop.scaledWidth}x${crop.scaledHeight}` + `+${crop.cropX}+${crop.cropY}`;
        const sattyCommand = `${mkdirCmd} && ${cropCmd} png:- ` + `| satty --filename - --fullscreen ` + `--output-filename ${eOutputPath} --early-exit --init-tool brush ` + `&& wl-copy --type image/png < ${eOutputPath}` + `${maybeShare(eOutputPath)}; rm -f ${eTempPath}`;
        const defaultSaveCommand = `${mkdirCmd} && ${cropCmd} ${eOutputPath} ` + `&& wl-copy --type image/png < ${eOutputPath}` + `${maybeShare(eOutputPath)} ` + `&& notify-send -a "HyprQuickFrame" -i ${eOutputPath} ` + `-h string:image-path:${eOutputPath} "Screenshot Saved" ` + `"Saved to ${picturesDir}"; rm -f ${eTempPath}`;
        const defaultTempCommand = `${cropCmd} ${eTempSnip} ` + `&& wl-copy --type image/png < ${eTempSnip}` + `${maybeShare(eTempSnip)} ` + `&& notify-send -a "HyprQuickFrame" "Screenshot Copied" ` + `"Copied to clipboard${shareTag}"; ` + `rm -f ${eTempPath} ${eTempSnip}`;
        let cmd;
        if (root.editActive)
            cmd = sattyCommand;
        else if (root.tempActive)
            cmd = defaultTempCommand;
        else
            cmd = defaultSaveCommand;
        screenshotProcess.command = ["sh", "-c", cmd];
        screenshotProcess.running = true;
        root.visible = false;
    }

    visible: false
    targetScreen: activeScreen
    Component.onCompleted: {
        const timestamp = Date.now();
        const rand = Math.floor(Math.random() * 100000);
        const path = Quickshell.cachePath(`screenshot-${timestamp}-${rand}.png`);
        tempPath = path;
        captureProcess.command = ["grim", "-l", "0", path];
        captureProcess.running = true;
        connectivityProcess.running = true;
    }

    Theme {
        id: theme
    }

    FileView {
        id: themeFile

        path: Quickshell.shellDir.toString().replace(/^file:\/\//, "") + "/theme.toml"
        onTextChanged: {
            try {
                let rawText = (typeof text === 'function') ? text() : text;
                theme.source = root.parseTOML(rawText);
            } catch (e) {
                console.warn("Failed to parse theme.toml:", e);
            }
        }
    }

    Process {
        id: captureProcess

        running: false
        onExited: (code) => {
            if (code === 0) {
                showTimer.start();
            } else {
                cleanup();
                Qt.quit();
            }
        }
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
        onActivated: {
            cleanup();
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
        onActivated: root.saveScreenshot(0, 0, root.width, root.height)
    }

    Shortcut {
        sequence: "e"
        onActivated: {
            root.editActive = !root.editActive;
            if (root.editActive)
                root.tempActive = false;
        }
    }

    Shortcut {
        sequence: "t"
        onActivated: {
            root.tempActive = !root.tempActive;
            if (root.tempActive)
                root.editActive = false;
        }
    }

    Shortcut {
        sequence: "k"
        onActivated: {
            root.shareActive = !root.shareActive;
            if (root.shareActive && !connectivityProcess.running && root.connectivityStatus !== 0)
                connectivityProcess.running = true;
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
        onExited: (code) => {
            if (code !== 0)
                console.error("Screenshot pipeline failed with exit code:", code);
            Qt.quit();
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim())
                    console.log(this.text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim())
                    console.warn(this.text);
            }
        }
    }

    Process {
        id: connectivityProcess

        command: ["sh", "-c", "kdeconnect-cli -l | grep 'reachable'"]
        onExited: (code) => {
            root.connectivityStatus = (code === 0 ? 1 : 2);
        }
    }

    RegionSelector {
        id: regionSelector

        visible: mode === "region"
        anchors.fill: parent
        dimOpacity: theme.dimOpacity
        borderRadius: theme.borderRadius
        outlineThickness: theme.outlineThickness
        onRegionSelected: (x, y, width, height) => {
            saveScreenshot(x, y, width, height);
        }
    }

    WindowSelector {
        id: windowSelector

        visible: mode === "window"
        anchors.fill: parent
        monitor: root.hyprlandMonitor
        dimOpacity: theme.dimOpacity
        borderRadius: theme.borderRadius
        outlineThickness: theme.outlineThickness
        onRegionSelected: (x, y, width, height) => {
            saveScreenshot(x, y, width, height);
        }
    }

    Rectangle {
        id: segmentedControl

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: theme.bottomMargin
        layer.enabled: true
        height: root.controlHeight
        width: root.targetMenuWidth
        radius: height / 2
        color: theme.barBackground
        border.color: theme.barBorder
        border.width: 1

        Rectangle {
            id: highlight

            width: root.tabItemSize
            height: parent.height - 8
            y: 4
            radius: height / 2
            color: theme.accent
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
                    height: segmentedControl.height - 8
                    visible: width > 0

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData === "temp") {
                                root.tempActive = true;
                                root.editActive = false;
                            } else if (modelData === "edit") {
                                root.editActive = true;
                                root.tempActive = false;
                            } else {
                                root.mode = modelData;
                            }
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
                        color: (modelData === "temp" || modelData === "edit") ? theme.barText : (root.mode === modelData ? theme.accentText : theme.barText)
                        font.weight: (modelData === "temp" || modelData === "edit") ? Font.Medium : (root.mode === modelData ? Font.Bold : Font.Medium)
                        font.pixelSize: 15
                        opacity: tabItem.collapsed ? 0 : 1

                        Behavior on opacity {
                            enabled: root.tempActive || root.editActive

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

        layer.effect: DropShadow {
            transparentBorder: true
            radius: 8
            samples: 16
            color: theme.barShadow
            verticalOffset: 4
        }
    }

    QuickToggle {
        id: editToggleButton

        active: root.editActive
        icon: "󰏫"
        iconColor: theme.toggleEdit
        backgroundColor: theme.toggleBackground
        shadowColor: theme.toggleShadow
        targetX: (root.width - root.targetMenuWidth) / 2 - 15 - width
        targetY: segmentedControl.y + segmentedControl.height / 2
        sourceX: root.width / 2 - 204 + 32
        onClicked: root.editActive = false
    }

    QuickToggle {
        id: tempToggleButton

        active: root.tempActive
        icon: "󰅇"
        iconColor: theme.toggleTemp
        backgroundColor: theme.toggleBackground
        shadowColor: theme.toggleShadow
        targetX: (root.width + root.targetMenuWidth) / 2 + 15
        targetY: segmentedControl.y + segmentedControl.height / 2
        sourceX: root.width / 2 - 204 + 332
        onClicked: root.tempActive = false
    }

    QuickToggle {
        id: shareToggleButton

        active: root.shareActive
        icon: "󰄜"
        iconColor: {
            if (root.connectivityStatus === 1)
                return theme.shareConnected;
            if (root.connectivityStatus === 2)
                return theme.shareErrorIcon;
            return theme.sharePending;
        }
        backgroundColor: root.connectivityStatus === 2 ? theme.shareErrorBackground : theme.toggleBackground
        shadowColor: theme.toggleShadow
        pulse: root.connectivityStatus === 0
        targetX: (root.width + root.targetMenuWidth) / 2 + 15 + (root.tempActive ? 44 + 10 : 0)
        targetY: segmentedControl.y + segmentedControl.height / 2
        sourceX: root.width / 2 + (root.targetMenuWidth / 2) - 22
        onClicked: root.shareActive = false
    }

    Item {
        anchors.fill: parent
        z: 999

        HoverHandler {
            onPointChanged: {
                if (root.mode === "region" && !regionSelector.pressed) {
                    regionSelector.mouseX = point.position.x;
                    regionSelector.mouseY = point.position.y;
                }
                if (root.mode === "window" && !windowSelector.pressed) {
                    windowSelector.mouseX = point.position.x;
                    windowSelector.mouseY = point.position.y;
                }
            }
        }
    }
}
