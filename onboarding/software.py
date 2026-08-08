#!/usr/bin/env python3
"""Curated software catalog and safe package transactions."""

from __future__ import annotations

import os
import shutil
import subprocess
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable


PopenFactory = Callable[..., subprocess.Popen[str]]


@dataclass(frozen=True)
class App:
    id: str
    name: str
    group: str
    description: str
    backend: str
    package: str
    probe: str
    state: str
    requires_root: bool
    multi_select: bool

    @property
    def installed(self) -> bool:
        return shutil.which(self.probe) is not None


@dataclass(frozen=True)
class Transaction:
    backend: str
    packages: tuple[str, ...]
    requires_root: bool = True

    def argv(self, escalation: str | None = None) -> list[str]:
        command = ["apt-get", "install", "-y", *self.packages]
        if escalation:
            return [escalation, *command]
        return command


def load_catalog(path: Path) -> tuple[App, ...]:
    with path.open("rb") as handle:
        data = tomllib.load(handle)
    apps: list[App] = []
    seen: set[str] = set()
    for item in data.get("apps", []):
        app = App(
            id=str(item["id"]),
            name=str(item["name"]),
            group=str(item["group"]),
            description=str(item["description"]),
            backend=str(item["backend"]),
            package=str(item["package"]),
            probe=str(item["probe"]),
            state=str(item["state"]),
            requires_root=bool(item.get("requires_root", True)),
            multi_select=bool(item.get("multi_select", True)),
        )
        if app.id in seen or app.backend not in {"apt"}:
            raise ValueError(f"Invalid or duplicate catalog app: {app.id}")
        if not app.package or any(char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.+_-" for char in app.package):
            raise ValueError(f"Invalid package name for {app.id}")
        seen.add(app.id)
        apps.append(app)
    return tuple(apps)


def plan_apt(apps: Iterable[App], selected_ids: Iterable[str]) -> Transaction | None:
    selected = set(selected_ids)
    packages = tuple(app.package for app in apps if app.id in selected and app.backend == "apt" and not app.installed and app.state != "builtin")
    return Transaction("apt", packages) if packages else None


def run_transaction(transaction: Transaction, escalation: str | None = "pkexec", popen_factory: PopenFactory | None = None) -> int:
    if not transaction.packages:
        return 0
    if shutil.which("apt-get") is None:
        raise RuntimeError("apt-get is not available")
    if escalation and shutil.which(escalation) is None:
        if shutil.which("sudo") is not None:
            escalation = "sudo"
        elif os.geteuid() == 0:
            escalation = None
        else:
            raise RuntimeError("No supported authorization tool is available")
    popen = popen_factory or subprocess.Popen
    process = popen(transaction.argv(escalation), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    assert process.stdout is not None
    for line in process.stdout:
        print(line, end="")
    return process.wait()
