#!/bin/sh -e
#======================================================
# SimpleMode OS — Single-Command Installer
#
# Installs the complete SimpleMode desktop experience:
#   - GTK4 graphical onboarding
#   - Terminal wizard fallback
#   - Built-in assistant and knowledge base
#   - Linutil system toolbox
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jeevan72/smos/main/install.sh | sh
#======================================================

RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'

SMOS_VERSION="main"
SMOS_ARCHIVE_URL="https://github.com/jeevan72/smos/archive/refs/heads/${SMOS_VERSION}.tar.gz"
SMOS_INSTALL_DIR="${HOME}/.local/share/simplemode"
SMOS_BIN_DIR="${HOME}/.local/bin"
SMOS_DESKTOP_DIR="${HOME}/.local/share/applications"

LINUTIL_VERSION="2026.07.17"
LINUTIL_RELEASE_BASE="https://github.com/ChrisTitusTech/linutil/releases/download/${LINUTIL_VERSION}"

fail() {
    printf "%b\n" "${RED}Error: $1${RC}" >&2
    exit 1
}

info() {
    printf "%b\n" "${CYAN}$1${RC}"
}

success() {
    printf "%b\n" "${GREEN}$1${RC}"
}

if [ "$(id -u)" -eq 0 ]; then
    fail "Do not run this installer as root. Run it as your normal desktop user."
fi

command -v curl >/dev/null 2>&1 || fail "curl is required. Install curl and run this command again."
command -v sudo >/dev/null 2>&1 || fail "sudo is required to install system dependencies."
command -v apt-get >/dev/null 2>&1 || fail "This installer supports Debian/Ubuntu systems with apt-get."
command -v tar >/dev/null 2>&1 || fail "tar is required to extract the SimpleMode source."
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required for release verification."

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
        fail "Unsupported architecture: $(uname -m)."
        ;;
esac

info "Installing SimpleMode OS for ${USER}..."

info "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-gi \
    gir1.2-gtk-4.0 \
    policykit-1 \
    python3-pip \
    python3-venv \
    whiptail \
    dialog \
    git \
    curl \
    wget \
    flatpak \
    gnome-terminal

TMP_ROOT="$(mktemp -d)"
cleanup() {
    rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT

ARCHIVE="${TMP_ROOT}/simplemode.tar.gz"
SOURCE_DIR="${TMP_ROOT}/source"

info "Downloading SimpleMode source..."
curl -fsSL -o "${ARCHIVE}" "${SMOS_ARCHIVE_URL}" || fail "Could not download SimpleMode source."
mkdir -p "${SOURCE_DIR}"
tar -xzf "${ARCHIVE}" -C "${SOURCE_DIR}" --strip-components=1 || fail "Could not extract SimpleMode source."

mkdir -p "${SMOS_INSTALL_DIR}"
cp -a "${SOURCE_DIR}/." "${SMOS_INSTALL_DIR}/"
chmod +x \
    "${SMOS_INSTALL_DIR}/simplemode-onboarding" \
    "${SMOS_INSTALL_DIR}/simplemode-wizard.sh" \
    "${SMOS_INSTALL_DIR}/simplemode-assistant.sh" \
    "${SMOS_INSTALL_DIR}/run.sh"

info "Preparing the SimpleMode Python environment..."
if [ ! -d "${SMOS_INSTALL_DIR}/venv" ]; then
    python3 -m venv "${SMOS_INSTALL_DIR}/venv"
fi
"${SMOS_INSTALL_DIR}/venv/bin/pip" install --quiet --upgrade pip
"${SMOS_INSTALL_DIR}/venv/bin/pip" install --quiet rapidfuzz rich markdown

info "Installing Linutil system toolbox..."
mkdir -p "${SMOS_BIN_DIR}"
LINUTIL_TARGET="${SMOS_BIN_DIR}/linutil"
if [ ! -f "${LINUTIL_TARGET}" ] || ! printf '%s  %s\n' "${LINUTIL_SHA256}" "${LINUTIL_TARGET}" | sha256sum -c - >/dev/null 2>&1; then
    LINUTIL_TMP="${TMP_ROOT}/linutil"
    curl -fsSL -o "${LINUTIL_TMP}" "${LINUTIL_RELEASE_BASE}/${LINUTIL_ASSET}" || fail "Could not download Linutil."
    printf '%s  %s\n' "${LINUTIL_SHA256}" "${LINUTIL_TMP}" | sha256sum -c - >/dev/null 2>&1 || fail "Linutil checksum verification failed."
    install -m 0755 "${LINUTIL_TMP}" "${LINUTIL_TARGET}"
fi

cat > "${SMOS_BIN_DIR}/simplemode-onboarding" <<LAUNCHER
#!/bin/sh
set -e
export PYTHONPATH="${SMOS_INSTALL_DIR}:\${PYTHONPATH:-}"
exec python3 -m onboarding.app "\$@"
LAUNCHER

cat > "${SMOS_BIN_DIR}/simplemode-wizard" <<LAUNCHER
#!/bin/sh
exec bash "${SMOS_INSTALL_DIR}/simplemode-wizard.sh" "\$@"
LAUNCHER

cat > "${SMOS_BIN_DIR}/simplemode-assistant" <<LAUNCHER
#!/bin/sh
set -e
if [ -f "\$HOME/.simplemode-profile" ]; then
    . "\$HOME/.simplemode-profile"
fi
exec "${SMOS_INSTALL_DIR}/venv/bin/python" "${SMOS_INSTALL_DIR}/assistant/assistant.py" \\
    --knowledge "${SMOS_INSTALL_DIR}/knowledge" \\
    --mode "\${USER_TYPE:-beginner}" "\$@"
LAUNCHER

chmod 0755 "${SMOS_BIN_DIR}/simplemode-onboarding" "${SMOS_BIN_DIR}/simplemode-wizard" "${SMOS_BIN_DIR}/simplemode-assistant"

mkdir -p "${SMOS_DESKTOP_DIR}"
cat > "${SMOS_DESKTOP_DIR}/simplemode-onboarding.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=SimpleMode setup
Comment=Choose your desktop style, accessibility mode, and software
Exec=${SMOS_BIN_DIR}/simplemode-onboarding
Icon=preferences-desktop
Terminal=false
Categories=Settings;System;
Keywords=SimpleMode;setup;onboarding;desktop;
DESKTOP

case ":${PATH}:" in
    *":${SMOS_BIN_DIR}:"*) ;;
    *)
        printf '\n# SimpleMode OS user commands\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "${HOME}/.profile"
        ;;
esac

success "SimpleMode OS installed."
printf "%b\n" "${YELLOW}Open a new terminal, then run: simplemode-onboarding${RC}"
printf "%b\n" "${YELLOW}Or launch 'SimpleMode setup' from your application menu.${RC}"
printf "%b\n" "${YELLOW}Terminal fallback: simplemode-wizard${RC}"
printf "%b\n" "${YELLOW}System toolbox: linutil${RC}"
