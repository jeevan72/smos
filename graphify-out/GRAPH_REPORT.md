# Graph Report - custumization  (2026-06-11)

## Corpus Check
- 28 files · ~33,596 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 182 nodes · 183 edges · 28 communities (14 shown, 14 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `decaaa3c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]

## God Nodes (most connected - your core abstractions)
1. `SimpleMode OS` - 9 edges
2. `Understanding File Permissions` - 9 edges
3. `PageTree` - 8 edges
4. `run_wizard()` - 8 edges
5. `How to Update Your System` - 8 edges
6. `Cubic Configuration Guide — SimpleMode OS` - 7 edges
7. `Managing Files and Folders` - 7 edges
8. `How to Set Up a Printer` - 7 edges
9. `How to Install and Remove Software` - 7 edges
10. `Terminal Basics` - 7 edges

## Surprising Connections (you probably didn't know these)
- `find_match()` --calls--> `levenshtein()`  [INFERRED]
  assistant/interceptor.py → assistant/assistant.py

## Import Cycles
- None detected.

## Communities (28 total, 14 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.14
Nodes (13): detect_intent(), fix_sentence(), fix_word(), levenshtein(), main(), PageTree, Fix a single word. Returns (corrected, was_fixed)., Fix typos in a full sentence. Returns (corrected, fixes_list). (+5 more)

### Community 1 - "Community 1"
Cohesion: 0.12
Nodes (15): 1. Hybrid AI Architecture (Smart Router), 1. OS Customization & Branding (Cubic), 1. Performance & Latency (The Interceptor), 2. Adaptive Desktop Experience, 2. Graphical UX (The Wizard), 2. Local LLM Integration, 3. Complete Immersion (Branding), 3. Global Terminal Interceptor (Typo Engine) (+7 more)

### Community 2 - "Community 2"
Cohesion: 0.13
Nodes (14): 1. Launch Cubic, 2. Clone Repository Inside Cubic, 3. Run the OS Integration Script, 4. Generate ISO, 🏗️ Architecture, 📋 Development Roadmap, 💻 End-User Experience (Once Installed), 🚀 How to Build the OS (For Developers) (+6 more)

### Community 3 - "Community 3"
Cohesion: 0.15
Nodes (12): Apply Branding, Cubic Configuration Guide — SimpleMode OS, Install Boot Splash, Install Packages, Set Up Welcome Screen (First Boot), Set Wallpaper, Step 1: Install Cubic, Step 2: Create Project (+4 more)

### Community 4 - "Community 4"
Cohesion: 0.18
Nodes (10): Changing File Ownership, Changing Permissions, Checking Permissions, Important Safety Notes, "Permission Denied" — What It Means, Quick Fixes, Troubleshooting, Understanding File Permissions (+2 more)

### Community 5 - "Community 5"
Cohesion: 0.18
Nodes (10): Common Mistakes, Essential Commands, File Operations, Keyboard Shortcuts in Terminal, Navigation, Opening the Terminal, System Commands, Terminal Basics (+2 more)

### Community 6 - "Community 6"
Cohesion: 0.42
Nodes (8): simplemode-wizard.sh script, apply_settings(), confirm_selection(), run_wizard(), save_profile(), select_desktop_style(), select_user_type(), welcome_screen()

### Community 7 - "Community 7"
Cohesion: 0.22
Nodes (8): Automatic Updates, How Often Should I Update?, How to Update Your System, Important Notes, One-Line Update Command, Quick Steps, Troubleshooting, Update via Terminal

### Community 8 - "Community 8"
Cohesion: 0.25
Nodes (7): Disk Space, File Operations via Terminal, Finding Files, Important Folders, Managing Files and Folders, Troubleshooting, Using the File Manager

### Community 9 - "Community 9"
Cohesion: 0.25
Nodes (7): files, permissions, printer, software, terminal, updates, wifi

### Community 10 - "Community 10"
Cohesion: 0.25
Nodes (7): Automatic Detection, How to Set Up a Printer, Install Printer Drivers, Quick Steps, Scanner Setup, Set Up Network Printer, Troubleshooting

### Community 11 - "Community 11"
Cohesion: 0.25
Nodes (7): Flatpak Packages, How to Install and Remove Software, Install via Terminal, Popular Applications, Snap Packages, Troubleshooting, Using the Software Center (Easiest)

### Community 12 - "Community 12"
Cohesion: 0.29
Nodes (6): Connect via Terminal, How to Connect to WiFi, If You Don't See Any Networks, Need More Help?, Quick Steps, Troubleshooting

### Community 13 - "Community 13"
Cohesion: 0.60
Nodes (5): setup.sh script, print_banner(), print_err(), print_info(), print_step()

## Knowledge Gaps
- **98 isolated node(s):** `build-iso.sh script`, `chroot-setup.sh script`, `welcome.sh script`, `App`, `Assistant` (+93 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `levenshtein()` connect `Community 0` to `Community 14`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `Compute Levenshtein distance between two strings.`, `Fix a single word. Returns (corrected, was_fixed).`, `Fix typos in a full sentence. Returns (corrected, fixes_list).` to the rest of the system?**
  _104 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.14130434782608695 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._