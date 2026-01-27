//
//  DailyRecordDetailInteractor.swift
//  BulletJournal
//

import Foundation
import Combine
import SwiftData

@MainActor
protocol DailyRecordDetailInteractorProtocol: AnyObject {
    var recordLoadedPublisher: AnyPublisher<DailyRecordDetail.LoadRecord.Response, Never> { get }
    var saveResultPublisher: AnyPublisher<DailyRecordDetail.SaveRecord.Response, Never> { get }
    var errorPublisher: AnyPublisher<AppError, Never> { get }

    func loadRecord(for date: Date)
    func saveRecord(moodEmoji: String?, reflectionText: String?, for date: Date)
}

@MainActor
final class DailyRecordDetailInteractor: DailyRecordDetailInteractorProtocol {
    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Publishers

    private let recordLoadedSubject = PassthroughSubject<DailyRecordDetail.LoadRecord.Response, Never>()
    private let saveResultSubject = PassthroughSubject<DailyRecordDetail.SaveRecord.Response, Never>()
    private let errorSubject = PassthroughSubject<AppError, Never>()

    var recordLoadedPublisher: AnyPublisher<DailyRecordDetail.LoadRecord.Response, Never> {
        recordLoadedSubject.eraseToAnyPublisher()
    }

    var saveResultPublisher: AnyPublisher<DailyRecordDetail.SaveRecord.Response, Never> {
        saveResultSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    func loadRecord(for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Fetch DailyRecord
        let record = fetchDailyRecord(for: normalizedDate)

        // Calculate goal achievement from FocusSessions
        let goalAchievement = calculateGoalAchievement(for: normalizedDate)

        let response = DailyRecordDetail.LoadRecord.Response(
            record: record,
            goalAchievement: goalAchievement,
            date: normalizedDate
        )

        recordLoadedSubject.send(response)
    }

    func saveRecord(moodEmoji: String?, reflectionText: String?, for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        do {
            let record = fetchOrCreateDailyRecord(for: normalizedDate)
            record.updateMood(moodEmoji)
            record.updateReflection(reflectionText)
            try modelContext.save()
            saveResultSubject.send(DailyRecordDetail.SaveRecord.Response(success: true))
        } catch {
            errorSubject.send(.saveFailed(error.localizedDescription))
            saveResultSubject.send(DailyRecordDetail.SaveRecord.Response(success: false))
        }
    }

    // MARK: - Private Methods

    private func fetchDailyRecord(for date: Date) -> DailyRecord? {
        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date == date
            }
        )

        do {
            let records = try modelContext.fetch(descriptor)
            return records.first
        } catch {
            return nil
        }
    }

    private func fetchOrCreateDailyRecord(for date: Date) -> DailyRecord {
        if let existing = fetchDailyRecord(for: date) {
            return existing
        }

        let newRecord = DailyRecord(date: date)
        modelContext.insert(newRecord)
        return newRecord
    }

    private func calculateGoalAchievement(for date: Date) -> DailyRecordDetail.GoalAchievementData {
        let calendar = Calendar.current
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: date) else {
            return .empty
        }

        // Fetch all sessions for this day
        let allSessions: [FocusSession]
        do {
            let descriptor = FetchDescriptor<FocusSession>()
            allSessions = try modelContext.fetch(descriptor)
        } catch {
            return .empty
        }

        let daySessions = allSessions.filter { session in
            session.status == .completed &&
            session.startedAt >= date &&
            session.startedAt < dayEnd
        }

        let totalFocusSeconds = daySessions.reduce(0) { $0 + $1.elapsedSeconds }

        // Fetch all tasks for this day
        let allTasks: [FocusTask]
        do {
            let descriptor = FetchDescriptor<FocusTask>()
            allTasks = try modelContext.fetch(descriptor)
        } catch {
            return DailyRecordDetail.GoalAchievementData(
                totalFocusSeconds: totalFocusSeconds,
                totalPlannedSeconds: 0
            )
        }

        let dayTasks = allTasks.filter { task in
            let taskDate = calendar.startOfDay(for: task.startTime)
            return taskDate == date
        }

        let totalPlannedSeconds = dayTasks.reduce(0) { $0 + Int($1.plannedDuration) }

        return DailyRecordDetail.GoalAchievementData(
            totalFocusSeconds: totalFocusSeconds,
            totalPlannedSeconds: totalPlannedSeconds
        )
    }
}
