# How to Set Up a Printer

## Quick Steps

1. **Connect your printer** via USB cable or make sure it's on the same WiFi network
2. Open **Settings → Printers** (or search for "Printers" in the application menu)
3. Click **Add Printer**
4. Select your printer from the list
5. Click **Add** and test with a print

## Automatic Detection

Most modern printers are detected automatically. SimpleMode OS includes **CUPS** (Common Unix Printing System) which supports thousands of printers.

## Install Printer Drivers

If your printer isn't detected automatically:

```bash
# Install common printer drivers
sudo apt install printer-driver-all

# For HP printers
sudo apt install hplip

# For Canon printers
sudo apt install cnijfilter2

# For Epson printers
sudo apt install printer-driver-escpr
```

## Set Up Network Printer

```bash
# Find network printers
lpstat -p -d

# Or use the CUPS web interface
# Open browser and go to: http://localhost:631
```

## Scanner Setup

```bash
# Install scanner support
sudo apt install sane-utils

# Test scanner
scanimage -L
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Printer not found | Check USB cable or WiFi connection |
| Print jobs stuck | Clear queue: `sudo cancel -a` |
| Poor print quality | Run printer head cleaning from printer menu |
| Permission denied | Add yourself to lp group: `sudo usermod -aG lp $USER` |
