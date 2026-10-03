import Cocoa
import WebKit

final class NetflixWebView: WKWebView {
    
    // MARK: - Initialization
    
    init(frame: CGRect = .zero) {
        let config = WKWebViewConfiguration()
        
        // Ensure standard AirPlay and hardware media routing
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.isElementFullscreenEnabled = true
        
        // Set Safari application identity so WebKit dynamically pairs with
        // macOS FairPlay DRM and produces an authentic Safari User-Agent without triggering bot detection
        config.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
        
        // Persistent cookies & credentials so login is preserved across launches
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // User content controller for scripts and style injection
        let userContentController = WKUserContentController()
        
        // Inject dark background CSS for the MAIN frame only (never override captchas or iframes)
        let cssSource = """
        const style = document.createElement('style');
        style.innerHTML = `\(UserScripts.customCSS)`;
        document.head.appendChild(style);
        """
        let cssScript = WKUserScript(source: cssSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        userContentController.addUserScript(cssScript)
        
        // Inject client bridge at document end for main frame
        let bridgeScript = WKUserScript(
            source: UserScripts.clientBridgeScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(bridgeScript)
        
        config.userContentController = userContentController
        
        super.init(frame: frame, configuration: config)
        
        // Setup message handler for playback state sync
        userContentController.add(self, name: "playbackState")
        
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        self.navigationDelegate = self
        self.uiDelegate = self
        
        // Enable Web Inspector (Right Click -> Inspect Element) for debugging
        if #available(macOS 13.3, *) {
            self.isInspectable = true
        }
        
        // Set background color to match Netflix dark theme
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0).cgColor
        self.setValue(false, forKey: "drawsBackground")
        
        loadNetflix()
    }
    
    func loadNetflix() {
        let request = URLRequest(
            url: AppPreferences.netflixURL,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30.0
        )
        self.load(request)
    }
    
    // MARK: - Video Controls & Actions
    
    func togglePlayPause() {
        evaluateJavaScript("window.flixWrapperPlayPause && window.flixWrapperPlayPause();", completionHandler: nil)
    }
    
    func seek(by deltaSeconds: Double) {
        evaluateJavaScript("window.flixWrapperSeek && window.flixWrapperSeek(\(deltaSeconds));", completionHandler: nil)
    }
    
    func nextEpisode() {
        evaluateJavaScript("window.flixWrapperNextEpisode && window.flixWrapperNextEpisode();", completionHandler: nil)
    }
    
    func togglePictureInPicture() {
        evaluateJavaScript("window.flixWrapperTogglePiP && window.flixWrapperTogglePiP();") { result, error in
            if let error = error {
                print("[FlixWrapper] Error triggering PiP: \(error.localizedDescription)")
            }
        }
    }
    
    func syncPreferencesToWeb() {
        let prefs = AppPreferences.shared
        let json = "{\"autoSkipIntro\": \(prefs.autoSkipIntro), \"autoNextEpisode\": \(prefs.autoNextEpisode)}"
        evaluateJavaScript("window.flixWrapperSetPreferences && window.flixWrapperSetPreferences(\(json));", completionHandler: nil)
    }
}

// MARK: - WKNavigationDelegate

extension NetflixWebView: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        syncPreferencesToWeb()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        // Always allow internal schemes (about, data, blob)
        if url.scheme == "about" || url.scheme == "data" || url.scheme == "blob" {
            decisionHandler(.allow)
            return
        }
        
        // 1. Crucial for reCAPTCHA & Arkose: ALWAYS allow subframes (iframes) without interception
        if let targetFrame = navigationAction.targetFrame, !targetFrame.isMainFrame {
            decisionHandler(.allow)
            return
        }
        
        // 2. Allow any non-user link click (redirects, form posts, JS navigations, OAuth tokens)
        if navigationAction.navigationType != .linkActivated {
            decisionHandler(.allow)
            return
        }
        
        let host = url.host?.lowercased() ?? ""
        
        // 3. Known streaming and verification domains allowed within the app
        let allowedDomains = [
            "netflix.com",
            "nflxvideo.net",
            "nflximg.net",
            "nflxext.com",
            "nflxso.net",
            "google.com",
            "gstatic.com",
            "recaptcha.net",
            "arkoselabs.com",
            "funcaptcha.com"
        ]
        
        let isAllowed = allowedDomains.contains { allowed in
            host == allowed || host.hasSuffix("." + allowed)
        }
        
        if isAllowed || host.isEmpty {
            decisionHandler(.allow)
        } else {
            // Open external links (e.g. social media, third-party help) in default browser
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}

// MARK: - WKUIDelegate

extension NetflixWebView: WKUIDelegate {
    
    // Support window.open / popup requests from Netflix & Captchas
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

// MARK: - WKScriptMessageHandler

extension NetflixWebView: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "playbackState",
              let dict = message.body as? [String: Any] else { return }
        
        let isPaused = dict["paused"] as? Bool ?? true
        let currentTime = dict["currentTime"] as? Double ?? 0.0
        let duration = dict["duration"] as? Double ?? 0.0
        let title = dict["title"] as? String ?? ""
        
        MediaKeyManager.shared.updateNowPlaying(
            title: title,
            isPaused: isPaused,
            currentTime: currentTime,
            duration: duration
        )
    }
}
