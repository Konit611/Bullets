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
        ambientSoundService: AmbientSoundServiceProtocol
    ) {
        self.modelContext = modelContext
        self.timerService = timerService
        self.ambientSoundService = ambientSoundService
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
            errorSubject.send(.dataNotFound)
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

    // MARK: - Private Timer Methods

    private func startTimer() {
        guard let task = currentTask else {
            errorSubject.send(.dataNotFound)
            return
        }

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

        saveContext()
    }

    private func resumeTimer() {
        guard let session = currentSession else {
            errorSubject.send(.timerNotRunning)
            return
        }

        timerService.resume()
        session.resume()
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
