# Understanding File Permissions

## What Are Permissions?

Every file and folder on your computer has **permissions** that control who can:
- **Read** (r) — view the file contents
- **Write** (w) — modify the file
- **Execute** (x) — run the file as a program

## "Permission Denied" — What It Means

If you see **"Permission denied"**, it means your user account doesn't have the right permissions to access that file or folder.

### Quick Fixes

```bash
# Run the command as administrator (most common fix)
sudo your-command-here

# Example: installing software
sudo apt install vlc

# Example: editing a system file
sudo nano /etc/hosts
```

## Checking Permissions

```bash
# View permissions of files in current directory
ls -la

# Output example:
# -rw-r--r-- 1 user group 1234 Jun 10 file.txt
# drwxr-xr-x 2 user group 4096 Jun 10 folder/
```

## Understanding Permission Codes

```
-rw-r--r--
│├──┤├──┤├──┤
│  │   │   └── Others: read only
│  │   └────── Group: read only
│  └────────── Owner: read + write
└───────────── File type (- = file, d = directory)
```

## Changing Permissions

```bash
# Make a file executable (run as a program)
chmod +x script.sh

# Give yourself full access
chmod u+rwx file.txt

# Common permission sets:
chmod 755 script.sh    # Owner: full, Others: read+execute
chmod 644 file.txt     # Owner: read+write, Others: read only
chmod 600 private.key  # Owner only: read+write
```

## Changing File Ownership

```bash
# Change owner of a file
sudo chown yourname file.txt

# Change owner of a folder and everything inside
sudo chown -R yourname:yourname folder/
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Permission denied" | Add `sudo` before your command |
| Can't run a script | Make it executable: `chmod +x script.sh` |
| Can't access a folder | Check ownership: `ls -la` then `sudo chown -R $USER folder/` |
| "Operation not permitted" | You may need root access: `sudo su` |

## Important Safety Notes

- **Never run `chmod 777`** on system files — this is a security risk
- **Be careful with `sudo`** — it gives full administrator access
- If you're unsure, ask for help before changing permissions
