# SimpleMode OS

> An adaptive, user-friendly Linux distribution with intelligent onboarding, customizable desktop styles, and a built-in AI assistant.

![Phase](https://img.shields.io/badge/Phase-1%20(Prototype)-blue)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%2024.04-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Overview

SimpleMode OS is a customized Ubuntu-based operating system (built with **Cubic**) that adapts its interface based on user expertise level. It features:

- **Adaptive Onboarding** — GTK4 first-boot setup for mode, layout, and software, with a terminal wizard fallback
- **3 User Modes** — Elder (large icons, high contrast), Beginner (simplified with help), Advanced (full Linux)
- **3 Desktop Styles** — Windows-inspired, macOS-inspired, or native Linux layout
- **Built-in Software Setup** — curated optional apps with safe package installation
- **Built-in System Toolbox** — Pre-installed [Linutil](https://github.com/ChrisTitusTech/linutil) (Chris Titus Tech's Rust toolbox) for system setup and maintenance
- **Built-in Terminal Assistant** — Chat-based help with typo correction and knowledge base
- **Smart Typo Correction** — Levenshtein + RapidFuzz fuzzy matching
- **PageTree Knowledge System** — Keyword-mapped documentation (no LLM required)

## 🚀 One-command install

Install the complete SimpleMode desktop experience on Ubuntu or Debian with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/jeevan72/smos/main/install.sh | sh
```

Pinned install (recommended for reproducibility):

```bash
SMOS_REF=4a11c34 curl -fsSL https://raw.githubusercontent.com/jeevan72/smos/main/install.sh | sh
```

The installer adds the GTK onboarding app, terminal wizard fallback, assistant, knowledge base, typed interceptor hook (autocorrects typos like `instal` → `sudo apt install`), and checksum-verified Linutil toolbox. It installs per-user launchers under `~/.local/bin` and only uses `sudo` for system packages.

After installation, open a new terminal and run:

```bash
simplemode
```

Or any of these individually:

```bash
simplemode-onboarding   # GTK graphical setup
simplemode-wizard       # Terminal wizard fallback
simplemode-assistant    # Knowledge base + typo assistant
linutil                 # System toolbox
```

`simplemode` is the smart entry point — it launches the wizard if you haven't configured yet, otherwise drops you into the assistant. You can also launch **SimpleMode setup** from the application menu.

### Developer checkout

For development or ISO creation:

```bash
git clone https://github.com/jeevan72/smos.git
cd smos
./setup.sh
```

> `setup.sh` installs dependencies into the checkout and is intended for development. The one-command installer is the recommended end-user path.

## 🛠️ How to Build the OS ISO (For Developers)

SimpleMode OS is designed to be built using **Cubic** (Custom Ubuntu ISO Creator). You can use any existing Ubuntu 24.04 ISO.

### 1. Launch Cubic
On your host machine, run Cubic and select your base Ubuntu ISO. Proceed through the wizard until you reach the **Virtual Environment (Chroot)** terminal page.

### 2. Clone Repository Inside Cubic
Inside the Cubic chroot terminal, run:

```bash
git clone https://github.com/jeevan72/smos.git /opt/simplemode-src
cd /opt/simplemode-src
```

### 3. Run the OS Integration Script
Execute the chroot configuration script to bake SimpleMode OS natively into the system:

```bash
chmod +x chroot-setup.sh
./chroot-setup.sh
```

This automatically:
- Installs all necessary dependencies (Python, Whiptail, accessibility tools)
- Removes bloatware
- Installs the **Linutil System Toolbox** for system setup and maintenance
- Configures the **Global Command Interceptor** in `/etc/bash.bashrc`
- Installs the **PageTree Knowledge Base** and **Typo Correction Engine**
- Sets the adaptive onboarding wizard to run automatically on first-boot

### 4. Generate ISO
Click **Next** in Cubic to compress the filesystem and generate your custom, bootable `simplemode-os.iso`.

---

## 💻 End-User Experience (Once Installed)

When an end-user installs and boots SimpleMode OS, everything works automatically. **The user does not need to run any manual setup scripts.**

- **Adaptive First Boot**: A GTK setup app launches automatically and guides you through experience mode, desktop layout, and optional software. The `simplemode-wizard` terminal flow remains available as a fallback.
- **Built-in Software Setup**: Included apps are detected automatically, while optional software such as Thunderbird, OBS Studio, and Chromium can be selected and installed from the setup screen.
- **System Toolbox**: `linutil` is pre-installed — a terminal toolbox with hundreds of tasks for app installs, system optimization, and maintenance.
- **Smart Terminal**: If the user opens a terminal and types a bad command (e.g., `updat` or `instal vlc`), the OS intercepts it natively, corrects it to `sudo apt update` or `sudo apt install vlc`, and executes it automatically after a 3-second countdown.
- **AI Assistant**: The user can type `help` at any time in the terminal to invoke the adaptive chat assistant, which has local knowledge about WiFi, Printers, Permissions, Updates, and more.

## 📁 Project Structure

```
simplemode-os/
├── setup.sh                    # Dev setup (installs deps into the checkout)
├── install.sh                  # One-command curl installer with interceptor hook
├── simplemode-wizard.sh        # Terminal onboarding wizard (whiptail)
├── simplemode-assistant.sh     # Terminal assistant launcher
├── simplemode-onboarding       # GTK first-boot setup launcher
├── run.sh                      # Wizard → assistant auto-runner
├── onboarding/                 # GTK app, desktop adapter, and software catalog
├── chroot-setup.sh             # Runs inside Cubic chroot
│
├── assistant/
│   ├── assistant.py            # Python terminal assistant (Rich TUI)
│   └── interceptor.py          # Bash command_not_found_handle typo engine
│
├── knowledge/                  # PageTree knowledge base
│   ├── index.json              # Keyword → document mapping
│   ├── wifi.md                 # WiFi guide
│   ├── printer.md              # Printer setup
│   ├── updates.md              # System updates
│   ├── software.md             # Software management
│   ├── permissions.md          # File permissions
│   ├── files.md                # File management
│   └── terminal.md             # Terminal basics
│
├── debian/                     # Cubic customization files
│   ├── cubic-config.md         # Cubic setup guide
│   ├── packages.list           # Pre-installed packages
│   ├── branding/os-release     # OS branding
│   └── welcome/welcome.sh     # First-boot script
│
├── demo/                       # Optional web demo (bonus)
│   ├── index.html
│   ├── css/ & js/
│
└── docs/
    └── roadmap.md              # Phase breakdown for examiners
```

## 🏗️ Architecture

```
User Question
     ↓
Typo Fix (Levenshtein + RapidFuzz)
     ↓
Intent Detection (Keyword Matching)
     ↓
PageTree Knowledge Lookup
     ↓
Adaptive Response (mode-aware)
```

## 📋 Development Roadmap

| Phase | Features | Status |
|-------|----------|--------|
| Phase 1 | Onboarding, Adaptive UI, Typo Fix, PageTree, Assistant | ✅ Done |
| Phase 2 | Intent Classification (TF-IDF), Action Engine, Voice | 🔄 Next |
| Phase 3 | Local LLM (Qwen2.5/Phi-3), Enhanced Responses | 🚀 Planned |
| Phase 4 | Hybrid AI (Smart Router), Query Optimization | 🚀 Planned |
| Phase 5 | Full RAG, User Learning Engine, Voice Assistant | 🚀 Future |

See [docs/roadmap.md](docs/roadmap.md) for detailed breakdown.

## 🧪 Testing

```bash
# Test the wizard
./simplemode-wizard.sh

# Test the assistant
./simplemode-assistant.sh

# Test with specific mode
source venv/bin/activate
python3 assistant/assistant.py --knowledge knowledge --mode elder
```

### Test Typo Correction

```
Input:  how do i instal wfi
Output: how do i install wifi
        → Shows WiFi connection guide

Input:  upadte my sofware
Output: update my software
        → Shows update guide
```

## 📄 License

MIT License
