/**
 * SimpleMode OS — PageTree Knowledge System
 * Keyword-based document retrieval (no RAG, no LLM)
 */

const PageTree = (() => {
    let knowledgeIndex = {};
    let knowledgeDocs = {};
    let loaded = false;

    // Inline knowledge content (no server needed)
    const DOCS = {
        wifi: {
            title: "How to Connect to WiFi",
            summary: "Connect to wireless networks, troubleshoot WiFi issues",
            content: `<h3>🌐 How to Connect to WiFi</h3>
<ol>
<li><strong>Click the network icon</strong> in the top-right corner of your screen</li>
<li><strong>Select your WiFi network</strong> from the list</li>
<li><strong>Enter the password</strong> when prompted</li>
<li><strong>Click Connect</strong></li>
</ol>
<h4>If You Don't See Any Networks</h4>
<ul>
<li>Make sure WiFi is <strong>turned on</strong></li>
<li>Make sure <strong>Airplane Mode</strong> is off</li>
<li>Try restarting: <code>sudo systemctl restart NetworkManager</code></li>
</ul>
<h4>Connect via Terminal</h4>
<pre>nmcli device wifi list
nmcli device wifi connect "YourNetwork" password "YourPassword"</pre>`
        },
        printer: {
            title: "How to Set Up a Printer",
            summary: "Connect and configure printers and scanners",
            content: `<h3>🖨️ How to Set Up a Printer</h3>
<ol>
<li><strong>Connect your printer</strong> via USB or WiFi</li>
<li>Open <strong>Settings → Printers</strong></li>
<li>Click <strong>Add Printer</strong></li>
<li>Select your printer and click <strong>Add</strong></li>
</ol>
<h4>Install Printer Drivers</h4>
<pre>sudo apt install printer-driver-all
# For HP: sudo apt install hplip
# For Canon: sudo apt install cnijfilter2</pre>
<h4>Troubleshooting</h4>
<ul>
<li><strong>Printer not found?</strong> Check USB cable or WiFi connection</li>
<li><strong>Jobs stuck?</strong> Clear queue: <code>sudo cancel -a</code></li>
</ul>`
        },
        updates: {
            title: "How to Update Your System",
            summary: "Keep your system up to date with latest patches",
            content: `<h3>🔄 How to Update Your System</h3>
<ol>
<li>Open <strong>Software Updater</strong> from the menu</li>
<li>Click <strong>Check for Updates</strong></li>
<li>Click <strong>Install Updates</strong></li>
<li><strong>Restart</strong> if prompted</li>
</ol>
<h4>Update via Terminal</h4>
<pre>sudo apt update && sudo apt upgrade -y</pre>
<h4>Full Update (everything at once)</h4>
<pre>sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y</pre>
<h4>Important</h4>
<ul>
<li>Save your work before updating</li>
<li>Never turn off your computer during an update</li>
<li>Some updates require a restart</li>
</ul>`
        },
        software: {
            title: "How to Install & Remove Software",
            summary: "Install, remove, and manage applications",
            content: `<h3>📦 How to Install Software</h3>
<h4>Using Software Center (Easiest)</h4>
<ol>
<li>Open <strong>Software Center</strong></li>
<li>Search for the app you want</li>
<li>Click <strong>Install</strong></li>
</ol>
<h4>Using Terminal</h4>
<pre>sudo apt install firefox     # Install
sudo apt remove firefox      # Remove
sudo apt search vlc          # Search</pre>
<h4>Popular Apps</h4>
<ul>
<li><strong>Firefox</strong>: <code>sudo apt install firefox</code></li>
<li><strong>VLC</strong>: <code>sudo apt install vlc</code></li>
<li><strong>GIMP</strong>: <code>sudo apt install gimp</code></li>
<li><strong>LibreOffice</strong>: <code>sudo apt install libreoffice</code></li>
</ul>`
        },
        permissions: {
            title: "Understanding File Permissions",
            summary: "Fix permission denied errors, understand chmod and sudo",
            content: `<h3>🔒 Understanding Permissions</h3>
<p>"<strong>Permission denied</strong>" means your account can't access that file.</p>
<h4>Quick Fix</h4>
<pre>sudo your-command-here</pre>
<h4>Common Solutions</h4>
<ul>
<li><strong>Run as admin:</strong> Add <code>sudo</code> before your command</li>
<li><strong>Make executable:</strong> <code>chmod +x script.sh</code></li>
<li><strong>Change ownership:</strong> <code>sudo chown $USER file.txt</code></li>
</ul>
<h4>Understanding Permission Codes</h4>
<pre>chmod 755 script.sh   # Owner: full, Others: read+execute
chmod 644 file.txt    # Owner: read+write, Others: read only</pre>
<h4>Safety Note</h4>
<p>Never run <code>chmod 777</code> on system files — it's a security risk!</p>`
        },
        files: {
            title: "Managing Files and Folders",
            summary: "Copy, move, delete files, navigate folders",
            content: `<h3>📁 Managing Files and Folders</h3>
<h4>File Manager</h4>
<p>Works just like Windows Explorer or macOS Finder — double-click to open, right-click for options, drag and drop to move.</p>
<h4>Terminal Commands</h4>
<pre>ls              # List files
cd Documents    # Go into folder
mkdir my-folder # Create folder
cp file.txt backup.txt  # Copy
mv old.txt new.txt      # Rename/Move
rm file.txt             # Delete</pre>
<h4>Important Folders</h4>
<ul>
<li><strong>Home (~)</strong> — Your personal files</li>
<li><strong>Desktop</strong> — Files on your desktop</li>
<li><strong>Documents</strong> — Your documents</li>
<li><strong>Downloads</strong> — Downloaded files</li>
</ul>`
        },
        terminal: {
            title: "Terminal Basics",
            summary: "Learn the command line, essential commands, shortcuts",
            content: `<h3>💻 Terminal Basics</h3>
<p>Open terminal with <strong>Ctrl + Alt + T</strong></p>
<h4>Essential Commands</h4>
<pre>pwd           # Where am I?
ls            # List files
cd folder     # Enter folder
cd ..         # Go back
sudo apt install app  # Install software</pre>
<h4>Keyboard Shortcuts</h4>
<ul>
<li><strong>Tab</strong> — Auto-complete</li>
<li><strong>Ctrl+C</strong> — Cancel command</li>
<li><strong>Up Arrow</strong> — Previous command</li>
<li><strong>Ctrl+L</strong> — Clear screen</li>
</ul>
<h4>Tips</h4>
<ul>
<li>Use <strong>Tab</strong> to auto-complete file names</li>
<li>Press <strong>Ctrl+C</strong> if something goes wrong</li>
<li><code>man command</code> shows the manual</li>
</ul>`
        }
    };

    // Keyword index (same as knowledge/index.json)
    const INDEX = {
        wifi: ["internet", "network", "wireless", "connect", "hotspot", "wi-fi", "router", "ethernet", "lan", "wlan", "connection", "online"],
        printer: ["print", "printing", "cups", "scanner", "scan", "paper", "ink", "driver"],
        updates: ["update", "upgrade", "patch", "security", "apt", "refresh", "latest", "version", "outdated"],
        software: ["install", "remove", "uninstall", "app", "application", "package", "program", "download", "store"],
        permissions: ["permission", "denied", "access", "chmod", "chown", "sudo", "root", "admin", "privilege", "restricted"],
        files: ["file", "folder", "directory", "copy", "move", "delete", "rename", "backup", "storage", "disk", "space"],
        terminal: ["terminal", "command", "bash", "shell", "cli", "console", "prompt", "script"]
    };

    /**
     * Score a query against all documents
     * Returns sorted array of { docId, score, doc }
     */
    function search(query) {
        const words = query.toLowerCase().split(/\s+/).filter(w => w.length > 1);
        const scores = {};

        for (const [docId, keywords] of Object.entries(INDEX)) {
            let score = 0;

            for (const word of words) {
                // Direct match with doc name
                if (word === docId) {
                    score += 5;
                    continue;
                }

                // Match with keywords
                for (const keyword of keywords) {
                    if (word === keyword) {
                        score += 3;
                    } else if (keyword.includes(word) || word.includes(keyword)) {
                        score += 1;
                    }
                }
            }

            if (score > 0) {
                scores[docId] = score;
            }
        }

        // Sort by score descending
        return Object.entries(scores)
            .sort(([, a], [, b]) => b - a)
            .map(([docId, score]) => ({
                docId,
                score,
                doc: DOCS[docId]
            }));
    }

    /**
     * Get the best matching document for a query
     */
    function lookup(query) {
        const results = search(query);
        if (results.length > 0) {
            return results[0];
        }
        return null;
    }

    /**
     * Get a document by ID
     */
    function getDoc(docId) {
        return DOCS[docId] || null;
    }

    /**
     * Get all available topics
     */
    function getTopics() {
        return Object.entries(DOCS).map(([id, doc]) => ({
            id,
            title: doc.title,
            summary: doc.summary
        }));
    }

    return { search, lookup, getDoc, getTopics };
})();
