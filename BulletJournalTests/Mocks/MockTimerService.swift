//
//  MockTimerService.swift
//  BulletJournalTests
//

import Foundation
import Combine
@testable import BulletJournal

final class MockTimerService: TimerServiceProtocol {
    private(set) var state: TimerState = .idle
    private(set) var elapsedSeconds: Int = 0

    private let stateSubject = CurrentValueSubject<TimerState, Never>(.idle)
    private let tickSubject = PassthroughSubject<Int, Never>()

    var statePublisher: AnyPublisher<TimerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var tickPublisher: AnyPublisher<Int, Never> {
        tickSubject.eraseToAnyPublisher()
    }

    // Spy properties
    var startCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0
    var stopCallCount = 0
    var resetCallCount = 0

    func start() {
        startCallCount += 1
        state = .running
        stateSubject.send(.running)
    }

    func pause() {
        pauseCallCount += 1
        state = .paused
        stateSubject.send(.paused)
    }

    func resume() {
        resumeCallCount += 1
        state = .running
        stateSubject.send(.running)
    }

    func stop() -> Int {
        stopCallCount += 1
        let seconds = elapsedSeconds
        state = .idle
        elapsedSeconds = 0
        stateSubject.send(.idle)
        return seconds
    }

    func reset() {
        resetCallCount += 1
        state = .idle
        elapsedSeconds = 0
        stateSubject.send(.idle)
    }

    // Test helpers
    func simulateTick(_ seconds: Int) {
        elapsedSeconds = seconds
        tickSubject.send(seconds)
    }

    func setElapsedSeconds(_ seconds: Int) {
        elapsedSeconds = seconds
    }
}
