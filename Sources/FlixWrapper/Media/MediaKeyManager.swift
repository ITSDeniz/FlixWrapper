import Foundation
import MediaPlayer

final class MediaKeyManager {
    static let shared = MediaKeyManager()
    
    weak var webView: NetflixWebView?
    
    private var isRegistered = false
    
    func setupMediaCommands(with webView: NetflixWebView) {
        self.webView = webView
        guard !isRegistered else { return }
        isRegistered = true
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play / Pause
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.webView?.togglePlayPause()
            return .success
        }
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.webView?.togglePlayPause()
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.webView?.togglePlayPause()
            return .success
        }
        
        // Skip Forward (10s)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.webView?.seek(by: 10)
            return .success
        }
        
        // Skip Backward (10s)
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.webView?.seek(by: -10)
            return .success
        }
        
        // Next Track (Next Episode)
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.webView?.nextEpisode()
            return .success
        }
    }
    
    func updateNowPlaying(title: String, isPaused: Bool, currentTime: Double, duration: Double) {
        var nowPlayingInfo = [String: Any]()
        
        let displayTitle = title.isEmpty ? "Netflix" : title
        nowPlayingInfo[MPMediaItemPropertyTitle] = displayTitle
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "FlixWrapper for macOS"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPaused ? 0.0 : 1.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
