//
//  BulletJournalWidget.swift
//  BulletJournalWidget
//
//  Created by GEUNIL on 2026/01/31.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct FocusWidgetEntry: TimelineEntry {
    let date: Date
    let taskTitle: String?
    let timeSlot: String?
    let progressPercentage: Double
    let totalFocusedSeconds: Int
    let remainingSeconds: Int
    let plannedDurationSeconds: Int
    let isEmpty: Bool

    static var empty: FocusWidgetEntry {
        FocusWidgetEntry(
            date: Date(),
            taskTitle: nil,
            timeSlot: nil,
            progressPercentage: 0,
            totalFocusedSeconds: 0,
            remainingSeconds: 0,
            plannedDurationSeconds: 0,
            isEmpty: true
        )
    }

    static var placeholder: FocusWidgetEntry {
        FocusWidgetEntry(
            date: Date(),
            taskTitle: "Reading",
            timeSlot: "09:00-10:00",
            progressPercentage: 0.45,
            totalFocusedSeconds: 1620,
            remainingSeconds: 1380,
            plannedDurationSeconds: 3600,
            isEmpty: false
        )
    }

    var formattedRemainingTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        if hours > 0 {
            return String(localized: "widget.remaining \(hours) \(minutes)")
        } else {
            return String(localized: "widget.remainingMinutes \(minutes)")
        }
    }

    var formattedFocusedTime: String {
        let hours = totalFocusedSeconds / 3600
        let minutes = (totalFocusedSeconds % 3600) / 60
        if hours > 0 {
            return String(localized: "widget.focused \(hours) \(minutes)")
        } else {
            return String(localized: "widget.focusedMinutes \(minutes)")
        }
    }
}

// MARK: - Timeline Provider

struct FocusWidgetProvider: TimelineProvider {
    private static let sharedContainer: ModelContainer? = {
        do {
            let schema = Schema([FocusTask.self, FocusSession.self, DailyRecord.self])
            let config = ModelConfiguration(
                schema: schema,
                url: AppConfiguration.sharedStoreURL,
                allowsSave: false
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            return nil
        }
    }()

    func placeholder(in context: Context) -> FocusWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(fetchCurrentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> Void) {
        let entry = fetchCurrentEntry()

        let fifteenMinutes = Date().addingTimeInterval(15 * 60)
        let refreshDate: Date
        if !entry.isEmpty {
            refreshDate = min(entry.date.addingTimeInterval(TimeInterval(entry.remainingSeconds)), fifteenMinutes)
        } else {
            refreshDate = fifteenMinutes
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> FocusWidgetEntry {
        guard let container = Self.sharedContainer else { return .empty }

        let now = Date()
        do {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<FocusTask>(
                predicate: #Predicate<FocusTask> { task in
                    task.startTime <= now && task.endTime >= now && !task.isCompleted
                },
                sortBy: [SortDescriptor(\.startTime)]
            )

            let tasks = try context.fetch(descriptor)
            guard let task = tasks.first else {
                return .empty
            }

            let remainingSeconds = max(0, Int(task.endTime.timeIntervalSince(now)))
            let totalFocusedSeconds = Int(task.totalFocusedTime)
            let plannedDurationSeconds = Int(task.plannedDuration)

            return FocusWidgetEntry(
                date: now,
                taskTitle: task.title,
                timeSlot: task.timeSlotString,
                progressPercentage: task.progressPercentage,
                totalFocusedSeconds: totalFocusedSeconds,
                remainingSeconds: remainingSeconds,
                plannedDurationSeconds: plannedDurationSeconds,
                isEmpty: false
            )
        } catch {
            return .empty
        }
    }
}

// MARK: - Widget View Router

struct BulletJournalWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            FocusWidgetSmallView(entry: entry)
        case .systemMedium:
            FocusWidgetMediumView(entry: entry)
        case .accessoryCircular:
            FocusWidgetLockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            FocusWidgetLockScreenRectangularView(entry: entry)
        default:
            FocusWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct BulletJournalWidget: Widget {
    let kind: String = "BulletJournalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                BulletJournalWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                BulletJournalWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Focus Task")
        .description("Shows your current focus task and progress.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    BulletJournalWidget()
} timeline: {
    FocusWidgetEntry.placeholder
    FocusWidgetEntry.empty
}

#Preview(as: .systemMedium) {
    BulletJournalWidget()
} timeline: {
    FocusWidgetEntry.placeholder
    FocusWidgetEntry.empty
}
