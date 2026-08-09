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
#
# Optional pinned source:
#   SMOS_REF=<git-commit-or-tag> curl -fsSL ... | sh
#======================================================

RC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'

# Prefer a commit/tag for reproducible installs. Empty = latest main tip.
SMOS_REF="${SMOS_REF:-}"
SMOS_BRANCH="main"
SMOS_INSTALL_ROOT="${HOME}/.local/share/simplemode"
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

warn() {
    printf "%b\n" "${YELLOW}$1${RC}"
}

success() {
    printf "%b\n" "${GREEN}$1${RC}"
}

ensure_path() {
    case ":${PATH}:" in
        *":${SMOS_BIN_DIR}:"*) ;;
        *)
            export PATH="${SMOS_BIN_DIR}:${PATH}"
            ;;
    esac

    for rcfile in "${HOME}/.profile" "${HOME}/.bashrc"; do
        if [ -f "${rcfile}" ] || [ "${rcfile}" = "${HOME}/.profile" ]; then
            if ! grep -Fqs 'SimpleMode OS user commands' "${rcfile}" 2>/dev/null; then
                printf '\n# SimpleMode OS user commands\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "${rcfile}"
            fi
        fi
    done
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

if [ -n "${SMOS_REF}" ]; then
    SMOS_ARCHIVE_URL="https://github.com/jeevan72/smos/archive/${SMOS_REF}.tar.gz"
    SMOS_LABEL="ref ${SMOS_REF}"
else
    SMOS_ARCHIVE_URL="https://github.com/jeevan72/smos/archive/refs/heads/${SMOS_BRANCH}.tar.gz"
    SMOS_LABEL="branch ${SMOS_BRANCH}"
    warn "Installing from moving branch tip (${SMOS_BRANCH}). Set SMOS_REF=<commit> for a pinned install."
fi

info "Installing SimpleMode OS for ${USER} (${SMOS_LABEL})..."

info "Installing required system packages..."

# policykit-1 was renamed to polkitd + pkexec in Ubuntu 24.10+
POLKIT_PKG="policykit-1"
OS_CODENAME=$(grep -oP 'UBUNTU_CODENAME=\K.*' /etc/os-release 2>/dev/null || true)
case "${OS_CODENAME}" in
    oracular|plucky|resolute) POLKIT_PKG="polkitd pkexec" ;;
esac

REQUIRED_PKGS="python3 python3-gi gir1.2-gtk-4.0 ${POLKIT_PKG} python3-pip python3-venv whiptail curl tar"
OPTIONAL_PKGS="dialog git wget flatpak gnome-terminal gnome-shell-extensions gnome-shell-extension-dash-to-panel gnome-shell-extension-ubuntu-dock"

# shellcheck disable=SC2086
sudo apt-get update
# shellcheck disable=SC2086
sudo apt-get install -y ${REQUIRED_PKGS} || fail "Required package installation failed."

for pkg in ${OPTIONAL_PKGS}; do
    if ! sudo apt-get install -y "${pkg}" >/dev/null 2>&1; then
        warn "Optional package unavailable: ${pkg}"
    fi
done

