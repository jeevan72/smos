# SimpleMode OS

> An adaptive, user-friendly Linux distribution with intelligent onboarding, customizable desktop styles, and a built-in AI assistant.

![Phase](https://img.shields.io/badge/Phase-1%20(Prototype)-blue)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%2024.04-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Overview

SimpleMode OS is a customized Ubuntu-based operating system (built with **Cubic**) that adapts its interface based on user expertise level. It features:

- **Adaptive Onboarding** — First-boot terminal wizard (whiptail) that configures the desktop
- **3 User Modes** — Elder (large icons, high contrast), Beginner (simplified with help), Advanced (full Linux)
- **3 Desktop Styles** — Windows, macOS, or Linux layout
- **Built-in Terminal Assistant** — Chat-based help with typo correction and knowledge base
- **Smart Typo Correction** — Levenshtein + RapidFuzz fuzzy matching
- **PageTree Knowledge System** — Keyword-mapped documentation (no LLM required)
- **Cubic ISO Builder** — Scripts to build custom Ubuntu ISO

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USER/simplemode-os.git
cd simplemode-os
```

### 2. Run Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

This installs: Python venv (RapidFuzz, Rich), whiptail/dialog, Cubic, and verifies project structure.

### 3. Run the Onboarding Wizard

```bash
./simplemode-wizard.sh
```

Terminal UI wizard — select user type (Elder/Beginner/Advanced) and desktop style (Windows/macOS/Linux).

### 4. Run the Terminal Assistant

```bash
./simplemode-assistant.sh
```

Ask questions like:
- `how do i instal wfi` → auto-corrects → shows WiFi guide
- `upadte my system` → auto-corrects → shows update guide
- `permission denied` → shows permissions guide

### 5. Build Custom ISO (with Cubic)

```bash
./download-iso.sh    # Download Ubuntu 24.04 base ISO
./build-iso.sh       # Prepare and launch Cubic
```

Inside Cubic's chroot terminal, run:
```bash
bash /tmp/chroot-setup.sh
```

## 📁 Project Structure

```
simplemode-os/
├── setup.sh                    # One-click setup (installs everything)
├── simplemode-wizard.sh        # Terminal onboarding wizard (whiptail)
├── simplemode-assistant.sh     # Terminal assistant launcher
├── build-iso.sh                # Cubic ISO builder
├── download-iso.sh             # Ubuntu ISO downloader
├── chroot-setup.sh             # Runs inside Cubic chroot
│
├── assistant/
│   └── assistant.py            # Python terminal assistant (Rich TUI)
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
| Phase 1 | Onboarding, Adaptive UI, Typo Fix, PageTree, Assistant, Cubic ISO | ✅ Done |
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
