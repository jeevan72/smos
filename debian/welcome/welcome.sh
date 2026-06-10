#!/bin/bash
#======================================================
# SimpleMode OS — First Boot Welcome Script
# This launches the onboarding wizard on first login
#======================================================

WELCOME_FLAG="$HOME/.simplemode-welcomed"

# Only show on first boot
if [ -f "$WELCOME_FLAG" ]; then
    exit 0
fi

# Check if we have a graphical display
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    exit 0
fi

# Launch the onboarding wizard
# Option 1: Open web-based wizard in browser
if command -v xdg-open &> /dev/null; then
    xdg-open /opt/simplemode/demo/index.html &
elif command -v firefox &> /dev/null; then
    firefox /opt/simplemode/demo/index.html &
fi

# Option 2: Show a simple zenity dialog as fallback
if command -v zenity &> /dev/null && [ ! -f "$WELCOME_FLAG" ]; then
    zenity --info \
        --title="Welcome to SimpleMode OS" \
        --text="Welcome to SimpleMode OS!\n\nYour personalized Linux experience starts now.\n\nThe setup wizard will help you configure your desktop." \
        --width=400 \
        --height=200 \
        2>/dev/null
fi

# Mark as welcomed
touch "$WELCOME_FLAG"

# Remove autostart entry so it doesn't show again
rm -f "$HOME/.config/autostart/simplemode-welcome.desktop" 2>/dev/null
