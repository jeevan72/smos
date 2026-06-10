# How to Install and Remove Software

## Using the Software Center (Easiest)

1. Open **Software Center** from the application menu
2. **Browse** categories or **search** for the app you want
3. Click **Install**
4. Enter your password when prompted

## Install via Terminal

```bash
# Search for a package
apt search firefox

# Install a package
sudo apt install firefox

# Install multiple packages at once
sudo apt install vlc gimp libreoffice

# Remove a package (keeps settings)
sudo apt remove firefox

# Remove a package completely (removes settings too)
sudo apt purge firefox

# Remove unused dependencies
sudo apt autoremove -y
```

## Popular Applications

| Application | Install Command | Description |
|------------|----------------|-------------|
| Firefox | `sudo apt install firefox` | Web browser |
| VLC | `sudo apt install vlc` | Video player |
| GIMP | `sudo apt install gimp` | Image editor |
| LibreOffice | `sudo apt install libreoffice` | Office suite |
| Thunderbird | `sudo apt install thunderbird` | Email client |
| OBS Studio | `sudo apt install obs-studio` | Screen recording |

## Snap Packages

Some apps are available as Snap packages:

```bash
# Install a snap
sudo snap install spotify

# List installed snaps
snap list

# Remove a snap
sudo snap remove spotify
```

## Flatpak Packages

```bash
# Install Flatpak support
sudo apt install flatpak

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install a Flatpak app
flatpak install flathub com.spotify.Client
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Package not found" | Run `sudo apt update` first |
| "Dependency problems" | Run `sudo apt --fix-broken install` |
| "Permission denied" | Make sure to use `sudo` before the command |
| App won't start after install | Try running it from terminal to see errors |
