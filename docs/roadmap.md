# SimpleMode OS (SMOS) — Development Roadmap

## Phase 1 ✅ (Implemented — Demo Ready)

### 1. OS Customization & Branding (Cubic)
- ✅ Deep branding removal (Replaced "Ubuntu" with "SMOS" in `os-release` and GRUB bootloader)
- ✅ Pre-installed applications & tools (via `chroot-setup.sh`)
- ✅ Automated ISO generation scripts

### 2. Adaptive Desktop Experience
- ✅ **First-Boot Onboarding Wizard**: Terminal UI (whiptail) to select preferences
- ✅ **Dynamic Desktop Morphing**: 
  - *Windows Style*: Installs/enables `dash-to-panel` for bottom taskbar
  - *macOS Style*: Enables `ubuntu-dock` bottom-centered with top-panel
  - *Linux Style*: Native GNOME layout
- ✅ **Elder Mode**: Automatically scales fonts by 125% and doubles cursor size
- ✅ **Beginner/Advanced Modes**: Intelligent layout scaling

### 3. Global Terminal Interceptor (Typo Engine)
- ✅ Smart CLI typo correction using Levenshtein distance & RapidFuzz
- ✅ Global Bash Hook: Intercepts `command_not_found_handle` in `/etc/bash.bashrc`
- ✅ **3-Second Auto-Execution**: Automatically runs the corrected command with a 3-second abort countdown
- ✅ Examples: `instal htop` → `sudo apt install -y htop`, `updat` → `sudo apt update && sudo apt upgrade -y`

### 4. PageTree Knowledge System
- ✅ Local documentation for WiFi, Printer, Updates, Software, Permissions
- ✅ Keyword → document mapping without relying on heavy Local LLMs

---

## Phase 2 🔄 (Professional Distro Upgrades)

### 1. Performance & Latency (The Interceptor)
- Rewrite the Python-based Terminal Interceptor in **Go** or **Rust** to reduce bash execution delay from ~150ms to < 5ms.

### 2. Graphical UX (The Wizard)
- Replace the terminal-based `whiptail` wizard with a **Graphical GTK4 / PyQt First-Boot App** featuring visual previews of the Windows/macOS layouts.

### 3. Complete Immersion (Branding)
- **Plymouth Boot Splash**: Design and inject a custom SMOS loading screen to replace the Ubuntu spinning circle.
- **Custom Installer**: Integrate Calamares with SMOS branding to replace the default Ubiquity installer.

### 4. Automated Build Pipeline
- Transition away from Cubic (manual GUI) to an automated CI/CD pipeline using **live-build** or **mkosi** for headless nightly ISO releases.

---

## Phase 3 🚀 (AI & Advanced Features)

### 1. Hybrid AI Architecture (Smart Router)
- Route simple terminal queries through the traditional ML engine (Zero latency).
- Route complex queries ("Explain Linux permissions") to a Local LLM.

### 2. Local LLM Integration
- Integrate Qwen2.5 (1.5B) or Phi-3 Mini locally via `llama.cpp`.
- Enable the terminal assistant to dynamically rewrite documentation into beginner-friendly explanations.

### 3. Voice Commands
- Speech-to-Text using Vosk or Whisper Small.
- Full Voice Assistant workflow: Speech → Intent Detection → Action Execution → Text-to-Speech.
