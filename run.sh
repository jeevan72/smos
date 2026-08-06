#!/bin/bash
#======================================================
# SimpleMode OS — Main Auto-Runner
#
# If no profile exists, launches onboarding wizard first.
# Then automatically runs the terminal assistant.
#======================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_FILE="${HOME}/.simplemode-profile"

# 1. Run onboarding wizard if not yet configured
if [ ! -f "$PROFILE_FILE" ]; then
    echo "No configuration found. Launching Onboarding Wizard..."
    bash "${PROJECT_DIR}/simplemode-wizard.sh"
fi

# 2. Launch simplemode assistant
if [ -f "$PROFILE_FILE" ]; then
    bash "${PROJECT_DIR}/simplemode-assistant.sh"
else
    echo "Setup incomplete. Exiting."
    exit 1
fi
