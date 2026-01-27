//
//  DashboardView.swift
//  BulletJournal
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var presenter: DashboardPresenter
    @State private var navigationPath = NavigationPath()

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let interactor = DashboardInteractor(modelContext: modelContext)
        _presenter = StateObject(wrappedValue: DashboardPresenter(interactor: interactor))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("dashboard.title")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColors.primaryText)

                    // Total Focus Time Section
                    sectionLabel("dashboard.totalFocusTime")
                    TotalFocusTimeCard(viewModel: presenter.totalFocusTimeViewModel)

                    // Weekly Chart Section
                    sectionLabel("dashboard.focusTrend")
                    WeeklyChartCard(viewModel: presenter.weeklyChartViewModel)

                    // Daily Records Section
                    sectionLabel("dashboard.dailyRecords")
                    if presenter.dailyRecordViewModels.isEmpty {
                        emptyRecordsCard
                    } else {
                        ForEach(presenter.dailyRecordViewModels) { record in
                            DailyRecordRow(viewModel: record) {
                                navigationPath.append(record.date)
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .background(AppColors.background)
            .navigationDestination(for: Date.self) { date in
                DailyRecordDetailView(date: date, modelContext: modelContext)
            }
            .onAppear {
                presenter.onAppear()
            }
        }
    }

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AppColors.primaryText)
    }

    private var emptyRecordsCard: some View {
        Text("dashboard.noData")
            .font(.system(size: 14))
            .foregroundStyle(AppColors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusTask.self, FocusSession.self, configurations: config)

    // Create sample data
    let calendar = Calendar.current
    let now = Date()

    // Create tasks and sessions for the past week
    for dayOffset in 0..<7 {
        guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayDate)!
        let endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dayDate)!

        let task = FocusTask(
            title: "Work Day \(dayOffset + 1)",
            startTime: startTime,
            endTime: endTime
        )
        container.mainContext.insert(task)

        // Add a completed session
        let session = FocusSession(
            startedAt: startTime,
            endedAt: calendar.date(byAdding: .hour, value: 2, to: startTime),
            elapsedSeconds: 7200 - (dayOffset * 600), // Varying times
            status: .completed
        )
        task.focusSessions.append(session)
        container.mainContext.insert(session)
    }

    return DashboardView(modelContext: container.mainContext)
}
