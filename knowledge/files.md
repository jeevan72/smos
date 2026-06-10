# Managing Files and Folders

## Using the File Manager

Your file manager works just like Windows Explorer or macOS Finder:
- **Double-click** to open files and folders
- **Right-click** for options (copy, paste, rename, delete)
- **Drag and drop** to move files

## Important Folders

| Folder | What's Inside |
|--------|--------------|
| Home (~) | Your personal files, documents, pictures |
| Desktop | Files shown on your desktop |
| Documents | Your documents |
| Downloads | Files you downloaded from the internet |
| Pictures | Your photos and images |
| Music | Your music files |
| Videos | Your video files |

## File Operations via Terminal

```bash
# List files in current folder
ls

# List with details (size, date, permissions)
ls -la

# Go into a folder
cd Documents

# Go back to home folder
cd ~

# Create a new folder
mkdir my-folder

# Create a new file
touch my-file.txt

# Copy a file
cp file.txt backup.txt

# Copy a folder
cp -r folder/ backup-folder/

# Move or rename a file
mv old-name.txt new-name.txt

# Delete a file
rm file.txt

# Delete a folder
rm -r folder/
```

## Finding Files

```bash
# Search by name
find ~ -name "*.pdf"

# Search by name (case insensitive)
find ~ -iname "report*"

# Search file contents
grep -r "search text" ~/Documents/
```

## Disk Space

```bash
# Check overall disk usage
df -h

# Check folder size
du -sh ~/Downloads

# Find large files
find ~ -size +100M -type f
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Accidentally deleted a file | Check Trash first. If not there, recovery is difficult — always backup! |
| Disk full | Clear Downloads folder, empty Trash, run `sudo apt autoremove` |
| Can't find a file | Use `find` command or search in file manager |
| File won't open | Right-click → "Open With" → choose the right application |
