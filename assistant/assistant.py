#!/usr/bin/env python3
"""
SimpleMode OS — Terminal Assistant
Workflow: Question → Typo Fix → Intent Detection → PageTree Lookup → Response

Uses 'rich' library for beautiful terminal output.
"""

import argparse
import json
import os
import sys
import re
from pathlib import Path

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.markdown import Markdown
    from rich.table import Table
    from rich.text import Text
    from rich.prompt import Prompt
    from rich import box
except ImportError:
    print("Error: 'rich' library not installed. Run: pip install rich")
    sys.exit(1)

try:
    from rapidfuzz import fuzz, process as rf_process
    HAS_RAPIDFUZZ = True
except ImportError:
    HAS_RAPIDFUZZ = False

console = Console()

# ============================================================
# Typo Correction Engine (Levenshtein Distance)
# ============================================================

DICTIONARY = [
    "firefox", "chrome", "chromium", "thunderbird", "libreoffice", "gimp", "vlc",
    "terminal", "nautilus", "calculator", "settings", "files", "spotify", "discord",
    "install", "uninstall", "remove", "update", "upgrade", "download",
    "open", "close", "start", "stop", "restart", "reboot", "shutdown",
    "search", "find", "help", "configure", "change", "enable", "disable",
    "wifi", "bluetooth", "network", "internet", "connection", "wireless",
    "printer", "scanner", "display", "screen", "monitor", "resolution",
    "volume", "sound", "audio", "microphone", "speaker", "headphone",
    "battery", "power", "brightness", "keyboard", "mouse", "touchpad",
    "password", "username", "account", "login", "logout", "permission",
    "folder", "directory", "file", "document", "desktop", "wallpaper",
    "storage", "memory", "disk", "space", "backup", "restore",
    "software", "application", "program", "package", "repository",
    "system", "computer", "laptop", "performance", "process",
    "security", "firewall", "antivirus", "encryption",
    "theme", "appearance", "font", "icon", "cursor",
    "connect", "disconnect", "setup", "reset",
    "copy", "paste", "cut", "delete", "rename", "move",
    "print", "save", "share", "send", "receive",
    "sudo", "apt", "bash", "shell", "command", "root",
    "chmod", "chown", "grep", "linux", "ubuntu", "debian",
]

OVERRIDES = {
    "wfi": "wifi", "wif": "wifi", "wiif": "wifi",
    "chorme": "chrome", "crhome": "chrome", "chrme": "chrome",
    "instal": "install", "intall": "install", "istall": "install", "intsall": "install",
    "upadte": "update", "udpate": "update", "udate": "update", "updte": "update",
    "donwload": "download", "downlod": "download", "dowload": "download",
    "pritn": "print", "prnter": "printer", "priner": "printer",
    "pasword": "password", "passwrod": "password", "passowrd": "password",
    "scren": "screen", "screan": "screen",
    "netwrok": "network", "netowrk": "network",
    "conect": "connect", "connetc": "connect",
    "bluethooth": "bluetooth", "bluetoth": "bluetooth", "blutooth": "bluetooth",
    "sofware": "software", "softwre": "software",
    "aplication": "application", "applcation": "application",
    "permision": "permission", "permssion": "permission",
    "termnial": "terminal", "temrinal": "terminal", "termnal": "terminal",
    "fierfox": "firefox", "fierfx": "firefox", "firfox": "firefox",
    "setings": "settings", "settngs": "settings",
    "seach": "search", "serach": "search",
    "hlep": "help", "helo": "help",
    "opne": "open", "oepn": "open",
    "clsoe": "close", "clos": "close",
    "delte": "delete", "deleet": "delete",
    "restar": "restart", "restrat": "restart",
    "shutdwon": "shutdown", "shtdown": "shutdown",
    "linus": "linux", "linx": "linux",
    "ubunt": "ubuntu", "ubunti": "ubuntu",
}


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


# Common English words that should NEVER be corrected
SKIP_WORDS = {
    "how", "what", "where", "when", "why", "which", "who", "whom",
    "the", "this", "that", "these", "those", "there", "here",
    "is", "are", "was", "were", "been", "being", "be", "am",
    "do", "does", "did", "done", "doing",
    "have", "has", "had", "having",
    "will", "would", "shall", "should", "can", "could", "may", "might", "must",
    "not", "no", "yes", "and", "but", "or", "if", "then", "else",
    "to", "for", "from", "with", "without", "in", "on", "at", "by", "of", "up",
    "my", "your", "his", "her", "its", "our", "their", "me", "you", "him", "it", "us", "them",
    "get", "got", "set", "let", "put", "run", "use", "try", "ask", "say", "see", "go",
    "want", "need", "know", "like", "make", "take", "give", "tell", "show", "keep",
    "very", "just", "also", "too", "now", "all", "any", "some", "each", "every",
    "about", "after", "before", "into", "over", "under", "between",
    "please", "thanks", "thank", "sorry", "okay",
    "new", "old", "big", "small", "good", "bad", "best", "more", "most", "much",
}


