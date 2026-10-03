import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var windowController: WindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        let controller = WindowController()
        self.windowController = controller
        controller.showWindow(nil)
        
        // Setup hardware media key controls (Touch Bar / Keyboard / Headphones)
        MediaKeyManager.shared.setupMediaCommands(with: controller.webView)
        
        setupMainMenu()
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            windowController?.showWindow(nil)
        }
        return true
    }
    
    // MARK: - Menu Setup
    
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // 1. App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        
        appMenu.addItem(withTitle: "About FlixWrapper", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide FlixWrapper", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit FlixWrapper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // 2. File Menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // 3. Playback Menu
        let playbackMenuItem = NSMenuItem()
        let playbackMenu = NSMenu(title: "Playback")
        
        playbackMenu.addItem(withTitle: "Play / Pause", action: #selector(togglePlayPause), keyEquivalent: " ")
        playbackMenu.addItem(withTitle: "Skip 10s Forward", action: #selector(seekForward), keyEquivalent: "\u{F703}") // Right arrow
        playbackMenu.addItem(withTitle: "Skip 10s Backward", action: #selector(seekBackward), keyEquivalent: "\u{F702}") // Left arrow
        playbackMenu.addItem(withTitle: "Next Episode", action: #selector(nextEpisode), keyEquivalent: "n")
        playbackMenu.addItem(NSMenuItem.separator())
        
        let autoSkipIntroItem = NSMenuItem(title: "Auto-Skip Intros", action: #selector(toggleAutoSkipIntro), keyEquivalent: "")
        autoSkipIntroItem.state = AppPreferences.shared.autoSkipIntro ? .on : .off
        playbackMenu.addItem(autoSkipIntroItem)
        
        let autoNextEpisodeItem = NSMenuItem(title: "Auto-Next Episode", action: #selector(toggleAutoNextEpisode), keyEquivalent: "")
        autoNextEpisodeItem.state = AppPreferences.shared.autoNextEpisode ? .on : .off
        playbackMenu.addItem(autoNextEpisodeItem)
        
        playbackMenuItem.submenu = playbackMenu
        mainMenu.addItem(playbackMenuItem)
        
        // 4. View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        
        let floatItem = NSMenuItem(title: "Always on Top", action: #selector(toggleAlwaysOnTop), keyEquivalent: "t")
        floatItem.keyEquivalentModifierMask = [.command, .shift]
        floatItem.state = AppPreferences.shared.alwaysOnTop ? .on : .off
        viewMenu.addItem(floatItem)
        
        let pipItem = NSMenuItem(title: "Picture-in-Picture", action: #selector(togglePictureInPicture), keyEquivalent: "p")
        pipItem.keyEquivalentModifierMask = [.command, .option]
        viewMenu.addItem(pipItem)
        
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        // 5. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        // 6. Help Menu
        let helpMenuItem = NSMenuItem()
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "FlixWrapper on GitHub", action: #selector(openGitHub), keyEquivalent: "")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    // MARK: - Actions
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "FlixWrapper for macOS"
        alert.informativeText = "A lightweight, open-source native wrapper for streaming with 4K HDR and Spatial Audio support.\n\nNot affiliated with Netflix, Inc."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func reloadPage() {
        windowController?.webView.loadNetflix()
    }
    
    @objc private func togglePlayPause() {
        windowController?.webView.togglePlayPause()
    }
    
    @objc private func seekForward() {
        windowController?.webView.seek(by: 10)
    }
    
    @objc private func seekBackward() {
        windowController?.webView.seek(by: -10)
    }
    
    @objc private func nextEpisode() {
        windowController?.webView.nextEpisode()
    }
    
    @objc private func toggleAlwaysOnTop(_ sender: NSMenuItem) {
        windowController?.toggleAlwaysOnTop()
        sender.state = (windowController?.isAlwaysOnTop ?? false) ? .on : .off
    }
    
    @objc private func togglePictureInPicture() {
        windowController?.webView.togglePictureInPicture()
    }
    
    @objc private func toggleAutoSkipIntro(_ sender: NSMenuItem) {
        let current = AppPreferences.shared.autoSkipIntro
        AppPreferences.shared.autoSkipIntro = !current
        sender.state = !current ? .on : .off
        windowController?.webView.syncPreferencesToWeb()
    }
    
    @objc private func toggleAutoNextEpisode(_ sender: NSMenuItem) {
        let current = AppPreferences.shared.autoNextEpisode
        AppPreferences.shared.autoNextEpisode = !current
        sender.state = !current ? .on : .off
        windowController?.webView.syncPreferencesToWeb()
    }
    
    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/topics/netflix-mac") {
            NSWorkspace.shared.open(url)
        }
    }
}
