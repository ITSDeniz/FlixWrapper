# FlixWrapper for macOS 🎬

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue?logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Language-Swift%206-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/4K%20HDR-Dolby%20Vision-purple" alt="4K HDR">
  <img src="https://img.shields.io/badge/Audio-Spatial%20%2F%20Atmos-success" alt="Spatial Audio">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
</p>

A lightweight, native macOS wrapper for Netflix built with Swift and WebKit. Engineered specifically to unlock **4K HDR (Dolby Vision / HDR10)** and **Spatial Audio (Dolby Atmos / 5.1 multichannel)** on Apple Silicon Macs—with hardware media key integration, Picture-in-Picture, floating mini-player mode, auto-skip intro automation, and smart external link routing.

---

## ⚡ Why FlixWrapper?

Most third-party desktop wrappers on GitHub are built with **Electron (Chromium)**. Because Google Chrome on macOS is restricted to Widevine L3 DRM, those apps are permanently locked to **1080p SDR and Stereo 2.0 audio**, while eating hundreds of megabytes of RAM.

**FlixWrapper** uses Apple's native **WebKit** engine paired with a calibrated Safari engine profile:

| Feature | FlixWrapper | Safari Tab | Chrome / Brave | Electron Wrappers |
| :--- | :---: | :---: | :---: | :---: |
| **4K HDR / Dolby Vision** | ✅ **Yes** | ✅ **Yes** | ❌ No (1080p SDR) | ❌ No (1080p SDR) |
| **Spatial Audio / Atmos** | ✅ **Yes** | ✅ **Yes** | ❌ No (Stereo 2.0) | ❌ No (Stereo 2.0) |
| **Dedicated App Window** | ✅ **Yes** | ❌ In browser tab | ❌ In browser tab | ✅ Yes |
| **Hardware Media Keys** | ✅ **Yes** | ⚠️ Partial | ⚠️ Partial | ⚠️ Buggy |
| **Control Center / Now Playing** | ✅ **Yes** | ❌ No | ❌ No | ❌ No |
| **Always-on-Top Floating Mode** | ✅ **Yes** (`⌘⇧T`) | ❌ No | ❌ No | ⚠️ Varies |
| **Native Picture-in-Picture** | ✅ **Yes** (`⌥⌘P`) | ⚠️ Manual | ⚠️ Manual | ❌ No |
| **Auto-Skip Intros** | ✅ **Yes** | ❌ Manual click | ⚠️ Requires extensions | ⚠️ Varies |
| **External Link Routing** | ✅ **Default Browser** | ❌ Opens in tab | ❌ Opens in tab | ❌ Trapped in app |
| **Zero White-Flash Startup** | ✅ **Yes (`#141414`)** | ❌ White flash | ❌ White flash | ⚠️ Varies |
| **Memory & Battery Footprint** | 🟢 **Ultra-low (Native)**| 🟢 Low | 🔴 Heavy | 🔴 Very Heavy |

---

## 🎧 Requirements for 4K HDR & Spatial Audio

To experience maximum audio-visual fidelity:

1. **Netflix Subscription:** Premium plan (required by Netflix for Ultra HD 4K, HDR, and Dolby Atmos/Spatial Audio streams).
2. **Mac Hardware:** Any Apple Silicon Mac (M1, M2, M3, M4) or Intel Mac equipped with the Apple T2 Security Chip.
3. **Display (for HDR):** Built-in Liquid Retina XDR display (MacBook Pro 14"/16") or an external HDR10 / Dolby Vision monitor.
4. **AirPods / Audio (for Spatial Audio):** AirPods Pro (1st/2nd gen), AirPods Max, AirPods (3rd gen), or Beats Fit Pro with Spatial Audio enabled in macOS Control Center.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action | Notes |
| :--- | :--- | :--- |
| `Space` | Play / Pause | In active video player |
| `⌥ + Space` | Play / Pause | Global menu shortcut (safe for typing in search fields) |
| `→` (Right Arrow) | Skip 10 seconds forward | |
| `←` (Left Arrow) | Skip 10 seconds backward | |
| `⌘ + N` | Next Episode | |
| `⌘ + ⇧ + T` | Toggle Always-on-Top | Floating mini-player mode |
| `⌥ + ⌘ + P` | Toggle Picture-in-Picture | Native macOS PiP |
| `⌃ + ⌘ + F` | Enter / Exit Full Screen | |
| `⌘ + R` | Reload Player | |
| `⌘ + W` | Close Window | |
| `⌘ + Q` | Quit FlixWrapper | |

