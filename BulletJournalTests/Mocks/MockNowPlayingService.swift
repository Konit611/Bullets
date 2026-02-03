//
//  MockNowPlayingService.swift
//  BulletJournalTests
//

import Foundation
@testable import BulletJournal

@MainActor
final class MockNowPlayingService: NowPlayingServiceProtocol {
    // MARK: - Call Tracking

    private(set) var setupRemoteCommandsCallCount = 0
    private(set) var updateNowPlayingInfoCallCount = 0
    private(set) var clearNowPlayingInfoCallCount = 0

    // MARK: - Last Call Parameters

    private(set) var lastTaskTitle: String?
    private(set) var lastSoundName: String?
    private(set) var lastElapsedSeconds: Int?
    private(set) var lastDurationSeconds: Int?
    private(set) var lastIsPlaying: Bool?

    // MARK: - Stored Callbacks

    private(set) var onPlayCallback: (() -> Void)?
    private(set) var onPauseCallback: (() -> Void)?

    // MARK: - NowPlayingServiceProtocol

    func setupRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void
    ) {
        setupRemoteCommandsCallCount += 1
        onPlayCallback = onPlay
        onPauseCallback = onPause
    }

    func updateNowPlayingInfo(
        taskTitle: String,
        soundName: String,
        elapsedSeconds: Int,
        durationSeconds: Int,
        isPlaying: Bool
    ) {
        updateNowPlayingInfoCallCount += 1
        lastTaskTitle = taskTitle
        lastSoundName = soundName
        lastElapsedSeconds = elapsedSeconds
        lastDurationSeconds = durationSeconds
        lastIsPlaying = isPlaying
    }

    func clearNowPlayingInfo() {
        clearNowPlayingInfoCallCount += 1
        lastTaskTitle = nil
        lastSoundName = nil
        lastElapsedSeconds = nil
        lastDurationSeconds = nil
        lastIsPlaying = nil
    }

    // MARK: - Test Helpers

    func simulateRemotePlay() {
        onPlayCallback?()
    }

    func simulateRemotePause() {
        onPauseCallback?()
    }

    func reset() {
        setupRemoteCommandsCallCount = 0
        updateNowPlayingInfoCallCount = 0
        clearNowPlayingInfoCallCount = 0
        lastTaskTitle = nil
        lastSoundName = nil
        lastElapsedSeconds = nil
        lastDurationSeconds = nil
        lastIsPlaying = nil
        onPlayCallback = nil
        onPauseCallback = nil
    }
}
