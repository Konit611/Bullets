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
    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)

    var currentSoundPublisher: AnyPublisher<AmbientSound, Never> {
        currentSoundSubject.eraseToAnyPublisher()
    }

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        isPlayingSubject.eraseToAnyPublisher()
    }

    // Spy properties
    var playCallCount = 0
    var lastPlayedSound: AmbientSound?
    var pauseCallCount = 0
    var resumeCallCount = 0
    var stopCallCount = 0
    var setVolumeCallCount = 0
    var lastVolume: Float?

    func play(_ sound: AmbientSound) {
        playCallCount += 1
        lastPlayedSound = sound
        currentSound = sound
        isPlaying = sound != .none
        currentSoundSubject.send(sound)
        isPlayingSubject.send(isPlaying)
    }

    func pause() {
        pauseCallCount += 1
        isPlaying = false
        isPlayingSubject.send(false)
    }

    func resume() {
        resumeCallCount += 1
        guard currentSound != .none else { return }
        isPlaying = true
        isPlayingSubject.send(true)
    }

    func stop() {
        stopCallCount += 1
        currentSound = .none
        isPlaying = false
        currentSoundSubject.send(.none)
        isPlayingSubject.send(false)
    }

    func setVolume(_ volume: Float) {
        setVolumeCallCount += 1
        lastVolume = volume
    }
}
