//
//  DailyPlanPresenter.swift
//  BulletJournal
//

import Foundation
import Combine

@MainActor
final class DailyPlanPresenter: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var viewModel: DailyPlan.ViewModel = .empty
    @Published var showTaskEditSheet: Bool = false
    @Published var isSleepCardExpanded: Bool = false
    @Published var editingTaskForm: DailyPlan.TaskFormData?
    @Published var error: DailyPlan.DailyPlanError?

    // MARK: - Sleep Time Picker State

    @Published var selectedBedTime: Date = defaultBedTime()
    @Published var selectedWakeTime: Date = defaultWakeTime()
    @Published var selectedSleepQuality: String?

    // MARK: - Dependencies

    private let interactor: DailyPlanInteractorProtocol
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current
    private var currentDate: Date = Date()
    private var currentTimeTimer: Timer?

    // MARK: - Cached DateFormatter

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd EEEE")
        return formatter
    }()

    // MARK: - Initialization

    init(interactor: DailyPlanInteractorProtocol) {
        self.interactor = interactor
        bindInteractor()
    }

    deinit {
        currentTimeTimer?.invalidate()
    }

    // MARK: - View Lifecycle

    func onAppear(date: Date) {
        currentDate = date
        interactor.loadDailyPlan(for: date)
        startCurrentTimeTimer()
    }

    func onDisappear() {
        stopCurrentTimeTimer()
    }

    // MARK: - Public Methods

    func saveSleepRecord() {
        interactor.saveSleepRecord(
            bedTime: selectedBedTime,
            wakeTime: selectedWakeTime,
            sleepQuality: selectedSleepQuality,
            for: currentDate
        )
        isSleepCardExpanded = false
    }

    func openNewTaskSheet(
        startHour: Int? = nil,
        startMinute: Int = 0,
        endHour: Int? = nil,
        endMinute: Int = 0
    ) {
        var form = DailyPlan.TaskFormData.empty(for: currentDate)

        if let startHour = startHour {
            if let startTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: currentDate) {
                form.startTime = startTime

                // Use provided end time or default to 1 hour after start
                if let endHour = endHour {
                    if let endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: currentDate) {
                        form.endTime = endTime
                    }
                } else if let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) {
                    form.endTime = endTime
                }
            }
        }

        editingTaskForm = form
        showTaskEditSheet = true
    }

    func openEditTaskSheet(taskId: UUID) {
        guard viewModel.taskBlocks.contains(where: { $0.id == taskId }) else {
            return
        }

        // Find the original task data to get actual dates
        let tasks = getCurrentTasks()
        guard let taskData = tasks.first(where: { $0.id == taskId }) else {
            return
        }

        editingTaskForm = DailyPlan.TaskFormData(
            id: taskData.id,
            title: taskData.title,
            startTime: taskData.startTime,
            endTime: taskData.endTime
        )
        showTaskEditSheet = true
    }

    func saveTask() {
        guard let form = editingTaskForm else { return }
        interactor.saveTask(form, for: currentDate)
        showTaskEditSheet = false
        editingTaskForm = nil
    }

    func deleteTask(id: UUID) {
        interactor.deleteTask(id: id)
    }

    func toggleHoliday() {
        interactor.toggleHoliday(for: currentDate)
    }

    func clearError() {
        error = nil
    }

    func hasTimeConflict(_ form: DailyPlan.TaskFormData) -> Bool {
        interactor.hasTimeConflict(form, on: currentDate)
    }

    // MARK: - Private Methods

    private func bindInteractor() {
        interactor.dailyPlanLoadedPublisher
            .sink { [weak self] response in
                self?.presentDailyPlan(response)
            }
            .store(in: &cancellables)

        interactor.errorPublisher
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)

        interactor.taskSavedPublisher
            .sink { [weak self] in
                self?.showTaskEditSheet = false
                self?.editingTaskForm = nil
            }
            .store(in: &cancellables)
    }

    private func presentDailyPlan(_ response: DailyPlan.LoadDailyPlan.Response) {
        let dateString = Self.dateFormatter.string(from: response.date)

        let sleepRecordViewModel: DailyPlan.SleepRecordViewModel?
        if let sleep = response.sleepRecord {
            sleepRecordViewModel = DailyPlan.SleepRecordViewModel(
                bedTimeString: sleep.bedTime.map { Self.timeFormatter.string(from: $0) } ?? "--:--",
                wakeTimeString: sleep.wakeTime.map { Self.timeFormatter.string(from: $0) } ?? "--:--",
                sleepQualityEmoji: sleep.sleepQualityEmoji,
                bedTime: sleep.bedTime,
                wakeTime: sleep.wakeTime
            )

            // Update picker state with existing values
            if let bedTime = sleep.bedTime {
                selectedBedTime = bedTime
            }
            if let wakeTime = sleep.wakeTime {
                selectedWakeTime = wakeTime
            }
            selectedSleepQuality = sleep.sleepQualityEmoji
        } else {
            sleepRecordViewModel = nil
        }

        // Calculate wake/bed hour for timeline (holiday-aware defaults)
        let defaultWakeHour = response.isHoliday
            ? DailyPlan.Configuration.holidayDefaultWakeHour
            : DailyPlan.Configuration.defaultWakeHour
        let defaultBedHour = response.isHoliday
            ? DailyPlan.Configuration.holidayDefaultTimelineEndHour
            : DailyPlan.Configuration.defaultTimelineEndHour

        let wakeHour: Int
        let bedHour: Int

        if let wakeTime = response.sleepRecord?.wakeTime {
            wakeHour = calendar.component(.hour, from: wakeTime)
        } else {
            wakeHour = defaultWakeHour
        }

        if let bedTime = response.sleepRecord?.bedTime {
            bedHour = calendar.component(.hour, from: bedTime)
        } else {
            bedHour = defaultBedHour
        }

        // Update picker defaults based on holiday mode when no existing values
        if response.sleepRecord?.bedTime == nil {
            let defaultBedPickerHour = response.isHoliday
                ? DailyPlan.Configuration.holidayDefaultBedTimePickerHour
                : DailyPlan.Configuration.defaultBedTimePickerHour
            if let bedDate = calendar.date(bySettingHour: defaultBedPickerHour, minute: 0, second: 0, of: response.date) {
                selectedBedTime = bedDate
            }
        }
        if response.sleepRecord?.wakeTime == nil {
            if let wakeDate = calendar.date(bySettingHour: defaultWakeHour, minute: 0, second: 0, of: response.date) {
                selectedWakeTime = wakeDate
            }
        }

        let timelineRows = buildTimelineRows(wakeHour: wakeHour, bedHour: bedHour)
        let taskBlocks = buildTaskBlocks(from: response.tasks, wakeHour: wakeHour)

        // Calculate current time position (only for today, within wake-bed range)
        var currentTimePosition: CGFloat?
        var currentTimeString: String?

        if calendar.isDateInToday(response.date) {
            let now = Date()
            let nowHour = calendar.component(.hour, from: now)
            let nowMinute = calendar.component(.minute, from: now)

            if nowHour >= wakeHour && nowHour <= bedHour {
                let hourOffset = CGFloat(nowHour - wakeHour)
                let minuteOffset = CGFloat(nowMinute) / 60.0
                currentTimePosition = (hourOffset + minuteOffset) * DailyPlan.Configuration.hourHeight
                currentTimeString = Self.timeFormatter.string(from: now)
            }
        }

        // Auto-expand sleep card if no sleep record
        if response.needsSleepRecord {
            isSleepCardExpanded = true
        }

        viewModel = DailyPlan.ViewModel(
            dateString: dateString,
            sleepRecord: sleepRecordViewModel,
            needsSleepRecord: response.needsSleepRecord,
            timelineRows: timelineRows,
            taskBlocks: taskBlocks,
            currentTimePosition: currentTimePosition,
            currentTimeString: currentTimeString,
            wakeHour: wakeHour,
            bedHour: bedHour,
            isHoliday: response.isHoliday
        )

        // Store tasks for later access
        currentTasks = response.tasks
    }

    private var currentTasks: [DailyPlan.TaskData] = []

    private func getCurrentTasks() -> [DailyPlan.TaskData] {
        return currentTasks
    }

    private func buildTimelineRows(wakeHour: Int, bedHour: Int) -> [DailyPlan.TimelineRowViewModel] {
        var rows: [DailyPlan.TimelineRowViewModel] = []

        // Timeline from wake hour to bed hour (inclusive)
        for hour in wakeHour...bedHour {
            let timeLabel = String(format: "%02d:00", hour)
            let yPosition = CGFloat(hour - wakeHour) * DailyPlan.Configuration.hourHeight

            rows.append(DailyPlan.TimelineRowViewModel(
                hour: hour,
                timeLabel: timeLabel,
                yPosition: yPosition
            ))
        }

        return rows
    }

    private func buildTaskBlocks(
        from tasks: [DailyPlan.TaskData],
        wakeHour: Int
    ) -> [DailyPlan.TaskBlockViewModel] {
        let now = Date()

        return tasks.compactMap { task in
            let taskStartHour = calendar.component(.hour, from: task.startTime)
            let taskStartMinute = calendar.component(.minute, from: task.startTime)
            let taskEndHour = calendar.component(.hour, from: task.endTime)
            let taskEndMinute = calendar.component(.minute, from: task.endTime)

            // Skip tasks before wake time
            guard taskStartHour >= wakeHour else { return nil }

            let startOffset = CGFloat(taskStartHour - wakeHour) + CGFloat(taskStartMinute) / 60.0
            let endOffset = CGFloat(taskEndHour - wakeHour) + CGFloat(taskEndMinute) / 60.0

            let yPosition = startOffset * DailyPlan.Configuration.hourHeight
            let height = (endOffset - startOffset) * DailyPlan.Configuration.hourHeight

            let isCurrentTask = now >= task.startTime && now <= task.endTime

            return DailyPlan.TaskBlockViewModel(
                id: task.id,
                title: task.title,
                startTimeString: Self.timeFormatter.string(from: task.startTime),
                endTimeString: Self.timeFormatter.string(from: task.endTime),
                yPosition: yPosition,
                height: height,
                isCurrentTask: isCurrentTask,
                progressPercentage: task.progressPercentage
            )
        }
    }

    // MARK: - Default Times

    private static func defaultBedTime() -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: DailyPlan.Configuration.defaultBedTimePickerHour,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private static func defaultWakeTime() -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: DailyPlan.Configuration.defaultWakeHour,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    // MARK: - Current Time Timer

    private func startCurrentTimeTimer() {
        stopCurrentTimeTimer()

        // Only run timer for today
        guard calendar.isDateInToday(currentDate) else { return }

        // Update every 30 seconds
        currentTimeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateCurrentTimePosition()
            }
        }
    }

    private func stopCurrentTimeTimer() {
        currentTimeTimer?.invalidate()
        currentTimeTimer = nil
    }

    private func updateCurrentTimePosition() {
        guard calendar.isDateInToday(currentDate) else {
            viewModel = viewModel.withUpdatedTime(position: nil, timeString: nil)
            return
        }

        let now = Date()
        let nowHour = calendar.component(.hour, from: now)
        let nowMinute = calendar.component(.minute, from: now)

        let wakeHour = viewModel.wakeHour
        let bedHour = viewModel.bedHour

        var newPosition: CGFloat?
        var newTimeString: String?

        if nowHour >= wakeHour && nowHour <= bedHour {
            let hourOffset = CGFloat(nowHour - wakeHour)
            let minuteOffset = CGFloat(nowMinute) / 60.0
            newPosition = (hourOffset + minuteOffset) * DailyPlan.Configuration.hourHeight
            newTimeString = Self.timeFormatter.string(from: now)
        }

        viewModel = viewModel.withUpdatedTime(position: newPosition, timeString: newTimeString)
    }
}
