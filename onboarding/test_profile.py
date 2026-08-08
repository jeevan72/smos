from pathlib import Path

import pytest

from .profile import Profile, has_valid_profile, load_profile, save_profile


def test_profile_round_trip(tmp_path: Path) -> None:
    profile = Profile("elder", "macos", ("vlc", "obs-studio"))
    save_profile(profile, tmp_path)
    assert load_profile(tmp_path).user_type == "elder"
    assert load_profile(tmp_path).selected_software == ("vlc", "obs-studio")
    assert "USER_TYPE=elder" in (tmp_path / ".simplemode-profile").read_text()
    assert has_valid_profile(tmp_path)


def test_profile_rejects_invalid_values() -> None:
    with pytest.raises(ValueError):
        Profile("root", "linux")


def test_profile_rejects_invalid_app_id() -> None:
    with pytest.raises(ValueError):
        Profile("beginner", "linux", ("apt install vlc",))
