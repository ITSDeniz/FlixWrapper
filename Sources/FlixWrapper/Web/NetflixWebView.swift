import Cocoa
import WebKit

// MARK: - Weak Script Message Handler Proxy (Eliminates WebKit Retain Cycles)

final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?
    
    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - NetflixWebView

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
        
        // User content controller for scripts
        let userContentController = WKUserContentController()
        
        // Inject client bridge at document end for main frame
        let bridgeScript = WKUserScript(
            source: UserScripts.clientBridgeScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(bridgeScript)
        
        config.userContentController = userContentController
        
        super.init(frame: frame, configuration: config)
        
        // Register message handler using a WEAK proxy to prevent memory leaks
        userContentController.add(WeakScriptMessageHandler(self), name: "playbackState")
        
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Cleanly detach script handler to avoid any lingering references
        configuration.userContentController.removeScriptMessageHandler(forName: "playbackState")
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        self.navigationDelegate = self
        self.uiDelegate = self
        
        // Enable Web Inspector (Right Click -> Inspect Element) for debugging
        if #available(macOS 13.3, *) {
            self.isInspectable = true
        }
        
        // Set modern, non-private API for dark under-page background (macOS 12+)
        let darkColor = NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        self.wantsLayer = true
        self.layer?.backgroundColor = darkColor.cgColor
        self.underPageBackgroundColor = darkColor
        
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
    
    // MARK: - Domain Whitelist Helper
    
    func isAllowedDomain(host: String) -> Bool {
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
        return allowedDomains.contains { allowed in
            host == allowed || host.hasSuffix("." + allowed)
        }
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
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleNavigationError(error)
    }
    
    private func handleNavigationError(_ error: Error) {
        let nsError = error as NSError
        // Ignore user-cancelled requests (e.g. redirected or stopped)
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        
        let offlineHTML = UserScripts.offlineHTML(errorMessage: error.localizedDescription)
        self.loadHTMLString(offlineHTML, baseURL: AppPreferences.netflixURL)
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
        let isAllowed = isAllowedDomain(host: host)
        
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
    
    // Support window.open / target="_blank" requests from Netflix
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            let host = url.host?.lowercased() ?? ""
            let isAllowed = isAllowedDomain(host: host)
            
            // If the popup / target="_blank" is an external link (e.g. Instagram, Twitter, Help Center),
            // open cleanly in default browser instead of taking over the app window
            if !isAllowed && !host.isEmpty {
                NSWorkspace.shared.open(url)
                return nil
            }
        }
        
        // Internal popups / auth dialogs remain in-app
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
        
        // Check if video playback was stopped / returned to catalog
        if let isStopped = dict["isStopped"] as? Bool, isStopped {
            MediaKeyManager.shared.clearNowPlaying()
            return
        }
        
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
