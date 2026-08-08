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
echo -e "${BOLD}━━━ Step 1/4: System Dependencies ━━━${NC}"

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
    flatpak \
    toilet || print_err "Failed to install some packages"

print_step "System packages installed"

#------------------------------------------------------
# Step 2: Python environment
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 2/4: Python Environment ━━━${NC}"

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
# Step 3: Make scripts executable
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 3/4: Setting Permissions ━━━${NC}"

chmod +x "${PROJECT_DIR}/setup.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/simplemode-wizard.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/simplemode-assistant.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/debian/welcome/welcome.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/chroot-setup.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/run.sh" 2>/dev/null || true
chmod +x "${PROJECT_DIR}/assistant/interceptor.py" 2>/dev/null || true

# Add interceptor to ~/.bashrc if not already present
if ! grep -q "interceptor.py" ~/.bashrc 2>/dev/null; then
    print_info "Configuring command interceptor in ~/.bashrc..."
    cat >> ~/.bashrc <<'BASHRC_EOF'

# --- SimpleMode OS Command Interceptor ---
if [ -f "${PROJECT_DIR}/assistant/interceptor.py" ]; then
    # Backup original command_not_found_handle if it exists and hasn't been backed up yet
    if declare -f command_not_found_handle >/dev/null && ! declare -f original_command_not_found_handle >/dev/null; then
        eval "original_$(declare -f command_not_found_handle)"
    fi

    command_not_found_handle() {
        python3 "${PROJECT_DIR}/assistant/interceptor.py" "$@"
        local status=$?
        if [ $status -eq 127 ]; then
            if declare -f original_command_not_found_handle >/dev/null; then
                original_command_not_found_handle "$@"
            else
                echo "bash: $1: command not found" >&2
            fi
        fi
        return $status
    }
fi
BASHRC_EOF
    print_step "Command interceptor configured in ~/.bashrc"
else
    print_info "Command interceptor already configured in ~/.bashrc"
fi

print_step "Scripts made executable"

#------------------------------------------------------
# Step 3.5: Linutil System Toolbox (dev machine)
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 3.5: Linutil Toolbox ━━━${NC}"

# Linutil is Chris Titus Tech's terminal toolbox (distro-agnostic task catalog).
# We install the official x86_64 release binary into ~/.local/bin.
# Pinned release: https://github.com/ChrisTitusTech/linutil/releases
LINUTIL_VERSION="2026.07.17"
LINUTIL_URL="https://github.com/ChrisTitusTech/linutil/releases/download/${LINUTIL_VERSION}/linutil"
LINUTIL_SHA256="3e7dd8da45b644e7af3ff29bfba391ebd13772865eeefb55ea88a48c74f7d1ff"

install_linutil() {
    if command -v linutil &> /dev/null && linutil --version >/dev/null 2>&1; then
        print_info "linutil already installed: $(linutil --version 2>/dev/null | head -n1)"
        return 0
    fi

    if ! command -v curl &> /dev/null; then
        print_err "curl not available — skipping Linutil install."
        return 1
    fi

    mkdir -p "${HOME}/.local/bin"
    local tmp="/tmp/linutil"
    echo "  Downloading Linutil ${LINUTIL_VERSION}..."
    if ! curl -fsSL -o "${tmp}" "${LINUTIL_URL}"; then
        print_err "Failed to download Linutil — skipping."
        return 1
    fi

    # Verify the binary checksum before installing
    echo "${LINUTIL_SHA256}  ${tmp}" | sha256sum -c - >/dev/null 2>&1 || {
        print_err "Linutil checksum mismatch — skipping install."
        rm -f "${tmp}"
        return 1
    }

    install -m 0755 "${tmp}" "${HOME}/.local/bin/linutil"
    rm -f "${tmp}"
    print_step "Linutil installed: $(${HOME}/.local/bin/linutil --version 2>/dev/null | head -n1)"

    # Desktop launcher (appears in the app menu)
    mkdir -p "${HOME}/.local/share/applications"
    cat > "${HOME}/.local/share/applications/linutil.desktop" <<'LINUTILDESKTOP'
[Desktop Entry]
Type=Application
Name=System Toolbox
GenericName=Linux Utility Toolbox
Comment=Chris Titus Tech's Linutil — setup, optimize, and maintain your system
Exec=linutil
Icon=utilities-terminal
Terminal=true
Categories=System;Utility;
Keywords=linutil;toolbox;titus;maintenance;
LINUTILDESKTOP
    print_step "Linutil desktop launcher created"
}

install_linutil

# Make sure ~/.local/bin is on PATH
if ! echo "${PATH}" | grep -q "${HOME}/.local/bin"; then
    print_info "Adding ~/.local/bin to PATH in ~/.bashrc..."
    echo '' >> ~/.bashrc
    echo '# Add ~/.local/bin to PATH (Linutil toolbox)' >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
fi

#------------------------------------------------------
# Step 4: Verify project
#------------------------------------------------------
echo ""
echo -e "${BOLD}━━━ Step 4/4: Project Verification ━━━${NC}"

REQUIRED_FILES=(
    "simplemode-wizard.sh"
    "simplemode-assistant.sh"
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
echo -e "${CYAN}║${NC}  ${YELLOW}3. Open System Toolbox (Linutil):${NC}                     ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     linutil                                          ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
