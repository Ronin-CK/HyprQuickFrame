# HyprQuickFrame

A polished, native screenshot utility for Hyprland built with **Quickshell**.
Features a modern overlay UI with shader-based dimming, bouncy animations, and intelligent window snapping.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Wayland](https://img.shields.io/badge/Wayland-Native-green.svg)
![Quickshell](https://img.shields.io/badge/Built%20With-Quickshell-cba6f7.svg)
![Hyprland](https://img.shields.io/badge/Desktop-Hyprland-blue.svg)
![Nix](https://img.shields.io/badge/Nix-Flake-blue.svg)

## ✨ Features

* **Capture Modes:** Region (drag to select), Window (hover to select), and Temp (clipboard-only).
* **KDE Connect** Push screenshots directly to your phone.
* **Editor Support:** Integrates with `satty` or `gradia` for immediate post-capture annotation.

## 🎥 Demo

<details>
<summary>Click to watch the demo</summary>
<video src="https://github.com/user-attachments/assets/1c15ba34-3571-4f62-8dc2-4d1997ce41e2" controls="controls"> </video>
<video src="https://github.com/user-attachments/assets/904066a7-3a67-4795-8353-0461219386a7" controls="controls"> </video>
</details>

## ⌨️ Shortcuts

* `r`: Region Mode
* `w`: Window Mode
* `s`: Full Screen Capture
* `t`: Toggle Temp Mode
* `k`: Toggle KDE Share
* `Esc,q`: Quit

## 📦 Requirements

1. **[Quickshell](https://github.com/outfoxxed/quickshell)**
2. `grim` (Screen capture)
3. `imagemagick` (Image processing)
4. `wl-clipboard` (Clipboard support)
5. `satty` or `gradia` (Optional: for Editor Mode)
6. `kdeconnect` (Optional: for Share Mode)
7. `libnotify` (For notifications)

## 🚀 Installation

### 1. Install System Dependencies

**Arch Linux:**

```bash
sudo pacman -S grim imagemagick wl-clipboard libnotify # Add satty or gradia depending on preference
```

### 2. Install Quickshell

```bash
yay -S quickshell-git
```

### 3. Install HyprQuickFrame

**AUR (Recommended):** Maintainer: [knownasnaffy](https://github.com/knownasnaffy)

```bash
yay -S hyprquickframe-git
```

**Manual:**

1. Clone Repository

```bash
git clone https://github.com/Ronin-CK/HyprQuickFrame ~/.config/quickshell/HyprQuickFrame
```

2. Basic Test

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

# Pre-selects the "window" mode (options: region, window)
bind = SUPER SHIFT, W, exec, env HQF_MODE=window quickshell -c HyprQuickFrame -n

# Pre-selects the "temp" action (options: temp, edit, share) natively
bind = SUPER SHIFT, C, exec, env HQF_ACTION=temp quickshell -c HyprQuickFrame -n
```

## 🛠️ Theme Configuration

Copy the default `theme.toml` to `~/.config/hyprquickframe/theme.toml` to customize. Changes apply instantly!

The application checks for `theme.toml` in this order:
1. `~/.config/hyprquickframe/theme.toml` (Recommended)
2. `~/.config/quickshell/HyprQuickFrame/theme.toml`
3. `[Install Directory]/theme.toml`

### Global Options

Configure animations and your preferred annotation tool inside `theme.toml`:

```toml
# Enable or disable animations (default: true)
animations = true
# Tool to use for the "edit" screenshot action (e.g., "satty" or "gradia")
annotationTool = "satty"
```

## 🌌 Noctalia Support

HyprQuickFrame can automatically sync its colors with your wallpaper using [Noctalia](https://github.com/Ronin-CK/Noctalia).

### Setup

1. Make the sync script executable:
   ```bash
   chmod +x /path/to/HyprQuickFrame/scripts/sync_theme.py
   ```
2. Add it to your Noctalia `wallpaperChange` hook in `~/.config/noctalia/settings.json`:
   ```json
   "hooks": {
       "enabled": true,
       "wallpaperChange": "python3 /path/to/HyprQuickFrame/scripts/sync_theme.py"
   }
   ```
3. **Dynamic Toggle Colors (Optional):** To allow toggle buttons to sync dynamically, delete or comment out the `background` key under the `[toggle]` section in your `theme.toml`.


## ⚖️ License & Attribution

This project is licensed under the **MIT License**.

* **Original Work:** [HyprQuickshot](https://github.com/JamDon2/hyprquickshot) © 2025 JamDon2.
* **Enhancements & Modifications:** © 2026 Chandra Kant (Ronin-CK).

HyprQuickFrame began as a fork of HyprQuickshot. It has been significantly extended with a custom Quickshell UI and an integrated editor mode. We honor the original work of JamDon2 while providing a modernized experience for Hyprland users.
