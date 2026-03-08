/*
 * Copyright (c) 2026 Ronin-CK
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "components"

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
    property string lastSavedPath: ""
    property string lastTimestamp: ""
    readonly property real targetMenuWidth: (modes.length - (editActive ? 1 : 0) - (tempActive ? 1 : 0)) * 100 + 8

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
        console.log("Parsed TOML:", JSON.stringify(result));
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

    function runPostSaveHook() {
        const hook = theme.postSaveHook;
        if (!hook || !root.lastSavedPath)
            return ;

        const filePath = root.lastSavedPath;
        const fileName = filePath.substring(filePath.lastIndexOf('/') + 1);
        const dirPath = filePath.substring(0, filePath.lastIndexOf('/'));
        let cmd = hook;
        cmd = cmd.replace(/%f/g, shellEscape(filePath));
        cmd = cmd.replace(/%n/g, shellEscape(fileName));
        cmd = cmd.replace(/%d/g, shellEscape(dirPath));
        cmd = cmd.replace(/%t/g, shellEscape(root.lastTimestamp));
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function saveScreenshot(x, y, width, height) {
        const crop = calculateCrop(x, y, width, height);
        const picturesBase = Quickshell.env("XDG_PICTURES_DIR") || (Quickshell.env("HOME") + "/Pictures");
        const picturesDir = picturesBase + "/Screenshots";
        const now = new Date();
        const timestamp = Qt.formatDateTime(now, "yyyy-MM-dd_hh-mm-ss");
        const outputPath = `${picturesDir}/screenshot-${timestamp}.png`;
        root.lastTimestamp = timestamp;
        root.lastSavedPath = root.tempActive ? "" : outputPath;
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
        const sattyCommand = `${mkdirCmd} && ${cropCmd} png:- ` + `| satty --filename - ` + `--output-filename ${eOutputPath} --early-exit --init-tool brush ` + `&& wl-copy --type image/png < ${eOutputPath}` + `${maybeShare(eOutputPath)}; rm -f ${eTempPath}`;
        const gradiaCommand = `${mkdirCmd} && ${cropCmd} ${eOutputPath} && hyprctl dispatch exec -- "gradia ${eOutputPath} || flatpak run be.alexandervanhee.gradia ${eOutputPath}"; sleep 0.5; rm -f ${eTempPath}`;
        const defaultSaveCommand = `${mkdirCmd} && ${cropCmd} ${eOutputPath} ` + `&& wl-copy --type image/png < ${eOutputPath}` + `${maybeShare(eOutputPath)} ` + `&& notify-send -a "HyprQuickFrame" -i ${eOutputPath} ` + `-h string:image-path:${eOutputPath} "Screenshot Saved" ` + `"Saved to ${picturesDir}"; rm -f ${eTempPath}`;
        const defaultTempCommand = `${cropCmd} ${eTempSnip} ` + `&& wl-copy --type image/png < ${eTempSnip}` + `${maybeShare(eTempSnip)} ` + `&& notify-send -a "HyprQuickFrame" "Screenshot Copied" ` + `"Copied to clipboard${shareTag}"; ` + `rm -f ${eTempPath} ${eTempSnip}`;
        let cmd;
        console.log("Evaluated annotationTool value:", theme.annotationTool);
        if (root.editActive)
            cmd = theme.annotationTool === "gradia" ? gradiaCommand : sattyCommand;
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

    Theme {
        id: theme
    }

    FileView {
        id: themeFile

        property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")
        property string userPath1: configHome + "/hyprquickframe/theme.toml"
        property string userPath2: configHome + "/quickshell/HyprQuickFrame/theme.toml"
        property string defaultPath: Quickshell.shellDir.toString().replace(/^file:\/\//, "") + "/theme.toml"

        path: defaultPath
        Component.onCompleted: {
            themePathCheck.command = ["sh", "-c", `if [ -f "${userPath1}" ]; then echo "${userPath1}";
                 elif [ -f "${userPath2}" ]; then echo "${userPath2}";
                 else echo "${defaultPath}"; fi`];
            themePathCheck.running = true;
        }
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
        id: themePathCheck

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                themeFile.path = this.text.trim();
                console.log("Theme loaded from:", themeFile.path);
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
            else
                root.runPostSaveHook();
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
        globalAnimations: theme.animations
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
        animateSelection: theme.animations
        onRegionSelected: (x, y, width, height) => {
            saveScreenshot(x, y, width, height);
        }
    }

    ControlBar {
        id: segmentedControl

        modes: root.modes
        mode: root.mode
        tempActive: root.tempActive
        editActive: root.editActive
        theme: theme
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: theme.bottomMargin
        onModeSelected: (m) => {
            return root.mode = m;
        }
        onTempToggled: {
            root.tempActive = true;
            root.editActive = false;
        }
        onEditToggled: {
            root.editActive = true;
            root.tempActive = false;
        }
    }

    QuickToggle {
        id: editToggleButton

        active: root.editActive
        icon: "" // "󰏫"
        imageSource: Qt.resolvedUrl("assets/icons/edit.svg")
        iconColor: theme.toggleEdit
        backgroundColor: theme.toggleBackground
        shadowColor: theme.toggleShadow
        borderColor: theme.barBorder
        borderWidth: 1
        targetX: (root.width - root.targetMenuWidth) / 2 - 15 - width
        targetY: segmentedControl.y + segmentedControl.height / 2
        sourceX: root.width / 2 - 204 + 32
        onClicked: root.editActive = false
    }

    QuickToggle {
        id: tempToggleButton

        active: root.tempActive
        icon: "" // "󰏫"
        imageSource: Qt.resolvedUrl("assets/icons/temp.svg")
        iconColor: theme.toggleTemp
        backgroundColor: theme.toggleBackground
        shadowColor: theme.toggleShadow
        borderColor: theme.barBorder
        borderWidth: 1
        targetX: (root.width + root.targetMenuWidth) / 2 + 15
        targetY: segmentedControl.y + segmentedControl.height / 2
        sourceX: root.width / 2 - 204 + 332
        onClicked: root.tempActive = false
    }

    QuickToggle {
        id: shareToggleButton

        active: root.shareActive
        icon: "" // "󰄜"
        imageSource: root.connectivityStatus === 2 ? Qt.resolvedUrl("assets/icons/share-error.svg") : Qt.resolvedUrl("assets/icons/share.svg")
        iconColor: {
            if (root.connectivityStatus === 1)
                return theme.shareConnected;

            if (root.connectivityStatus === 2)
                return theme.shareErrorIcon;

            return theme.sharePending;
        }
        backgroundColor: root.connectivityStatus === 2 ? theme.shareErrorBackground : theme.toggleBackground
        shadowColor: theme.toggleShadow
        borderColor: theme.barBorder
        borderWidth: 1
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
