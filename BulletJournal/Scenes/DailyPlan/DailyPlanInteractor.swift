//
//  DailyPlanInteractor.swift
//  BulletJournal
//

import Foundation
import Combine
import SwiftData

@MainActor
protocol DailyPlanInteractorProtocol: AnyObject {
    var dailyPlanLoadedPublisher: AnyPublisher<DailyPlan.LoadDailyPlan.Response, Never> { get }
    var taskSavedPublisher: AnyPublisher<Void, Never> { get }
    var taskDeletedPublisher: AnyPublisher<Void, Never> { get }
    var errorPublisher: AnyPublisher<DailyPlan.DailyPlanError, Never> { get }

    func loadDailyPlan(for date: Date)
    func saveSleepRecord(bedTime: Date, wakeTime: Date, sleepQuality: String?, for date: Date)
    func saveTask(_ form: DailyPlan.TaskFormData, for date: Date)
    func deleteTask(id: UUID)
    func hasTimeConflict(_ form: DailyPlan.TaskFormData, on date: Date) -> Bool
}

@MainActor
final class DailyPlanInteractor: DailyPlanInteractorProtocol {
    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let calendar: Calendar

    // MARK: - Publishers

    private let dailyPlanLoadedSubject = PassthroughSubject<DailyPlan.LoadDailyPlan.Response, Never>()
    private let taskSavedSubject = PassthroughSubject<Void, Never>()
    private let taskDeletedSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<DailyPlan.DailyPlanError, Never>()

    var dailyPlanLoadedPublisher: AnyPublisher<DailyPlan.LoadDailyPlan.Response, Never> {
        dailyPlanLoadedSubject.eraseToAnyPublisher()
    }

    var taskSavedPublisher: AnyPublisher<Void, Never> {
        taskSavedSubject.eraseToAnyPublisher()
    }

    var taskDeletedPublisher: AnyPublisher<Void, Never> {
        taskDeletedSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<DailyPlan.DailyPlanError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.calendar = Calendar.current
    }

    // MARK: - Public Methods

    func loadDailyPlan(for date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)

        // Fetch daily record for sleep times
        let dailyRecord = fetchDailyRecord(for: normalizedDate)

        // Fetch tasks for the date
        var tasks = fetchTasks(for: normalizedDate)

