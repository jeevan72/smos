#!/usr/bin/env python3
import sys
import time
import subprocess
import shlex

# Mapping from recognized command keywords to the actual command(s) to run.
# Keys are single words with no spaces (so Levenshtein matching stays sane),
# and we only auto-execute commands that are SAFE to run non-interactively.
# Anything requiring interactivity (install) goes through its own handler.
SAFE_COMMANDS = {
    "wifi": ["nmcli", "device", "wifi", "list"],
    "wlan": ["nmcli", "device", "wifi", "list"],
    "network": ["nmcli", "connection", "show"],
    "files": ["nautilus"],
    "file": ["nautilus"],
    "clean": ["sudo", "apt", "autoremove", "-y"],
    "reboot": ["sudo", "reboot"],
    "restart": ["sudo", "reboot"],
    "shutdown": ["sudo", "poweroff"],
    "poweroff": ["sudo", "poweroff"],
    "clear": ["clear"],
    "help": ["simplemode-assistant"],
}

# Install-type keywords routed through the interactive package handler.
INSTALL_COMMANDS = {"install", "remove", "uninstall"}

# Commands that take extra arguments from the user.
ARG_COMMANDS = {"install", "remove", "uninstall", "clean"}

# Misspelling rules (command name -> canonical keyword in the maps above)
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

# update / upgrade are intentionally NOT auto-run: they would silently run
# "sudo apt upgrade -y" with no password prompt available and no confirmation,
# which is surprising and risky from a typo interceptor. They can still be
# launched manually (see note below).
HANDLED_KEYWORDS = set(SAFE_COMMANDS) | set(INSTALL_COMMANDS) | set(CORRECTIONS.values()) | {"update", "upgrade"}


def levenshtein(a: str, b: str) -> int:
    """Compute Levenshtein distance between two strings."""
    m, n = len(a), len(b)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if a[i - 1] == b[j - 1]:
                dp[i][j] = dp[i - 1][j - 1]
            else:
                dp[i][j] = 1 + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
    return dp[m][n]


def find_match(cmd_name: str):
    """Return the canonical keyword for a (possibly misspelled) command, or None."""
    # Direct typo override
    if cmd_name in CORRECTIONS:
        return CORRECTIONS[cmd_name]

    # Levenshtein match against known keywords (distance <= 2)
    best_match = None
    best_dist = 999
    for key in HANDLED_KEYWORDS:
        if " " in key:
            continue
        dist = levenshtein(cmd_name, key)
        if dist <= 2 and dist < best_dist:
            best_match = key
            best_dist = dist
    return best_match


