#!/usr/bin/env python3
"""GNOME capability checks, preset application, and rollback."""

from __future__ import annotations

import json
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


Runner = Callable[..., subprocess.CompletedProcess[str]]


@dataclass(frozen=True)
class DesktopResult:
    success: bool
    message: str
    rollback_available: bool = False


class DesktopAdapter:
    def __init__(self, runner: Runner | None = None, home: Path | None = None) -> None:
        self.runner = runner or subprocess.run
        self.home = home or Path.home()
        self.state_dir = self.home / ".local" / "state" / "simplemode"

    def _run(self, argv: list[str]) -> subprocess.CompletedProcess[str]:
        return self.runner(argv, check=False, capture_output=True, text=True)

    def detect(self) -> tuple[bool, str]:
        if os.environ.get("XDG_CURRENT_DESKTOP", "").lower() not in {"gnome", "ubuntu:gnome", "ubuntu"}:
            return False, "GNOME desktop was not detected."
        if not os.environ.get("DBUS_SESSION_BUS_ADDRESS"):
            return False, "No D-Bus desktop session is available."
        result = self._run(["gsettings", "list-schemas"])
        if result.returncode != 0:
            return False, "GNOME settings are unavailable in this session."
        return True, "GNOME desktop detected."

    def _get(self, schema: str, key: str) -> str:
        result = self._run(["gsettings", "get", schema, key])
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or f"Could not read {schema} {key}")
        return result.stdout.strip()

    def _set(self, schema: str, key: str, value: str) -> None:
        result = self._run(["gsettings", "set", schema, key, value])
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or f"Could not set {schema} {key}")

    def _extension_available(self, extension: str) -> bool:
        result = self._run(["gnome-extensions", "info", extension])
        return result.returncode == 0

    def _extension_state(self, extension: str) -> bool:
        result = self._run(["gnome-extensions", "info", extension])
        return result.returncode == 0 and "State: ENABLED" in result.stdout

    def snapshot(self) -> Path:
        self.state_dir.mkdir(parents=True, exist_ok=True)
        snapshot = {
            "text-scaling-factor": self._get("org.gnome.desktop.interface", "text-scaling-factor"),
            "cursor-size": self._get("org.gnome.desktop.interface", "cursor-size"),
            "button-layout": self._get("org.gnome.desktop.wm.preferences", "button-layout"),
            "extensions": {
                "dash-to-panel@jderose9.github.com": self._extension_state("dash-to-panel@jderose9.github.com"),
                "ubuntu-dock@ubuntu.com": self._extension_state("ubuntu-dock@ubuntu.com"),
            },
        }
        path = self.state_dir / "desktop-snapshot.json"
        path.write_text(json.dumps(snapshot, indent=2) + "\n", encoding="utf-8")
        return path

    def apply(self, user_type: str, desktop_style: str) -> DesktopResult:
        detected, message = self.detect()
        if not detected:
            return DesktopResult(False, message)
        try:
            snapshot = self.snapshot()
            mode_values = {
                "elder": ("1.25", "48"),
                "beginner": ("1.0", "24"),
                "advanced": ("1.0", "24"),
            }
            if user_type not in mode_values:
                return DesktopResult(False, f"Unsupported user mode: {user_type}", True)
            if desktop_style not in {"windows", "macos", "linux"}:
                return DesktopResult(False, f"Unsupported desktop style: {desktop_style}", True)
            required_extension = "dash-to-panel@jderose9.github.com" if desktop_style == "windows" else "ubuntu-dock@ubuntu.com"
            if not self._extension_available(required_extension):
                return DesktopResult(False, f"Required GNOME extension is unavailable: {required_extension}", True)
            scaling, cursor = mode_values[user_type]
            self._set("org.gnome.desktop.interface", "text-scaling-factor", scaling)
            self._set("org.gnome.desktop.interface", "cursor-size", cursor)
            self._set("org.gnome.desktop.wm.preferences", "button-layout", {
                "windows": "appmenu:minimize,maximize,close",
                "macos": "close,minimize,maximize:appmenu",
                "linux": "appmenu:minimize,maximize,close",
            }[desktop_style])
            for extension in ("dash-to-panel@jderose9.github.com", "ubuntu-dock@ubuntu.com"):
                self._run(["gnome-extensions", "disable", extension])
            if desktop_style == "windows":
                self._run(["gnome-extensions", "enable", "dash-to-panel@jderose9.github.com"])
            else:
                self._run(["gnome-extensions", "enable", "ubuntu-dock@ubuntu.com"])
                dock_values = {
                    "macos": ("BOTTOM", "false", "false", "true"),
                    "linux": ("LEFT", "true", "true", "false"),
                }[desktop_style]
                for key, value in zip(("dock-position", "extend-height", "dock-fixed", "intellihide"), dock_values):
                    self._set("org.gnome.shell.extensions.dash-to-dock", key, value)
            return DesktopResult(True, f"Applied {desktop_style} layout and {user_type} mode.", True)
        except (OSError, RuntimeError) as error:
            return DesktopResult(False, str(error), True)

    def restore(self) -> DesktopResult:
        path = self.state_dir / "desktop-snapshot.json"
        if not path.is_file():
            return DesktopResult(False, "No desktop snapshot is available.")
        try:
            snapshot = json.loads(path.read_text(encoding="utf-8"))
            self._set("org.gnome.desktop.interface", "text-scaling-factor", snapshot["text-scaling-factor"])
            self._set("org.gnome.desktop.interface", "cursor-size", snapshot["cursor-size"])
            self._set("org.gnome.desktop.wm.preferences", "button-layout", snapshot["button-layout"])
            for extension, enabled in snapshot["extensions"].items():
                self._run(["gnome-extensions", "enable" if enabled else "disable", extension])
            return DesktopResult(True, "Previous desktop settings restored.")
        except (OSError, KeyError, json.JSONDecodeError, RuntimeError) as error:
            return DesktopResult(False, f"Could not restore desktop settings: {error}")
