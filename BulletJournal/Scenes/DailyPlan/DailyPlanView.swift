//
//  DailyPlanView.swift
//  BulletJournal
//

import SwiftUI
import SwiftData

struct DailyPlanView: View {
    @StateObject private var presenter: DailyPlanPresenter
    @Environment(\.dismiss) private var dismiss

    private let date: Date

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 15
        static let topPadding: CGFloat = 10
        static let bottomPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 16
    }

    // MARK: - Initialization

    init(date: Date, modelContext: ModelContext) {
        self.date = date
        let interactor = DailyPlanInteractor(modelContext: modelContext)
        _presenter = StateObject(wrappedValue: DailyPlanPresenter(interactor: interactor))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerView

            if presenter.viewModel.needsSleepRecord && presenter.isSleepCardExpanded {
                sleepInputView
            } else {
                mainContent
            }
        }
        .background(AppColors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .onAppear {
            presenter.onAppear(date: date)
        }
        .onDisappear {
            presenter.onDisappear()
        }
        .sheet(isPresented: $presenter.showTaskEditSheet) {
            if let form = presenter.editingTaskForm {
                TaskEditSheet(
                    form: Binding(
                        get: { presenter.editingTaskForm ?? DailyPlan.TaskFormData.empty(for: date) },
                        set: { presenter.editingTaskForm = $0 }
                    ),
                    isEditing: form.id != nil,
                    onSave: presenter.saveTask,
                    onDelete: form.id != nil ? { presenter.deleteTask(id: form.id!) } : nil,
                    hasConflict: { presenter.hasTimeConflict($0) }
                )
            }
        }
        .alert(
            Text("Error"),
            isPresented: .init(
                get: { presenter.error != nil },
                set: { if !$0 { presenter.clearError() } }
            )
        ) {
            Button(String(localized: "OK")) {
                presenter.clearError()
            }
        } message: {
            if let error = presenter.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Header View (Spacer for toolbar)

    private var headerView: some View {
        Color.clear
            .frame(height: 8)
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button(action: { dismiss() }) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .accessibilityLabel(Text("accessibility.back"))
    }

    // MARK: - Sleep Input View (When no sleep record)

    private var sleepInputView: some View {
        VStack(spacing: Layout.cardSpacing) {
            SleepRecordCard(
                viewModel: presenter.viewModel.sleepRecord ?? .empty,
                isExpanded: $presenter.isSleepCardExpanded,
                selectedBedTime: $presenter.selectedBedTime,
                selectedWakeTime: $presenter.selectedWakeTime,
                selectedSleepQuality: $presenter.selectedSleepQuality,
                onSave: presenter.saveSleepRecord,
                isEditable: true
            )
            .padding(.horizontal, Layout.horizontalPadding)

            // Empty timeline card placeholder
            VStack {
                Spacer()

                Text("dailyPlan.sleepRequired")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .padding(.top, Layout.topPadding)
    }

    // MARK: - Main Content (Timeline)

    private var mainContent: some View {
        VStack(spacing: Layout.cardSpacing) {
            SleepRecordCard(
                viewModel: presenter.viewModel.sleepRecord ?? .empty,
                isExpanded: $presenter.isSleepCardExpanded,
                selectedBedTime: $presenter.selectedBedTime,
                selectedWakeTime: $presenter.selectedWakeTime,
                selectedSleepQuality: $presenter.selectedSleepQuality,
                onSave: presenter.saveSleepRecord,
                isEditable: true
            )
            .padding(.horizontal, Layout.horizontalPadding)

            // Timeline Card
            ScrollView(showsIndicators: false) {
                TimelineView(
                    rows: presenter.viewModel.timelineRows,
                    taskBlocks: presenter.viewModel.taskBlocks,
                    currentTimePosition: presenter.viewModel.currentTimePosition,
                    currentTimeString: presenter.viewModel.currentTimeString,
                    wakeHour: presenter.viewModel.wakeHour,
                    bedHour: presenter.viewModel.bedHour,
                    onEmptySlotTapped: { startHour, startMinute, endHour, endMinute in
                        presenter.openNewTaskSheet(
                            startHour: startHour,
                            startMinute: startMinute,
                            endHour: endHour,
                            endMinute: endMinute
                        )
                    },
                    onTaskTapped: { taskId in
                        presenter.openEditTaskSheet(taskId: taskId)
                    }
                )
                .padding(.top, 18)
                .padding(.bottom, Layout.bottomPadding)
            }
            .frame(maxHeight: .infinity)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
        .padding(.top, Layout.topPadding)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FocusTask.self, FocusSession.self, DailyRecord.self,
        configurations: config
    )

    return NavigationStack {
        DailyPlanView(date: Date(), modelContext: container.mainContext)
    }
}
