//
//  NowPlayingService.swift
//  BulletJournal
//

import Foundation
import MediaPlayer
import UIKit

@MainActor
protocol NowPlayingServiceProtocol: AnyObject {
    func setupRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void
    )
    func updateNowPlayingInfo(
        taskTitle: String,
        soundName: String,
        elapsedSeconds: Int,
        durationSeconds: Int,
        isPlaying: Bool
    )
    func clearNowPlayingInfo()
}

@MainActor
final class NowPlayingService: NowPlayingServiceProtocol {

    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()

    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?

    // MARK: - Setup Remote Commands

    func setupRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void
    ) {
        // Remove existing targets
        removeRemoteCommandTargets()

        // Play command
        remoteCommandCenter.playCommand.isEnabled = true
        playCommandTarget = remoteCommandCenter.playCommand.addTarget { _ in
            Task { @MainActor in
                onPlay()
            }
            return .success
        }

        // Pause command
        remoteCommandCenter.pauseCommand.isEnabled = true
        pauseCommandTarget = remoteCommandCenter.pauseCommand.addTarget { _ in
            Task { @MainActor in
                onPause()
            }
            return .success
        }

        // Disable unused commands
        remoteCommandCenter.stopCommand.isEnabled = false
        remoteCommandCenter.nextTrackCommand.isEnabled = false
        remoteCommandCenter.previousTrackCommand.isEnabled = false
        remoteCommandCenter.skipForwardCommand.isEnabled = false
        remoteCommandCenter.skipBackwardCommand.isEnabled = false
        remoteCommandCenter.seekForwardCommand.isEnabled = false
        remoteCommandCenter.seekBackwardCommand.isEnabled = false
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = false
    }

    // MARK: - Update Now Playing Info

    func updateNowPlayingInfo(
        taskTitle: String,
        soundName: String,
        elapsedSeconds: Int,
        durationSeconds: Int,
        isPlaying: Bool
    ) {
        var nowPlayingInfo = [String: Any]()

        // Title: Task 이름
        nowPlayingInfo[MPMediaItemPropertyTitle] = taskTitle

        // Artist: 사운드 이름
        nowPlayingInfo[MPMediaItemPropertyArtist] = soundName

        // Duration: Task의 계획된 시간
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Double(durationSeconds)

        // Elapsed time: 집중한 시간
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(elapsedSeconds)

        // Playback rate (1.0 = playing, 0.0 = paused)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        // Artwork: 앱 로고
        if let appIcon = UIImage(named: "AppLogoWhite") {
            let artwork = MPMediaItemArtwork(boundsSize: appIcon.size) { _ in appIcon }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    // MARK: - Clear Now Playing Info

    func clearNowPlayingInfo() {
        removeRemoteCommandTargets()
        nowPlayingInfoCenter.nowPlayingInfo = nil
    }

    // MARK: - Private

    private func removeRemoteCommandTargets() {
        if let target = playCommandTarget {
            remoteCommandCenter.playCommand.removeTarget(target)
            playCommandTarget = nil
        }
        if let target = pauseCommandTarget {
            remoteCommandCenter.pauseCommand.removeTarget(target)
            pauseCommandTarget = nil
        }
    }
}
