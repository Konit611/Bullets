//
//  MockAmbientSoundService.swift
//  BulletJournalTests
//

import Foundation
import Combine
@testable import BulletJournal

final class MockAmbientSoundService: AmbientSoundServiceProtocol {
    private(set) var currentSound: AmbientSound = .none
    private(set) var isPlaying: Bool = false

    private let currentSoundSubject = CurrentValueSubject<AmbientSound, Never>(.none)

    var currentSoundPublisher: AnyPublisher<AmbientSound, Never> {
        currentSoundSubject.eraseToAnyPublisher()
    }

    // Spy properties
    var playCallCount = 0
    var lastPlayedSound: AmbientSound?
    var stopCallCount = 0
    var setVolumeCallCount = 0
    var lastVolume: Float?

    func play(_ sound: AmbientSound) {
        playCallCount += 1
        lastPlayedSound = sound
        currentSound = sound
        isPlaying = sound != .none
        currentSoundSubject.send(sound)
    }

    func stop() {
        stopCallCount += 1
        currentSound = .none
        isPlaying = false
        currentSoundSubject.send(.none)
    }

    func setVolume(_ volume: Float) {
        setVolumeCallCount += 1
        lastVolume = volume
    }
}
