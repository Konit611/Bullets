//
//  FocusSession.swift
//  BulletJournal
//

import Foundation
import SwiftData

enum FocusSessionStatus: String, Codable {
    case inProgress
    case paused
    case completed
}

@Model
final class FocusSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var elapsedSeconds: Int
    var status: FocusSessionStatus

    @Relationship(inverse: \FocusTask.focusSessions)
    var task: FocusTask?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        elapsedSeconds: Int = 0,
        status: FocusSessionStatus = .inProgress
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.elapsedSeconds = elapsedSeconds
        self.status = status
    }

    var duration: TimeInterval {
        TimeInterval(elapsedSeconds)
    }

    func complete(at date: Date = Date()) {
        self.endedAt = date
        self.status = .completed
    }

    func pause() {
        self.status = .paused
    }

    func resume() {
        self.status = .inProgress
    }
}
