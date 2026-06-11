#!/bin/bash
#======================================================
# SimpleMode OS — Chroot Setup Script
# Run this INSIDE the Cubic chroot terminal.
#
# This script customizes the Ubuntu filesystem:
#   - Applies branding (os-release, hostname)
#   - Installs packages
#   - Sets wallpaper
#   - Installs SimpleMode tools (wizard, assistant)
#   - Sets up first-boot welcome screen
#======================================================

set -e

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  🐧 SimpleMode OS — Chroot Customization    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# The directory where the script is located (the git clone directory)
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIMPLEMODE_DIR="/opt/simplemode"

#------------------------------------------------------
# 1. Apply Branding
#------------------------------------------------------
echo "━━━ Step 1/6: Applying Branding ━━━"

# Custom os-release
if [ -f "${PROJECT_DIR}/debian/branding/os-release" ]; then
    cp "${PROJECT_DIR}/debian/branding/os-release" /etc/os-release
    echo "[✓] os-release updated"
else
    # Write it inline
    cat > /etc/os-release <<'OSEOF'
PRETTY_NAME="SimpleMode OS 1.0"
NAME="SimpleMode OS"
VERSION_ID="1.0"
VERSION="1.0 (Adaptive)"
VERSION_CODENAME=adaptive
ID=simplemode
ID_LIKE=ubuntu debian
HOME_URL="https://github.com/jeevan72/smos"
SUPPORT_URL="https://github.com/jeevan72/smos/issues"
BUG_REPORT_URL="https://github.com/jeevan72/smos/issues"
UBUNTU_CODENAME=noble
OSEOF
    echo "[✓] os-release created"
fi

# Hostname
echo "simplemode" > /etc/hostname
echo "[✓] Hostname set to: simplemode"

# LSB release
if [ -f /etc/lsb-release ]; then
    cat > /etc/lsb-release <<'LSBEOF'
DISTRIB_ID=SimpleMode
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=adaptive
DISTRIB_DESCRIPTION="SimpleMode OS 1.0"
LSBEOF
    echo "[✓] lsb-release updated"
fi

# GRUB Branding
if [ -f /etc/default/grub ]; then
    sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="SMOS"/g' /etc/default/grub
    update-grub 2>/dev/null || true
    echo "[✓] GRUB bootloader branded as SMOS"
fi

#------------------------------------------------------
# 2. Update & Install Packages
#------------------------------------------------------
echo ""
echo "━━━ Step 2/6: Installing Packages ━━━"

# Remove the cdrom repository which causes apt update to fail inside the Cubic chroot
sed -i '/cdrom/d' /etc/apt/sources.list 2>/dev/null || true
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    sed -i 's/.*cdrom.*//g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true
fi

apt update || echo "[!] apt update had some errors, continuing anyway..."

# Core packages
apt install -y \
    python3 python3-pip python3-venv \
    whiptail dialog figlet \
    firefox vlc gimp libreoffice \
    gnome-tweaks gnome-shell-extensions gnome-shell-extension-dash-to-panel gnome-shell-extension-ubuntu-dock \
    synaptic gdebi timeshift \
    htop neofetch curl wget git nano \
    network-manager network-manager-gnome \
    gnome-accessibility-themes orca onboard \
    fonts-noto fonts-liberation \
    cups system-config-printer hplip printer-driver-all \
    flatpak \
    2>/dev/null || echo "[!] Some packages may not be available"

echo "[✓] Packages installed"

#------------------------------------------------------
# 3. Remove Unwanted Packages
#------------------------------------------------------
echo ""
echo "━━━ Step 3/6: Removing Bloat ━━━"

apt remove -y \
    gnome-games aisleriot gnome-mines gnome-sudoku \
    gnome-mahjongg 2>/dev/null || true

apt autoremove -y 2>/dev/null || true
echo "[✓] Bloat removed"

#------------------------------------------------------
# 4. Install SimpleMode Tools
#------------------------------------------------------
echo ""
echo "━━━ Step 4/6: Installing SimpleMode Tools ━━━"

mkdir -p "${SIMPLEMODE_DIR}"

# Copy simplemode tools from the repository
cp -r "${PROJECT_DIR}/assistant" "${SIMPLEMODE_DIR}/"
cp -r "${PROJECT_DIR}/knowledge" "${SIMPLEMODE_DIR}/"
cp "${PROJECT_DIR}/simplemode-assistant.sh" "${SIMPLEMODE_DIR}/"
cp "${PROJECT_DIR}/simplemode-wizard.sh" "${SIMPLEMODE_DIR}/"
echo "[✓] SimpleMode files copied to ${SIMPLEMODE_DIR}"

# Set up Python venv for the assistant
python3 -m venv ${SIMPLEMODE_DIR}/venv
${SIMPLEMODE_DIR}/venv/bin/pip install -q rapidfuzz rich markdown 2>/dev/null || true
echo "[✓] Python environment set up"

# Create launcher script in /usr/local/bin
cat > /usr/local/bin/simplemode-assistant <<'LAUNCHEOF'
#!/bin/bash
source /opt/simplemode/venv/bin/activate
PROFILE_MODE="beginner"
if [ -f "$HOME/.simplemode-profile" ]; then
    source "$HOME/.simplemode-profile"
    PROFILE_MODE="${USER_TYPE:-beginner}"
fi
python3 /opt/simplemode/assistant/assistant.py \
    --knowledge /opt/simplemode/knowledge \
    --mode "$PROFILE_MODE"
