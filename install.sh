#!/bin/sh -e
#======================================================
# SimpleMode OS — Linutil Toolbox Installer
#
# Installs Chris Titus Tech's Linutil (terminal toolbox)
# to ~/.local/bin with checksum verification, and creates
# a desktop launcher.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jeevan72/smos/main/install.sh | sh
#======================================================

RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'

LINUTIL_VERSION="2026.07.17"
RELEASE_BASE_URL="https://github.com/ChrisTitusTech/linutil/releases/download/${LINUTIL_VERSION}"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"

case "$(uname -m)" in
    x86_64|amd64)
        LINUTIL_ASSET="linutil"
        LINUTIL_SHA256="3e7dd8da45b644e7af3ff29bfba391ebd13772865eeefb55ea88a48c74f7d1ff"
        ;;
    aarch64|arm64)
        LINUTIL_ASSET="linutil-aarch64"
        LINUTIL_SHA256="0504580240adc8977c831d18030469dd3c3848ce8fed3b310d94374899a8b708"
        ;;
    *)
        printf "%b\n" "${RED}Unsupported architecture: $(uname -m).${RC}"
        exit 1
        ;;
esac
LINUTIL_URL="${RELEASE_BASE_URL}/${LINUTIL_ASSET}"

# Skip downloading only when the managed binary matches the pinned release.
if [ -f "${BIN_DIR}/linutil" ] && printf '%s  %s\n' "${LINUTIL_SHA256}" "${BIN_DIR}/linutil" | sha256sum -c - >/dev/null 2>&1; then
    printf "%b\n" "${GREEN}linutil ${LINUTIL_VERSION} is already installed.${RC}"
else
    # Never treat an unrelated executable earlier on PATH as our installation.
    if ! command -v curl >/dev/null 2>&1; then
        printf "%b\n" "${RED}curl is required to install Linutil.${RC}"
        exit 1
    fi

    printf "%b\n" "${CYAN}Installing Linutil ${LINUTIL_VERSION}...${RC}"
    mkdir -p "${BIN_DIR}"

    TMP_BIN="$(mktemp)"
    trap 'rm -f "${TMP_BIN}"' EXIT

    if ! curl -fsSL -o "${TMP_BIN}" "${LINUTIL_URL}"; then
        printf "%b\n" "${RED}Failed to download Linutil.${RC}"
        exit 1
    fi

    # Verify checksum before installing
    if ! printf '%s  %s\n' "${LINUTIL_SHA256}" "${TMP_BIN}" | sha256sum -c - >/dev/null 2>&1; then
        printf "%b\n" "${RED}Checksum mismatch — download may be corrupted.${RC}"
        exit 1
    fi

    install -m 0755 "${TMP_BIN}" "${BIN_DIR}/linutil"
    trap - EXIT
    rm -f "${TMP_BIN}"
fi

# Desktop launcher (appears in the app menu)
mkdir -p "${DESKTOP_DIR}"
cat > "${DESKTOP_DIR}/linutil.desktop" <<LINUTILDESKTOP
[Desktop Entry]
Type=Application
Name=System Toolbox
GenericName=Linux Utility Toolbox
Comment=Chris Titus Tech's Linutil — setup, optimize, and maintain your system
Exec=${BIN_DIR}/linutil
Icon=utilities-terminal
Terminal=true
Categories=System;Utility;
Keywords=linutil;toolbox;titus;maintenance;
LINUTILDESKTOP

printf "%b\n" "${GREEN}Linutil installed: $(${BIN_DIR}/linutil --version 2>/dev/null | head -n1)${RC}"

# Ensure ~/.local/bin is on PATH
case ":${PATH}:" in
    *":${BIN_DIR}:"*) ;;
    *)
        printf "%b\n" "${YELLOW}Adding ${BIN_DIR} to PATH in ~/.bashrc...${RC}"
        printf '\n# Add ~/.local/bin to PATH (Linutil toolbox)\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "${HOME}/.bashrc"
        printf "%b\n" "${YELLOW}Run 'source ~/.bashrc' (or open a new terminal), then: linutil${RC}"
        ;;
esac

printf "%b\n" "${GREEN}Open the toolbox anytime with: linutil${RC}"
