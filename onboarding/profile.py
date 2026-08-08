#!/usr/bin/env python3
"""Validated SimpleMode profile storage."""

from __future__ import annotations

import json
import os
import tempfile
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path

USER_TYPES = ("elder", "beginner", "advanced")
DESKTOP_STYLES = ("windows", "macos", "linux")


@dataclass(frozen=True)
class Profile:
    user_type: str
    desktop_style: str
    selected_software: tuple[str, ...] = ()
    desktop_environment: str = "gnome"
    schema_version: int = 1
    adapter_version: str = "1"
    applied_at: str = ""

    def __post_init__(self) -> None:
        if self.user_type not in USER_TYPES:
            raise ValueError(f"Unsupported user type: {self.user_type}")
        if self.desktop_style not in DESKTOP_STYLES:
            raise ValueError(f"Unsupported desktop style: {self.desktop_style}")
        if self.desktop_environment != "gnome":
            raise ValueError(f"Unsupported desktop environment: {self.desktop_environment}")
        if self.schema_version != 1:
            raise ValueError(f"Unsupported profile schema: {self.schema_version}")
        if any(not item or any(char not in "abcdefghijklmnopqrstuvwxyz0123456789-_" for char in item) for item in self.selected_software):
            raise ValueError("Invalid software identifier")

    def to_dict(self) -> dict[str, object]:
        return asdict(self) | {"selected_software": list(self.selected_software)}


def default_config_dir(home: Path | None = None) -> Path:
    return (home or Path.home()) / ".config" / "simplemode"


def profile_path(home: Path | None = None) -> Path:
    return default_config_dir(home) / "profile.json"


def compatibility_path(home: Path | None = None) -> Path:
    return (home or Path.home()) / ".simplemode-profile"


def load_profile(home: Path | None = None) -> Profile | None:
    path = profile_path(home)
    if not path.is_file():
        return None
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    return Profile(
        user_type=str(data["user_type"]),
        desktop_style=str(data["desktop_style"]),
        selected_software=tuple(str(item) for item in data.get("selected_software", [])),
        desktop_environment=str(data.get("desktop_environment", "gnome")),
        schema_version=int(data.get("schema_version", 1)),
        adapter_version=str(data.get("adapter_version", "1")),
        applied_at=str(data.get("applied_at", "")),
    )


def _atomic_write(path: Path, content: str, mode: int = 0o600) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        try:
            os.chmod(temporary, mode)
        except OSError:
            pass
        os.replace(temporary, path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def save_profile(profile: Profile, home: Path | None = None) -> None:
    applied = profile.applied_at or datetime.now(timezone.utc).isoformat()
    saved = Profile(
        user_type=profile.user_type,
        desktop_style=profile.desktop_style,
        selected_software=profile.selected_software,
        desktop_environment=profile.desktop_environment,
        schema_version=profile.schema_version,
        adapter_version=profile.adapter_version,
        applied_at=applied,
    )
    path = profile_path(home)
    _atomic_write(path, json.dumps(saved.to_dict(), indent=2) + "\n")
    compatibility = f"USER_TYPE={saved.user_type}\nDESKTOP_STYLE={saved.desktop_style}\n"
    _atomic_write(compatibility_path(home), compatibility)


def has_valid_profile(home: Path | None = None) -> bool:
    try:
        return load_profile(home) is not None
    except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError):
        return False