def fix_word(word: str):
    """Fix a single word. Returns (corrected, was_fixed)."""
    lower = word.lower()
    if lower in OVERRIDES:
        return OVERRIDES[lower], True
    if lower in DICTIONARY:
        return word, False
    if len(lower) <= 2 or lower.isdigit():
        return word, False
    # Skip common English words — never try to "correct" these
    if lower in SKIP_WORDS:
        return word, False

    # Use RapidFuzz if available for better matching
    if HAS_RAPIDFUZZ:
        result = rf_process.extractOne(lower, DICTIONARY, scorer=fuzz.ratio, score_cutoff=70)
        if result:
            return result[0], True
        return word, False

    # Fallback to Levenshtein
    max_dist = 1 if len(lower) <= 4 else 2
    best, best_dist = None, float("inf")
    for term in DICTIONARY:
        if abs(len(term) - len(lower)) > max_dist:
            continue
        d = levenshtein(lower, term)
        if 0 < d <= max_dist and d < best_dist:
            best, best_dist = term, d
    if best:
        return best, True
    return word, False


def fix_sentence(text: str):
    """Fix typos in a full sentence. Returns (corrected, fixes_list)."""
    tokens = re.findall(r"[a-zA-Z]+|[^a-zA-Z]+", text)
    fixes = []
    result = []
    for token in tokens:
        if token.strip() and token.isalpha():
            corrected, was_fixed = fix_word(token)
            if was_fixed:
                fixes.append((token, corrected))
            result.append(corrected)
        else:
            result.append(token)
    return "".join(result), fixes


# ============================================================
# PageTree Knowledge System
# ============================================================

class PageTree:
    def __init__(self, knowledge_dir: str):
        self.knowledge_dir = Path(knowledge_dir)
        self.index = {}
        self.docs = {}
        self._load()

    def _load(self):
        # Load keyword index
        index_file = self.knowledge_dir / "index.json"
        if index_file.exists():
            with open(index_file) as f:
                self.index = json.load(f)

        # Load markdown docs
        for md_file in self.knowledge_dir.glob("*.md"):
            doc_id = md_file.stem
            with open(md_file) as f:
                self.docs[doc_id] = f.read()

    def search(self, query: str):
        """Score query against all docs. Returns sorted list of (doc_id, score)."""
        words = query.lower().split()
        scores = {}
        for doc_id, keywords in self.index.items():
            score = 0
            for word in words:
                if len(word) <= 1:
                    continue
                if word == doc_id:
                    score += 5
                for kw in keywords:
                    if word == kw:
                        score += 3
                    elif kw in word or word in kw:
                        score += 1
            if score > 0:
                scores[doc_id] = score
        return sorted(scores.items(), key=lambda x: x[1], reverse=True)

    def lookup(self, query: str):
        """Get best matching doc for query. Returns (doc_id, content) or None."""
        results = self.search(query)
        if results and results[0][1] >= 2:
            doc_id = results[0][0]
            return doc_id, self.docs.get(doc_id, "No content available.")
        return None

    def get_doc(self, doc_id: str):
        return self.docs.get(doc_id)

    def list_topics(self):
        return list(self.docs.keys())


# ============================================================
# Intent Detection (keyword-based)
# ============================================================

def detect_intent(text: str) -> str:
    lower = text.lower()
    if re.match(r"^(hi|hello|hey|good morning|good evening)\b", lower):
        return "greeting"
    if re.match(r"^(thanks|thank you|thx|ty|cheers)\b", lower):
        return "thanks"
    if re.search(r"\b(quit|exit|bye|goodbye)\b", lower):
        return "quit"
    if re.search(r"\b(install|setup|add|get)\b", lower):
        return "install"
    if re.search(r"\b(remove|uninstall|delete)\b", lower):
        return "remove"
    if re.search(r"\b(update|upgrade|patch)\b", lower):
        return "update"
    if re.search(r"\b(connect|wifi|network|internet)\b", lower):
        return "network"
    if re.search(r"\b(permission|denied|access|sudo|root)\b", lower):
        return "permissions"
    if re.search(r"\b(file|folder|directory|copy|move)\b", lower):
        return "files"
    if re.search(r"\b(terminal|command|bash|shell)\b", lower):
        return "terminal"
    if re.search(r"\b(print|printer|scan)\b", lower):
        return "printer"
    if re.search(r"\b(topic|list|all|help)\b", lower):
        return "list_topics"
    return "unknown"


# ============================================================
# Assistant
# ============================================================