LAUNCHEOF
chmod +x /usr/local/bin/simplemode-assistant

cat > /usr/local/bin/simplemode-wizard <<'WIZEOF'
#!/bin/bash
bash /opt/simplemode/simplemode-wizard.sh
WIZEOF
chmod +x /usr/local/bin/simplemode-wizard

echo "[✓] Commands installed: simplemode-assistant, simplemode-wizard"

# Configure command interceptor globally in /etc/bash.bashrc
cat >> /etc/bash.bashrc <<'GLOBALBASHRC'

# --- SimpleMode OS Command Interceptor ---
if [ -f "/opt/simplemode/assistant/interceptor.py" ]; then
    # Backup original command_not_found_handle if it exists and hasn't been backed up yet
    if declare -f command_not_found_handle >/dev/null && ! declare -f original_command_not_found_handle >/dev/null; then
        eval "original_$(declare -f command_not_found_handle)"
    fi

    command_not_found_handle() {
        /opt/simplemode/venv/bin/python3 "/opt/simplemode/assistant/interceptor.py" "$@"
        local status=$?
        if [ $status -eq 127 ]; then
            if declare -f original_command_not_found_handle >/dev/null; then
                original_command_not_found_handle "$@"
            else
                echo "bash: $1: command not found" >&2
                return 127
            fi
        else
            return $status
        fi
    }
fi
GLOBALBASHRC
echo "[✓] Command interceptor configured in /etc/bash.bashrc"

#------------------------------------------------------
# 5. Desktop Customization (GNOME)
#------------------------------------------------------
echo ""
echo "━━━ Step 5/6: Desktop Customization ━━━"

# Install Wallpaper
if [ -f "${PROJECT_DIR}/debian/branding/wallpapers/smos-default.png" ]; then
    mkdir -p /usr/share/backgrounds
    cp "${PROJECT_DIR}/debian/branding/wallpapers/smos-default.png" /usr/share/backgrounds/
    echo "[✓] Default wallpaper installed"
fi

# GNOME schema overrides for default settings
mkdir -p /usr/share/glib-2.0/schemas/
cat > /usr/share/glib-2.0/schemas/99_simplemode.gschema.override <<'SCHEMAEOF'
[org.gnome.desktop.interface]
gtk-theme='Adwaita-dark'
icon-theme='Adwaita'
font-name='Noto Sans 11'
document-font-name='Noto Sans 11'
monospace-font-name='Noto Sans Mono 11'

[org.gnome.desktop.background]
picture-uri='file:///usr/share/backgrounds/smos-default.png'
picture-uri-dark='file:///usr/share/backgrounds/smos-default.png'
picture-options='zoom'

[org.gnome.desktop.wm.preferences]
titlebar-font='Noto Sans Bold 11'
button-layout='close,minimize,maximize:'

[org.gnome.shell]
favorite-apps=['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'libreoffice-writer.desktop', 'org.gnome.Settings.desktop']
SCHEMAEOF

glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
echo "[✓] GNOME defaults configured"

#------------------------------------------------------
# 6. First-Boot Welcome / Onboarding
#------------------------------------------------------
echo ""
echo "━━━ Step 6/6: Setting Up First-Boot Welcome ━━━"

# Copy welcome script
cat > /usr/local/bin/simplemode-welcome <<'WELCOMEEOF'
#!/bin/bash
WELCOME_FLAG="$HOME/.simplemode-welcomed"
if [ -f "$WELCOME_FLAG" ]; then
    exit 0
fi
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    exit 0
fi
# Run the onboarding wizard in a terminal
if command -v gnome-terminal &> /dev/null; then
    gnome-terminal -- bash -c "simplemode-wizard; echo ''; echo 'Press Enter to close...'; read"
elif command -v xfce4-terminal &> /dev/null; then
    xfce4-terminal -e "bash -c 'simplemode-wizard; read'"
elif command -v xterm &> /dev/null; then
    xterm -e "simplemode-wizard; read"
fi
touch "$WELCOME_FLAG"
rm -f "$HOME/.config/autostart/simplemode-welcome.desktop" 2>/dev/null
WELCOMEEOF
chmod +x /usr/local/bin/simplemode-welcome

# Create autostart entry (runs on first login)
mkdir -p /etc/skel/.config/autostart
cat > /etc/skel/.config/autostart/simplemode-welcome.desktop <<'AUTOEOF'
[Desktop Entry]
Type=Application
Name=SimpleMode Welcome
Comment=First-boot setup wizard for SimpleMode OS
Exec=/usr/local/bin/simplemode-welcome
X-GNOME-Autostart-enabled=true
Terminal=false
AUTOEOF

echo "[✓] First-boot welcome configured"

#------------------------------------------------------
# Done!
#------------------------------------------------------
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✓ SimpleMode OS customization complete!     ║"
echo "║                                              ║"
echo "║  Installed:                                  ║"
echo "║    • Custom branding (SimpleMode OS 1.0)     ║"
echo "║    • Pre-installed applications              ║"
echo "║    • Onboarding wizard (first-boot)          ║"
echo "║    • Terminal assistant                      ║"
echo "║    • PageTree knowledge base                 ║"
echo "║    • GNOME desktop customization             ║"
echo "║                                              ║"
echo "║  Now click NEXT in Cubic to generate ISO.    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Clean up
apt clean
rm -rf /tmp/*.bak 2>/dev/null || true
