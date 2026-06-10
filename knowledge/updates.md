# How to Update Your System

## Quick Steps

1. Open **Software Updater** from the application menu
2. Click **Check for Updates**
3. If updates are available, click **Install Updates**
4. **Restart** if prompted

## Update via Terminal

```bash
# Update the package list (checks for new versions)
sudo apt update

# Install available updates
sudo apt upgrade -y

# Full system upgrade (includes new dependencies)
sudo apt full-upgrade -y

# Remove old unused packages
sudo apt autoremove -y

# Clean downloaded package files
sudo apt clean
```

## One-Line Update Command

Copy and paste this to do everything at once:

```bash
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
```

## Automatic Updates

To enable automatic security updates:

```bash
# Install automatic update tool
sudo apt install unattended-upgrades

# Enable it
sudo dpkg-reconfigure -plow unattended-upgrades
```

## How Often Should I Update?

- **Security updates**: Install immediately (these protect your computer)
- **Regular updates**: Once a week is fine
- **Major version upgrades**: Read the release notes first

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Could not get lock" error | Another update is running. Wait or run: `sudo killall apt` |
| "Hash Sum mismatch" | Run: `sudo rm -rf /var/lib/apt/lists/* && sudo apt update` |
| Broken packages | Run: `sudo apt --fix-broken install` |
| Update fails | Check internet connection and try again |

## Important Notes

- Always **save your work** before updating
- Some updates require a **restart** to take effect
- Never turn off your computer **during** an update
