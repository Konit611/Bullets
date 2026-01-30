//
//  TimerService.swift
//  BulletJournal
//

import Foundation
import Combine
import UIKit

@MainActor
final class TimerService: TimerServiceProtocol {

    // MARK: - Public State

    private(set) var state: TimerState = .idle
    private(set) var elapsedSeconds: Int = 0

    // MARK: - Private State

    private var timer: Timer?
    private var startedAt: Date?
    private var accumulatedSeconds: Int = 0

    // MARK: - Publishers

    private let stateSubject = CurrentValueSubject<TimerState, Never>(.idle)
    private let tickSubject = PassthroughSubject<Int, Never>()

    var statePublisher: AnyPublisher<TimerState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var tickPublisher: AnyPublisher<Int, Never> {
        tickSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init() {
        setupNotifications()
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func start(from initialSeconds: Int = 0) {
        guard state == .idle else { return }

        state = .running
        stateSubject.send(state)
        startedAt = Date()
        accumulatedSeconds = initialSeconds
        elapsedSeconds = initialSeconds

        // Send immediate tick so UI shows the initial time
        tickSubject.send(elapsedSeconds)

        startTimer()
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

        // Send immediate tick so UI updates without waiting 1 second
        tickSubject.send(elapsedSeconds)
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
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
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

    @objc private func appDidEnterBackground() {
        // Use assumeIsolated to avoid async Task race condition
        // NotificationCenter callbacks on main thread when observer is on main
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.handleBackgroundTransition()
        }
    }

    @objc private func appWillEnterForeground() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.handleForegroundTransition()
        }
    }

    private func handleBackgroundTransition() {
        guard state == .running else { return }
        // Timer만 정지, 상태는 유지
        // Shield가 활성화되어 있으므로 백그라운드 = 화면 잠금
        timer?.invalidate()
        timer = nil
    }

    private func handleForegroundTransition() {
        guard state == .running else { return }
        // 경과 시간 계산 후 타이머 재시작
        updateElapsedTime()
        tickSubject.send(elapsedSeconds)
        startTimer()
    }
}
