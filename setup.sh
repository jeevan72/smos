#!/bin/bash
#======================================================
# SimpleMode OS — Full Setup Script
# Clone from GitHub, run this, and you're ready.
# Tested on: Ubuntu 24.04+ / Debian 12+
#
# Usage:
#   git clone https://github.com/YOUR_USER/simplemode-os.git
#   cd simplemode-os
#   chmod +x setup.sh
#   ./setup.sh
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

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}🐧 SimpleMode OS — Setup & Installer${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     Adaptive Linux for Everyone                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() { echo -e "  ${GREEN}[✓]${NC} $1"; }
print_info() { echo -e "  ${YELLOW}[i]${NC} $1"; }
print_err()  { echo -e "  ${RED}[✗]${NC} $1"; }

#------------------------------------------------------
# Pre-checks
#------------------------------------------------------
print_banner

if ! command -v apt &> /dev/null; then
    print_err "This script requires a Debian/Ubuntu-based system."
    exit 1
fi

OS_NAME=$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
print_info "OS: ${OS_NAME}"
print_info "Project: ${PROJECT_DIR}"
echo ""

#------------------------------------------------------
# Step 1: System packages
#------------------------------------------------------
echo -e "${BOLD}━━━ Step 1/6: System Dependencies ━━━${NC}"

echo "Updating package list..."
sudo apt update || print_err "apt update had some errors, continuing anyway..."

echo "Installing required packages..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    whiptail \
    dialog \
    figlet \
    toilet || print_err "Failed to install some packages"

print_step "System packages installed"

#------------------------------------------------------
# Step 2: Python environment
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 2/6: Python Environment ━━━${NC}"

if [ ! -d "${PROJECT_DIR}/venv" ]; then
    python3 -m venv "${PROJECT_DIR}/venv"
    print_step "Virtual environment created"
else
    print_info "Virtual environment already exists"
fi

source "${PROJECT_DIR}/venv/bin/activate"

pip install --upgrade pip -q 2>/dev/null

pip install -q \
    rapidfuzz \
    rich \
    markdown

print_step "Python packages installed (rapidfuzz, rich, markdown)"

#------------------------------------------------------
# Step 3: Cubic (for ISO building)
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 3/6: Cubic ISO Customizer ━━━${NC}"

if command -v cubic &> /dev/null; then
    print_info "Cubic is already installed"
else
    print_info "Adding Cubic PPA..."
    sudo apt-add-repository -y ppa:cubic-wizard/release 2>/dev/null || true
    sudo apt update -qq 2>/dev/null
    sudo apt install -y cubic 2>/dev/null && print_step "Cubic installed" || print_err "Cubic install failed (PPA may not support your Ubuntu version). You can install manually later."
fi

#------------------------------------------------------
# Step 4: Download Ubuntu ISO (optional)
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 4/6: Ubuntu Base ISO ━━━${NC}"

ISO_DIR="${PROJECT_DIR}/iso"
mkdir -p "${ISO_DIR}"

if ls "${ISO_DIR}"/*.iso 1>/dev/null 2>&1; then
    print_info "ISO file found in ${ISO_DIR}/"
    ls -lh "${ISO_DIR}"/*.iso | awk '{print "       " $NF " (" $5 ")"}'
else
    print_info "No base ISO found."
    print_info "To download Ubuntu 24.04 Desktop ISO, run:"
    echo -e "       ${CYAN}./download-iso.sh${NC}"
    echo "       Or manually download from https://ubuntu.com/download/desktop"
    echo "       and place the .iso file in: ${ISO_DIR}/"
fi

#------------------------------------------------------
# Step 5: Make scripts executable
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 5/6: Setting Permissions ━━━${NC}"

chmod +x "${PROJECT_DIR}/setup.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/simplemode-wizard.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/simplemode-assistant.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/build-iso.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/download-iso.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/debian/welcome/welcome.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/chroot-setup.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/run.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/assistant/interceptor.py" 2>/dev/null || true

# Add interceptor to ~/.bashrc if not already present
BASHRC_HOOK_CMD="python3 ${PROJECT_DIR}/assistant/interceptor.py"
if ! grep -q "interceptor.py" ~/.bashrc 2>/dev/null; then
    print_info "Configuring command interceptor in ~/.bashrc..."
    cat >> ~/.bashrc <<BASHRC_EOF

# --- SimpleMode OS Command Interceptor ---
if [ -f "${PROJECT_DIR}/assistant/interceptor.py" ]; then
    # Backup original command_not_found_handle if it exists and hasn't been backed up yet
    if declare -f command_not_found_handle >/dev/null && ! declare -f original_command_not_found_handle >/dev/null; then
        eval "original_\$(declare -f command_not_found_handle)"
    fi

    command_not_found_handle() {
        python3 "${PROJECT_DIR}/assistant/interceptor.py" "\$@"
        local status=\$?
        if [ \$status -eq 127 ]; then
            if declare -f original_command_not_found_handle >/dev/null; then
                original_command_not_found_handle "\$@"
            else
                echo "bash: \$1: command not found" >&2
                return 127
            fi
        else
            return \$status
        fi
    }
fi
BASHRC_EOF
    print_step "Command interceptor configured in ~/.bashrc"
else
    print_info "Command interceptor already configured in ~/.bashrc"
fi

print_step "Scripts made executable"

#------------------------------------------------------
# Step 6: Verify project
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 6/6: Project Verification ━━━${NC}"

REQUIRED_FILES=(
    "simplemode-wizard.sh"
    "simplemode-assistant.sh"
    "build-iso.sh"
    "chroot-setup.sh"
    "knowledge/index.json"
    "debian/packages.list"
    "debian/branding/os-release"
)

ALL_OK=true
for f in "${REQUIRED_FILES[@]}"; do
    if [ -f "${PROJECT_DIR}/${f}" ]; then
        print_step "${f}"
    else
        print_err "${f} — MISSING"
        ALL_OK=false
    fi
done

#------------------------------------------------------
# Done
#------------------------------------------------------
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}✓ Setup Complete!${NC}                                   ${CYAN}║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Available Commands:${NC}                                  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}1. Run Onboarding Wizard (TUI):${NC}                     ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     ./simplemode-wizard.sh                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}2. Run Terminal Assistant:${NC}                           ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     ./simplemode-assistant.sh                         ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}3. Build Custom ISO (Cubic):${NC}                         ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     ./build-iso.sh                                    ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}4. Download Ubuntu Base ISO:${NC}                         ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     ./download-iso.sh                                 ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
