/**
 * SimpleMode OS — Typo Correction Engine
 * Uses Levenshtein Distance for fuzzy matching
 */

const TypoFix = (() => {
    // Dictionary of known correct terms (Linux/OS vocabulary)
    const DICTIONARY = [
        // Applications
        'firefox', 'chrome', 'chromium', 'thunderbird', 'libreoffice', 'gimp', 'vlc',
        'terminal', 'nautilus', 'calculator', 'calendar', 'settings', 'files',
        'spotify', 'discord', 'steam', 'vscode', 'sublime',
        // System commands
        'install', 'uninstall', 'remove', 'update', 'upgrade', 'download',
        'open', 'close', 'start', 'stop', 'restart', 'reboot', 'shutdown',
        'search', 'find', 'help', 'configure', 'change', 'enable', 'disable',
        // System concepts
        'wifi', 'bluetooth', 'network', 'internet', 'connection', 'wireless',
        'printer', 'scanner', 'display', 'screen', 'monitor', 'resolution',
        'volume', 'sound', 'audio', 'microphone', 'speaker', 'headphone',
        'battery', 'power', 'brightness', 'keyboard', 'mouse', 'touchpad',
        'password', 'username', 'account', 'login', 'logout', 'permission',
        'folder', 'directory', 'file', 'document', 'desktop', 'wallpaper',
        'storage', 'memory', 'disk', 'space', 'backup', 'restore',
        'software', 'application', 'program', 'package', 'repository',
        'system', 'computer', 'laptop', 'performance', 'process',
        'security', 'firewall', 'antivirus', 'encryption',
        'theme', 'appearance', 'font', 'icon', 'cursor',
        // Actions
        'how', 'what', 'where', 'when', 'why', 'which', 'who',
        'can', 'could', 'should', 'would', 'will', 'does', 'the',
        'connect', 'disconnect', 'setup', 'configure', 'reset',
        'copy', 'paste', 'cut', 'delete', 'rename', 'move',
        'print', 'save', 'share', 'send', 'receive',
        // Linux specific
        'sudo', 'apt', 'bash', 'shell', 'command', 'root',
        'chmod', 'chown', 'grep', 'linux', 'ubuntu', 'debian'
    ];

    // Common misspelling overrides (instant corrections)
    const OVERRIDES = {
        'wfi': 'wifi',
        'wif': 'wifi',
        'wiif': 'wifi',
        'chorme': 'chrome',
        'crhome': 'chrome',
        'chrme': 'chrome',
        'instal': 'install',
        'intall': 'install',
        'istall': 'install',
        'intsall': 'install',
        'upadte': 'update',
        'udpate': 'update',
        'udate': 'update',
        'updte': 'update',
        'donwload': 'download',
        'downlod': 'download',
        'dowload': 'download',
        'pritn': 'print',
        'prnter': 'printer',
        'priner': 'printer',
        'pasword': 'password',
        'passwrod': 'password',
        'passowrd': 'password',
        'scren': 'screen',
        'screan': 'screen',
        'netwrok': 'network',
        'netowrk': 'network',
        'conect': 'connect',
        'connetc': 'connect',
        'bluethooth': 'bluetooth',
        'bluetoth': 'bluetooth',
        'blutooth': 'bluetooth',
        'sofware': 'software',
        'softwre': 'software',
        'aplication': 'application',
        'applcation': 'application',
        'permision': 'permission',
        'permssion': 'permission',
        'termnial': 'terminal',
        'temrinal': 'terminal',
        'termnal': 'terminal',
        'fierfox': 'firefox',
        'fierfx': 'firefox',
        'firfox': 'firefox',
        'setings': 'settings',
        'settngs': 'settings',
        'seach': 'search',
        'serach': 'search',
        'hlep': 'help',
        'helo': 'help',
        'opne': 'open',
        'oepn': 'open',
        'clsoe': 'close',
        'clos': 'close',
        'delte': 'delete',
        'deleet': 'delete',
        'restar': 'restart',
        'restrat': 'restart',
        'shutdwon': 'shutdown',
        'shtdown': 'shutdown',
        'linus': 'linux',
        'linx': 'linux',
        'ubunt': 'ubuntu',
        'ubunti': 'ubuntu'
    };

    /**
     * Compute Levenshtein distance between two strings
     */
    function levenshtein(a, b) {
        const m = a.length, n = b.length;
        const dp = Array.from({ length: m + 1 }, () => Array(n + 1).fill(0));

        for (let i = 0; i <= m; i++) dp[i][0] = i;
        for (let j = 0; j <= n; j++) dp[0][j] = j;

        for (let i = 1; i <= m; i++) {
            for (let j = 1; j <= n; j++) {
                if (a[i - 1] === b[j - 1]) {
                    dp[i][j] = dp[i - 1][j - 1];
                } else {
                    dp[i][j] = 1 + Math.min(
                        dp[i - 1][j],     // deletion
                        dp[i][j - 1],     // insertion
                        dp[i - 1][j - 1]  // substitution
                    );
                }
            }
        }
        return dp[m][n];
    }

    /**
     * Find the best match for a word from the dictionary
     */
    function findBestMatch(word) {
        const lower = word.toLowerCase();

        // Check overrides first
        if (OVERRIDES[lower]) {
            return { original: word, corrected: OVERRIDES[lower], distance: 1 };
        }

        // Check if already correct
        if (DICTIONARY.includes(lower)) {
            return null; // No correction needed
        }

        // Skip very short words (1-2 chars) and numbers
        if (lower.length <= 2 || /^\d+$/.test(lower)) {
            return null;
        }

        let bestMatch = null;
        let bestDistance = Infinity;

        // Dynamic threshold based on word length
        const maxDistance = lower.length <= 4 ? 1 : 2;

        for (const term of DICTIONARY) {
            // Quick length check to skip impossible matches
            if (Math.abs(term.length - lower.length) > maxDistance) continue;

            const dist = levenshtein(lower, term);
            if (dist > 0 && dist <= maxDistance && dist < bestDistance) {
                bestDistance = dist;
                bestMatch = term;
            }
        }

        if (bestMatch) {
            return { original: word, corrected: bestMatch, distance: bestDistance };
        }
        return null;
    }

    /**
     * Fix typos in a full sentence
     * Returns { corrected: string, fixes: [{original, corrected, distance}] }
     */
    function fixSentence(text) {
        const words = text.split(/\s+/);
        const fixes = [];
        const correctedWords = [];

        for (const word of words) {
            // Strip punctuation for matching
            const clean = word.replace(/[^a-zA-Z0-9]/g, '');
            const prefix = word.match(/^[^a-zA-Z0-9]*/)?.[0] || '';
            const suffix = word.match(/[^a-zA-Z0-9]*$/)?.[0] || '';

            if (!clean) {
                correctedWords.push(word);
                continue;
            }

            const match = findBestMatch(clean);
            if (match) {
                fixes.push(match);
                correctedWords.push(prefix + match.corrected + suffix);
            } else {
                correctedWords.push(word);
            }
        }

        return {
            corrected: correctedWords.join(' '),
            fixes,
            hadTypos: fixes.length > 0
        };
    }

    return { fixSentence, findBestMatch, levenshtein };
})();