def run_interactive_install(cmd_name: str, cmd_args):
    """Interactive multi-manager package search + install. Handles cancel gracefully."""
    if not cmd_args:
        print("\033[1;31m[!] Nothing to install. Usage: instal <package-name>\033[0m")
        sys.exit(127)

    pkg_name = cmd_args[0]
    if any(ch in pkg_name for ch in "&|;`$\n"):
        print("\033[1;31m[!] Invalid package name.\033[0m")
        sys.exit(127)

    # Map of source name -> (search argv, parse fn, install argv)
    # Search/install commands are built with argv lists (no shell), and
    # package names are validated to contain only safe characters.
    import re
    if not re.fullmatch(r"[A-Za-z0-9._+-]+", pkg_name):
        print("\033[1;31m[!] Invalid package name.\033[0m")
        sys.exit(127)

    print(f"\n\033[1;36m[*] Searching for '{pkg_name}' across package managers...\033[0m")
    options = []

    # 1. APT exact search
    try:
        res = subprocess.run(["apt-cache", "search", f"^{pkg_name}$"],
                             capture_output=True, text=True, timeout=15)
        if res.stdout.strip():
            line = res.stdout.strip().splitlines()[0]
            name, _, desc = line.partition(" - ")
            options.append({"mgr": "apt", "argv": ["sudo", "apt", "install", "-y", name],
                            "display": f"[APT] {name} - {desc}"})
    except Exception:
        pass

    # 2. APT broad search
    if not options:
        try:
            res = subprocess.run(["apt-cache", "search", pkg_name],
                                 capture_output=True, text=True, timeout=15)
            line = res.stdout.strip().splitlines()[0] if res.stdout.strip() else ""
            if line:
                name, _, desc = line.partition(" - ")
                options.append({"mgr": "apt", "argv": ["sudo", "apt", "install", "-y", name],
                                "display": f"[APT] {name} - {desc}"})
        except Exception:
            pass

    # 3. Snap search
    try:
        res = subprocess.run(["snap", "find", pkg_name], capture_output=True, text=True, timeout=15)
        lines = [l for l in res.stdout.strip().splitlines() if l.strip()]
        if len(lines) > 1:
            parts = lines[1].split()
            if parts:
                name = parts[0]
                desc = " ".join(parts[1:]) if len(parts) > 1 else "Snap Package"
                options.append({"mgr": "snap", "argv": ["sudo", "snap", "install", name],
                                "display": f"[SNAP] {name} - {desc}"})
    except Exception:
        pass

    # 4. Flatpak search
    if subprocess.run(["command", "-v", "flatpak"], capture_output=True).returncode == 0:
        try:
            res = subprocess.run(["flatpak", "search", pkg_name], capture_output=True, text=True, timeout=15)
            out = res.stdout.strip()
            if out and not out.startswith("No matches"):
                parts = out.split("\t")
                if len(parts) >= 2:
                    name, app_id = parts[0], parts[1]
                    options.append({"mgr": "flatpak", "argv": ["flatpak", "install", "-y", app_id],
                                    "display": f"[FLATPAK] {name} ({app_id})"})
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
            if choice == "c":
                print("\033[1;31mCancelled.\033[0m")
                sys.exit(130)

            idx = int(choice) - 1
            if 0 <= idx < len(options):
                exec_argv = options[idx]["argv"]
                print(f"\n\033[1;32mExecuting: {shlex.join(exec_argv)}\033[0m\n")
                res = subprocess.run(exec_argv)
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
        # Not a command we know or can correct — fall through to bash's own handler.
        print(f"bash: {cmd_name}: command not found")
        sys.exit(127)

    # Interactive package management
    if corrected_name in INSTALL_COMMANDS:
        run_interactive_install(cmd_name, cmd_args)

    # update / upgrade are handled (typo-corrected) but NOT auto-executed:
    # running "sudo apt upgrade -y" with zero confirmation is a bad default.
    if corrected_name in ("update", "upgrade"):
        print(f"\033[1;33m[!] Did you mean: 'sudo apt update && sudo apt upgrade'?\033[0m")
        print("\033[1;32m[+] Run it yourself:  sudo apt update && sudo apt upgrade\033[0m")
        sys.exit(127)

    base_argv = list(SAFE_COMMANDS[corrected_name])
    if corrected_name in ARG_COMMANDS and cmd_args:
        base_argv = base_argv + cmd_args

    exec_argv = base_argv
    print(f"\n\033[1;33m[!] Command not found: '{cmd_name}'\033[0m")
    print(f"\033[1;32m[+] Did you mean: '{shlex.join(exec_argv)}'?\033[0m")
    print("\033[1;36mPress Ctrl+C to cancel...\033[0m")

    # 3 second countdown
    try:
        for i in range(3, 0, -1):
            print(f"Executing in {i} seconds...", end="\r", flush=True)
            time.sleep(1)
        print("\n\033[1;32mExecuting...\033[0m\n")
        try:
            res = subprocess.run(exec_argv)
        except FileNotFoundError:
            print(f"\033[1;31m[!] Could not run: {shlex.join(exec_argv)}\033[0m")
            sys.exit(127)
        sys.exit(res.returncode)
    except KeyboardInterrupt:
        print("\n\033[1;31mCancelled.\033[0m")
        sys.exit(130)


if __name__ == "__main__":
    main()
