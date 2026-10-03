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
        
        // Persistent cookies & credentials so login is preserved across launches
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // User content controller for scripts and style injection
        let userContentController = WKUserContentController()
        
        // Inject dark background CSS immediately at document start
        let cssSource = """
        const style = document.createElement('style');
        style.innerHTML = `\(UserScripts.customCSS)`;
        document.head.appendChild(style);
        """
        let cssScript = WKUserScript(source: cssSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(cssScript)
        
        // Inject client bridge at document end
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
        
        // Set Safari User Agent to unlock 4K HDR & Spatial Audio stream delivery
        self.customUserAgent = AppPreferences.safariUserAgent
        
        // Set background color to match Netflix dark theme
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0).cgColor
        self.setValue(false, forKey: "drawsBackground") // WKWebView private KVC fallback for transparent loading
        
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
        
        let host = url.host?.lowercased() ?? ""
        
        // Allow Netflix navigation and auth flows
        if host.contains("netflix.com") || host.contains("nflxvideo.net") || host.contains("nflximg.net") || host.isEmpty {
            decisionHandler(.allow)
        } else {
            // Open external external links (help, billing, privacy policies) in default browser
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}

// MARK: - WKUIDelegate

extension NetflixWebView: WKUIDelegate {
    
    // Support window.open / popup requests from Netflix
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
