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

# Launch the graphical onboarding app first. The terminal wizard remains the
# fallback for missing GTK dependencies, SSH recovery, and headless systems.
launch_onboarding() {
    if command -v simplemode-onboarding >/dev/null 2>&1; then
        if simplemode-onboarding; then
            return 0
        fi
    fi

    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal --wait -- bash -c "simplemode-wizard; status=\$?; echo ''; echo 'Press Enter to close...'; read; exit \$status"
        return $?
    elif command -v xfce4-terminal &> /dev/null; then
        xfce4-terminal -e "bash -c 'simplemode-wizard; status=\$?; echo \"Press Enter to close...\"; read; exit \$status'"
        return $?
    elif command -v xterm &> /dev/null; then
        xterm -e "bash -c 'simplemode-wizard; status=\$?; echo \"Press Enter to close...\"; read; exit \$status'"
        return $?
    fi

    return 1
}

if launch_onboarding && [ -f "$PROFILE_FILE" ]; then
    touch "$WELCOME_FLAG"
else
    if command -v zenity &> /dev/null; then
        zenity --warning \
            --title="SimpleMode setup was not completed" \
            --text="Open a terminal and run: simplemode-wizard" \
            --width=420 \
            --height=180
    fi
    exit 1
fi
