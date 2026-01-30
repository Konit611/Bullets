//
//  DashboardPresenter.swift
//  BulletJournal
//

import Foundation
import Combine

@MainActor
final class DashboardPresenter: ObservableObject {
    // MARK: - Published Properties (ViewModels)

    @Published private(set) var totalFocusTimeViewModel: Dashboard.TotalFocusTimeViewModel = .empty
    @Published private(set) var weeklyChartViewModel: Dashboard.WeeklyChartViewModel = .empty
    @Published private(set) var dailyRecordViewModels: [Dashboard.DailyRecordViewModel] = []
    @Published var error: AppError?

    // MARK: - Dependencies

    private let interactor: DashboardInteractorProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(interactor: DashboardInteractorProtocol) {
        self.interactor = interactor
        bindInteractor()
    }

    // MARK: - View Lifecycle

    func onAppear() {
        interactor.loadStatistics()
    }

    // MARK: - Private Methods

    func clearError() {
        error = nil
    }

    private func bindInteractor() {
        interactor.statisticsLoadedPublisher
            .sink { [weak self] response in
                self?.presentStatistics(response)
            }
            .store(in: &cancellables)

        interactor.errorPublisher
            .sink { [weak self] appError in
                self?.error = appError
            }
            .store(in: &cancellables)
    }

    private func presentStatistics(_ response: Dashboard.LoadStatistics.Response) {
        totalFocusTimeViewModel = Dashboard.TotalFocusTimeViewModel(
            displayString: FocusTimeFormatter.formatTotalTime(response.totalFocusSeconds)
        )

        weeklyChartViewModel = mapWeeklyData(response.weeklyData)
        dailyRecordViewModels = mapDailyRecords(response.dailyRecords)
    }

    private func mapWeeklyData(_ data: Dashboard.WeeklyData) -> Dashboard.WeeklyChartViewModel {
        guard !data.dailyTotals.isEmpty else {
            return .empty
        }

        let maxSeconds = data.dailyTotals.map(\.totalSeconds).max() ?? 1
        let normalizedMax = max(maxSeconds, 1)

        let bars = data.dailyTotals.map { dayTotal in
            Dashboard.WeeklyChartViewModel.BarData(
                id: dayTotal.id,
                weekday: FocusTimeFormatter.weekdayAbbreviation(for: dayTotal.date),
                timeLabel: dayTotal.totalSeconds > 0
                    ? FocusTimeFormatter.formatShortTime(dayTotal.totalSeconds)
                    : "-",
                heightRatio: Double(dayTotal.totalSeconds) / Double(normalizedMax),
                seconds: dayTotal.totalSeconds
            )
        }

        return Dashboard.WeeklyChartViewModel(bars: bars)
    }

    private func mapDailyRecords(_ records: [Dashboard.DailyRecordData]) -> [Dashboard.DailyRecordViewModel] {
        records.map { record in
            let percentage = record.completionPercentage
            let percentageInt = Int(percentage * 100)

            // Use user's mood emoji if set, otherwise show default
            let emoji = record.moodEmoji ?? "➖"

            return Dashboard.DailyRecordViewModel(
                id: record.id,
                date: record.date,
                dateString: FocusTimeFormatter.formatDailyDate(record.date),
                timeString: FocusTimeFormatter.formatShortTime(record.totalFocusSeconds),
                percentageString: "\(percentageInt)%",
                emoji: emoji
            )
        }
    }
}
