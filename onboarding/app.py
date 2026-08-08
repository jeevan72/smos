#!/usr/bin/env python3
"""SimpleMode GTK4 onboarding application."""

from __future__ import annotations

import os
import sys
import threading
from pathlib import Path

try:
    import gi

    gi.require_version("Gtk", "4.0")
    from gi.repository import GLib, Gtk
except (ImportError, ValueError) as error:
    raise SystemExit(f"GTK4 dependencies are unavailable: {error}") from error

from .desktop import DesktopAdapter
from .profile import Profile, save_profile
from .software import App, load_catalog, plan_apt, run_transaction

ROOT = Path(__file__).resolve().parent

MODE_INFO = {
    "elder": ("Elder mode", "Larger text and cursor, with a calmer interface for easier reading."),
    "beginner": ("Beginner mode", "A guided desktop with the standard scale and helpful onboarding."),
    "advanced": ("Advanced mode", "The full desktop with standard scale and fewer guided choices."),
}
STYLE_INFO = {
    "windows": ("Windows-inspired layout", "A bottom taskbar with familiar right-side window controls."),
    "macos": ("macOS-inspired layout", "A floating bottom dock with left-side window controls."),
    "linux": ("Native Linux layout", "GNOME conventions with a left dock and standard controls."),
}


class OnboardingWindow(Gtk.ApplicationWindow):
    def __init__(self, application: Gtk.Application) -> None:
        super().__init__(application=application, title="SimpleMode setup")
        self.set_default_size(980, 680)
        self.set_size_request(720, 560)
        self.user_type = "beginner"
        self.desktop_style = "linux"
        self.selected_software: set[str] = set()
        self.apps = load_catalog(ROOT / "catalog.toml")
        self.pages = Gtk.Stack(transition_type=Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.steps = ["Mode", "Layout", "Software", "Review"]
        self.step_labels: list[Gtk.Label] = []
        self.status_label = Gtk.Label()
        self.status_label.set_wrap(True)
        self.status_label.set_xalign(0)
        self._build()

    def _build(self) -> None:
        root = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        root.add_css_class("window-root")
        self.set_child(root)
        root.append(self._build_sidebar())
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        content.set_hexpand(True)
        content.set_vexpand(True)
        root.append(content)
        content.append(self.pages)
        content.append(self._build_navigation())
        self._add_pages()
        self._load_css()

    def _build_sidebar(self) -> Gtk.Widget:
        sidebar = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        sidebar.set_size_request(220, -1)
        sidebar.set_margin_top(32)
        sidebar.set_margin_bottom(32)
        sidebar.set_margin_start(28)
        sidebar.set_margin_end(20)
        brand = Gtk.Label(label="SimpleMode")
        brand.set_xalign(0)
        brand.add_css_class("brand")
        sidebar.append(brand)
        subtitle = Gtk.Label(label="Set up your Linux desktop")
        subtitle.set_xalign(0)
        subtitle.set_wrap(True)
        subtitle.add_css_class("muted")
        sidebar.append(subtitle)
        for index, step in enumerate(self.steps):
            label = Gtk.Label(label=f"{index + 1}  {step}")
            label.set_xalign(0)
            label.add_css_class("step")
            if index == 0:
                label.add_css_class("step-active")
            self.step_labels.append(label)
            sidebar.append(label)
        note = Gtk.Label(label="You can change these choices later by running simplemode-wizard.")
        note.set_xalign(0)
        note.set_wrap(True)
        note.set_valign(Gtk.Align.END)
        note.set_vexpand(True)
        note.add_css_class("muted")
        sidebar.append(note)
        return sidebar

    def _build_navigation(self) -> Gtk.Widget:
        bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        bar.set_margin_top(16)
        bar.set_margin_bottom(22)
        bar.set_margin_start(28)
        bar.set_margin_end(28)
        back = Gtk.Button(label="Back")
        back.connect("clicked", self._back)
        back.add_css_class("secondary")
        self.back_button = back
        bar.append(back)
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        bar.append(spacer)
        next_button = Gtk.Button(label="Continue")
        next_button.add_css_class("suggested-action")
        self.next_handler = next_button.connect("clicked", self._next)
        self.next_button = next_button
        bar.append(next_button)
        return bar

    def _add_pages(self) -> None:
        self.pages.add_named(self._choice_page("Choose your experience", "The desktop will adjust its scale and guidance to match you.", MODE_INFO, "mode"), "mode")
        self.pages.add_named(self._choice_page("Choose your layout", "These are layout presets inspired by familiar desktop conventions.", STYLE_INFO, "style"), "style")
        self.pages.add_named(self._software_page(), "software")
        self.pages.add_named(self._review_page(), "review")
        self.pages.set_visible_child_name("mode")

    def _choice_page(self, title: str, description: str, choices: dict[str, tuple[str, str]], kind: str) -> Gtk.Widget:
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        page.set_margin_top(42)
        page.set_margin_start(42)
        page.set_margin_end(42)
        title_label = Gtk.Label(label=title)
        title_label.set_xalign(0)
        title_label.add_css_class("title")
        page.append(title_label)
        detail = Gtk.Label(label=description)
        detail.set_xalign(0)
        detail.set_wrap(True)
        detail.add_css_class("muted")
        page.append(detail)
        group = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        group.set_vexpand(True)
        for key, (name, text) in choices.items():
            button = Gtk.CheckButton()
            button.set_active(key == (self.user_type if kind == "mode" else self.desktop_style))
            button.set_label(f"{name}\n{text}")
            button.set_hexpand(True)
            button.set_halign(Gtk.Align.FILL)
            button.add_css_class("choice")
            button.connect("toggled", self._choice_changed, kind, key, group)
            group.append(button)
        page.append(group)
        return page

    def _choice_changed(self, button: Gtk.CheckButton, kind: str, key: str, group: Gtk.Box) -> None:
        if not button.get_active():
            return
        for child in group.observe_children():
            if child is not button and isinstance(child, Gtk.CheckButton):
                child.set_active(False)
        if kind == "mode":
            self.user_type = key
        else:
            self.desktop_style = key

    def _software_page(self) -> Gtk.Widget:
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        page.set_margin_top(42)
        page.set_margin_start(42)
        page.set_margin_end(42)
        title = Gtk.Label(label="Choose software")
        title.set_xalign(0)
        title.add_css_class("title")
        page.append(title)
        detail = Gtk.Label(label="Included apps are already part of SimpleMode. Select optional apps to install after your desktop is configured.")
        detail.set_xalign(0)
        detail.set_wrap(True)
        detail.add_css_class("muted")
        page.append(detail)
        search = Gtk.SearchEntry(placeholder_text="Search software")
        search.set_hexpand(True)
        search.connect("search-changed", self._software_search_changed)
        page.append(search)
        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        list_box = Gtk.ListBox()
        list_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.software_rows: list[tuple[Gtk.ListBoxRow, App]] = []
        for app in self.apps:
            row = Gtk.ListBoxRow()
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
            box.set_margin_top(10)
            box.set_margin_bottom(10)
            box.set_margin_start(14)
            box.set_margin_end(14)
            check = Gtk.CheckButton()
            check.set_active(app.id in self.selected_software)
            check.set_sensitive(app.state != "builtin" and not app.installed)
            check.connect("toggled", self._software_changed, app.id)
            box.append(check)
            text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            name = Gtk.Label(label=app.name)
            name.set_xalign(0)
            name.add_css_class("row-title")
            text.append(name)
            description = Gtk.Label(label=f"{app.description}  •  {self._app_state(app)}")
            description.set_xalign(0)
            description.set_wrap(True)
            description.add_css_class("muted")
            text.append(description)
            box.append(text)
            row.set_child(box)
            list_box.append(row)
            self.software_rows.append((row, app))
        scroll.set_child(list_box)
        page.append(scroll)
        return page

    def _software_search_changed(self, entry: Gtk.SearchEntry) -> None:
        query = entry.get_text().strip().lower()
        for row, app in self.software_rows:
            searchable = f"{app.name} {app.group} {app.description}".lower()
            row.set_visible(not query or query in searchable)

    def _app_state(self, app: App) -> str:
        if app.installed:
            return "Installed"
        if app.state == "builtin":
            return "Included in SimpleMode"
        return "Optional APT package"

    def _software_changed(self, button: Gtk.CheckButton, app_id: str) -> None:
        if button.get_active():
            self.selected_software.add(app_id)
        else:
            self.selected_software.discard(app_id)

    def _review_page(self) -> Gtk.Widget:
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        page.set_margin_top(42)
        page.set_margin_start(42)
        page.set_margin_end(42)
        title = Gtk.Label(label="Review your setup")
        title.set_xalign(0)
        title.add_css_class("title")
        page.append(title)
        self.review_label = Gtk.Label()
        self.review_label.set_xalign(0)
        self.review_label.set_wrap(True)
        self.review_label.set_selectable(True)
        self.review_label.set_vexpand(True)
        self.review_label.add_css_class("review")
        page.append(self.review_label)
        page.append(self.status_label)
        return page

    def _update_review(self) -> None:
        selected = [app.name for app in self.apps if app.id in self.selected_software]
        software = ", ".join(selected) if selected else "None"
        self.review_label.set_text(
            f"Experience mode\n{MODE_INFO[self.user_type][0]}\n\n"
            f"Desktop layout\n{STYLE_INFO[self.desktop_style][0]}\n\n"
            f"Optional software\n{software}\n\n"
            "Applying this setup will change your GNOME layout and may request administrator permission for selected packages."
        )

    def _set_step(self, index: int) -> None:
        for position, label in enumerate(self.step_labels):
            label.remove_css_class("step-active")
            if position == index:
                label.add_css_class("step-active")
        self.back_button.set_sensitive(index > 0)
        self.next_button.set_label("Apply setup" if index == 3 else "Continue")

    def _next(self, _button: Gtk.Button) -> None:
        current = self.pages.get_visible_child_name()
        order = ["mode", "style", "software", "review"]
        index = order.index(current)
        if index < len(order) - 1:
            next_name = order[index + 1]
            if next_name == "review":
                self._update_review()
            self.pages.set_visible_child_name(next_name)
            self._set_step(index + 1)
            return
        self._apply()

    def _back(self, _button: Gtk.Button) -> None:
        order = ["mode", "style", "software", "review"]
        index = order.index(self.pages.get_visible_child_name())
        if index > 0:
            self.pages.set_visible_child_name(order[index - 1])
            self._set_step(index - 1)

    def _apply(self) -> None:
        self.next_button.set_sensitive(False)
        self.back_button.set_sensitive(False)
        self.status_label.set_text("Preparing your desktop…")
        thread = threading.Thread(target=self._apply_worker, daemon=True)
        thread.start()

    def _apply_worker(self) -> None:
        desktop = DesktopAdapter()
        result = desktop.apply(self.user_type, self.desktop_style)
        if not result.success:
            GLib.idle_add(self._apply_finished, False, result.message)
            return
        try:
            transaction = plan_apt(self.apps, self.selected_software)
            if transaction:
                code = run_transaction(transaction, escalation="pkexec")
                if code != 0:
                    desktop.restore()
                    GLib.idle_add(self._apply_finished, False, "Software installation failed. Previous desktop settings were restored.")
                    return
            profile = Profile(self.user_type, self.desktop_style, tuple(sorted(self.selected_software)))
            save_profile(profile)
        except (OSError, RuntimeError, ValueError) as error:
            desktop.restore()
            GLib.idle_add(self._apply_finished, False, f"Setup could not be completed: {error}")
            return
        GLib.idle_add(self._apply_finished, True, "Setup complete. Your SimpleMode profile has been saved.")

    def _apply_finished(self, success: bool, message: str) -> bool:
        self.status_label.set_text(message)
        if success:
            self.next_button.set_label("Close")
            self.next_button.set_sensitive(True)
            self.next_button.disconnect(self.next_handler)
            self.next_handler = self.next_button.connect("clicked", lambda _button: self.close())
        else:
            self.next_button.set_label("Retry")
            self.next_button.set_sensitive(True)
            self.back_button.set_sensitive(True)
        return False

    def _load_css(self) -> None:
        css = Gtk.CssProvider()
        css.load_from_data("""
        .window-root { background: #f4f1ea; color: #20241f; }
        .brand { font-size: 26px; font-weight: 700; color: #314c3a; }
        .title { font-size: 30px; font-weight: 700; color: #263b2d; }
        .muted { color: #687168; }
        .step { padding: 10px 12px; border-radius: 8px; color: #687168; }
        .step-active { background: #dbe8d8; color: #263b2d; font-weight: 700; }
        .choice { min-height: 76px; padding: 14px; border-radius: 10px; background: #fffdf8; border: 1px solid #d4d8cf; }
        .choice:checked { background: #dbe8d8; border-color: #5b8562; }
        .row-title { font-weight: 700; }
        .review { font-size: 18px; line-height: 1.4; }
        button.suggested-action { background: #315d3d; color: white; }
        button.secondary { background: #e5e7e0; }
        """, -1)
        Gtk.StyleContext.add_provider_for_display(self.get_display(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


class OnboardingApplication(Gtk.Application):
    def __init__(self) -> None:
        super().__init__(application_id="org.simplemode.Onboarding")

    def do_activate(self) -> None:
        window = OnboardingWindow(self)
        window.present()


def main() -> int:
    if "DISPLAY" not in os.environ and "WAYLAND_DISPLAY" not in os.environ:
        print("No graphical session is available; use simplemode-wizard instead.", file=sys.stderr)
        return 2
    return OnboardingApplication().run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
