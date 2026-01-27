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
    @Published var showFocusView: Bool = false
    @Published var showScreenTimePermissionAlert: Bool = false

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

    private func startTimer() {
        interactor.handleTimerAction(.start)
        showFocusView = true
    }

    func pauseTimer() {
        interactor.handleTimerAction(.pause)
        // showFocusView 유지 - 집중화면에서 pause/resume
    }

    func resumeTimer() {
        // 홈 화면에서 호출 시 - 집중화면으로 이동
        interactor.handleTimerAction(.resume)
        showFocusView = true
    }

    func resumeTimerInFocus() {
        // 집중화면에서 호출 시 - 화면 유지
        interactor.handleTimerAction(.resume)
    }

    func stopTimer() {
        interactor.handleTimerAction(.stop)
        showFocusView = false
    }

    func selectSound(_ sound: AmbientSound) {
        interactor.selectSound(sound)
    }

    func clearError() {
        error = nil
    }

    func requestStartTimer() {
        Task {
            await requestStartTimerAsync()
        }
    }

    private func requestStartTimerAsync() async {
        // 1. Screen Time 권한 확인
        switch interactor.screenTimeAuthorizationStatus {
        case .notDetermined:
            let granted = await interactor.requestScreenTimeAuthorization()
            if !granted {
                showScreenTimePermissionAlert = true
                return
            }
        case .denied:
            showScreenTimePermissionAlert = true
            return
        case .approved:
            break
        }

        // 2. 수면 품질 프롬프트 확인
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
        // Note: All publishers are from @MainActor services, so receive(on:) is not needed

        // Bind task loaded
        interactor.taskLoadedPublisher
            .sink { [weak self] response in
                self?.presentCurrentTask(response)
            }
            .store(in: &cancellables)

        // Bind errors
        interactor.errorPublisher
            .sink { [weak self] appError in
                self?.error = appError
            }
            .store(in: &cancellables)

        // Bind timer tick
        interactor.timerTickPublisher
            .sink { [weak self] elapsedSeconds in
                self?.handleTimerTick(elapsedSeconds: elapsedSeconds)
            }
            .store(in: &cancellables)

        // Bind timer state
        interactor.timerStatePublisher
            .sink { [weak self] state in
                self?.handleTimerStateChange(state: state)
            }
            .store(in: &cancellables)

        // Bind sound changes
        interactor.soundPublisher
            .sink { [weak self] sound in
                self?.soundViewModel = Home.SoundViewModel(
                    selectedSound: sound,
                    displayName: sound.localizedName
                )
            }
            .store(in: &cancellables)

        // Bind sleep quality check
        interactor.sleepQualityPublisher
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
