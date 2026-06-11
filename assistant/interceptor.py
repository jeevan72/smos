#!/usr/bin/env python3
import sys
import os
import time
import subprocess
import re

# Add assistant directory to path to reuse typo correction if needed
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Define key mapping from common intent keywords/commands to actual execution commands
COMMAND_MAPs = {
    "update": "sudo apt update && sudo apt upgrade -y",
    "upgrade": "sudo apt update && sudo apt upgrade -y",
    "install": "sudo apt install -y",
    "remove": "sudo apt remove -y",
    "uninstall": "sudo apt remove -y",
    "wifi": "nmcli device wifi list",
    "wlan": "nmcli device wifi list",
    "network": "nmcli connection show",
    "printer": "system-config-printer",
    "files": "nautilus . &",
    "file": "nautilus . &",
    "clean": "sudo apt autoremove -y && sudo apt clean",
    "reboot": "sudo reboot",
    "restart": "sudo reboot",
    "shutdown": "sudo poweroff",
    "poweroff": "sudo poweroff",
    "clear": "clear",
    "help": "simplemode-assistant",
}

# Misspelling rules
CORRECTIONS = {
    "updat": "update",
    "updte": "update",
    "upadte": "update",
    "udpate": "update",
    "instal": "install",
    "intall": "install",
    "istall": "install",
    "wfi": "wifi",
    "wif": "wifi",
    "cleer": "clear",
    "cler": "clear",
    "rebot": "reboot",
    "shudown": "shutdown",
    "shtdown": "shutdown",
}

def find_match(cmd_name):
    # Direct typo override
    if cmd_name in CORRECTIONS:
        return CORRECTIONS[cmd_name]
    
    # Check if a word in command_maps is close (Levenshtein)
    from assistant import levenshtein
    best_match = None
    best_dist = 999
    
    for key in COMMAND_MAPs.keys():
        dist = levenshtein(cmd_name, key)
        if dist <= 2 and dist < best_dist:
            best_match = key
            best_dist = dist
            
    return best_match

def handle_install(cmd_args):
    pkg_name = cmd_args[0]
    print(f"\n\033[1;36m[*] Searching for '{pkg_name}' across package managers...\033[0m")
    
    options = []
    
    # 1. APT search
    try:
        res = subprocess.run(f"apt-cache search '^{pkg_name}$' | head -n 1", shell=True, capture_output=True, text=True)
        if res.stdout.strip():
            desc = res.stdout.strip().split(" - ", 1)[-1] if " - " in res.stdout else "APT Package"
            options.append({"mgr": "apt", "cmd": f"sudo apt install -y {pkg_name}", "display": f"[APT] {pkg_name} - {desc}"})
        else:
            # Try a broader search if exact match fails
            res = subprocess.run(f"apt-cache search {pkg_name} | head -n 1", shell=True, capture_output=True, text=True)
            if res.stdout.strip():
                parts = res.stdout.strip().split(" - ", 1)
                name = parts[0]
                desc = parts[1] if len(parts) > 1 else "APT Package"
                options.append({"mgr": "apt", "cmd": f"sudo apt install -y {name}", "display": f"[APT] {name} - {desc}"})
    except Exception:
        pass

    # 2. Snap search
    try:
        res = subprocess.run(f"snap find {pkg_name} | awk 'NR==2 {{print $1, $4}}'", shell=True, capture_output=True, text=True)
        out = res.stdout.strip()
        if out:
            parts = out.split(maxsplit=1)
            name = parts[0]
            desc = parts[1] if len(parts) > 1 else "Snap Package"
            options.append({"mgr": "snap", "cmd": f"sudo snap install {name}", "display": f"[SNAP] {name} - {desc}"})
    except Exception:
        pass

    # 3. Flatpak search
    if subprocess.run("command -v flatpak", shell=True, capture_output=True).returncode == 0:
        try:
            res = subprocess.run(f"flatpak search {pkg_name} | head -n 1", shell=True, capture_output=True, text=True)
            out = res.stdout.strip()
            if out and not out.startswith("No matches"):
                parts = out.split('\t')
                if len(parts) >= 2:
                    name = parts[0]
                    app_id = parts[1]
                    options.append({"mgr": "flatpak", "cmd": f"flatpak install -y {app_id}", "display": f"[FLATPAK] {name} ({app_id})"})
        except Exception:
            pass

    if not options:
        print(f"\033[1;31m[!] No packages found for '{pkg_name}'.\033[0m")
        sys.exit(1)

    print("\n\033[1;32mFound the following options:\033[0m")
    for i, opt in enumerate(options, 1):
        print(f"  {i}. {opt['display']}")
    print("  c. Cancel")
    
    while True:
        try:
            choice = input("\n\033[1;33mShall I install? Select a number (or 'c' to cancel): \033[0m").strip().lower()
            if choice == 'c':
                print("\033[1;31mCancelled.\033[0m")
                sys.exit(130)
            
            idx = int(choice) - 1
            if 0 <= idx < len(options):
                exec_cmd = options[idx]['cmd']
                print(f"\n\033[1;32mExecuting: {exec_cmd}\033[0m\n")
                res = subprocess.run(exec_cmd, shell=True)
                sys.exit(res.returncode)
            else:
                print("Invalid selection.")
        except ValueError:
            print("Invalid input. Enter a number or 'c'.")
        except KeyboardInterrupt:
            print("\n\033[1;31mCancelled.\033[0m")
            sys.exit(130)

def main():
    if len(sys.argv) < 2:
        sys.exit(127)

    args = sys.argv[1:]
    cmd_name = args[0]
    cmd_args = args[1:]

    corrected_name = find_match(cmd_name)
    if not corrected_name:
        # Command not found in our mapping
        print(f"bash: {cmd_name}: command not found")
        sys.exit(127)

    # Special logic for interactive package installation
    if corrected_name == "install" and cmd_args:
        handle_install(cmd_args)

    # Reconstruct execution command
    base_exec = COMMAND_MAPs[corrected_name]
    if cmd_args:
        # If user typed "instal vlc", we map to "sudo apt install -y vlc"
        exec_cmd = f"{base_exec} {' '.join(cmd_args)}"
    else:
        exec_cmd = base_exec

    print(f"\n\033[1;33m[!] Command not found: '{cmd_name}'\033[0m")
    print(f"\033[1;32m[✓] Did you mean: '{exec_cmd}'?\033[0m")
    print("\033[1;36mPress Ctrl+C to cancel...\033[0m")

    # 3 second countdown
    try:
        for i in range(3, 0, -1):
            print(f"Executing in {i} seconds...", end="\r", flush=True)
            time.sleep(1)
        print("\n\033[1;32mExecuting...\033[0m\n")
        
        # Execute command in system
        res = subprocess.run(exec_cmd, shell=True)
        sys.exit(res.returncode)
    except KeyboardInterrupt:
        print("\n\033[1;31mCancelled.\033[0m")
        sys.exit(130)

if __name__ == "__main__":
    main()
