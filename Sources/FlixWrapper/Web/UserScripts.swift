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
            // Only perform skip checks if a video is present (in player view)
            // This prevents any observer overhead during login or profile selection
            const video = document.querySelector('video');
            if (!video) return;

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
        let hadVideo = false;

        function syncPlaybackState() {
            try {
                const video = document.querySelector('video');

                // If video element is gone (e.g. user returned to home/browse screen)
                if (!video) {
                    if (hadVideo) {
                        hadVideo = false;
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.playbackState) {
                            window.webkit.messageHandlers.playbackState.postMessage({ isStopped: true });
                        }
                    }
                    return;
                }

                hadVideo = true;

                // Extract title from Netflix player view
                let title = '';
                const titleElem = document.querySelector('[data-uia="video-title"]') ||
                                  document.querySelector('.ellipsize-text') ||
                                  document.querySelector('h4');
                if (titleElem) {
                    title = titleElem.innerText.trim();
                }

                const state = {
                    isStopped: false,
                    paused: video.paused,
                    currentTime: video.currentTime || 0,
                    duration: video.duration || 0,
                    title: title
                };

                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.playbackState) {
                    window.webkit.messageHandlers.playbackState.postMessage(state);
                }
            } catch (err) {
                // Safeguard against DOM transition errors
            }
        }

        setInterval(syncPlaybackState, 1000);
    })();
    """
    
    /// Elegant offline error page when network is unavailable
    static func offlineHTML(errorMessage: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background-color: #141414;
                    color: #FFFFFF;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    text-align: center;
                }
                .container {
                    max-width: 480px;
                    padding: 40px;
                }
                h1 {
                    font-size: 28px;
                    font-weight: 700;
                    margin-bottom: 12px;
                    color: #E50914;
                }
                p {
                    font-size: 15px;
                    color: #A3A3A3;
                    line-height: 1.5;
                    margin-bottom: 28px;
                }
                .error-detail {
                    font-size: 12px;
                    color: #737373;
                    margin-bottom: 24px;
                    font-family: monospace;
                }
                button {
                    background-color: #E50914;
                    color: #FFFFFF;
                    border: none;
                    border-radius: 6px;
                    padding: 12px 28px;
                    font-size: 15px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: background-color 0.2s;
                }
                button:hover {
                    background-color: #F40612;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Connection Lost</h1>
                <p>Unable to connect to Netflix. Please check your internet connection and try again.</p>
                <div class="error-detail">\(errorMessage)</div>
                <button onclick="window.location.reload()">Retry Connection</button>
            </div>
        </body>
        </html>
        """
    }
}
