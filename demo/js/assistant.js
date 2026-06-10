/**
 * SimpleMode OS — Basic Assistant
 * Workflow: Question → Typo Fix → Intent Detection → PageTree Lookup → Response
 */

const Assistant = (() => {
    let visible = false;
    let chatHistory = [];

    const GREETINGS = {
        elder: "Hello! I'm your SimpleMode assistant. I'm here to help you with anything. Just type your question below — don't worry about spelling! 😊",
        beginner: "Hi there! 👋 I'm your helpful assistant. Ask me anything about your computer — how to connect WiFi, install apps, manage files, and more!",
        advanced: "SimpleMode Assistant ready. Ask about system configuration, packages, networking, permissions, or any other topic."
    };

    const SUGGESTIONS = {
        elder: ["How do I connect to WiFi?", "How do I print?", "How do I update?"],
        beginner: ["How to install apps?", "How to use the terminal?", "How to manage files?"],
        advanced: ["File permissions guide", "Package management", "Terminal shortcuts"]
    };

    function toggle() {
        visible = !visible;
        const panel = document.getElementById('assistant-panel');
        if (visible && !panel.innerHTML) {
            renderPanel();
        }
        panel.classList.toggle('visible', visible);
        if (visible) {
            setTimeout(() => {
                document.querySelector('.chat-input')?.focus();
            }, 100);
        }
    }

    function renderPanel() {
        const panel = document.getElementById('assistant-panel');
        const mode = document.body.getAttribute('data-mode') || 'beginner';

        panel.innerHTML = `
            <div class="assistant-header">
                <div class="assistant-avatar">🤖</div>
                <div class="assistant-title">
                    <h3>SimpleMode Assistant</h3>
                    <p>● Online</p>
                </div>
                <button class="assistant-close" onclick="Assistant.toggle()">✕</button>
            </div>
            <div class="chat-messages" id="chat-messages"></div>
            <div class="suggestions" id="suggestions"></div>
            <div class="chat-input-area">
                <input type="text" class="chat-input" id="chat-input"
                       placeholder="Ask me anything..."
                       onkeydown="if(event.key==='Enter')Assistant.send()" autocomplete="off">
                <button class="chat-send" onclick="Assistant.send()" id="chat-send-btn">➤</button>
            </div>
        `;

        // Show greeting
        addBotMessage(GREETINGS[mode] || GREETINGS.beginner);

        // Show suggestions
        showSuggestions(SUGGESTIONS[mode] || SUGGESTIONS.beginner);
    }

    function addBotMessage(html, extras = {}) {
        const container = document.getElementById('chat-messages');
        const msg = document.createElement('div');
        msg.className = 'message bot';

        let content = `
            <div class="message-avatar">🤖</div>
            <div>
        `;

        if (extras.typoFix) {
            content += `
                <div class="typo-fix">
                    ✏️ <span class="original">${extras.typoFix.original}</span> → <span class="corrected">${extras.typoFix.corrected}</span>
                </div>
            `;
        }

        content += `<div class="message-content">${html}</div>`;

        if (extras.source) {
            content += `<div class="source-tag">📄 Source: ${extras.source}</div>`;
        }

        content += `</div>`;
        msg.innerHTML = content;
        container.appendChild(msg);
        container.scrollTop = container.scrollHeight;
    }

    function addUserMessage(text) {
        const container = document.getElementById('chat-messages');
        const msg = document.createElement('div');
        msg.className = 'message user';
        msg.innerHTML = `
            <div class="message-avatar">👤</div>
            <div class="message-content">${escapeHtml(text)}</div>
        `;
        container.appendChild(msg);
        container.scrollTop = container.scrollHeight;
    }

    function showTypingIndicator() {
        const container = document.getElementById('chat-messages');
        const typing = document.createElement('div');
        typing.className = 'message bot';
        typing.id = 'typing-indicator';
        typing.innerHTML = `
            <div class="message-avatar">🤖</div>
            <div class="typing-indicator"><span></span><span></span><span></span></div>
        `;
        container.appendChild(typing);
        container.scrollTop = container.scrollHeight;
    }

    function removeTypingIndicator() {
        document.getElementById('typing-indicator')?.remove();
    }

    function showSuggestions(suggestions) {
        const container = document.getElementById('suggestions');
        container.innerHTML = suggestions.map(s =>
            `<button class="suggestion-chip" onclick="Assistant.askSuggestion('${escapeAttr(s)}')">${s}</button>`
        ).join('');
    }

    function send() {
        const input = document.getElementById('chat-input');
        const text = input.value.trim();
        if (!text) return;

        input.value = '';
        addUserMessage(text);
        document.getElementById('suggestions').innerHTML = '';

        // Show typing indicator
        showTypingIndicator();

        // Process with delay for realism
        setTimeout(() => processQuery(text), 600);
    }

    function askSuggestion(text) {
        document.getElementById('chat-input').value = text;
        send();
    }

    function processQuery(originalText) {
        removeTypingIndicator();

        const mode = document.body.getAttribute('data-mode') || 'beginner';

        // Step 1: Typo correction
        const typoResult = TypoFix.fixSentence(originalText);
        const query = typoResult.corrected;

        let typoInfo = null;
        if (typoResult.hadTypos) {
            typoInfo = {
                original: originalText,
                corrected: query
            };
        }

        // Step 2: Intent detection (keyword-based for Phase 1)
        const intent = detectIntent(query);

        // Step 3: PageTree lookup
        const lookupResult = PageTree.lookup(query);

        // Step 4: Generate response
        let response = '';
        let source = null;
        let followUp = [];

        if (lookupResult && lookupResult.score >= 2) {
            // Good match found
            response = lookupResult.doc.content;
            source = lookupResult.doc.title;

            // Adapt response based on mode
            if (mode === 'elder') {
                response = `<p style="margin-bottom:12px">📋 I found this guide for you:</p>${response}`;
            }

            // Suggest related topics
            const allTopics = PageTree.getTopics().filter(t => t.id !== lookupResult.docId);
            followUp = allTopics.slice(0, 3).map(t => t.title.replace('How to ', '').replace('Understanding ', ''));
        } else if (intent === 'greeting') {
            response = getGreetingResponse(mode);
            followUp = ['How to connect WiFi?', 'How to install apps?', 'Help with files'];
        } else if (intent === 'thanks') {
            response = getThanksResponse(mode);
            followUp = ['Ask another question', 'Show all topics'];
        } else if (query.toLowerCase().includes('all topics') || query.toLowerCase().includes('what can')) {
            response = getTopicListResponse(mode);
            followUp = [];
        } else {
            // No match
            response = getNoMatchResponse(query, mode);
            const searchResults = PageTree.search(query);
            if (searchResults.length > 0) {
                followUp = searchResults.slice(0, 3).map(r => r.doc.title.replace('How to ', ''));
            } else {
                followUp = ['Connect WiFi', 'Install software', 'File permissions'];
            }
        }

        addBotMessage(response, { typoFix: typoInfo, source });

        if (followUp.length > 0) {
            showSuggestions(followUp);
        }

        chatHistory.push({ query: originalText, corrected: query, intent, response: lookupResult?.docId });
    }

    function detectIntent(text) {
        const lower = text.toLowerCase();
        if (/^(hi|hello|hey|good morning|good evening|greetings)\b/.test(lower)) return 'greeting';
        if (/^(thanks|thank you|thx|ty|cheers)\b/.test(lower)) return 'thanks';
        if (/\b(install|setup|add|get)\b/.test(lower)) return 'install';
        if (/\b(remove|uninstall|delete)\b/.test(lower)) return 'remove';
        if (/\b(update|upgrade|patch)\b/.test(lower)) return 'update';
        if (/\b(connect|wifi|network|internet)\b/.test(lower)) return 'network';
        if (/\b(permission|denied|access|sudo|root)\b/.test(lower)) return 'permissions';
        if (/\b(file|folder|directory|copy|move)\b/.test(lower)) return 'files';
        if (/\b(terminal|command|bash|shell)\b/.test(lower)) return 'terminal';
        if (/\b(print|printer|scan)\b/.test(lower)) return 'printer';
        if (/\b(open|launch|start|run)\b/.test(lower)) return 'open';
        return 'unknown';
    }

    function getGreetingResponse(mode) {
        if (mode === 'elder') return "Hello! 😊 I'm here to help you. What would you like to know? You can ask me about WiFi, printing, installing apps, or anything else!";
        if (mode === 'beginner') return "Hey there! 👋 How can I help you today? Try asking me something like <em>\"How do I connect to WiFi?\"</em>";
        return "Hello. How can I assist you? I can help with networking, package management, permissions, and more.";
    }

    function getThanksResponse(mode) {
        if (mode === 'elder') return "You're very welcome! 😊 Don't hesitate to ask if you need anything else. I'm always here to help!";
        if (mode === 'beginner') return "You're welcome! 😄 Feel free to ask me anything else anytime!";
        return "You're welcome. Let me know if you need anything else.";
    }

    function getNoMatchResponse(query, mode) {
        if (mode === 'elder') {
            return `<p>I'm sorry, I don't have specific information about "<em>${escapeHtml(query)}</em>" yet.</p>
                    <p style="margin-top:8px">But don't worry! Here are some topics I <strong>can</strong> help you with. Click one of the suggestions below. 👇</p>`;
        }
        if (mode === 'beginner') {
            return `<p>I don't have an answer for "<em>${escapeHtml(query)}</em>" right now.</p>
                    <p style="margin-top:8px">Try one of these topics instead:</p>`;
        }
        return `<p>No matching documentation found for "<code>${escapeHtml(query)}</code>". Available topics are listed below.</p>`;
    }

    function getTopicListResponse(mode) {
        const topics = PageTree.getTopics();
        let html = '<p>Here are all the topics I can help with:</p><ul style="margin-top:8px;padding-left:20px;">';
        for (const topic of topics) {
            html += `<li style="margin-bottom:4px"><strong>${topic.title}</strong> — ${topic.summary}</li>`;
        }
        html += '</ul>';
        return html;
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    function escapeAttr(text) {
        return text.replace(/'/g, "\\'").replace(/"/g, '&quot;');
    }

    return { toggle, send, askSuggestion };
})();
