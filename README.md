# HyprQuickFrame

A polished, native screenshot utility for Hyprland built with **Quickshell**. 
Features a modern overlay UI with shader-based dimming, "juicy" bouncy animations, and intelligent window snapping.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Wayland](https://img.shields.io/badge/Wayland-Native-green.svg)
![Quickshell](https://img.shields.io/badge/Built%20With-Quickshell-cba6f7.svg)
![Hyprland](https://img.shields.io/badge/Desktop-Hyprland-blue.svg)
![Nix](https://img.shields.io/badge/Nix-Flake-blue.svg)

## ✨ Features

*   **Three Modes**:
    *   **Region**: Drag to select an area. **Left-click** automatically captures the full screen, and **Right-click** resets your selection.
    *   **Window**: Hovering over a window highlights it—click to capture.
    *   **Temp**: A "clipboard-only" mode. Great for quick sharing when you don't want to clutter your disk.
*   **KDE Connect**: Push screenshots (and your clipboard) directly to your phone.
*   **Fast**: It launches instantly. No waiting.
*   **Editor Support**: If you have `satty` installed, you can annotate right after capturing.

## ⌨️ Shortcuts

*   `r`: Region Mode
*   `w`: Window Mode
*   `s`: Full Screen Capture
*   `t`: Toggle Temp Mode
*   `k`: Toggle KDE Share
*   `Escape`: Quit

## 🎥 Demo
https://github.com/user-attachments/assets/1cb331a7-c9d2-474f-96e2-d78a18bd3a5c


## 📦 Requirements

1.  **[Quickshell](https://github.com/outfoxxed/quickshell)** (0.2.1+)
2.  `grim` (Screen capture)
3.  `imagemagick` (Image processing)
4.  `wl-clipboard` (Clipboard support)
5.  `satty` (Optional: for Editor Mode)
6.  `kdeconnect` (Optional: for Share Mode)
7.  `libnotify` (For notifications)

## 🚀 Installation

### 1. Install System Dependencies
**Arch Linux:**
```bash
sudo pacman -S grim imagemagick wl-clipboard satty libnotify
```

### 2. Install Quickshell
```bash
yay -S quickshell-git
```

### 3. Clone Repository
```bash
git clone https://github.com/Ronin-CK/HyprQuickFrame ~/.config/quickshell/HyprQuickFrame
```

### 4. Basic Test
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

## ⚙️ Configuration (Hyprland)

Add the following keybinding to your `hyprland.conf`:

```ini
# Opens HyprQuickFrame - Decided on-the-fly whether to Edit, Save, or Copy
bind = SUPER SHIFT, S, exec, quickshell -c HyprQuickFrame -n
```

## 🛠️ Theme Configuration

You can customize the look and feel by editing `theme.toml`. The application looks for the configuration file in the following order:

1.  `~/.config/hyprquickframe/theme.toml` (Recommended for user customization)
2.  `~/.config/quickshell/HyprQuickFrame/theme.toml`
3.  `[Install Directory]/theme.toml` (Default fallback)

Copy the default `theme.toml` to `~/.config/hyprquickframe/theme.toml` and edit it to your liking. New colors are applied instantly!

## ⚖️ License & Attribution

This project is licensed under the **MIT License**.

* **Original Work:** [HyprQuickshot](https://github.com/JamDon2/hyprquickshot) © 2025 JamDon2.
* **Enhancements & Modifications:** © 2026 Chandra Kant (Ronin-CK).

HyprQuickFrame began as a fork of HyprQuickshot. It has been significantly extended with a custom Quickshell UI and an integrated editor mode. We honor the original work of JamDon2 while providing a modernized experience for Hyprland users.
