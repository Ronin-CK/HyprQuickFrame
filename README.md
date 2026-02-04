# HyprQuickFrame

A polished, native screenshot utility for Hyprland built with **Quickshell**.
Features a modern overlay UI with shader-based dimming, smooth spring animations, and intelligent window snapping.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Wayland](https://img.shields.io/badge/Wayland-Native-green.svg)
![Quickshell](https://img.shields.io/badge/Built%20With-Quickshell-cba6f7.svg)
![Hyprland](https://img.shields.io/badge/Desktop-Hyprland-blue.svg)
![Nix](https://img.shields.io/badge/Nix-Flake-blue.svg)

## ✨ Features

*   **3 Capture Modes:**
    *   **Region:** Freehand selection with alignment guides.
    *   **Window:** Automatically snaps to open Hyprland windows.
    *   **Screen:** Instant full-screen capture.
*   **Modern UI:**
    *   Floating "Pill" control bar to switch modes.
    *   **Animations:** Smooth spring animations for selection resizing.
    *   **Visuals:** Fragment shader for smooth dimming and rounded corners.
*   **Smart Saving:**
    *   **Quick Save:** Automatically saves to `Pictures/Screenshots` and copies to clipboard.
    *   **Notifications:** System notification with preview upon save.
    *   **Editor Mode:** Opens the screenshot in **Satty** for annotation (Optional).

## 🎥 Demo

<details>
<summary>Click to watch the demo</summary>
<video src="https://github.com/user-attachments/assets/1c15ba34-3571-4f62-8dc2-4d1997ce41e2" controls="controls"> </video>
<video src="https://github.com/user-attachments/assets/904066a7-3a67-4795-8353-0461219386a7" controls="controls"> </video>
</details>

## 📦 Requirements

1.  **[Quickshell](https://github.com/outfoxxed/quickshell)** (The shell environment)
2.  `grim` (Screen capture)
3.  `imagemagick` (Image processing)
4.  `wl-clipboard` (Clipboard support)
5.  `libnotify` (Desktop notifications)
5.  `satty` (Optional: for Editor Mode)

## 🚀 Installation

### 1. Install System Dependencies
**Arch Linux:**
```bash
sudo pacman -S grim imagemagick wl-clipboard satty libnotify
```

### 2. Install Quickshell
```bash
yay -S quickshell
```

### 3. Clone Repository
```bash
git clone https://github.com/Ronin-CK/HyprQuickFrame ~/.config/quickshell/HyprQuickFrame
```

### 4. Basic Test
Run this in your terminal to verify installation:
```bash
quickshell -c HyprQuickFrame -n
```

## ❄️ Nix Installation

This project includes a `flake.nix` for easy installation.

**Run directly:**
```bash
nix run github:Ronin-CK/HyprQuickFrame
```

**Install in configuration:**
Add to your inputs:
```nix
inputs.HyprQuickFrame.url = "github:Ronin-CK/HyprQuickFrame";
inputs.HyprQuickFrame.inputs.nixpkgs.follows = "nixpkgs";
```
Then add to your packages:
```nix
environment.systemPackages = [ inputs.HyprQuickFrame.packages.${pkgs.system}.default ];
```

**Using Overlay:**
```nix
nixpkgs = {
  overlays = [
    inputs.HyprQuickFrame.overlays.default
  ];
};
```
Then install via `pkgs.hyprquickframe`.


## ⚙️ Configuration (Hyprland)

Add the following keybindings to your `hyprland.conf`:

```ini
# 1. Standard Screenshot (Quick Save)
# Saves directly to ~/Pictures/Screenshots and copies to clipboard
bind = SUPER SHIFT, S, exec, quickshell -c HyprQuickFrame -n

# 2. Editor Mode (Annotation)
# Opens the screenshot in Satty for editing before saving
# Requires: satty
bind = SUPER CTRL SHIFT, S, exec, HYPRQUICKFRAME_EDITOR=1 quickshell -c HyprQuickFrame -n
```

## Credit
*   [hyprquickshot](https://github.com/JamDon2/hyprquickshot) - Inspiration
