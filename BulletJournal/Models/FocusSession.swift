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

    /// Complete the session (valid from .inProgress or .paused state)
    /// - Returns: true if state was changed, false if already completed
    @discardableResult
    func complete(at date: Date = Date()) -> Bool {
        guard status != .completed else { return false }
        self.endedAt = date
        self.status = .completed
        return true
    }

    /// Pause the session (only valid from .inProgress state)
    /// - Returns: true if state was changed, false if invalid transition
    @discardableResult
    func pause() -> Bool {
        guard status == .inProgress else { return false }
        self.status = .paused
        return true
    }

    /// Resume the session (only valid from .paused state)
    /// - Returns: true if state was changed, false if invalid transition
    @discardableResult
    func resume() -> Bool {
        guard status == .paused else { return false }
        self.status = .inProgress
        return true
    }
}
