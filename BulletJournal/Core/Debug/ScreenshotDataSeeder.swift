//
//  ScreenshotDataSeeder.swift
//  BulletJournal
//
//  DEBUG only - Generates sample data for App Store screenshots.
//  This file is excluded from Release builds via #if DEBUG.
//

#if DEBUG

import Foundation
import SwiftData

@MainActor
enum ScreenshotDataSeeder {

    static func seedIfNeeded(modelContext: ModelContext) {
        let key = "screenshotDataSeeded"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        seed(modelContext: modelContext)
        UserDefaults.standard.set(true, forKey: key)
    }

    static func seed(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Task titles (not localized - user content)
        let taskSets: [[String]] = [
            ["Morning Reading", "Deep Work - Project", "Email & Meetings", "Exercise"],
            ["Journaling", "Algorithm Study", "Side Project", "Language Study"],
            ["Meditation", "Report Writing", "Code Review", "Design Research"],
            ["Morning Workout", "Client Presentation", "Team Sync", "Learning Time"],
            ["Planning", "Feature Development", "Documentation", "Sketching"],
            ["Yoga", "Data Analysis", "1:1 Meeting", "Blog Writing"],
            ["Stretching", "Sprint Tasks", "Brainstorming", "Reading"],
            ["Morning Walk", "Deep Work - API", "Lunch Study", "Review & Reflect"],
            ["Breathwork", "UI Development", "Tech Research", "Podcast Notes"],
            ["Running", "Backend Refactor", "Design Sprint", "Evening Study"],
            ["Morning Pages", "Product Planning", "User Research", "Skill Practice"],
            ["Core Training", "Bug Fixes", "Team Retro", "Creative Writing"],
            ["Mindfulness", "Architecture Design", "PR Reviews", "Course Work"],
            ["Cycling", "Integration Testing", "Stakeholder Call", "Portfolio Work"],
        ]

        let sleepEmojis = ["😴", "😪", "😌", "😊", "🥱"]
        let moodEmojis = ["😩", "😑", "🙂", "☺️", "😆"]

        let reflections = [
            "Productive day. Managed to finish the main feature ahead of schedule.",
            "Started slow but picked up momentum after lunch. Deep work session was great.",
            "Good focus in the morning. Need to minimize meetings in the afternoon.",
            "Felt energized today. Exercise really helps with concentration.",
            "Challenging day but learned a lot. Tomorrow I'll start with the hardest task.",
            "Great flow state during the project work. Music really helped.",
            "Balanced day between learning and doing. Happy with the progress.",
            "Need more sleep. Tired but still managed to complete core tasks.",
            "Best focus day this week! The new routine is working.",
            "Relaxed pace today. Sometimes it's okay to go slow.",
            "Pushed through a tough problem. Persistence pays off.",
            "Creative day - lots of new ideas during brainstorming.",
            "Focused on quality over quantity today. Fewer tasks, better results.",
            "Good collaboration with the team. Solo deep work after lunch.",
        ]

        // Generate 14 days of data (2 weeks)
        for dayOffset in 0..<14 {
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: dayDate)

            let tasks = taskSets[dayOffset % taskSets.count]
            let isWeekend = calendar.isDateInWeekend(dayDate)

            // Time slots for tasks
            let timeSlots: [(startHour: Int, startMin: Int, endHour: Int, endMin: Int)] = isWeekend
                ? [(10, 0, 11, 30), (13, 0, 14, 30), (15, 0, 16, 0), (17, 0, 18, 0)]
                : [(7, 0, 8, 0), (9, 0, 11, 30), (13, 0, 14, 30), (16, 0, 17, 30)]

            // Create tasks and sessions
            for (index, slot) in timeSlots.enumerated() {
                guard index < tasks.count else { break }

                let startTime = calendar.date(bySettingHour: slot.startHour, minute: slot.startMin, second: 0, of: dayDate)!
                let endTime = calendar.date(bySettingHour: slot.endHour, minute: slot.endMin, second: 0, of: dayDate)!

                let task = FocusTask(
                    title: tasks[index],
                    startTime: startTime,
                    endTime: endTime,
                    isCompleted: dayOffset > 0, // Today's tasks not all completed
                    isFocusTask: index < 3 // First 3 are focus tasks
                )
                modelContext.insert(task)

                // Add completed sessions for past days
                if dayOffset > 0 {
                    let plannedSeconds = Int(endTime.timeIntervalSince(startTime))
                    // 60~95% completion rate for variety
                    let completionRate = Double.random(in: 0.6...0.95)
                    let elapsedSeconds = Int(Double(plannedSeconds) * completionRate)

                    let session = FocusSession(
                        startedAt: startTime,
                        endedAt: calendar.date(byAdding: .second, value: elapsedSeconds, to: startTime),
                        elapsedSeconds: elapsedSeconds,
                        status: .completed
                    )
                    task.focusSessions.append(session)
                    modelContext.insert(session)
                } else if index == 0 {
                    // Today: first task has a partial session
                    let elapsedSeconds = 2520 // 42 minutes
                    let session = FocusSession(
                        startedAt: startTime,
                        endedAt: calendar.date(byAdding: .second, value: elapsedSeconds, to: startTime),
                        elapsedSeconds: elapsedSeconds,
                        status: .completed
                    )
                    task.focusSessions.append(session)
                    modelContext.insert(session)
                }
            }

            // Create DailyRecord
            let bedHour = Int.random(in: 22...23)
            let bedMin = [0, 15, 30, 45].randomElement()!
            let wakeHour = Int.random(in: 6...7)
            let wakeMin = [0, 15, 30, 45].randomElement()!

            let bedTime = calendar.date(bySettingHour: bedHour, minute: bedMin, second: 0, of: dayDate)
            let wakeTime = calendar.date(bySettingHour: wakeHour, minute: wakeMin, second: 0, of: dayDate)

            let sleepIdx = min(dayOffset, sleepEmojis.count - 1)
            let moodIdx = dayOffset % moodEmojis.count

            let record = DailyRecord(
                date: dayStart,
                sleepQualityEmoji: sleepEmojis[sleepIdx % sleepEmojis.count],
                moodEmoji: dayOffset < 10 ? moodEmojis[(moodEmojis.count - 1) - (moodIdx % 3)] : moodEmojis[moodIdx],
                reflectionText: dayOffset > 0 ? reflections[dayOffset % reflections.count] : nil,
                bedTime: bedTime,
                wakeTime: wakeTime,
                isHoliday: isWeekend
            )
            modelContext.insert(record)
        }

        try? modelContext.save()
    }

    /// Reset seeded data flag (call to re-seed on next launch)
    static func reset() {
        UserDefaults.standard.removeObject(forKey: "screenshotDataSeeded")
    }
}

#endif
