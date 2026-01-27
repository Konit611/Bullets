//
//  HomeInteractor.swift
//  BulletJournal
//

import Foundation
import Combine
import SwiftData

@MainActor
final class HomeInteractor {
    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let timerService: TimerServiceProtocol
    private let ambientSoundService: AmbientSoundServiceProtocol
    private let screenTimeService: ScreenTimeService

    // MARK: - State

    private(set) var currentTask: FocusTask?
    private(set) var currentSession: FocusSession?

    // MARK: - Publishers

    private let taskLoadedSubject = PassthroughSubject<Home.LoadCurrentTask.Response, Never>()
    private let errorSubject = PassthroughSubject<AppError, Never>()
    private let sleepQualitySubject = PassthroughSubject<Home.SleepQuality.Response, Never>()

    var taskLoadedPublisher: AnyPublisher<Home.LoadCurrentTask.Response, Never> {
        taskLoadedSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var timerTickPublisher: AnyPublisher<Int, Never> {
        timerService.tickPublisher
    }

    var timerStatePublisher: AnyPublisher<TimerState, Never> {
        timerService.statePublisher
    }

    var soundPublisher: AnyPublisher<AmbientSound, Never> {
        ambientSoundService.currentSoundPublisher
    }

    var sleepQualityPublisher: AnyPublisher<Home.SleepQuality.Response, Never> {
        sleepQualitySubject.eraseToAnyPublisher()
    }

    var currentElapsedSeconds: Int {
        timerService.elapsedSeconds
    }

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        timerService: TimerServiceProtocol,
        ambientSoundService: AmbientSoundServiceProtocol,
        screenTimeService: ScreenTimeService = .shared
    ) {
        self.modelContext = modelContext
        self.timerService = timerService
        self.ambientSoundService = ambientSoundService
        self.screenTimeService = screenTimeService
    }

    // MARK: - Use Cases

    func loadCurrentTask() {
        let now = Date()
        let descriptor = FetchDescriptor<FocusTask>(
            predicate: #Predicate<FocusTask> { task in
                task.startTime <= now && task.endTime >= now && !task.isCompleted
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            let tasks = try modelContext.fetch(descriptor)
            currentTask = tasks.first
            let response = Home.LoadCurrentTask.Response(task: currentTask)
            taskLoadedSubject.send(response)
        } catch {
            currentTask = nil
            errorSubject.send(.fetchFailed(error.localizedDescription))
        }
    }

    func handleTimerAction(_ action: Home.TimerAction.ActionType) {
        switch action {
        case .start:
            startTimer()
        case .pause:
            pauseTimer()
        case .resume:
            resumeTimer()
        case .stop:
            stopTimer()
        }
    }

    func selectSound(_ sound: AmbientSound) {
        ambientSoundService.play(sound)
    }

    func switchTask(to newTask: FocusTask) {
        if timerService.state != .idle {
            stopTimer()
        }
        currentTask = newTask
        let response = Home.LoadCurrentTask.Response(task: newTask)
        taskLoadedSubject.send(response)
    }

    func checkNeedsSleepQualityPrompt() {
        let record = fetchTodayDailyRecord()
        let needsPrompt = record?.sleepQualityEmoji == nil
        sleepQualitySubject.send(Home.SleepQuality.Response(needsPrompt: needsPrompt))
    }

    func saveSleepQuality(_ emoji: String) {
        let today = Calendar.current.startOfDay(for: Date())

        if let existingRecord = fetchTodayDailyRecord() {
            existingRecord.setSleepQuality(emoji)
        } else {
            let newRecord = DailyRecord(date: today, sleepQualityEmoji: emoji)
            modelContext.insert(newRecord)
        }
        saveContext()
    }

    private func fetchTodayDailyRecord() -> DailyRecord? {
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date == today
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Screen Time Authorization

    var screenTimeAuthorizationStatus: ScreenTimeService.AuthorizationStatus {
        screenTimeService.authorizationStatus
    }

    func requestScreenTimeAuthorization() async -> Bool {
        await screenTimeService.requestAuthorization()
    }

    // MARK: - Private Timer Methods

    private func startTimer() {
        guard let task = currentTask else {
            errorSubject.send(.dataNotFound)
            return
        }

        // Screen Time Shield 활성화
        screenTimeService.enableFocusShield()

        let session = FocusSession(startedAt: Date())
        currentSession = session
        task.focusSessions.append(session)
        modelContext.insert(session)

        saveContext()
        timerService.start()
    }

    private func pauseTimer() {
        guard let session = currentSession else {
            errorSubject.send(.timerNotRunning)
            return
        }

        timerService.pause()
        session.elapsedSeconds = timerService.elapsedSeconds
        session.pause()

        // Shield는 유지 (pause 상태에서도 다른 앱 차단)
        saveContext()
    }

    private func resumeTimer() {
        guard let session = currentSession else {
            errorSubject.send(.timerNotRunning)
            return
        }

        timerService.resume()
        session.resume()
        saveContext()
    }

    private func stopTimer() {
        guard let session = currentSession else {
            errorSubject.send(.timerNotRunning)
            return
        }

        let totalSeconds = timerService.stop()
        session.elapsedSeconds = totalSeconds
        session.complete()
        currentSession = nil

        // Screen Time Shield 해제
        screenTimeService.disableFocusShield()

        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            errorSubject.send(.saveFailed(error.localizedDescription))
        }
    }
}
