//
//  FocusTask.swift
//  BulletJournal
//

import Foundation
import SwiftData

@Model
final class FocusTask {
    var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var focusSessions: [FocusSession]

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        endTime: Date,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        focusSessions: [FocusSession] = []
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.focusSessions = focusSessions
    }

    var plannedDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var totalFocusedTime: TimeInterval {
        focusSessions
            .filter { $0.status == .completed || $0.status == .inProgress }
            .reduce(0) { $0 + TimeInterval($1.elapsedSeconds) }
    }

    var progressPercentage: Double {
        guard plannedDuration > 0 else { return 0 }
        return min(totalFocusedTime / plannedDuration, 1.0)
    }

    var timeSlotString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }

    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startTime)
    }

    var endTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: endTime)
    }

    var durationString: String {
        let hours = Int(plannedDuration) / 3600
        let minutes = (Int(plannedDuration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var currentSession: FocusSession? {
        focusSessions.first { $0.status == .inProgress || $0.status == .paused }
    }

    func isWithinTimeSlot(at date: Date = Date()) -> Bool {
        date >= startTime && date <= endTime
    }
}
