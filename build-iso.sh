#!/bin/bash
#======================================================
# SimpleMode OS — Build Custom ISO with Cubic
#
# This script automates the Cubic workflow:
#   1. Check for base Ubuntu ISO
#   2. Set up Cubic project directory
#   3. Launch Cubic with our customization script
#
# NOTE: Cubic is a GUI tool — this script prepares
# everything and then launches it. Inside Cubic's
# chroot terminal, you run: /tmp/chroot-setup.sh
#======================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="${PROJECT_DIR}/iso"
CUBIC_PROJECT="${PROJECT_DIR}/cubic-project"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}🐧 SimpleMode OS — ISO Builder (Cubic)${NC}             ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

#------------------------------------------------------
# Step 1: Check prerequisites
#------------------------------------------------------
echo -e "${BOLD}━━━ Checking Prerequisites ━━━${NC}"

if ! command -v cubic &> /dev/null; then
    echo -e "${YELLOW}[!] Cubic is not installed.${NC}"
    echo "    Installing Cubic..."
    sudo apt-add-repository -y ppa:cubic-wizard/release 2>/dev/null
    sudo apt update -qq
    sudo apt install -y cubic
    echo -e "${GREEN}[✓] Cubic installed${NC}"
else
    echo -e "${GREEN}[✓] Cubic is installed${NC}"
fi

#------------------------------------------------------
# Step 2: Find or download base ISO
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Base Ubuntu ISO ━━━${NC}"

mkdir -p "${ISO_DIR}"

BASE_ISO=$(find "${ISO_DIR}" -maxdepth 1 -name "*.iso" -type f | head -1)

if [ -z "$BASE_ISO" ]; then
    echo -e "${YELLOW}[!] No .iso file found in ${ISO_DIR}/${NC}"
    echo ""
    echo "  Please do ONE of the following:"
    echo ""
    echo -e "  ${CYAN}Option A:${NC} Download automatically:"
    echo "    ./download-iso.sh"
    echo ""
    echo -e "  ${CYAN}Option B:${NC} Download manually from:"
    echo "    https://ubuntu.com/download/desktop"
    echo "    Then place the .iso file in: ${ISO_DIR}/"
    echo ""
    echo -e "  ${CYAN}Option C:${NC} Specify path to existing ISO:"
    read -p "    Enter full path to ISO (or press Enter to exit): " CUSTOM_ISO
    if [ -n "$CUSTOM_ISO" ] && [ -f "$CUSTOM_ISO" ]; then
        BASE_ISO="$CUSTOM_ISO"
    else
        echo "Exiting. Get a base ISO first."
        exit 1
    fi
fi

echo -e "${GREEN}[✓] Base ISO: $(basename "$BASE_ISO")${NC}"
echo "    Size: $(du -h "$BASE_ISO" | cut -f1)"

#------------------------------------------------------
# Step 3: Prepare Cubic project
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Preparing Cubic Project ━━━${NC}"

mkdir -p "${CUBIC_PROJECT}"

# Copy our customization script so it's accessible inside chroot
cp "${PROJECT_DIR}/chroot-setup.sh" "${CUBIC_PROJECT}/chroot-setup.sh"
cp "${PROJECT_DIR}/debian/packages.list" "${CUBIC_PROJECT}/packages.list"
cp "${PROJECT_DIR}/debian/branding/os-release" "${CUBIC_PROJECT}/os-release"
cp "${PROJECT_DIR}/debian/welcome/welcome.sh" "${CUBIC_PROJECT}/welcome.sh"

# Copy knowledge base
mkdir -p "${CUBIC_PROJECT}/simplemode-files/knowledge"
cp -r "${PROJECT_DIR}/knowledge/"* "${CUBIC_PROJECT}/simplemode-files/knowledge/"

# Copy assistant
mkdir -p "${CUBIC_PROJECT}/simplemode-files/assistant"
cp "${PROJECT_DIR}/assistant/assistant.py" "${CUBIC_PROJECT}/simplemode-files/assistant/"
cp "${PROJECT_DIR}/simplemode-assistant.sh" "${CUBIC_PROJECT}/simplemode-files/"
cp "${PROJECT_DIR}/simplemode-wizard.sh" "${CUBIC_PROJECT}/simplemode-files/"

echo -e "${GREEN}[✓] Project files prepared${NC}"

#------------------------------------------------------
# Step 4: Launch Cubic
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Launching Cubic ━━━${NC}"
echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  IMPORTANT: Follow these steps inside Cubic:        ║${NC}"
echo -e "${YELLOW}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${YELLOW}║${NC}                                                      ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  1. Set project directory to:                        ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}     ${CYAN}${CUBIC_PROJECT}${NC}       ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                      ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  2. Select the base ISO:                             ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}     ${CYAN}$(basename "$BASE_ISO")${NC}                      ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                      ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  3. When you reach the chroot terminal, run:         ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}     ${GREEN}bash /tmp/chroot-setup.sh${NC}                        ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                      ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  4. Click Next to generate the custom ISO            ${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}                                                      ${YELLOW}║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Press Enter to launch Cubic (or Ctrl+C to cancel)..."

# Launch Cubic
sudo cubic "${CUBIC_PROJECT}" &

echo ""
echo -e "${GREEN}Cubic launched! Follow the steps above.${NC}"
echo -e "Your custom ISO will be saved in: ${CYAN}${CUBIC_PROJECT}/${NC}"
echo ""
