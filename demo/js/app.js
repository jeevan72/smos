/**
 * SimpleMode OS — Main App Controller
 */

const App = (() => {
    function init() {
        // Check if user has already completed onboarding
        const saved = localStorage.getItem('simplemode-profile');
        if (saved) {
            try {
                const profile = JSON.parse(saved);
                if (profile.userType && profile.desktopStyle) {
                    // Skip onboarding, go to desktop
                    document.body.setAttribute('data-mode', profile.userType);
                    document.body.setAttribute('data-style', profile.desktopStyle);
                    document.getElementById('onboarding-screen').style.display = 'none';
                    Desktop.init(profile);
                    return;
                }
            } catch (e) { /* ignore parse errors */ }
        }

        // Show onboarding
        Onboarding.init();
    }

    return { init };
})();

// Start the app when DOM is ready
document.addEventListener('DOMContentLoaded', App.init);
