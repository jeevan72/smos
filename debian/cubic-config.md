# Cubic Configuration Guide — SimpleMode OS

## What is Cubic?

**Cubic** (Custom Ubuntu ISO Creator) is a GUI tool that lets you customize Ubuntu/Debian ISO images. We use it to create SimpleMode OS from a base Ubuntu image.

## Step 1: Install Cubic

```bash
sudo apt-add-repository universe
sudo apt-add-repository ppa:cubic-wizard/release
sudo apt update
sudo apt install cubic
```

## Step 2: Create Project

1. Launch Cubic
2. Select a **project directory** (e.g., `~/cubic-project`)
3. Select the **base Ubuntu ISO** (Ubuntu 24.04 LTS recommended)
4. Click **Next** to extract the ISO

## Step 3: Customize (Inside Chroot)

Once inside the chroot terminal, run these commands:

### Apply Branding

```bash
# Copy our custom os-release file
cp /path/to/debian/branding/os-release /etc/os-release

# Set hostname
echo "simplemode" > /etc/hostname
```

### Install Packages

```bash
# Update package list
apt update

# Install our package list
xargs -a /path/to/debian/packages.list apt install -y

# Remove unwanted packages
apt remove -y gnome-games aisleriot gnome-mines gnome-sudoku
```

### Set Wallpaper

```bash
# Copy wallpapers
cp /path/to/debian/wallpapers/* /usr/share/backgrounds/

# Set default wallpaper (for GNOME)
cat > /usr/share/glib-2.0/schemas/99_simplemode.gschema.override << EOF
[org.gnome.desktop.background]
picture-uri='file:///usr/share/backgrounds/simplemode-wallpaper.png'
picture-uri-dark='file:///usr/share/backgrounds/simplemode-wallpaper.png'
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas/
```

### Install Boot Splash

```bash
# Copy Plymouth theme
cp -r /path/to/debian/branding/plymouth/simplemode /usr/share/plymouth/themes/

# Set as default theme
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
    /usr/share/plymouth/themes/simplemode/simplemode.plymouth 200

update-alternatives --set default.plymouth \
    /usr/share/plymouth/themes/simplemode/simplemode.plymouth

update-initramfs -u
```

### Set Up Welcome Screen (First Boot)

```bash
# Copy welcome script
cp /path/to/debian/welcome/welcome.sh /usr/local/bin/simplemode-welcome
chmod +x /usr/local/bin/simplemode-welcome

# Create autostart entry for first boot
mkdir -p /etc/skel/.config/autostart
cat > /etc/skel/.config/autostart/simplemode-welcome.desktop << EOF
[Desktop Entry]
Type=Application
Name=SimpleMode Welcome
Exec=/usr/local/bin/simplemode-welcome
X-GNOME-Autostart-enabled=true
EOF
```

## Step 4: Generate ISO

1. Click **Next** in Cubic
2. Choose compression type (gzip recommended for speed)
3. Wait for ISO generation
4. Test the ISO in a virtual machine (VirtualBox/QEMU)

## Step 5: Test

```bash
# Quick test with QEMU
qemu-system-x86_64 -m 4096 -cdrom simplemode-os.iso -boot d
```
