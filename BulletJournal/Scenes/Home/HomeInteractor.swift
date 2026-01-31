//
//  HomeInteractor.swift
//  BulletJournal
//

import Foundation
import Combine
import SwiftData
import WidgetKit

@MainActor
protocol HomeInteractorProtocol: AnyObject {
    var currentTask: FocusTask? { get }
    var currentSession: FocusSession? { get }
    var taskLoadedPublisher: AnyPublisher<Home.LoadCurrentTask.Response, Never> { get }
    var errorPublisher: AnyPublisher<AppError, Never> { get }
    var timerTickPublisher: AnyPublisher<Int, Never> { get }
    var timerStatePublisher: AnyPublisher<TimerState, Never> { get }
    var soundPublisher: AnyPublisher<AmbientSound, Never> { get }
    var soundIsPlayingPublisher: AnyPublisher<Bool, Never> { get }
    var sleepQualityPublisher: AnyPublisher<Home.SleepQuality.Response, Never> { get }
    var hasAnyTasksPublisher: AnyPublisher<Bool, Never> { get }
    var currentElapsedSeconds: Int { get }

    func loadCurrentTask()
    func handleTimerAction(_ action: Home.TimerAction.ActionType)
    func selectSound(_ sound: AmbientSound)
    func toggleSound()
    func switchTask(to newTask: FocusTask)
    func checkNeedsSleepQualityPrompt()
    func saveSleepQuality(_ emoji: String)
}

@MainActor
final class HomeInteractor: HomeInteractorProtocol {
    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let timerService: TimerServiceProtocol
    private let ambientSoundService: AmbientSoundServiceProtocol

    // MARK: - State

    private(set) var currentTask: FocusTask?
    private(set) var currentSession: FocusSession?
    private var selectedSound: AmbientSound = .none

    // MARK: - Publishers

    private let taskLoadedSubject = PassthroughSubject<Home.LoadCurrentTask.Response, Never>()
    private let errorSubject = PassthroughSubject<AppError, Never>()
    private let sleepQualitySubject = PassthroughSubject<Home.SleepQuality.Response, Never>()
    private let hasAnyTasksSubject = PassthroughSubject<Bool, Never>()
    private let selectedSoundSubject = CurrentValueSubject<AmbientSound, Never>(.none)

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
        selectedSoundSubject.eraseToAnyPublisher()
    }

    var soundIsPlayingPublisher: AnyPublisher<Bool, Never> {
        ambientSoundService.isPlayingPublisher
    }

    var sleepQualityPublisher: AnyPublisher<Home.SleepQuality.Response, Never> {
        sleepQualitySubject.eraseToAnyPublisher()
    }

    var hasAnyTasksPublisher: AnyPublisher<Bool, Never> {
        hasAnyTasksSubject.eraseToAnyPublisher()
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
            let newTask = tasks.first

            // Task 전환 감지: 다른 Task로 바뀌면 타이머 리셋
            if let newTask, let oldTask = currentTask, newTask.id != oldTask.id {
                if timerService.state != .idle {
                    _ = timerService.stop()
                    currentSession = nil
                }
            }

            currentTask = newTask
            let response = Home.LoadCurrentTask.Response(task: currentTask)
            taskLoadedSubject.send(response)

            var allDescriptor = FetchDescriptor<FocusTask>()
            allDescriptor.fetchLimit = 1
            let hasAnyTasks = try modelContext.fetch(allDescriptor).isEmpty == false
            hasAnyTasksSubject.send(hasAnyTasks)
        } catch {
            currentTask = nil
            hasAnyTasksSubject.send(false)
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
        selectedSound = sound
        selectedSoundSubject.send(sound)
        // 타이머 실행 중이면 즉시 전환, 아니면 선택만 저장
        if timerService.state != .idle {
            ambientSoundService.play(sound)
        }
    }

    func toggleSound() {
        if ambientSoundService.isPlaying {
            ambientSoundService.pause()
        } else {
            ambientSoundService.resume()
        }
    }

    func switchTask(to newTask: FocusTask) {
        if timerService.state != .idle {
            stopTimer()
        }
        currentTask = newTask
        let response = Home.LoadCurrentTask.Response(task: newTask)
        taskLoadedSubject.send(response)
        hasAnyTasksSubject.send(true)
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
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            errorSubject.send(.fetchFailed(error.localizedDescription))
            return nil
        }
    }

    // MARK: - Private Timer Methods

    private func startTimer() {
        guard let task = currentTask else {
            errorSubject.send(.dataNotFound)
            return
        }

        // 이전 세션들의 누적 시간 계산
        let previousElapsed = task.focusSessions
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.elapsedSeconds }

        let session = FocusSession(startedAt: Date())
        currentSession = session
        task.focusSessions.append(session)
        modelContext.insert(session)

        saveContext()

        // 누적 시간부터 타이머 시작
        timerService.start(from: previousElapsed)

        // 선택된 사운드 재생
        if selectedSound != .none {
            ambientSoundService.play(selectedSound)
        }

        reloadWidgetTimelines()
    }

    private func pauseTimer() {
        guard let task = currentTask, let session = currentSession else {
            errorSubject.send(.timerNotRunning)
            return
        }

        timerService.pause()

        // 이 세션의 시간만 저장 (총 시간 - 이전 세션들 누적)
        let previousElapsed = calculatePreviousElapsed(for: task, excluding: session)
        session.elapsedSeconds = timerService.elapsedSeconds - previousElapsed
        session.pause()

        saveContext()
        reloadWidgetTimelines()
    }

    private func resumeTimer() {
        guard let session = currentSession else {
            errorSubject.send(.timerNotRunning)
            return
        }

        timerService.resume()
        session.resume()
        saveContext()
        reloadWidgetTimelines()
    }

    private func stopTimer() {
        guard let task = currentTask, let session = currentSession else {
            errorSubject.send(.timerNotRunning)
            return
        }

        let totalSeconds = timerService.stop()

        // 이 세션의 시간만 저장 (총 시간 - 이전 세션들 누적)
        let previousElapsed = calculatePreviousElapsed(for: task, excluding: session)
        session.elapsedSeconds = totalSeconds - previousElapsed
        session.complete()
        currentSession = nil

        // 세션 종료 시 사운드도 정지
        ambientSoundService.stop()

        saveContext()
        reloadWidgetTimelines()
    }

    private func calculatePreviousElapsed(for task: FocusTask, excluding currentSession: FocusSession) -> Int {
        task.focusSessions
            .filter { $0.status == .completed && $0.id != currentSession.id }
            .reduce(0) { $0 + $1.elapsedSeconds }
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            errorSubject.send(.saveFailed(error.localizedDescription))
        }
    }

    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
