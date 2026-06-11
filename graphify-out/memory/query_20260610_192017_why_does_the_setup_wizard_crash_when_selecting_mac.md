---
type: "query"
date: "2026-06-10T19:20:17.753494+00:00"
question: "Why does the setup wizard crash when selecting macOS or Windows desktop styles, and why don't they apply?"
contributor: "graphify"
---

# Q: Why does the setup wizard crash when selecting macOS or Windows desktop styles, and why don't they apply?

## Answer

1. simplemode-wizard.sh was writing .simplemode-profile to the read-only /opt directory instead of $HOME. 2. disable-user-extensions was true in gsettings, so gnome-extensions commands were ignored. 3. ubuntu-dock extension package was missing for macOS layout. Fixed all three.