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
    func toggleHoliday(for date: Date)
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

        // Fetch or determine holiday status
        let dailyRecord = fetchDailyRecord(for: normalizedDate)

        let isHoliday: Bool
        if let record = dailyRecord {
            isHoliday = record.isHoliday
        } else {
            // Auto-detect weekend for new records
            let weekday = calendar.component(.weekday, from: normalizedDate)
            let isWeekend = (weekday == 1 || weekday == 7) // Sun=1, Sat=7
            isHoliday = isWeekend
        }

        // Fetch tasks for the date
        let tasks = fetchTasks(for: normalizedDate)

        // Note: Template auto-copy is handled in saveSleepRecord, not here

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
                isFocusTask: task.isFocusTask,
                totalFocusedTime: task.totalFocusedTime,
                plannedDuration: task.plannedDuration
            )
        }

        let needsSleepRecord = dailyRecord?.hasSleepTimes != true

        let response = DailyPlan.LoadDailyPlan.Response(
            date: normalizedDate,
            sleepRecord: sleepRecordData,
            tasks: taskDataList,
            needsSleepRecord: needsSleepRecord,
            isHoliday: isHoliday
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

            // Auto-copy from template if no tasks exist yet
            let tasks = fetchTasks(for: normalizedDate)
            if tasks.isEmpty {
                if let template = fetchTemplate(isHoliday: record.isHoliday) {
                    copyTasksFromTemplate(template, to: normalizedDate)
                }
            }

            loadDailyPlan(for: date)
        } catch {
            modelContext.rollback()
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
                    existingTask.isFocusTask = form.isFocusTask
                }
            } else {
                // Create new task
                let newTask = FocusTask(
                    title: form.title,
                    startTime: form.startTime,
                    endTime: form.endTime,
                    isFocusTask: form.isFocusTask
                )
                modelContext.insert(newTask)
            }

            try modelContext.save()
            updateTemplate(for: date)
            taskSavedSubject.send(())
            loadDailyPlan(for: date)
        } catch {
            modelContext.rollback()
            errorSubject.send(.saveFailed(error))
        }
    }

    func deleteTask(id: UUID) {
        guard let task = fetchTask(by: id) else {
            errorSubject.send(.taskNotFound)
            return
        }

        let taskDate = task.startTime

        modelContext.delete(task)

        do {
            try modelContext.save()
            updateTemplate(for: taskDate)
            taskDeletedSubject.send(())
            loadDailyPlan(for: taskDate)
        } catch {
            modelContext.rollback()
            errorSubject.send(.saveFailed(error))
        }
    }

    func toggleHoliday(for date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)

        // 1. Determine current mode
        let currentRecord = fetchDailyRecord(for: normalizedDate)
        let currentIsHoliday: Bool
        if let record = currentRecord {
            currentIsHoliday = record.isHoliday
        } else {
            let weekday = calendar.component(.weekday, from: normalizedDate)
            currentIsHoliday = (weekday == 1 || weekday == 7)
        }
        let newIsHoliday = !currentIsHoliday

        // 2. Save current tasks to existing mode template
        updateTemplate(for: normalizedDate)

        // 3. Delete all tasks for this day (FocusSessions cascade-deleted)
        let existingTasks = fetchTasks(for: normalizedDate)
        for task in existingTasks {
            modelContext.delete(task)
        }

        // 4. Update existing record (preserve mood, reflection, sleepQuality) or create new
        let record = fetchOrCreateDailyRecord(for: normalizedDate)
        record.isHoliday = newIsHoliday
        record.updateSleepTimes(bedTime: nil, wakeTime: nil)
        record.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorSubject.send(.saveFailed(error))
            return
        }

        // 6. Copy tasks from new mode template (if exists)
        if let template = fetchTemplate(isHoliday: newIsHoliday) {
            copyTasksFromTemplate(template, to: normalizedDate)
        }

        // 7. Reload — needsSleepRecord will be true since DailyRecord has no sleep times
        loadDailyPlan(for: date)
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
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            errorSubject.send(.fetchFailed(error))
            return nil
        }
    }

    private func fetchOrCreateDailyRecord(for date: Date) -> DailyRecord {
        if let existing = fetchDailyRecord(for: date) {
            return existing
        }

        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = (weekday == 1 || weekday == 7)
        let newRecord = DailyRecord(date: date, isHoliday: isWeekend)
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

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorSubject.send(.fetchFailed(error))
            return []
        }
    }

    private func fetchTask(by id: UUID) -> FocusTask? {
        let descriptor = FetchDescriptor<FocusTask>(
            predicate: #Predicate<FocusTask> { task in
                task.id == id
            }
        )
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            errorSubject.send(.fetchFailed(error))
            return nil
        }
    }

    private func fetchTemplate(isHoliday: Bool) -> PlanTemplate? {
        let descriptor = FetchDescriptor<PlanTemplate>()
        do {
            let templates = try modelContext.fetch(descriptor)
            return templates.first { $0.isHoliday == isHoliday }
        } catch {
            errorSubject.send(.fetchFailed(error))
            return nil
        }
    }

    private func copyTasksFromTemplate(_ template: PlanTemplate, to targetDate: Date) {
        let targetDayStart = calendar.startOfDay(for: targetDate)
        let sortedSlots = template.timeSlots.sorted { $0.sortOrder < $1.sortOrder }

        for slot in sortedSlots {
            guard let newStartTime = calendar.date(
                bySettingHour: slot.startHour,
                minute: slot.startMinute,
                second: 0,
                of: targetDayStart
            ),
            let newEndTime = calendar.date(
                bySettingHour: slot.endHour,
                minute: slot.endMinute,
                second: 0,
                of: targetDayStart
            ) else {
                continue
            }

            let newTask = FocusTask(
                title: slot.title,
                startTime: newStartTime,
                endTime: newEndTime,
                isFocusTask: slot.isFocusTask
            )
            modelContext.insert(newTask)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorSubject.send(.saveFailed(error))
        }
    }

    private func updateTemplate(for date: Date) {
        let normalizedDate = calendar.startOfDay(for: date)

        // Determine current mode for this date
        let dailyRecord = fetchDailyRecord(for: normalizedDate)
        let isHoliday: Bool
        if let record = dailyRecord {
            isHoliday = record.isHoliday
        } else {
            let weekday = calendar.component(.weekday, from: normalizedDate)
            isHoliday = (weekday == 1 || weekday == 7)
        }

        let tasks = fetchTasks(for: normalizedDate)

        // Fetch or create template
        let template: PlanTemplate
        if let existing = fetchTemplate(isHoliday: isHoliday) {
            // Remove old slots
            for slot in existing.timeSlots {
                modelContext.delete(slot)
            }
            existing.timeSlots = []
            existing.updatedAt = Date()
            template = existing
        } else {
            template = PlanTemplate(isHoliday: isHoliday)
            modelContext.insert(template)
        }

        // Create new slots from current tasks
        for (index, task) in tasks.enumerated() {
            let startComponents = calendar.dateComponents([.hour, .minute], from: task.startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: task.endTime)

            let slot = PlanTemplateSlot(
                title: task.title,
                startHour: startComponents.hour ?? 0,
                startMinute: startComponents.minute ?? 0,
                endHour: endComponents.hour ?? 0,
                endMinute: endComponents.minute ?? 0,
                sortOrder: index,
                isFocusTask: task.isFocusTask
            )
            template.timeSlots.append(slot)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorSubject.send(.saveFailed(error))
        }
    }
}
