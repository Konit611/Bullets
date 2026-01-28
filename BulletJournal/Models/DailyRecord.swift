//
//  DailyRecord.swift
//  BulletJournal
//

import Foundation
import SwiftData

@Model
final class DailyRecord {
    var id: UUID
    var date: Date                    // Normalized to start of day
    var sleepQualityEmoji: String?    // Set once on first focus, NOT editable
    var moodEmoji: String?            // Editable in DailyRecordDetail
    var reflectionText: String?       // Editable in DailyRecordDetail
    var bedTime: Date?                // Bedtime (e.g., 22:00)
    var wakeTime: Date?               // Wake time (e.g., 07:00) - Timeline starts from this time
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        sleepQualityEmoji: String? = nil,
        moodEmoji: String? = nil,
        reflectionText: String? = nil,
        bedTime: Date? = nil,
        wakeTime: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.sleepQualityEmoji = sleepQualityEmoji
        self.moodEmoji = moodEmoji
        self.reflectionText = reflectionText
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Check if sleep quality has been set (cannot be modified after setting)
    var hasSleepQuality: Bool {
        sleepQualityEmoji != nil
    }

    /// Update mood emoji (editable anytime)
    func updateMood(_ emoji: String?) {
        self.moodEmoji = emoji
        self.updatedAt = Date()
    }

    /// Update reflection text (editable anytime)
    func updateReflection(_ text: String?) {
        self.reflectionText = text
        self.updatedAt = Date()
    }

    /// Set sleep quality (can only be set once)
    func setSleepQuality(_ emoji: String) {
        guard sleepQualityEmoji == nil else { return }
        self.sleepQualityEmoji = emoji
        self.updatedAt = Date()
    }

    /// Check if sleep times have been set
    var hasSleepTimes: Bool {
        bedTime != nil && wakeTime != nil
    }

    /// Update sleep times (bedTime and wakeTime)
    func updateSleepTimes(bedTime: Date?, wakeTime: Date?) {
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.updatedAt = Date()
    }
}
