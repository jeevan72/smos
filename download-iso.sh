#!/bin/bash
#======================================================
# SimpleMode OS — Download Ubuntu Base ISO
#======================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="${PROJECT_DIR}/iso"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🐧 SimpleMode OS — Ubuntu ISO Downloader${NC}"
echo ""

mkdir -p "${ISO_DIR}"

# Check if ISO already exists
if ls "${ISO_DIR}"/*.iso 1>/dev/null 2>&1; then
    echo -e "${GREEN}[✓] ISO already exists:${NC}"
    ls -lh "${ISO_DIR}"/*.iso
    echo ""
    read -p "Download again? (y/N): " AGAIN
    if [ "$AGAIN" != "y" ] && [ "$AGAIN" != "Y" ]; then
        echo "Keeping existing ISO."
        exit 0
    fi
fi

# Ubuntu 24.04.2 LTS Desktop
ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso"
ISO_NAME="ubuntu-24.04.2-desktop-amd64.iso"

echo -e "${YELLOW}Downloading: ${ISO_NAME}${NC}"
echo -e "From: ${CYAN}${ISO_URL}${NC}"
echo -e "To:   ${CYAN}${ISO_DIR}/${ISO_NAME}${NC}"
echo ""
echo "This is ~6GB and may take a while..."
echo ""

# Download with wget (resume support)
wget --continue \
     --show-progress \
     --output-document="${ISO_DIR}/${ISO_NAME}" \
     "${ISO_URL}"

echo ""
echo -e "${GREEN}[✓] Download complete!${NC}"
echo -e "    ISO: ${ISO_DIR}/${ISO_NAME}"
echo -e "    Size: $(du -h "${ISO_DIR}/${ISO_NAME}" | cut -f1)"
echo ""
echo -e "    Next step: ${CYAN}./build-iso.sh${NC}"
echo ""
