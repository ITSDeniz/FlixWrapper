import Foundation

enum UserScripts {
    
    /// Script injected to track playback state (for macOS Now Playing and Media Keys)
    /// and provide helper functions for Picture-in-Picture, auto-skipping intros, and episode controls.
    static let clientBridgeScript: String = """
    (function() {
        if (window.__flixWrapperInjected) return;
        window.__flixWrapperInjected = true;

        // Custom helpers exposed to native Swift
        window.flixWrapperTogglePiP = async function() {
            try {
                const video = document.querySelector('video');
                if (!video) return false;
                if (document.pictureInPictureElement) {
                    await document.exitPictureInPicture();
                    return false;
                } else {
                    await video.requestPictureInPicture();
                    return true;
                }
            } catch (err) {
                console.error('[FlixWrapper] PiP Error:', err);
                return false;
            }
        };

        window.flixWrapperPlayPause = function() {
            const video = document.querySelector('video');
            if (!video) return;
            if (video.paused) {
                video.play();
            } else {
                video.pause();
            }
        };

        window.flixWrapperSeek = function(secondsDelta) {
            const video = document.querySelector('video');
            if (!video) return;
            video.currentTime = Math.max(0, Math.min(video.duration || 0, video.currentTime + secondsDelta));
        };

        window.flixWrapperNextEpisode = function() {
            const nextBtn = document.querySelector('[data-uia="next-episode-seamless-button"]') ||
                            document.querySelector('.watch-video--seamless-button') ||
                            document.querySelector('[data-uia="control-next"]');
            if (nextBtn) {
                nextBtn.click();
            }
        };

        // Auto Skip Intro & Seamless Next Episode observer
        let autoSkipIntroEnabled = true;
        let autoNextEpisodeEnabled = true;

        window.flixWrapperSetPreferences = function(prefs) {
            if (typeof prefs.autoSkipIntro === 'boolean') autoSkipIntroEnabled = prefs.autoSkipIntro;
            if (typeof prefs.autoNextEpisode === 'boolean') autoNextEpisodeEnabled = prefs.autoNextEpisode;
        };

        function checkAutomationButtons() {
            if (autoSkipIntroEnabled) {
                const skipBtn = document.querySelector('[data-uia="player-skip-intro"]') ||
                                document.querySelector('.watch-video--skip-content-button');
                if (skipBtn && skipBtn.offsetParent !== null) {
                    skipBtn.click();
                }
            }

            if (autoNextEpisodeEnabled) {
                const nextSeamless = document.querySelector('[data-uia="next-episode-seamless-button"]') ||
                                     document.querySelector('.watch-video--seamless-button');
                if (nextSeamless && nextSeamless.offsetParent !== null) {
                    nextSeamless.click();
                }
            }
        }

        // MutationObserver to catch skip buttons the moment they appear
        const observer = new MutationObserver(() => {
            checkAutomationButtons();
        });

        observer.observe(document.documentElement, {
            childList: true,
            subtree: true
        });

        // Periodic state sync to macOS Now Playing Info
        let lastReportedState = { paused: true, title: '', currentTime: 0, duration: 0 };
        
        function syncPlaybackState() {
            const video = document.querySelector('video');
            if (!video) return;

            // Extract title from Netflix DOM if in player view
            let title = '';
            const titleElem = document.querySelector('[data-uia="video-title"]') ||
                              document.querySelector('.ellipsize-text') ||
                              document.querySelector('h4');
            if (titleElem) {
                title = titleElem.innerText.trim();
            }

            const state = {
                paused: video.paused,
                currentTime: video.currentTime || 0,
                duration: video.duration || 0,
                title: title
            };

            // Post to Swift handler if meaningful change
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.playbackState) {
                window.webkit.messageHandlers.playbackState.postMessage(state);
            }
        }

        setInterval(syncPlaybackState, 1000);
    })();
    """
    
    /// Dark styling tweaks to avoid white blinks during page transitions
    static let customCSS: String = """
    html, body {
        background-color: #141414 !important;
    }
    """
}
