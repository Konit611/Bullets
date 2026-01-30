//
//  DailyRecordDetailView.swift
//  BulletJournal
//

import SwiftUI
import SwiftData

struct DailyRecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var presenter: DailyRecordDetailPresenter

    private let date: Date

    init(date: Date, modelContext: ModelContext) {
        self.date = date
        let interactor = DailyRecordDetailInteractor(modelContext: modelContext)
        _presenter = StateObject(wrappedValue: DailyRecordDetailPresenter(interactor: interactor))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Goal Achievement + Sleep Quality (same row, read-only)
                HStack(spacing: 12) {
                    GoalAchievementCard(viewModel: presenter.viewModel.goalAchievement)
                    SleepQualityDisplayCard(viewModel: presenter.viewModel.sleepQuality)
                }

                // Mood Selection (editable)
                MoodSelectionCard(
                    selectedEmoji: $presenter.selectedMoodEmoji,
                    onSelect: presenter.selectMood
                )

                // Reflection (editable)
                ReflectionCard(
                    viewModel: presenter.viewModel.reflection,
                    text: $presenter.reflectionText
                )

                // Save Button
                Button {
                    presenter.saveAndGoBack()
                } label: {
                    Text("dailyRecord.saveAndReturn")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.startButton)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(presenter.viewModel.dateString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .onAppear {
            presenter.onAppear(date: date)
        }
        .onChange(of: presenter.saveSuccess) { _, success in
            if success {
                dismiss()
            }
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { presenter.error != nil },
                set: { if !$0 { presenter.clearError() } }
            )
        ) {
            Button("OK") {
                presenter.clearError()
            }
        } message: {
            if let error = presenter.error {
                Text(error.localizedDescription)
            }
        }
    }

}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FocusTask.self, FocusSession.self, DailyRecord.self,
        configurations: config
    )

    // Create sample data
    let today = Calendar.current.startOfDay(for: Date())
    let dailyRecord = DailyRecord(
        date: today,
        sleepQualityEmoji: "☺️",
        moodEmoji: "😆",
        reflectionText: "Today was a great day!"
    )
    container.mainContext.insert(dailyRecord)

    return NavigationStack {
        DailyRecordDetailView(
            date: today,
            modelContext: container.mainContext
        )
    }
}
