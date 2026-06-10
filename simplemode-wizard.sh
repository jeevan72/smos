#!/bin/bash
#======================================================
# SimpleMode OS — Onboarding Wizard (Terminal UI)
# Uses whiptail for beautiful terminal dialogs
#======================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_FILE="${PROJECT_DIR}/.simplemode-profile"

# Colors for non-whiptail output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Terminal dimensions
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
DIALOG_HEIGHT=$((TERM_HEIGHT - 4))
DIALOG_WIDTH=$((TERM_WIDTH - 10))
[ "$DIALOG_WIDTH" -gt 76 ] && DIALOG_WIDTH=76
[ "$DIALOG_HEIGHT" -gt 24 ] && DIALOG_HEIGHT=24

#------------------------------------------------------
# Step 1: Welcome Screen
#------------------------------------------------------
welcome_screen() {
    whiptail --title "SimpleMode OS" \
        --msgbox "\
    ╔═══════════════════════════════════════╗
    ║                                       ║
    ║     🐧  Welcome to SimpleMode OS      ║
    ║                                       ║
    ║   Your Personalized Linux Experience  ║
    ║                                       ║
    ║   This wizard will configure your     ║
    ║   desktop in just 2 simple steps.     ║
    ║                                       ║
    ╚═══════════════════════════════════════╝

    SimpleMode OS adapts its interface based on
    your experience level and preferred style.

    Press OK to begin setup..." \
        $DIALOG_HEIGHT $DIALOG_WIDTH
}

#------------------------------------------------------
# Step 2: Select User Type
#------------------------------------------------------
select_user_type() {
    USER_TYPE=$(whiptail --title "SimpleMode OS — Step 1 of 2" \
        --radiolist "\
Select your experience level:

Use ARROW KEYS to move, SPACE to select, ENTER to confirm.
" $DIALOG_HEIGHT $DIALOG_WIDTH 3 \
        "elder"    "Elder / Senior — Bigger icons, bigger fonts, high contrast" OFF \
        "beginner" "Beginner — Simplified menus, help buttons everywhere"       ON \
        "advanced" "Advanced — Full Linux desktop, all features enabled"        OFF \
        3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        echo "Setup cancelled."
        exit 1
    fi
}

#------------------------------------------------------
# Step 3: Select Desktop Style
#------------------------------------------------------
select_desktop_style() {
    DESKTOP_STYLE=$(whiptail --title "SimpleMode OS — Step 2 of 2" \
        --radiolist "\
Choose your preferred desktop layout:

Use ARROW KEYS to move, SPACE to select, ENTER to confirm.
" $DIALOG_HEIGHT $DIALOG_WIDTH 3 \
        "windows" "Windows Style — Bottom taskbar, start menu, system tray"    OFF \
        "macos"   "macOS Style — Top menu bar, bottom dock"                    OFF \
        "linux"   "Linux Style — GNOME top bar, Activities overview"           ON \
        3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        echo "Setup cancelled."
        exit 1
    fi
}

#------------------------------------------------------
# Step 4: Confirmation
#------------------------------------------------------
confirm_selection() {
    # Map values to display names
    case "$USER_TYPE" in
        elder)    TYPE_DISPLAY="👴 Elder / Senior";;
        beginner) TYPE_DISPLAY="🌱 Beginner";;
        advanced) TYPE_DISPLAY="⚡ Advanced";;
    esac

    case "$DESKTOP_STYLE" in
        windows) STYLE_DISPLAY="🪟 Windows Style";;
        macos)   STYLE_DISPLAY="🍎 macOS Style";;
        linux)   STYLE_DISPLAY="🐧 Linux Style";;
    esac

    whiptail --title "SimpleMode OS — Confirm Setup" \
        --yesno "\
Your personalized configuration:

    ┌─────────────────────────────────────┐
    │                                     │
    │  Experience Level:                  │
    │    ${TYPE_DISPLAY}                  
    │                                     │
    │  Desktop Style:                     │
    │    ${STYLE_DISPLAY}                 
    │                                     │
    └─────────────────────────────────────┘

Apply these settings?" \
        $DIALOG_HEIGHT $DIALOG_WIDTH

    if [ $? -ne 0 ]; then
        # User chose No — restart wizard
        run_wizard
        return
    fi
}

#------------------------------------------------------
# Step 5: Save Profile & Apply Settings
#------------------------------------------------------
apply_settings() {
    # 1. Apply User Type (Scaling)
    if [ "$USER_TYPE" == "elder" ]; then
        gsettings set org.gnome.desktop.interface text-scaling-factor 1.25 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 48 2>/dev/null || true
    else
        gsettings set org.gnome.desktop.interface text-scaling-factor 1.0 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    fi

    # 2. Apply Desktop Style
    case "$DESKTOP_STYLE" in
        windows)
            # Enable dash-to-panel
            gnome-extensions enable dash-to-panel@jderose9.github.com 2>/dev/null || true
            gnome-extensions disable ubuntu-dock@ubuntu.com 2>/dev/null || true
            gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true
            ;;
        macos)
            # Enable dock, move to bottom
            gnome-extensions disable dash-to-panel@jderose9.github.com 2>/dev/null || true
            gnome-extensions enable ubuntu-dock@ubuntu.com 2>/dev/null || true
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' 2>/dev/null || true
            gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false 2>/dev/null || true
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false 2>/dev/null || true
            gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true 2>/dev/null || true
            # macOS window buttons on the left
            gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu' 2>/dev/null || true
            ;;
        linux)
            # Default GNOME (Dock on left)
            gnome-extensions disable dash-to-panel@jderose9.github.com 2>/dev/null || true
            gnome-extensions enable ubuntu-dock@ubuntu.com 2>/dev/null || true
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT' 2>/dev/null || true
            gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true 2>/dev/null || true
            gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true 2>/dev/null || true
            gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true
            ;;
    esac
}

save_profile() {
    # Save profile to file
    cat > "$PROFILE_FILE" <<EOF
# SimpleMode OS User Profile
# Generated: $(date)
USER_TYPE=${USER_TYPE}
DESKTOP_STYLE=${DESKTOP_STYLE}
EOF

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Profile saved successfully!              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}User Type:${NC}     ${USER_TYPE}"
    echo -e "  ${BOLD}Desktop Style:${NC} ${DESKTOP_STYLE}"
    echo -e "  ${BOLD}Profile File:${NC}  ${PROFILE_FILE}"
    echo ""
    echo -e "  ${YELLOW}What's next:${NC}"
    echo -e "    • Run the assistant:  ${CYAN}./simplemode-assistant.sh${NC}"
    echo -e "    • Build the ISO:      ${CYAN}./build-iso.sh${NC}"
    echo ""
}

#------------------------------------------------------
# Main
#------------------------------------------------------
run_wizard() {
    welcome_screen
    select_user_type
    select_desktop_style
    confirm_selection
    apply_settings
    save_profile
}

# Check for whiptail
if ! command -v whiptail &> /dev/null; then
    echo "Installing whiptail..."
    sudo apt install -y whiptail 2>/dev/null
fi

run_wizard