---

## ✨ Standout Features

* **🛡️ Smart External Link Routing:** Clicking external links (e.g. Instagram, Twitter/X, Help Center) opens them automatically in your Mac's default browser (Safari, Chrome, Arc), so you never get trapped outside Netflix.
* **🤖 Bot & reCAPTCHA Resilient:** Tailored WebKit configuration ensures verification challenges and login flows load seamlessly without broken iframes.
* **📶 Offline Graceful Recovery:** If your Wi-Fi drops, FlixWrapper displays a clean dark-mode connection screen with a one-click reload button.
* **🔍 Web Inspector Support:** Right-click anywhere and select **Inspect Element** (macOS 13.3+) for instant developer inspection.
* **🧼 Memory Safe Architecture:** Built with weak script message proxies to guarantee zero memory leaks or circular retain cycles.

---

## 🚀 Building & Running

### Option 1: Quick Run with Swift PM
No Xcode installation required—just Apple command line tools:

```bash
git clone https://github.com/ITSDeniz/FlixWrapper.git
cd FlixWrapper
swift run
```

### Option 2: Build a Standalone `.app` Bundle
To generate an optimized release `.app` and install it:

```bash
# Build the release bundle
./scripts/build_app.sh

# Copy to Applications for Spotlight indexing
cp -r dist/FlixWrapper.app /Applications/

# Launch anytime via Spotlight: ⌘ + Space -> FlixWrapper
```

---

## 🔧 Troubleshooting & Tips

* **Launching with Spotlight (`⌘ + Space`):**  
  Copying `FlixWrapper.app` into `/Applications/` allows macOS Spotlight to index it immediately. Simply press `⌘ + Space`, type `FlixWrapper`, and press `Enter`.
* **Gatekeeper Notice ("App from an unidentified developer"):**  
  If downloading pre-built binaries, clear the quarantine attribute:
  ```bash
  xattr -cr /Applications/FlixWrapper.app
  ```
* **Developer Rebuilds (Keychain Prompt):**  
  If actively modifying source code and recompiling multiple ad-hoc builds in a row, macOS Keychain may ask for permission. Click **Always Allow**, or reset the temporary development key with:
  ```bash
  security delete-generic-password -l "FlixWrapper WebCrypto Master Key"
  ```

---

## 🛠️ Architecture

```
FlixWrapper/
├── Package.swift                  // Swift Package Manager definition
├── scripts/
│   └── build_app.sh               // App bundle compilation & ad-hoc code signer
├── Support/
│   └── Info.plist                 // Application metadata & graphics configs
└── Sources/
    └── FlixWrapper/
        ├── main.swift             // Application entry point
        ├── App/
        │   ├── AppDelegate.swift       // App lifecycle & native menu bar
        │   └── WindowController.swift  // Borderless dark window & floating state
        ├── Web/
        │   ├── NetflixWebView.swift    // WebKit engine with FairPlay & UA profile
        │   └── UserScripts.swift       // JS bridge, auto-skip intro observer, PiP
        ├── Media/
        │   └── MediaKeyManager.swift   // MPRemoteCommandCenter & Now Playing info
        └── Support/
            └── AppPreferences.swift    // Persistent UserDefaults settings
```

---

## ⚖️ Legal Disclaimer

* **FlixWrapper** is an independent, open-source project and is **not** affiliated with, endorsed by, sponsored by, or associated with Netflix, Inc.
* "Netflix" and related trademarks, logos, and brand assets are the property of Netflix, Inc.
* This project is a specialized web browser client utilizing Apple's official `WebKit` framework. It does not circumvent digital rights management (DRM), decrypt protected content, or distribute copyrighted video or audio. A valid Netflix subscription is required to access content.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
