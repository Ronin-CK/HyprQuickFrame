# HyprShot


https://github.com/user-attachments/assets/904066a7-3a67-4795-8353-0461219386a7



## Dependecies
```bash
pacman -S grim imagemagick wl-clipboard
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
quickshell -c hyprquickshot -n
```
### Add this line to you hyprland.conf
```bash
bind = , Print, exec, quickshell -c hyprquickshot -n
```

## Credit
[hyprquickshot](https://github.com/JamDon2/hyprquickshot)
