#!/bin/bash
#======================================================
# SimpleMode OS — First Boot Welcome Script
# This launches the onboarding wizard on first login.
#
# It shows the wizard only once per user: if the profile
# already exists, or the wizard has already been shown,
# it exits immediately.
#======================================================

WELCOME_FLAG="$HOME/.simplemode-welcomed"
PROFILE_FILE="$HOME/.simplemode-profile"

# Only show on first boot
if [ -f "$WELCOME_FLAG" ]; then
    exit 0
fi

# If the user already completed the wizard, don't show it again
if [ -f "$PROFILE_FILE" ]; then
    touch "$WELCOME_FLAG"
    exit 0
fi

# Check if we have a graphical display
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    exit 0
fi

# Launch the onboarding wizard inside a terminal so whiptail can render.
# The wizard writes $HOME/.simplemode-profile on completion.
launch_wizard() {
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal --wait -- bash -c "simplemode-wizard; echo ''; echo 'Press Enter to close...'; read"
        return
    elif command -v xfce4-terminal &> /dev/null; then
        xfce4-terminal -e "bash -c 'simplemode-wizard; echo \"Press Enter to close...\"; read'"
        return
    elif command -v xterm &> /dev/null; then
        xterm -e "bash -c 'simplemode-wizard; echo \"Press Enter to close...\"; read'"
        return
    fi

    # No terminal emulator available — fall back to a zenity notice.
    if command -v zenity &> /dev/null; then
        zenity --info \
            --title="Welcome to SimpleMode OS" \
            --text="Welcome to SimpleMode OS!\n\nYour personalized Linux experience starts now.\n\nOpen a terminal and run:  simplemode-wizard" \
            --width=400 \
            --height=200
    fi
}

launch_wizard

# Mark as welcomed so it never shows again
touch "$WELCOME_FLAG"
