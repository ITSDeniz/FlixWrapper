import Foundation

final class AppPreferences {
    static let shared = AppPreferences()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let alwaysOnTop = "alwaysOnTop"
        static let autoSkipIntro = "autoSkipIntro"
        static let autoNextEpisode = "autoNextEpisode"
    }
    
    var alwaysOnTop: Bool {
        get { defaults.bool(forKey: Keys.alwaysOnTop) }
        set { defaults.set(newValue, forKey: Keys.alwaysOnTop) }
    }
    
    var autoSkipIntro: Bool {
        get {
            if defaults.object(forKey: Keys.autoSkipIntro) == nil {
                return true // default to true
            }
            return defaults.bool(forKey: Keys.autoSkipIntro)
        }
        set { defaults.set(newValue, forKey: Keys.autoSkipIntro) }
    }
    
    var autoNextEpisode: Bool {
        get {
            if defaults.object(forKey: Keys.autoNextEpisode) == nil {
                return true // default to true
            }
            return defaults.bool(forKey: Keys.autoNextEpisode)
        }
        set { defaults.set(newValue, forKey: Keys.autoNextEpisode) }
    }
    
    /// Modern Safari macOS User-Agent.
    /// This string guarantees Netflix's server serves FairPlay DRM 4K/HDR10/Dolby Vision video
    /// and multi-channel Spatial Audio (Dolby Atmos / 5.1).
    static let safariUserAgent: String = {
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
    }()
    
    static let netflixURL = URL(string: "https://www.netflix.com")!
}
