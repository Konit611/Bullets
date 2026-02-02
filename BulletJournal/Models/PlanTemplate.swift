//
//  PlanTemplate.swift
//  BulletJournal
//

import Foundation
import SwiftData

@Model
final class PlanTemplate {
    var id: UUID
    var isHoliday: Bool
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var timeSlots: [PlanTemplateSlot]

    init(
        id: UUID = UUID(),
        isHoliday: Bool,
        updatedAt: Date = Date(),
        timeSlots: [PlanTemplateSlot] = []
    ) {
        self.id = id
        self.isHoliday = isHoliday
        self.updatedAt = updatedAt
        self.timeSlots = timeSlots
    }
}

@Model
final class PlanTemplateSlot {
    var id: UUID
    var title: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var sortOrder: Int

    @Relationship(inverse: \PlanTemplate.timeSlots)
    var template: PlanTemplate?

    init(
        id: UUID = UUID(),
        title: String,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        sortOrder: Int
    ) {
        self.id = id
        self.title = title
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.sortOrder = sortOrder
    }
}