TMP_ROOT="$(mktemp -d)"
cleanup() {
    rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT

ARCHIVE="${TMP_ROOT}/simplemode.tar.gz"
SOURCE_DIR="${TMP_ROOT}/source"
STAGE_DIR="${TMP_ROOT}/stage"

info "Downloading SimpleMode source..."
curl -fsSL -o "${ARCHIVE}" "${SMOS_ARCHIVE_URL}" || fail "Could not download SimpleMode source."
mkdir -p "${SOURCE_DIR}"
tar -xzf "${ARCHIVE}" -C "${SOURCE_DIR}" --strip-components=1 || fail "Could not extract SimpleMode source."

mkdir -p "${STAGE_DIR}"
cp -a "${SOURCE_DIR}/." "${STAGE_DIR}/"
chmod +x \
    "${STAGE_DIR}/simplemode-onboarding" \
    "${STAGE_DIR}/simplemode-wizard.sh" \
    "${STAGE_DIR}/simplemode-assistant.sh" \
    "${STAGE_DIR}/run.sh" \
    "${STAGE_DIR}/install.sh" 2>/dev/null || true

if [ -x "${SMOS_INSTALL_ROOT}/venv/bin/python" ]; then
    cp -a "${SMOS_INSTALL_ROOT}/venv" "${STAGE_DIR}/venv"
fi

info "Preparing the SimpleMode Python environment..."
if [ ! -d "${STAGE_DIR}/venv" ]; then
    python3 -m venv "${STAGE_DIR}/venv"
fi
"${STAGE_DIR}/venv/bin/pip" install --quiet --upgrade pip
"${STAGE_DIR}/venv/bin/pip" install --quiet rapidfuzz rich markdown

mkdir -p "$(dirname "${SMOS_INSTALL_ROOT}")"
if [ -e "${SMOS_INSTALL_ROOT}" ]; then
    BACKUP_DIR="${SMOS_INSTALL_ROOT}.bak.$$"
    mv "${SMOS_INSTALL_ROOT}" "${BACKUP_DIR}"
    if ! mv "${STAGE_DIR}" "${SMOS_INSTALL_ROOT}"; then
        mv "${BACKUP_DIR}" "${SMOS_INSTALL_ROOT}"
        fail "Could not replace the existing SimpleMode install."
    fi
    rm -rf "${BACKUP_DIR}"
else
    mv "${STAGE_DIR}" "${SMOS_INSTALL_ROOT}"
fi

info "Installing Linutil system toolbox..."
mkdir -p "${SMOS_BIN_DIR}"
LINUTIL_TARGET="${SMOS_BIN_DIR}/linutil"
if [ ! -f "${LINUTIL_TARGET}" ] || ! printf '%s  %s\n' "${LINUTIL_SHA256}" "${LINUTIL_TARGET}" | sha256sum -c - >/dev/null 2>&1; then
    LINUTIL_TMP="${TMP_ROOT}/linutil"
    curl -fsSL -o "${LINUTIL_TMP}" "${LINUTIL_RELEASE_BASE}/${LINUTIL_ASSET}" || fail "Could not download Linutil."
    printf '%s  %s\n' "${LINUTIL_SHA256}" "${LINUTIL_TMP}" | sha256sum -c - >/dev/null 2>&1 || fail "Linutil checksum verification failed."
    install -m 0755 "${LINUTIL_TMP}" "${LINUTIL_TARGET}"
fi

cat > "${SMOS_BIN_DIR}/simplemode-onboarding" <<EOF
#!/bin/sh
set -e
export PYTHONPATH="${SMOS_INSTALL_ROOT}:\${PYTHONPATH:-}"
exec python3 -m onboarding.app "\$@"
EOF

cat > "${SMOS_BIN_DIR}/simplemode-wizard" <<EOF
#!/bin/sh
exec bash "${SMOS_INSTALL_ROOT}/simplemode-wizard.sh" "\$@"
EOF

cat > "${SMOS_INSTALL_ROOT}/bin/read-mode.py" <<'EOF'
#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

valid = {"elder", "beginner", "advanced"}
home = Path.home()
json_path = home / ".config" / "simplemode" / "profile.json"
shell_path = home / ".simplemode-profile"

if json_path.is_file():
    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
        mode = str(data.get("user_type", "beginner"))
        print(mode if mode in valid else "beginner")
        raise SystemExit(0)
    except (OSError, json.JSONDecodeError, TypeError, ValueError):
        pass

if shell_path.is_file():
    text = shell_path.read_text(encoding="utf-8", errors="replace")
    match = re.search(r"(?m)^USER_TYPE=(elder|beginner|advanced)\s*$", text)
    if match:
        print(match.group(1))
        raise SystemExit(0)

print("beginner")
EOF
chmod 0755 "${SMOS_INSTALL_ROOT}/bin/read-mode.py"

cat > "${SMOS_BIN_DIR}/simplemode-assistant" <<EOF
#!/bin/sh
set -e
MODE=\$("${SMOS_INSTALL_ROOT}/venv/bin/python" "${SMOS_INSTALL_ROOT}/bin/read-mode.py")
exec "${SMOS_INSTALL_ROOT}/venv/bin/python" "${SMOS_INSTALL_ROOT}/assistant/assistant.py" \\
    --knowledge "${SMOS_INSTALL_ROOT}/knowledge" \\
    --mode "\$MODE" "\$@"
EOF

cat > "${SMOS_BIN_DIR}/simplemode" <<SMLAFEOF
#!/bin/sh
set -e
PROFILE="\${HOME}/.simplemode-profile"
if [ ! -f "\${PROFILE}" ]; then
    printf "\033[1;36mNo configuration found. Launching Onboarding Wizard...\033[0m\n"
    exec bash "${SMOS_INSTALL_ROOT}/simplemode-wizard.sh"
fi
MODE=\$("${SMOS_INSTALL_ROOT}/venv/bin/python" "${SMOS_INSTALL_ROOT}/bin/read-mode.py")
exec "${SMOS_INSTALL_ROOT}/venv/bin/python" "${SMOS_INSTALL_ROOT}/assistant/assistant.py" \\
    --knowledge "${SMOS_INSTALL_ROOT}/knowledge" \\
    --mode "\${MODE}" "\$@"
SMLAFEOF

chmod 0755 \
    "${SMOS_BIN_DIR}/simplemode-onboarding" \
    "${SMOS_BIN_DIR}/simplemode-wizard" \
    "${SMOS_BIN_DIR}/simplemode-assistant" \
    "${SMOS_BIN_DIR}/simplemode"

info "Configuring command interceptor for typo correction..."

configure_interceptor() {
    local rcfile="$1"
    local marker="SimpleMode OS command interceptor"
    if grep -Fqs "${marker}" "${rcfile}" 2>/dev/null; then
        return 0
    fi
    if [ ! -f "${rcfile}" ]; then
        touch "${rcfile}"
    fi
    cat >> "${rcfile}" <<INTERCEPTOR

# --- ${marker} ---
if [ -f "${SMOS_INSTALL_ROOT}/assistant/interceptor.py" ]; then
    if declare -f command_not_found_handle >/dev/null 2>&1 && ! declare -f original_command_not_found_handle >/dev/null 2>&1; then
        eval "original_\$(declare -f command_not_found_handle)"
    fi
    command_not_found_handle() {
        "${SMOS_INSTALL_ROOT}/venv/bin/python" "${SMOS_INSTALL_ROOT}/assistant/interceptor.py" "\$@"
        local _smos_rc=\$?
        if [ \$_smos_rc -eq 127 ] && declare -f original_command_not_found_handle >/dev/null 2>&1; then
            original_command_not_found_handle "\$@"
        elif [ \$_smos_rc -eq 127 ]; then
            printf 'bash: %s: command not found\n' "\$1" >&2
        fi
        return \$_smos_rc
    }
fi
INTERCEPTOR
}

configure_interceptor "${HOME}/.bashrc"
if command -v zsh >/dev/null 2>&1; then
    configure_interceptor "${HOME}/.zshrc"
fi

mkdir -p "${SMOS_DESKTOP_DIR}"
cat > "${SMOS_DESKTOP_DIR}/simplemode-onboarding.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=SimpleMode setup
Comment=Choose your desktop style, accessibility mode, and software
Exec=${SMOS_BIN_DIR}/simplemode-onboarding
Icon=preferences-desktop
Terminal=false
Categories=Settings;System;
Keywords=SimpleMode;setup;onboarding;desktop;
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${SMOS_DESKTOP_DIR}" >/dev/null 2>&1 || true
fi

ensure_path

info "Running install smoke checks..."
[ -f "${SMOS_INSTALL_ROOT}/onboarding/catalog.toml" ] || fail "Missing onboarding catalog after install."
[ -f "${SMOS_INSTALL_ROOT}/onboarding/app.py" ] || fail "Missing onboarding app after install."
[ -f "${SMOS_INSTALL_ROOT}/assistant/interceptor.py" ] || fail "Missing interceptor after install."
[ -x "${SMOS_BIN_DIR}/simplemode-onboarding" ] || fail "Onboarding launcher is not executable."
[ -x "${SMOS_BIN_DIR}/simplemode-wizard" ] || fail "Wizard launcher is not executable."
[ -x "${SMOS_BIN_DIR}/simplemode-assistant" ] || fail "Assistant launcher is not executable."
[ -x "${SMOS_BIN_DIR}/simplemode" ] || fail "SimpleMode launcher is not executable."
[ -x "${LINUTIL_TARGET}" ] || fail "Linutil is not executable."
PYTHONPATH="${SMOS_INSTALL_ROOT}" python3 -c 'import onboarding.profile, onboarding.software, onboarding.desktop' \
    || fail "SimpleMode Python package import failed."
grep -Fqs "SimpleMode OS command interceptor" "${HOME}/.bashrc" \
    || fail "Command interceptor not configured in .bashrc."

success "SimpleMode OS installed."
printf "%b\n" "${YELLOW}Launch setup now:${RC}"
printf "  %s\n" "${SMOS_BIN_DIR}/simplemode-onboarding"
printf "%b\n" "${YELLOW}Or, after opening a new terminal:${RC}"
printf "  simplemode\n"
printf "  simplemode-onboarding\n"
printf "  simplemode-wizard\n"
printf "  simplemode-assistant\n"
printf "  linutil\n"
printf "%b\n" "${YELLOW}App menu entry: SimpleMode setup${RC}"
printf "%b\n" "${YELLOW}Pinned install: SMOS_REF=<git-commit> curl -fsSL https://raw.githubusercontent.com/jeevan72/smos/main/install.sh | sh${RC}"