class SimpleModeAssistant:
    def __init__(self, knowledge_dir: str, mode: str = "beginner"):
        self.pagetree = PageTree(knowledge_dir)
        self.mode = mode
        self.history = []

    def greet(self):
        greetings = {
            "elder": "Hello! 😊 I'm your SimpleMode assistant.\nI'm here to help you with anything — just type your question.\nDon't worry about spelling, I'll fix typos automatically!",
            "beginner": "Hi there! 👋 I'm your helpful assistant.\nAsk me anything about your computer:\n  • How to connect WiFi\n  • How to install apps\n  • How to manage files\n  • And much more!",
            "advanced": "SimpleMode Assistant ready.\nTopics: networking, packages, permissions, files, terminal.\nType 'topics' for full list, 'quit' to exit.",
        }
        msg = greetings.get(self.mode, greetings["beginner"])
        console.print(Panel(msg, title="🤖 SimpleMode Assistant", border_style="bright_blue", box=box.ROUNDED))

        # Show suggestions
        topics = self.pagetree.list_topics()
        table = Table(show_header=False, box=None, padding=(0, 2))
        table.add_column(style="dim")
        for t in topics:
            table.add_row(f"  💡 Try: \"{t}\"")
        console.print(table)
        console.print()

    def process(self, user_input: str) -> bool:
        """Process a query. Returns False if user wants to quit."""

        # Step 1: Typo correction
        corrected, fixes = fix_sentence(user_input)
        if fixes:
            fix_text = ", ".join([f"[red strikethrough]{orig}[/] → [green bold]{fixed}[/]" for orig, fixed in fixes])
            console.print(f"  ✏️  Typo corrected: {fix_text}")
            console.print(f"  📝 Interpreted as: [italic]{corrected}[/]")
            console.print()

        query = corrected

        # Step 2: Intent detection
        intent = detect_intent(query)

        if intent == "quit":
            console.print(Panel("Goodbye! 👋", border_style="bright_blue"))
            return False

        if intent == "greeting":
            responses = {
                "elder": "Hello! 😊 What can I help you with today?",
                "beginner": "Hey! 👋 What would you like to know?",
                "advanced": "Hello. How can I assist?",
            }
            console.print(Panel(responses.get(self.mode, responses["beginner"]),
                                title="🤖 Assistant", border_style="bright_blue"))
            return True

        if intent == "thanks":
            responses = {
                "elder": "You're very welcome! 😊 Ask me anything else anytime!",
                "beginner": "You're welcome! 😄 Happy to help!",
                "advanced": "You're welcome.",
            }
            console.print(Panel(responses.get(self.mode, responses["beginner"]),
                                title="🤖 Assistant", border_style="bright_blue"))
            return True

        if intent == "list_topics":
            self._show_topics()
            return True

        # Step 3: PageTree lookup
        result = self.pagetree.lookup(query)

        if result:
            doc_id, content = result
            console.print(Panel(
                Markdown(content),
                title=f"🤖 Assistant — 📄 Source: {doc_id}.md",
                border_style="bright_blue",
                box=box.ROUNDED,
            ))
            # Show related topics
            all_topics = [t for t in self.pagetree.list_topics() if t != doc_id]
            if all_topics:
                related = ", ".join(all_topics[:3])
                console.print(f"  💡 Related topics: {related}")
                console.print()
        else:
            # No match found
            no_match = {
                "elder": f"I'm sorry, I don't have information about \"{query}\" yet.\nBut I can help with these topics:",
                "beginner": f"I couldn't find an answer for \"{query}\".\nHere are topics I can help with:",
                "advanced": f"No docs found for \"{query}\". Available topics:",
            }
            console.print(Panel(no_match.get(self.mode, no_match["beginner"]),
                                title="🤖 Assistant", border_style="yellow"))
            self._show_topics()

        self.history.append({"query": user_input, "corrected": query, "intent": intent})
        return True

    def _show_topics(self):
        table = Table(title="Available Topics", box=box.SIMPLE_HEAVY, border_style="bright_blue")
        table.add_column("Topic", style="bold cyan")
        table.add_column("Keywords", style="dim")
        for topic in self.pagetree.list_topics():
            keywords = self.pagetree.index.get(topic, [])
            table.add_row(topic, ", ".join(keywords[:5]))
        console.print(table)
        console.print()


# ============================================================
# Main
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="SimpleMode OS Terminal Assistant")
    parser.add_argument("--knowledge", default="knowledge", help="Path to knowledge directory")
    parser.add_argument("--mode", default="beginner", choices=["elder", "beginner", "advanced"],
                        help="User mode (affects response style)")
    args = parser.parse_args()

    # Resolve knowledge dir
    knowledge_dir = args.knowledge
    if not os.path.isabs(knowledge_dir):
        knowledge_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", knowledge_dir)

    if not os.path.isdir(knowledge_dir):
        console.print(f"[red]Error: Knowledge directory not found: {knowledge_dir}[/]")
        sys.exit(1)

    assistant = SimpleModeAssistant(knowledge_dir, args.mode)

    console.print()
    console.rule("[bold bright_blue]SimpleMode OS — Terminal Assistant[/]")
    console.print(f"  Mode: [bold]{args.mode}[/] | Type [bold cyan]topics[/] for help | [bold cyan]quit[/] to exit")
    console.print()

    assistant.greet()

    # Main loop
    while True:
        try:
            user_input = Prompt.ask("\n[bold green]You[/]")
            if not user_input.strip():
                continue
            console.print()
            keep_going = assistant.process(user_input.strip())
            if not keep_going:
                break
        except (KeyboardInterrupt, EOFError):
            console.print("\n")
            console.print(Panel("Goodbye! 👋", border_style="bright_blue"))
            break


if __name__ == "__main__":
    main()
