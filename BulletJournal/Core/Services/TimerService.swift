//
//  TimerService.swift
//  BulletJournal
//

import Foundation
import Combine
import UIKit

final class TimerService: TimerServiceProtocol {
    private(set) var state: TimerState = .idle
    private(set) var elapsedSeconds: Int = 0

    private var timer: Timer?
    private var startedAt: Date?
    private var accumulatedSeconds: Int = 0
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private let stateSubject = CurrentValueSubject<TimerState, Never>(.idle)
    private let tickSubject = PassthroughSubject<Int, Never>()

    var statePublisher: AnyPublisher<TimerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var tickPublisher: AnyPublisher<Int, Never> {
        tickSubject.eraseToAnyPublisher()
    }

    init() {
        setupNotifications()
    }

    deinit {
        timer?.invalidate()
        removeNotifications()
    }

    func start() {
        guard state == .idle else { return }

        state = .running
        stateSubject.send(state)
        startedAt = Date()
        accumulatedSeconds = 0
        elapsedSeconds = 0

        startTimer()
        beginBackgroundTask()
    }

    func pause() {
        guard state == .running else { return }

        updateElapsedTime()
        accumulatedSeconds = elapsedSeconds
        startedAt = nil

        timer?.invalidate()
        timer = nil

        state = .paused
        stateSubject.send(state)
    }

    func resume() {
        guard state == .paused else { return }

        state = .running
        stateSubject.send(state)
        startedAt = Date()

        startTimer()
    }

    func stop() -> Int {
        updateElapsedTime()
        let totalSeconds = elapsedSeconds

        timer?.invalidate()
        timer = nil
        startedAt = nil
        accumulatedSeconds = 0
        elapsedSeconds = 0

        state = .idle
        stateSubject.send(state)

        endBackgroundTask()

        return totalSeconds
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        startedAt = nil
        accumulatedSeconds = 0
        elapsedSeconds = 0

        state = .idle
        stateSubject.send(state)
        tickSubject.send(0)

        endBackgroundTask()
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(newTimer, forMode: .common)
        timer = newTimer
    }

    private func tick() {
        updateElapsedTime()
        tickSubject.send(elapsedSeconds)
    }

    private func updateElapsedTime() {
        guard let startedAt else {
            elapsedSeconds = accumulatedSeconds
            return
        }
        let currentInterval = Int(Date().timeIntervalSince(startedAt))
        elapsedSeconds = accumulatedSeconds + currentInterval
    }

    // MARK: - Background Task Handling

    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    // MARK: - App Lifecycle Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appDidEnterBackground() {
        guard state == .running else { return }
        timer?.invalidate()
        timer = nil
    }

    @objc private func appWillEnterForeground() {
        guard state == .running else { return }
        updateElapsedTime()
        tickSubject.send(elapsedSeconds)
        startTimer()
    }
}
