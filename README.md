# HyprShot

A polished, native screenshot utility for Hyprland built with **Quickshell**.
Features a modern overlay UI with shader-based dimming, smooth spring animations, and intelligent window snapping.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Wayland](https://img.shields.io/badge/Wayland-Native-green.svg)
![Quickshell](https://img.shields.io/badge/Built%20With-Quickshell-cba6f7.svg)

## ✨ Features

* **3 Capture Modes:**
    * **Region:** Freehand selection with alignment guides.
    * **Window:** Automatically snaps to open Hyprland windows.
    * **Screen:** Instant full-screen capture.
* **Modern UI:**
    * Floating "Pill" control bar to switch modes.
    * Smooth spring animations for selection resizing.
    * Fragment shader for smooth dimming and rounded corners.
* **Smart Saving:** Automatically saves to your `Pictures/Screenshots` folder AND copies to clipboard.

🎥 Demo

https://github.com/user-attachments/assets/904066a7-3a67-4795-8353-0461219386a7


## 📦 Requirements

1.  **[Quickshell](https://github.com/outfoxxed/quickshell)** (The shell environment)
2.  `grim` (For capturing the screen)
3.  `imagemagick` (For cropping the screenshot)
4.  `wl-clipboard` (For copying to clipboard)

## 🚀 Installation

### 1. Install System Dependencies
**Arch Linux:**
```bash
sudo pacman -S grim imagemagick wl-clipboard
```
```bash
yay -S quickshell
```
## Clone Repo
```bash
git clone https://github.com/Ronin-CK/HyprShot ~/.config/quickshell/HyprShot
```
### run on terminal (not necessary )

```bash
quickshell -c HyprShot -n
```
### Add this line to you hyprland.conf
```bash
bind = , Print, exec, quickshell -c HyprShot -n
```

## Credit
[hyprquickshot](https://github.com/JamDon2/hyprquickshot)
