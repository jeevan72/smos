/**
 * SimpleMode OS — Onboarding Wizard
 */

const Onboarding = (() => {
    let currentStep = 0;
    let selections = { userType: null, desktopStyle: null };
    const STEPS = ['welcome', 'user-type', 'desktop-style', 'summary'];

    function init() {
        renderWizard();
        showStep(0);
    }

    function renderWizard() {
        const screen = document.getElementById('onboarding-screen');
        screen.innerHTML = `
            <div class="onboarding-bg">
                <div class="orb"></div>
                <div class="orb"></div>
                <div class="orb"></div>
            </div>
            <div class="wizard-container">
                <div class="wizard-card">
                    <div class="step-indicators" id="step-indicators">
                        ${STEPS.map((_, i) => `<div class="step-dot" data-step="${i}"></div>`).join('')}
                    </div>

                    <!-- Step 0: Welcome -->
                    <div class="wizard-step" data-step="welcome">
                        <div class="wizard-logo">🐧</div>
                        <h1>Welcome to SimpleMode OS</h1>
                        <p class="subtitle">Your personalized Linux experience starts here.<br>Let's set up your perfect desktop in just 2 steps.</p>
                        <div class="wizard-actions" style="justify-content: center;">
                            <button class="btn btn-primary btn-large" onclick="Onboarding.next()">Get Started →</button>
                        </div>
                    </div>

                    <!-- Step 1: User Type -->
                    <div class="wizard-step" data-step="user-type">
                        <h1>Select Your Experience Level</h1>
                        <p class="subtitle">We'll adapt the interface to match your comfort level.</p>
                        <div class="option-grid">
                            <div class="option-card" onclick="Onboarding.selectUserType('elder')" data-value="elder">
                                <div class="option-icon">👴</div>
                                <div class="option-info">
                                    <h3>Elder / Senior</h3>
                                    <p>Larger text, bigger icons, high contrast. Designed for comfortable reading and easy clicking.</p>
                                </div>
                                <div class="option-radio"></div>
                            </div>
                            <div class="option-card" onclick="Onboarding.selectUserType('beginner')" data-value="beginner">
                                <div class="option-icon">🌱</div>
                                <div class="option-info">
                                    <h3>Beginner</h3>
                                    <p>Simplified menus with help buttons everywhere. Perfect if you're new to computers.</p>
                                </div>
                                <div class="option-radio"></div>
                            </div>
                            <div class="option-card" onclick="Onboarding.selectUserType('advanced')" data-value="advanced">
                                <div class="option-icon">⚡</div>
                                <div class="option-info">
                                    <h3>Advanced</h3>
                                    <p>Full Linux desktop with all features. For users comfortable with technology.</p>
                                </div>
                                <div class="option-radio"></div>
                            </div>
                        </div>
                        <div class="wizard-actions">
                            <button class="btn btn-secondary" onclick="Onboarding.prev()">← Back</button>
                            <button class="btn btn-primary" id="btn-step1-next" onclick="Onboarding.next()" disabled>Continue →</button>
                        </div>
                    </div>

                    <!-- Step 2: Desktop Style -->
                    <div class="wizard-step" data-step="desktop-style">
                        <h1>Choose Your Desktop Style</h1>
                        <p class="subtitle">Pick the layout that feels most familiar to you.</p>
                        <div class="style-grid">
                            <div class="style-card" onclick="Onboarding.selectStyle('windows')" data-value="windows">
                                <div class="style-preview preview-windows">
                                    <div class="preview-taskbar"><div class="preview-start"></div></div>
                                </div>
                                <h3>Windows Style</h3>
                            </div>
                            <div class="style-card" onclick="Onboarding.selectStyle('macos')" data-value="macos">
                                <div class="style-preview preview-macos">
                                    <div class="preview-menubar"></div>
                                    <div class="preview-dock">
                                        <div class="preview-dock-icon"></div>
                                        <div class="preview-dock-icon"></div>
                                        <div class="preview-dock-icon"></div>
                                        <div class="preview-dock-icon"></div>
                                    </div>
                                </div>
                                <h3>macOS Style</h3>
                            </div>
                            <div class="style-card" onclick="Onboarding.selectStyle('linux')" data-value="linux">
                                <div class="style-preview preview-linux">
                                    <div class="preview-topbar"><span class="preview-activities">Activities</span></div>
                                </div>
                                <h3>Linux Style</h3>
                            </div>
                        </div>
                        <div class="wizard-actions">
                            <button class="btn btn-secondary" onclick="Onboarding.prev()">← Back</button>
                            <button class="btn btn-primary" id="btn-step2-next" onclick="Onboarding.next()" disabled>Continue →</button>
                        </div>
                    </div>

                    <!-- Step 3: Summary -->
                    <div class="wizard-step" data-step="summary">
                        <h1>You're All Set!</h1>
                        <p class="subtitle">Here's your personalized configuration:</p>
                        <div class="summary-grid">
                            <div class="summary-item">
                                <div class="label">Experience Level</div>
                                <div class="value-icon" id="summary-mode-icon"></div>
                                <div class="value" id="summary-mode"></div>
                            </div>
                            <div class="summary-item">
                                <div class="label">Desktop Style</div>
                                <div class="value-icon" id="summary-style-icon"></div>
                                <div class="value" id="summary-style"></div>
                            </div>
                        </div>
                        <div class="wizard-actions">
                            <button class="btn btn-secondary" onclick="Onboarding.prev()">← Back</button>
                            <button class="btn btn-primary btn-large" onclick="Onboarding.finish()">🚀 Launch Desktop</button>
                        </div>
                    </div>
                </div>
            </div>`;
    }

    function showStep(step) {
        currentStep = step;
        // Update step dots
        document.querySelectorAll('.step-dot').forEach((dot, i) => {
            dot.className = 'step-dot';
            if (i < step) dot.classList.add('completed');
            if (i === step) dot.classList.add('active');
        });
        // Show/hide steps
        document.querySelectorAll('.wizard-step').forEach((el, i) => {
            el.classList.toggle('active', i === step);
        });
        // Update summary if on last step
        if (step === 3) updateSummary();
    }

    function next() { if (currentStep < STEPS.length - 1) showStep(currentStep + 1); }
    function prev() { if (currentStep > 0) showStep(currentStep - 1); }

    function selectUserType(type) {
        selections.userType = type;
        document.querySelectorAll('[data-step="user-type"] .option-card').forEach(card => {
            card.classList.toggle('selected', card.dataset.value === type);
        });
        const btn = document.getElementById('btn-step1-next');
        if (btn) btn.disabled = false;
    }

    function selectStyle(style) {
        selections.desktopStyle = style;
        document.querySelectorAll('[data-step="desktop-style"] .style-card').forEach(card => {
            card.classList.toggle('selected', card.dataset.value === style);
        });
        const btn = document.getElementById('btn-step2-next');
        if (btn) btn.disabled = false;
    }

    function updateSummary() {
        const modeMap = { elder: '👴 Elder', beginner: '🌱 Beginner', advanced: '⚡ Advanced' };
        const iconMap = { elder: '👴', beginner: '🌱', advanced: '⚡' };
        const styleMap = { windows: '🪟 Windows', macos: '🍎 macOS', linux: '🐧 Linux' };
        const styleIconMap = { windows: '🪟', macos: '🍎', linux: '🐧' };

        document.getElementById('summary-mode').textContent = modeMap[selections.userType] || '—';
        document.getElementById('summary-mode-icon').textContent = iconMap[selections.userType] || '❓';
        document.getElementById('summary-style').textContent = styleMap[selections.desktopStyle] || '—';
        document.getElementById('summary-style-icon').textContent = styleIconMap[selections.desktopStyle] || '❓';
    }

    function finish() {
        // Save to localStorage
        localStorage.setItem('simplemode-profile', JSON.stringify(selections));
        // Apply to body
        document.body.setAttribute('data-mode', selections.userType);
        document.body.setAttribute('data-style', selections.desktopStyle);
        // Hide onboarding, show desktop
        document.getElementById('onboarding-screen').style.display = 'none';
        Desktop.init(selections);
    }

    function getSelections() { return selections; }

    function reset() {
        localStorage.removeItem('simplemode-profile');
        selections = { userType: null, desktopStyle: null };
        document.getElementById('onboarding-screen').style.display = 'flex';
        init();
    }

    return { init, next, prev, selectUserType, selectStyle, finish, getSelections, reset };
})();
