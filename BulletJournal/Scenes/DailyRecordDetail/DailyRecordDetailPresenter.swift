//
//  DailyRecordDetailPresenter.swift
//  BulletJournal
//

import Foundation
import Combine

@MainActor
final class DailyRecordDetailPresenter: ObservableObject {
    // MARK: - Published Properties (ViewModels)

    @Published private(set) var viewModel: DailyRecordDetail.ViewModel = .empty
    @Published private(set) var error: AppError?
    @Published private(set) var saveSuccess: Bool = false
    @Published var selectedMoodEmoji: String?
    @Published var reflectionText: String = ""

    // MARK: - Dependencies

    private let interactor: DailyRecordDetailInteractorProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - State

    private var currentDate: Date?

    // MARK: - Initialization

    init(interactor: DailyRecordDetailInteractorProtocol) {
        self.interactor = interactor
        bindInteractor()
    }

    // MARK: - View Lifecycle

    func onAppear(date: Date) {
        currentDate = date
        saveSuccess = false  // Reset for reappear case
        interactor.loadRecord(for: date)
    }

    // MARK: - User Actions

    func selectMood(_ emoji: String) {
        if selectedMoodEmoji == emoji {
            selectedMoodEmoji = nil
        } else {
            selectedMoodEmoji = emoji
        }
    }

    func saveAndGoBack() {
        guard let date = currentDate else { return }
        let trimmedReflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        interactor.saveRecord(
            moodEmoji: selectedMoodEmoji,
            reflectionText: trimmedReflection.isEmpty ? nil : trimmedReflection,
            for: date
        )
    }

    func clearError() {
        error = nil
    }

    // MARK: - Private Methods

    private func bindInteractor() {
        interactor.recordLoadedPublisher
            .sink { [weak self] response in
                self?.presentRecord(response)
            }
            .store(in: &cancellables)

        interactor.saveResultPublisher
            .sink { [weak self] response in
                self?.saveSuccess = response.success
            }
            .store(in: &cancellables)

        interactor.errorPublisher
            .sink { [weak self] appError in
                self?.error = appError
            }
            .store(in: &cancellables)
    }

    private func presentRecord(_ response: DailyRecordDetail.LoadRecord.Response) {
        let dateString = formatDate(response.date)
        let goalAchievementVM = mapGoalAchievement(response.goalAchievement)
        let sleepQualityVM = mapSleepQuality(response.record?.sleepQualityEmoji)
        let reflectionVM = mapReflection(response.record?.reflectionText)

        // Update editable state
        selectedMoodEmoji = response.record?.moodEmoji
        reflectionText = response.record?.reflectionText ?? ""

        viewModel = DailyRecordDetail.ViewModel(
            dateString: dateString,
            goalAchievement: goalAchievementVM,
            sleepQuality: sleepQualityVM,
            reflection: reflectionVM
        )
    }

    private func formatDate(_ date: Date) -> String {
        FocusTimeFormatter.formatDailyDate(date)
    }

    private func mapGoalAchievement(
        _ data: DailyRecordDetail.GoalAchievementData
    ) -> DailyRecordDetail.GoalAchievementViewModel {
        let percentageInt = Int(data.percentage * 100)
        let focusTimeString = FocusTimeFormatter.formatShortTime(data.totalFocusSeconds)
        let plannedTimeString = data.totalPlannedSeconds > 0
            ? FocusTimeFormatter.formatShortTime(data.totalPlannedSeconds)
            : "-"

        return DailyRecordDetail.GoalAchievementViewModel(
            percentageString: "\(percentageInt)%",
            focusTimeString: focusTimeString,
            plannedTimeString: plannedTimeString
        )
    }

    private func mapSleepQuality(_ emoji: String?) -> DailyRecordDetail.SleepQualityViewModel {
        DailyRecordDetail.SleepQualityViewModel(
            emoji: emoji,
            isSet: emoji != nil
        )
    }

    private func mapReflection(_ text: String?) -> DailyRecordDetail.ReflectionViewModel {
        DailyRecordDetail.ReflectionViewModel(
            text: text ?? "",
            maxLength: DailyRecordDetail.Configuration.reflectionMaxLength,
            placeholder: String(localized: "dailyRecord.reflection.placeholder")
        )
    }
}
