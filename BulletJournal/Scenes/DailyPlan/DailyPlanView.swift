//
//  DailyPlanView.swift
//  BulletJournal
//

import SwiftUI
import SwiftData

struct DailyPlanView: View {
    @StateObject private var presenter: DailyPlanPresenter


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
        .navigationBarTitleDisplayMode(.inline)
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
            Text("dailyPlan.toggleAlert.title"),
            isPresented: $presenter.showToggleHolidayAlert
        ) {
            Button(String(localized: "dailyPlan.toggleAlert.cancel"), role: .cancel) { }
            Button(String(localized: "dailyPlan.toggleAlert.confirm"), role: .destructive) {
                presenter.confirmToggleHoliday()
            }
        } message: {
            Text("dailyPlan.toggleAlert.message")
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

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 0) {
            Spacer()

            HStack(spacing: 0) {
                segmentButton(
                    title: String(localized: "dailyPlan.weekday"),
                    icon: "💼",
                    isSelected: !presenter.viewModel.isHoliday
                ) {
                    if presenter.viewModel.isHoliday {
                        presenter.toggleHoliday()
                    }
                }

                segmentButton(
                    title: String(localized: "dailyPlan.holiday"),
                    icon: "🏖️",
                    isSelected: presenter.viewModel.isHoliday
                ) {
                    if !presenter.viewModel.isHoliday {
                        presenter.toggleHoliday()
                    }
                }
            }
            .background(AppColors.chevronBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.top, 4)
    }

    private func segmentButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? AppColors.cardBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(isSelected ? AppColors.primaryText : AppColors.secondaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Sleep Record Card (shared)

    private var sleepRecordCard: some View {
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
    }

    // MARK: - Sleep Input View (When no sleep record)

    private var sleepInputView: some View {
        VStack(spacing: Layout.cardSpacing) {
            sleepRecordCard

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
            sleepRecordCard

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

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FocusTask.self, FocusSession.self, DailyRecord.self, PlanTemplate.self, PlanTemplateSlot.self,
        configurations: config
    )

    return NavigationStack {
        DailyPlanView(date: Date(), modelContext: container.mainContext)
    }
}

#Preview("With Tasks") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: FocusTask.self, FocusSession.self, DailyRecord.self, PlanTemplate.self, PlanTemplateSlot.self,
        configurations: config
    )

    let context = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())

    // Add sleep record
    let record = DailyRecord(date: today, bedTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: today), wakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: today))
    context.insert(record)

    // Add sample tasks
    let task1 = FocusTask(
        title: "Morning Study",
        startTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: today)!,
        endTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
    )
    let task2 = FocusTask(
        title: "Project Work",
        startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: today)!,
        endTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: today)!
    )
    context.insert(task1)
    context.insert(task2)

    return NavigationStack {
        DailyPlanView(date: Date(), modelContext: context)
    }
}
