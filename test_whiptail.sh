#!/bin/bash
TERM_HEIGHT=24
TERM_WIDTH=80
DIALOG_HEIGHT=$((TERM_HEIGHT - 4))
DIALOG_WIDTH=$((TERM_WIDTH - 10))
[ "$DIALOG_WIDTH" -gt 76 ] && DIALOG_WIDTH=76

whiptail --title "SimpleMode OS — Step 1 of 2" \
    --radiolist "Select your experience level:\n\nUse ARROW KEYS to move, SPACE to select, ENTER to confirm." \
    $DIALOG_HEIGHT $DIALOG_WIDTH 3 \
    "elder"    "Elder / Senior — Bigger icons, bigger fonts, high contrast" OFF \
    "beginner" "Beginner — Simplified menus, help buttons everywhere"       ON \
    "advanced" "Advanced — Full Linux desktop, all features enabled"        OFF \
    3>&1 1>&2 2>&3
