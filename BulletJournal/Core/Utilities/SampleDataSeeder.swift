//
//  SampleDataSeeder.swift
//  BulletJournal
//

import Foundation
import SwiftData

@MainActor
struct SampleDataSeeder {
    private static let hasSeededKey = "hasSeededSampleData_v3"

    static func seedIfNeeded(modelContext: ModelContext) {
        // Only seed once
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else { return }

        // Create today's tasks
        let todayTasks = createSampleTasks()
        for task in todayTasks {
            modelContext.insert(task)
        }

        // Create historical data for Dashboard
        let historicalData = createHistoricalData()
        for (task, sessions) in historicalData {
            modelContext.insert(task)
            for session in sessions {
                task.focusSessions.append(session)
                modelContext.insert(session)
            }
        }

        // Create DailyRecords for historical data
        let dailyRecords = createDailyRecords()
        for record in dailyRecords {
            modelContext.insert(record)
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: hasSeededKey)
    }

    /// Reset seeding flag (for development/testing)
    static func resetSeedingFlag() {
        UserDefaults.standard.set(false, forKey: hasSeededKey)
    }

    private static func createSampleTasks() -> [FocusTask] {
        let calendar = Calendar.current
        let today = Date()

        // Sample tasks (user-created content, not localized)
        // (title, startHour, startMinute, endHour, endMinute)
        let taskData: [(String, Int, Int, Int, Int)] = [
            ("Morning Routine", 6, 0, 7, 0),
            ("Exercise", 7, 0, 8, 0),
            ("Work - Morning", 9, 0, 12, 0),
            ("Lunch Break", 12, 0, 13, 0),
            ("Work - Afternoon", 13, 0, 17, 0),
            ("Side Project", 18, 0, 20, 0),
            ("Reading", 20, 0, 21, 0),
            ("Evening Routine", 21, 0, 22, 0),
        ]

        return taskData.compactMap { (title, startHour, startMinute, endHour, endMinute) in
            guard let startTime = calendar.date(
                bySettingHour: startHour,
                minute: startMinute,
                second: 0,
                of: today
            ),
            let endTime = calendar.date(
                bySettingHour: endHour,
                minute: endMinute,
                second: 0,
                of: today
            ) else {
                return nil
            }

            return FocusTask(
                title: title,
                startTime: startTime,
                endTime: endTime
            )
        }
    }

    /// Create historical tasks with completed sessions for Dashboard display
    private static func createHistoricalData() -> [(FocusTask, [FocusSession])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Data for past 14 days
        // (daysAgo, taskTitle, plannedHours, focusedMinutes)
        let historicalData: [(Int, String, Int, Int)] = [
            // Yesterday
            (1, "Work Session", 8, 180),      // 3h focused out of 8h planned
            (1, "Side Project", 2, 90),       // 1.5h focused out of 2h planned

            // 2 days ago
            (2, "Work Session", 8, 240),      // 4h focused
            (2, "Reading", 1, 45),            // 45m focused

            // 3 days ago
            (3, "Work Session", 8, 300),      // 5h focused
            (3, "Exercise", 1, 60),           // 1h focused

            // 4 days ago
            (4, "Work Session", 8, 120),      // 2h focused
            (4, "Side Project", 2, 30),       // 30m focused

            // 5 days ago
            (5, "Work Session", 8, 360),      // 6h focused
            (5, "Reading", 1, 60),            // 1h focused

            // 6 days ago
            (6, "Work Session", 8, 200),      // 3h 20m focused

            // 7 days ago (a week ago)
            (7, "Work Session", 8, 280),      // 4h 40m focused
            (7, "Side Project", 2, 100),      // 1h 40m focused

            // 10 days ago
            (10, "Work Session", 8, 150),

            // 14 days ago
            (14, "Work Session", 8, 220),
        ]

        var result: [(FocusTask, [FocusSession])] = []

        for (daysAgo, title, plannedHours, focusedMinutes) in historicalData {
            guard let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: today),
                  let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayDate),
                  let endTime = calendar.date(byAdding: .hour, value: plannedHours, to: startTime) else {
                continue
            }

            let task = FocusTask(
                title: title,
                startTime: startTime,
                endTime: endTime,
                isCompleted: true
            )

            let session = FocusSession(
                startedAt: startTime,
                endedAt: calendar.date(byAdding: .minute, value: focusedMinutes, to: startTime),
                elapsedSeconds: focusedMinutes * 60,
                status: .completed
            )

            result.append((task, [session]))
        }

        return result
    }

    /// Create DailyRecords with mood emojis for historical data
    private static func createDailyRecords() -> [DailyRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // (daysAgo, sleepQualityEmoji, moodEmoji, reflectionText)
        let recordData: [(Int, String, String, String?)] = [
            (1, "☺️", "😆", "Productive day! Completed all my tasks."),
            (2, "🙂", "☺️", "Good focus session today."),
            (3, "😆", "😆", "Best day this week!"),
            (4, "😑", "🙂", nil),
            (5, "☺️", "☺️", "Made good progress on the project."),
            (6, "🙂", "😑", "Tired but managed to get work done."),
            (7, "😩", "🙂", nil),
            (10, "☺️", "☺️", nil),
            (14, "🙂", "😆", "Great start to the week!"),
        ]

        return recordData.compactMap { (daysAgo, sleepEmoji, moodEmoji, reflection) in
            guard let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return nil
            }

            return DailyRecord(
                date: dayDate,
                sleepQualityEmoji: sleepEmoji,
                moodEmoji: moodEmoji,
                reflectionText: reflection
            )
        }
    }
}
