//
//  DashboardInteractor.swift
//  BulletJournal
//

import Foundation
import Combine
import SwiftData

@MainActor
protocol DashboardInteractorProtocol: AnyObject {
    var statisticsLoadedPublisher: AnyPublisher<Dashboard.LoadStatistics.Response, Never> { get }
    func loadStatistics()
}

@MainActor
final class DashboardInteractor: DashboardInteractorProtocol {
    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Publishers

    private let statisticsLoadedSubject = PassthroughSubject<Dashboard.LoadStatistics.Response, Never>()

    var statisticsLoadedPublisher: AnyPublisher<Dashboard.LoadStatistics.Response, Never> {
        statisticsLoadedSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    func loadStatistics() {
        let calendar = Calendar.current
        let now = Date()

        // Single fetch for all sessions
        let allSessions: [FocusSession]
        do {
            let descriptor = FetchDescriptor<FocusSession>()
            allSessions = try modelContext.fetch(descriptor)
        } catch {
            allSessions = []
        }

        let completedSessions = allSessions.filter { $0.status == .completed }

        // Calculate total focus time
        let totalFocusSeconds = completedSessions.reduce(0) { $0 + $1.elapsedSeconds }

        // Calculate weekly data
        let weeklyData = buildWeeklyData(from: completedSessions, calendar: calendar, now: now)

        // Calculate daily records
        let dailyRecords = buildDailyRecords(from: completedSessions, calendar: calendar, now: now)

        let response = Dashboard.LoadStatistics.Response(
            totalFocusSeconds: totalFocusSeconds,
            weeklyData: weeklyData,
            dailyRecords: dailyRecords
        )

        statisticsLoadedSubject.send(response)
    }

    // MARK: - Private Methods

    private func buildWeeklyData(
        from sessions: [FocusSession],
        calendar: Calendar,
        now: Date
    ) -> Dashboard.WeeklyData {
        let weekStart = FocusTimeFormatter.startOfWeek(for: now)

        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return .empty
        }

        let weeklySessions = sessions.filter {
            $0.startedAt >= weekStart && $0.startedAt < weekEnd
        }

        var dailyTotals: [Dashboard.DayTotal] = []

        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }

            let dayTotal = weeklySessions
                .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                .reduce(0) { $0 + $1.elapsedSeconds }

            dailyTotals.append(Dashboard.DayTotal(
                date: dayDate,
                totalSeconds: dayTotal
            ))
        }

        return Dashboard.WeeklyData(
            weekStartDate: weekStart,
            dailyTotals: dailyTotals
        )
    }

    private func buildDailyRecords(
        from sessions: [FocusSession],
        calendar: Calendar,
        now: Date
    ) -> [Dashboard.DailyRecordData] {
        let limit = 30
        guard let startDate = calendar.date(byAdding: .day, value: -limit, to: now) else {
            return []
        }

        let recentSessions = sessions.filter { $0.startedAt >= startDate }

        // Fetch tasks for planned time calculation
        let tasks: [FocusTask]
        do {
            let taskDescriptor = FetchDescriptor<FocusTask>(
                predicate: #Predicate<FocusTask> { task in
                    task.startTime >= startDate
                }
            )
            tasks = try modelContext.fetch(taskDescriptor)
        } catch {
            tasks = []
        }

        // Fetch DailyRecords for mood emoji
        let dailyRecords: [DailyRecord]
        do {
            let recordDescriptor = FetchDescriptor<DailyRecord>(
                predicate: #Predicate<DailyRecord> { record in
                    record.date >= startDate
                }
            )
            dailyRecords = try modelContext.fetch(recordDescriptor)
        } catch {
            dailyRecords = []
        }

        // Create lookup for mood emojis
        let moodEmojiLookup = Dictionary(
            uniqueKeysWithValues: dailyRecords.map { ($0.date, $0.moodEmoji) }
        )

        // Group by day
        var dailyRecordsDict: [Date: (focusSeconds: Int, plannedSeconds: Int)] = [:]

        for session in recentSessions {
            let dayStart = calendar.startOfDay(for: session.startedAt)
            let current = dailyRecordsDict[dayStart] ?? (focusSeconds: 0, plannedSeconds: 0)
            dailyRecordsDict[dayStart] = (
                focusSeconds: current.focusSeconds + session.elapsedSeconds,
                plannedSeconds: current.plannedSeconds
            )
        }

        for task in tasks {
            let dayStart = calendar.startOfDay(for: task.startTime)
            let current = dailyRecordsDict[dayStart] ?? (focusSeconds: 0, plannedSeconds: 0)
            let plannedDuration = Int(task.plannedDuration)
            dailyRecordsDict[dayStart] = (
                focusSeconds: current.focusSeconds,
                plannedSeconds: current.plannedSeconds + plannedDuration
            )
        }

        return dailyRecordsDict
            .filter { $0.value.focusSeconds > 0 || $0.value.plannedSeconds > 0 }
            .map { date, values in
                Dashboard.DailyRecordData(
                    date: date,
                    totalFocusSeconds: values.focusSeconds,
                    totalPlannedSeconds: values.plannedSeconds,
                    moodEmoji: moodEmojiLookup[date] ?? nil
                )
            }
            .sorted { $0.date > $1.date }
    }
}
