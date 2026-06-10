# Terminal Basics

## What Is the Terminal?

The terminal (also called the command line) lets you control your computer by typing text commands. It's very powerful — anything you can do with the mouse, you can also do (usually faster) in the terminal.

## Opening the Terminal

- Press **Ctrl + Alt + T** (keyboard shortcut)
- Or search for **"Terminal"** in the application menu

## Essential Commands

### Navigation
```bash
# Where am I?
pwd

# List files here
ls

# Go to a folder
cd Documents

# Go back one folder
cd ..

# Go to home folder
cd ~
```

### File Operations
```bash
# Create a file
touch notes.txt

# Create a folder
mkdir projects

# Edit a file
nano notes.txt

# View file contents
cat notes.txt

# Copy a file
cp notes.txt backup.txt

# Move a file
mv notes.txt Documents/

# Delete a file
rm notes.txt
```

### System Commands
```bash
# Update your system
sudo apt update && sudo apt upgrade -y

# Install software
sudo apt install firefox

# Check system info
uname -a

# Check disk space
df -h

# Check memory usage
free -h

# See running processes
htop
```

## Keyboard Shortcuts in Terminal

| Shortcut | Action |
|----------|--------|
| Tab | Auto-complete file/folder names |
| Ctrl + C | Cancel current command |
| Ctrl + L | Clear the screen |
| Up Arrow | Previous command |
| Ctrl + R | Search command history |
| Ctrl + A | Go to beginning of line |
| Ctrl + E | Go to end of line |

## Tips for Beginners

1. **Tab completion** is your best friend — type the first few letters and press Tab
2. **Up arrow** repeats your last command
3. **`man` command** shows the manual: `man ls` shows help for the `ls` command
4. **Don't panic** — if something goes wrong, press **Ctrl + C** to cancel
5. **`sudo`** means "run as administrator" — use it carefully

## Common Mistakes

| Mistake | What Happens | Fix |
|---------|-------------|-----|
| Forgetting `sudo` | "Permission denied" | Add `sudo` before the command |
| Wrong folder | Command runs in wrong place | Use `pwd` to check, `cd` to navigate |
| Typo in command | "Command not found" | Check spelling carefully |
| Running `rm -rf /` | **DELETES EVERYTHING** | NEVER run this! |
