//
//  ServiceContainer.swift
//  BulletJournal
//

import Foundation

@MainActor
final class ServiceContainer {
    /// Singleton instance. Uses `nonisolated(unsafe)` because it's initialized once at app launch
    /// and only read thereafter, making it safe to access from default parameter contexts.
    nonisolated(unsafe) static let shared = ServiceContainer()

    let timerService: TimerServiceProtocol
    let ambientSoundService: AmbientSoundServiceProtocol
    let nowPlayingService: NowPlayingServiceProtocol

    private init() {
        self.timerService = TimerService()
        self.ambientSoundService = AmbientSoundService()
        self.nowPlayingService = NowPlayingService()
    }

    // For testing
    init(
        timerService: TimerServiceProtocol,
        ambientSoundService: AmbientSoundServiceProtocol,
        nowPlayingService: NowPlayingServiceProtocol
    ) {
        self.timerService = timerService
        self.ambientSoundService = ambientSoundService
        self.nowPlayingService = nowPlayingService
    }
}
