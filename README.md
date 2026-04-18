# HyprQuickFrame

A polished, native screenshot utility for Hyprland built with **Quickshell**.
Features a modern overlay UI with shader-based dimming, bouncy animations, and intelligent window snapping.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Wayland](https://img.shields.io/badge/Wayland-Native-green.svg)
![Quickshell](https://img.shields.io/badge/Built%20With-Quickshell-cba6f7.svg)
![Hyprland](https://img.shields.io/badge/Desktop-Hyprland-blue.svg)
![Nix](https://img.shields.io/badge/Nix-Flake-blue.svg)

## ✨ Features

* **Three Modes**:
  * **Region**: Drag to select an area. **Left-click** automatically captures the full screen, and **Right-click** resets your selection.
  * **Window**: Hovering over a window highlights it—click to capture.
  * **Temp**: A "clipboard-only" mode. Great for quick sharing when you don't want to clutter your disk.
* **KDE Connect**: Push screenshots (and your clipboard) directly to your phone..
* **Editor Support**: Choose between `satty` (default, fast utilitarian) or `gradia` (polished, modern Wayland support) to annotate right after capturing.

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

**AUR (Recommended):**

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

You can customize the look and feel by editing `theme.toml`. The application looks for the configuration file in the following order:

1. `~/.config/hyprquickframe/theme.toml` (Recommended for user customization)
2. `~/.config/quickshell/HyprQuickFrame/theme.toml`
3. `[Install Directory]/theme.toml` (Default fallback)

Copy the default `theme.toml` to `~/.config/hyprquickframe/theme.toml` and edit it to your liking. New colors are applied instantly!

### Global Options

You can toggle animations globally and configure the annotation tool:

```toml
# Enable or disable animations (default: true)
animations = true
# Tool to use for the "edit" screenshot action (e.g., "satty" or "gradia")
annotationTool = "satty"
```

## 🌌 Noctalia Support

 This project includes built-in support for [Noctalia](https://github.com/Ronin-CK/Noctalia), allowing HyprQuickFrame to automatically sync with your active wallpaper's color scheme.

### Features

* **Automatic Theme Sync**: Your accent, bar, and toggle colors update whenever you change your wallpaper in Noctalia.
* **Smart Mapping**: Intelligently maps Noctalia's material design colors (`mPrimary`, `mSecondary`, etc.) to HyprQuickFrame's theme elements.
* **Customizable**: You can disable specific sync components (like the bar background) by editing the sync script.

### Enabling Dynamic Toggle Colors

 By default, `theme.toml` may have a hardcoded background color for the toggle buttons (e.g., `background = "white"` under `[toggle]`).
 To make the toggle buttons automatically sync with your `accent` color (whether set by Noctalia, `pywal`, `matugen`, or any other script):

1. Open your active `theme.toml`.
2. Find the `[toggle]` section.
3. Delete or comment out the `background` key.

```toml
 [toggle]
 # Remove or comment out this line:
 # background = "white"
```

 Now, the toggles will dynamically follow whatever `accent` color is set by your external tools!

### Setup

1. Ensure you have `Noctalia` installed.
2. The sync script is located at `scripts/sync_theme.py` in the repository. Make sure it is executable:

   ```bash
   chmod +x scripts/sync_theme.py
   ```
3. Configure Noctalia's `wallpaperChange` hook to run the script in `~/.config/noctalia/settings.json`:

   ```json
   "hooks": {
       "enabled": true,
       "wallpaperChange": "python3 /home/vishal/config/quickshell/HyprQuickFrame/scripts/sync_theme.py"
   }
   ```

   > [!NOTE]
   > Replace `/home/vishal/config/quickshell/HyprQuickFrame/` with the actual path to your repository if it differs.
   >


## ⚖️ License & Attribution

This project is licensed under the **MIT License**.

* **Original Work:** [HyprQuickshot](https://github.com/JamDon2/hyprquickshot) © 2025 JamDon2.
* **Enhancements & Modifications:** © 2026 Chandra Kant (Ronin-CK).

HyprQuickFrame began as a fork of HyprQuickshot. It has been significantly extended with a custom Quickshell UI and an integrated editor mode. We honor the original work of JamDon2 while providing a modernized experience for Hyprland users.
