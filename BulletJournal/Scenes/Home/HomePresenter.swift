//
//  HomePresenter.swift
//  BulletJournal
//

import Foundation
import Combine
import SwiftData

@MainActor
final class HomePresenter: ObservableObject {
    // MARK: - Published Properties (ViewModels)

    @Published private(set) var taskViewModel: Home.TaskCardViewModel = .empty
    @Published private(set) var timerViewModel: Home.TimerViewModel = .initial
    @Published private(set) var soundViewModel: Home.SoundViewModel = .initial
    @Published private(set) var hasCurrentTask: Bool = false
    @Published private(set) var error: AppError?
    @Published var showSleepQualityPrompt: Bool = false

    private var needsSleepQualityPrompt: Bool = false

    // MARK: - Dependencies

    private let interactor: HomeInteractor

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(interactor: HomeInteractor) {
        self.interactor = interactor
        bindInteractor()
    }

    // MARK: - View Lifecycle

    func onAppear() {
        interactor.loadCurrentTask()
        interactor.checkNeedsSleepQualityPrompt()
    }

    // MARK: - User Actions

    func startTimer() {
        interactor.handleTimerAction(.start)
    }

    func pauseTimer() {
        interactor.handleTimerAction(.pause)
    }

    func resumeTimer() {
        interactor.handleTimerAction(.resume)
    }

    func stopTimer() {
        interactor.handleTimerAction(.stop)
    }

    func selectSound(_ sound: AmbientSound) {
        interactor.selectSound(sound)
    }

    func clearError() {
        error = nil
    }

    func requestStartTimer() {
        if needsSleepQualityPrompt {
            showSleepQualityPrompt = true
        } else {
            startTimer()
        }
    }

    func selectSleepQuality(_ emoji: String) {
        interactor.saveSleepQuality(emoji)
        needsSleepQualityPrompt = false
        startTimer()
    }

    // MARK: - Private Methods

    private func bindInteractor() {
        // Bind task loaded
        interactor.taskLoadedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.presentCurrentTask(response)
            }
            .store(in: &cancellables)

        // Bind errors
        interactor.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appError in
                self?.error = appError
            }
            .store(in: &cancellables)

        // Bind timer tick
        interactor.timerTickPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] elapsedSeconds in
                self?.handleTimerTick(elapsedSeconds: elapsedSeconds)
            }
            .store(in: &cancellables)

        // Bind timer state
        interactor.timerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleTimerStateChange(state: state)
            }
            .store(in: &cancellables)

        // Bind sound changes
        interactor.soundPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sound in
                self?.soundViewModel = Home.SoundViewModel(
                    selectedSound: sound,
                    displayName: sound.localizedName
                )
            }
            .store(in: &cancellables)

        // Bind sleep quality check
        interactor.sleepQualityPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.needsSleepQualityPrompt = response.needsPrompt
            }
            .store(in: &cancellables)
    }

    private func presentCurrentTask(_ response: Home.LoadCurrentTask.Response) {
        guard let task = response.task else {
            hasCurrentTask = false
            taskViewModel = .empty
            return
        }

        hasCurrentTask = true
        taskViewModel = mapToTaskViewModel(task)
    }

    private func handleTimerTick(elapsedSeconds: Int) {
        guard let task = interactor.currentTask else { return }

        let progress = calculateProgress(elapsed: elapsedSeconds, task: task)

        timerViewModel = Home.TimerViewModel(
            timerDisplay: formatTime(elapsedSeconds),
            progressPercentage: progress,
            state: timerViewModel.state,
            buttonTitle: timerViewModel.buttonTitle
        )

        taskViewModel = mapToTaskViewModel(task, additionalElapsed: elapsedSeconds)
    }

    private func handleTimerStateChange(state: TimerState) {
        let elapsed = interactor.currentElapsedSeconds
        let progress = calculateProgress(elapsed: elapsed, task: interactor.currentTask)

        timerViewModel = Home.TimerViewModel(
            timerDisplay: formatTime(elapsed),
            progressPercentage: progress,
            state: state,
            buttonTitle: buttonTitle(for: state)
        )
    }

    private func mapToTaskViewModel(_ task: FocusTask, additionalElapsed: Int = 0) -> Home.TaskCardViewModel {
        let totalFocused = task.totalFocusedTime + TimeInterval(additionalElapsed)
        let progress = task.plannedDuration > 0
            ? min(totalFocused / task.plannedDuration, 1.0)
            : 0

        return Home.TaskCardViewModel(
            id: task.id,
            title: task.title,
            startTime: task.startTimeString,
            endTime: task.endTimeString,
            duration: task.durationString,
            progressPercentage: progress,
            focusedTimeDisplay: formatTime(Int(totalFocused))
        )
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func calculateProgress(elapsed: Int, task: FocusTask?) -> Double {
        guard let task, task.plannedDuration > 0 else { return 0 }

        let previousSessions = task.focusSessions
            .filter { $0.status == .completed }
            .reduce(0) { $0 + TimeInterval($1.elapsedSeconds) }
        let totalElapsed = previousSessions + TimeInterval(elapsed)

        return min(totalElapsed / task.plannedDuration, 1.0)
    }

    private func buttonTitle(for state: TimerState) -> String {
        switch state {
        case .idle:
            return String(localized: "home.timer.start")
        case .running:
            return String(localized: "home.timer.pause")
        case .paused:
            return String(localized: "home.timer.resume")
        }
    }
}
