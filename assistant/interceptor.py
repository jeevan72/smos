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
