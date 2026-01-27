//
//  SampleDataSeeder.swift
//  BulletJournal
//

import Foundation
import SwiftData

@MainActor
struct SampleDataSeeder {
    private static let hasSeededKey = "hasSeededSampleData"

    static func seedIfNeeded(modelContext: ModelContext) {
        // Only seed once
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else { return }

        let tasks = createSampleTasks()
        for task in tasks {
            modelContext.insert(task)
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
}
