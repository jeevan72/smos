/**
 * SimpleMode OS — Desktop Simulation
 */

const Desktop = (() => {
    let profile = {};
    let launcherVisible = false;
    let clockInterval = null;

    const APPS = [
        { id: 'files', name: 'Files', icon: '📁' },
        { id: 'firefox', name: 'Firefox', icon: '🦊' },
        { id: 'terminal', name: 'Terminal', icon: '💻' },
        { id: 'settings', name: 'Settings', icon: '⚙️' },
        { id: 'libreoffice', name: 'LibreOffice', icon: '📝' },
        { id: 'vlc', name: 'VLC Player', icon: '🎬' },
        { id: 'gimp', name: 'GIMP', icon: '🎨' },
        { id: 'calculator', name: 'Calculator', icon: '🔢' },
        { id: 'assistant', name: 'Assistant', icon: '🤖' },
        { id: 'store', name: 'Software Store', icon: '🏪' },
        { id: 'camera', name: 'Camera', icon: '📷' },
        { id: 'music', name: 'Music', icon: '🎵' },
    ];

    const DESKTOP_ICONS = [
        { id: 'files', name: 'Files', icon: '📁' },
        { id: 'firefox', name: 'Firefox', icon: '🦊' },
        { id: 'assistant', name: 'Assistant', icon: '🤖' },
        { id: 'settings', name: 'Settings', icon: '⚙️' },
        { id: 'terminal', name: 'Terminal', icon: '💻' },
        { id: 'store', name: 'Software Store', icon: '🏪' },
    ];

    function init(p) {
        profile = p;
        const screen = document.getElementById('desktop-screen');
        screen.classList.add('active');
        renderDesktop();
        startClock();
    }

    function renderDesktop() {
        const screen = document.getElementById('desktop-screen');
        const style = profile.desktopStyle;
        const mode = profile.userType;

        screen.innerHTML = `
            <div class="desktop-wallpaper"></div>

            <!-- Desktop Icons -->
            <div class="desktop-icons" id="desktop-icons">
                ${DESKTOP_ICONS.map(app => `
                    <div class="desktop-icon" onclick="Desktop.openApp('${app.id}')" title="${app.name}">
                        <span class="icon">${app.icon}</span>
                        <span class="label">${app.name}</span>
                    </div>
                `).join('')}
            </div>

            <!-- Windows Taskbar -->
            <div class="taskbar-bottom">
                <button class="start-btn" onclick="Desktop.toggleLauncher()" title="Start Menu">🐧</button>
                <div class="taskbar-apps">
                    ${['files', 'firefox', 'terminal', 'assistant'].map(id => {
                        const app = APPS.find(a => a.id === id);
                        return `<button class="taskbar-app" onclick="Desktop.openApp('${id}')" title="${app.name}">${app.icon}</button>`;
                    }).join('')}
                </div>
                <div class="taskbar-tray">
                    <span>🔊</span>
                    <span>🌐</span>
                    <span>🔋</span>
                    <span class="taskbar-clock" id="clock-windows"></span>
                </div>
            </div>

            <!-- macOS Menu Bar -->
            <div class="menubar-top">
                <span class="menubar-logo" onclick="Desktop.toggleLauncher()">🐧 SimpleMode</span>
                <span>File</span><span>Edit</span><span>View</span><span>Help</span>
                <div style="flex:1"></div>
                <span>🔊</span><span>🌐</span><span>🔋</span>
                <span class="taskbar-clock" id="clock-macos"></span>
            </div>

            <!-- macOS Dock -->
            <div class="dock-bottom">
                ${['files', 'firefox', 'terminal', 'settings', 'assistant', 'vlc', 'gimp'].map(id => {
                    const app = APPS.find(a => a.id === id);
                    return `<button class="dock-icon" onclick="Desktop.openApp('${id}')" title="${app.name}">${app.icon}</button>`;
                }).join('')}
            </div>

            <!-- Linux GNOME Top Bar -->
            <div class="topbar-gnome">
                <span class="topbar-activities" onclick="Desktop.toggleLauncher()">Activities</span>
                <span class="taskbar-clock" id="clock-linux"></span>
                <div class="topbar-status">
                    <span>🔊</span><span>🌐</span><span>🔋</span>
                </div>
            </div>

            <!-- App Launcher (shared) -->
            <div class="app-launcher" id="app-launcher">
                <input type="text" class="app-launcher-search" placeholder="Search applications..."
                       oninput="Desktop.filterApps(this.value)" autocomplete="off">
                <div class="app-list" id="app-list">
                    ${APPS.map(app => `
                        <div class="app-item" data-name="${app.name.toLowerCase()}" onclick="Desktop.openApp('${app.id}')">
                            <span class="app-icon">${app.icon}</span>
                            <span class="app-name">${app.name}</span>
                        </div>
                    `).join('')}
                </div>
            </div>

            <!-- Help Float (beginner mode) -->
            <button class="help-float" onclick="Desktop.openApp('assistant')" title="Need help? Click here!">❓</button>

            <!-- Profile Switcher (demo controls) -->
            <div class="profile-switcher">
                <button onclick="Desktop.switchMode('elder')" class="${mode === 'elder' ? 'active' : ''}">Elder</button>
                <button onclick="Desktop.switchMode('beginner')" class="${mode === 'beginner' ? 'active' : ''}">Beginner</button>
                <button onclick="Desktop.switchMode('advanced')" class="${mode === 'advanced' ? 'active' : ''}">Advanced</button>
                <button onclick="Onboarding.reset()" style="color:var(--brand-accent)">Reset</button>
            </div>

            <!-- Assistant panel placeholder -->
            <div id="assistant-panel"></div>
        `;

        // Close launcher when clicking desktop
        document.getElementById('desktop-icons').addEventListener('click', (e) => {
            if (e.target === e.currentTarget) closeLauncher();
        });
    }

    function toggleLauncher() {
        const launcher = document.getElementById('app-launcher');
        launcherVisible = !launcherVisible;
        launcher.classList.toggle('visible', launcherVisible);
        if (launcherVisible) {
            launcher.querySelector('.app-launcher-search').focus();
        }
    }

    function closeLauncher() {
        const launcher = document.getElementById('app-launcher');
        launcherVisible = false;
        launcher?.classList.remove('visible');
    }

    function filterApps(query) {
        const items = document.querySelectorAll('#app-list .app-item');
        const q = query.toLowerCase();
        items.forEach(item => {
            item.style.display = item.dataset.name.includes(q) ? 'flex' : 'none';
        });
    }

    function openApp(id) {
        closeLauncher();
        if (id === 'assistant') {
            Assistant.toggle();
        } else {
            // Show a simple notification for other apps
            showNotification(`Opening ${APPS.find(a => a.id === id)?.name || id}...`);
        }
    }

    function showNotification(text) {
        const notif = document.createElement('div');
        notif.style.cssText = `
            position: fixed; top: 60px; right: 20px; z-index: 500;
            padding: 12px 20px; background: rgba(20,20,35,0.95);
            backdrop-filter: blur(16px); border: 1px solid rgba(255,255,255,0.1);
            border-radius: 12px; color: #f0f0f0; font-size: 14px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.4);
            animation: fadeInUp 0.3s ease; font-family: 'Inter', sans-serif;
        `;
        notif.textContent = text;
        document.body.appendChild(notif);
        setTimeout(() => {
            notif.style.opacity = '0';
            notif.style.transition = 'opacity 0.3s';
            setTimeout(() => notif.remove(), 300);
        }, 2000);
    }

    function switchMode(mode) {
        profile.userType = mode;
        document.body.setAttribute('data-mode', mode);
        // Update profile switcher buttons
        document.querySelectorAll('.profile-switcher button').forEach(btn => {
            btn.classList.remove('active');
        });
        event.target.classList.add('active');
        localStorage.setItem('simplemode-profile', JSON.stringify(profile));
    }

    function startClock() {
        function update() {
            const now = new Date();
            const time = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            document.querySelectorAll('.taskbar-clock').forEach(el => el.textContent = time);
        }
        update();
        clockInterval = setInterval(update, 30000);
    }

    function getProfile() { return profile; }

    return { init, toggleLauncher, filterApps, openApp, switchMode, getProfile, showNotification };
})();