        // Auto-copy from yesterday if no tasks and yesterday has tasks
        if tasks.isEmpty {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: normalizedDate) ?? normalizedDate
            let yesterdayTasks = fetchTasks(for: yesterday)
            if !yesterdayTasks.isEmpty && dailyRecord?.hasSleepTimes == true {
                copyTasks(from: yesterdayTasks, to: normalizedDate)
                tasks = fetchTasks(for: normalizedDate)
            }
        }

        let sleepRecordData: DailyPlan.SleepRecordData?
        if let record = dailyRecord {
            sleepRecordData = DailyPlan.SleepRecordData(
                bedTime: record.bedTime,
                wakeTime: record.wakeTime,
                sleepQualityEmoji: record.sleepQualityEmoji
            )
        } else {
            sleepRecordData = nil
        }

        let taskDataList = tasks.map { task in
            DailyPlan.TaskData(
                id: task.id,
                title: task.title,
                startTime: task.startTime,
                endTime: task.endTime,
                isCompleted: task.isCompleted,
                totalFocusedTime: task.totalFocusedTime,
                plannedDuration: task.plannedDuration
            )
        }

        let needsSleepRecord = dailyRecord?.hasSleepTimes != true

        let response = DailyPlan.LoadDailyPlan.Response(
            date: normalizedDate,
            sleepRecord: sleepRecordData,
            tasks: taskDataList,
            needsSleepRecord: needsSleepRecord
        )

        dailyPlanLoadedSubject.send(response)
    }

    func saveSleepRecord(bedTime: Date, wakeTime: Date, sleepQuality: String?, for date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)

        let record = fetchOrCreateDailyRecord(for: normalizedDate)
        record.updateSleepTimes(bedTime: bedTime, wakeTime: wakeTime)
        if let emoji = sleepQuality {
            record.setSleepQuality(emoji)
        }

        do {
            try modelContext.save()
            loadDailyPlan(for: date)
        } catch {
            errorSubject.send(.saveFailed(error))
        }
    }

    func saveTask(_ form: DailyPlan.TaskFormData, for date: Date) {
        guard form.isValid else {
            errorSubject.send(.invalidTimeSlot)
            return
        }

        if hasTimeConflict(form, on: date) {
            errorSubject.send(.timeConflict)
            return
        }

        do {
            if let existingId = form.id {
                // Update existing task
                if let existingTask = fetchTask(by: existingId) {
                    existingTask.title = form.title
                    existingTask.startTime = form.startTime
                    existingTask.endTime = form.endTime
                }
            } else {
                // Create new task
                let newTask = FocusTask(
                    title: form.title,
                    startTime: form.startTime,
                    endTime: form.endTime
                )
                modelContext.insert(newTask)
            }

            try modelContext.save()
            taskSavedSubject.send(())
            loadDailyPlan(for: date)
        } catch {
            errorSubject.send(.saveFailed(error))
        }
    }

    func deleteTask(id: UUID) {
        guard let task = fetchTask(by: id) else { return }

        let taskDate = task.startTime

        modelContext.delete(task)

        do {
            try modelContext.save()
            taskDeletedSubject.send(())
            loadDailyPlan(for: taskDate)
        } catch {
            errorSubject.send(.saveFailed(error))
        }
    }

    func hasTimeConflict(_ form: DailyPlan.TaskFormData, on date: Date) -> Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        let existingTasks = fetchTasks(for: normalizedDate).filter { $0.id != form.id }

        for task in existingTasks {
            if form.startTime < task.endTime && form.endTime > task.startTime {
                return true
            }
        }
        return false
    }

    // MARK: - Private Methods

    private func fetchDailyRecord(for date: Date) -> DailyRecord? {
        let normalizedDate = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date == normalizedDate
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchOrCreateDailyRecord(for date: Date) -> DailyRecord {
        if let existing = fetchDailyRecord(for: date) {
            return existing
        }

        let newRecord = DailyRecord(date: date)
        modelContext.insert(newRecord)
        return newRecord
    }

    private func fetchTasks(for date: Date) -> [FocusTask] {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return []
        }

        let descriptor = FetchDescriptor<FocusTask>(
            predicate: #Predicate<FocusTask> { task in
                task.startTime >= dayStart && task.startTime < dayEnd
            },
            sortBy: [SortDescriptor(\.startTime)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchTask(by id: UUID) -> FocusTask? {
        let descriptor = FetchDescriptor<FocusTask>(
            predicate: #Predicate<FocusTask> { task in
                task.id == id
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func copyTasks(from sourceTasks: [FocusTask], to targetDate: Date) {
        let targetDayStart = calendar.startOfDay(for: targetDate)

        for sourceTask in sourceTasks {
            let startTimeComponents = calendar.dateComponents([.hour, .minute], from: sourceTask.startTime)
            let endTimeComponents = calendar.dateComponents([.hour, .minute], from: sourceTask.endTime)

            guard let newStartTime = calendar.date(
                bySettingHour: startTimeComponents.hour ?? 0,
                minute: startTimeComponents.minute ?? 0,
                second: 0,
                of: targetDayStart
            ),
            let newEndTime = calendar.date(
                bySettingHour: endTimeComponents.hour ?? 0,
                minute: endTimeComponents.minute ?? 0,
                second: 0,
                of: targetDayStart
            ) else {
                continue
            }

            let newTask = FocusTask(
                title: sourceTask.title,
                startTime: newStartTime,
                endTime: newEndTime
            )
            modelContext.insert(newTask)
        }

        try? modelContext.save()
    }
}
