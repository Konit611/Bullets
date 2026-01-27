//
//  ServiceContainer.swift
//  BulletJournal
//

import Foundation

final class ServiceContainer {
    static let shared = ServiceContainer()

    let timerService: TimerServiceProtocol
    let ambientSoundService: AmbientSoundServiceProtocol

    private init() {
        self.timerService = TimerService()
        self.ambientSoundService = AmbientSoundService()
    }

    // For testing
    init(
        timerService: TimerServiceProtocol,
        ambientSoundService: AmbientSoundServiceProtocol
    ) {
        self.timerService = timerService
        self.ambientSoundService = ambientSoundService
    }
}
