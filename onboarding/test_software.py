from pathlib import Path

from .software import App, Transaction, load_catalog


def test_catalog_loads() -> None:
    apps = load_catalog(Path(__file__).with_name("catalog.toml"))
    assert {app.id for app in apps} >= {"firefox", "vlc", "thunderbird"}


def test_transaction_uses_fixed_argv() -> None:
    transaction = Transaction("apt", ("vlc", "gimp"))
    assert transaction.argv("pkexec") == ["pkexec", "apt-get", "install", "-y", "vlc", "gimp"]
