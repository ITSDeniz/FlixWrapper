import Cocoa

final class WindowController: NSWindowController {
    
    let webView: NetflixWebView
    
    init() {
        self.webView = NetflixWebView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        guard let window = self.window else { return }
        
        window.title = "FlixWrapper"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 640, height: 360)
        window.setFrameAutosaveName("FlixWrapperMainWindowFrame")
        window.center()
        
        // Embed web view as the primary content view
        window.contentView = webView
        
        // Restore always on top preference
        updateWindowLevel(isAlwaysOnTop: AppPreferences.shared.alwaysOnTop)
    }
    
    var isAlwaysOnTop: Bool {
        return window?.level == .floating
    }
    
    func toggleAlwaysOnTop() {
        let newState = !isAlwaysOnTop
        AppPreferences.shared.alwaysOnTop = newState
        updateWindowLevel(isAlwaysOnTop: newState)
    }
    
    private func updateWindowLevel(isAlwaysOnTop: Bool) {
        window?.level = isAlwaysOnTop ? .floating : .normal
    }
}
