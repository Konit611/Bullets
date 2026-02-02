//
//  DailyPlanModels.swift
//  BulletJournal
//

import Foundation

enum DailyPlan {
    // MARK: - Configuration

    enum Configuration {
        static let hourHeight: CGFloat = 66
        static let defaultWakeHour: Int = 7
        static let defaultTimelineEndHour: Int = 23      // Timeline ends at this hour
        static let defaultBedTimePickerHour: Int = 22    // Default bedtime in DatePicker
        static let holidayDefaultWakeHour: Int = 9
        static let holidayDefaultTimelineEndHour: Int = 23
        static let holidayDefaultBedTimePickerHour: Int = 22
        static let sleepEmojis = ["😩", "😑", "🙂", "☺️", "😆"]
    }

    // MARK: - Load Use Case

    enum LoadDailyPlan {
        struct Response {
            let date: Date
            let sleepRecord: SleepRecordData?
            let tasks: [TaskData]
            let needsSleepRecord: Bool
            let isHoliday: Bool
        }
    }

    // MARK: - Domain Models

    struct SleepRecordData: Equatable {
        let bedTime: Date?
        let wakeTime: Date?
        let sleepQualityEmoji: String?

        static let empty = SleepRecordData(bedTime: nil, wakeTime: nil, sleepQualityEmoji: nil)
    }

    struct TaskData: Identifiable, Equatable {
        let id: UUID
        let title: String
        let startTime: Date
        let endTime: Date
        let isCompleted: Bool
        let isFocusTask: Bool
        let totalFocusedTime: TimeInterval
        let plannedDuration: TimeInterval

        var progressPercentage: Double {
            guard plannedDuration > 0 else { return 0 }
            return min(totalFocusedTime / plannedDuration, 1.0)
        }
    }

    // MARK: - ViewModels

    struct ViewModel: Equatable {
        let dateString: String
        let sleepRecord: SleepRecordViewModel?
        let needsSleepRecord: Bool
        let timelineRows: [TimelineRowViewModel]
        let taskBlocks: [TaskBlockViewModel]
        let currentTimePosition: CGFloat?
        let currentTimeString: String?
        let wakeHour: Int
        let bedHour: Int
        let isHoliday: Bool

        func withUpdatedTime(position: CGFloat?, timeString: String?) -> ViewModel {
            ViewModel(
                dateString: dateString,
                sleepRecord: sleepRecord,
                needsSleepRecord: needsSleepRecord,
                timelineRows: timelineRows,
                taskBlocks: taskBlocks,
                currentTimePosition: position,
                currentTimeString: timeString,
                wakeHour: wakeHour,
                bedHour: bedHour,
                isHoliday: isHoliday
            )
        }

        static let empty = ViewModel(
            dateString: "",
            sleepRecord: nil,
            needsSleepRecord: true,
            timelineRows: [],
            taskBlocks: [],
            currentTimePosition: nil,
            currentTimeString: nil,
            wakeHour: Configuration.defaultWakeHour,
            bedHour: Configuration.defaultTimelineEndHour,
            isHoliday: false
        )
    }

    struct SleepRecordViewModel: Equatable {
        let bedTimeString: String
        let wakeTimeString: String
        let sleepQualityEmoji: String?
        let bedTime: Date?
        let wakeTime: Date?

        static let empty = SleepRecordViewModel(
            bedTimeString: "--:--",
            wakeTimeString: "--:--",
            sleepQualityEmoji: nil,
            bedTime: nil,
            wakeTime: nil
        )
    }

    struct TimelineRowViewModel: Identifiable, Equatable {
        let id: UUID
        let hour: Int
        let timeLabel: String
        let yPosition: CGFloat

        init(id: UUID = UUID(), hour: Int, timeLabel: String, yPosition: CGFloat) {
            self.id = id
            self.hour = hour
            self.timeLabel = timeLabel
            self.yPosition = yPosition
        }
    }

    struct TaskBlockViewModel: Identifiable, Equatable {
        let id: UUID
        let title: String
        let startTimeString: String
        let endTimeString: String
        let yPosition: CGFloat
        let height: CGFloat
        let isCurrentTask: Bool
        let isFocusTask: Bool
        let progressPercentage: Double
    }

    // MARK: - Task Edit Form

    struct TaskFormData: Equatable {
        var id: UUID?
        var title: String
        var startTime: Date
        var endTime: Date
        var isFocusTask: Bool

        var isValid: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            endTime > startTime
        }

        static func empty(for date: Date) -> TaskFormData {
            let calendar = Calendar.current
            let now = Date()
            let currentHour = calendar.component(.hour, from: now)
            let startTime = calendar.date(bySettingHour: currentHour, minute: 0, second: 0, of: date) ?? date
            let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) ?? date

            return TaskFormData(
                id: nil,
                title: "",
                startTime: startTime,
                endTime: endTime,
                isFocusTask: true
            )
        }
    }

    // MARK: - Error

    enum DailyPlanError: Error, LocalizedError {
        case timeConflict
        case invalidTimeSlot
        case saveFailed(Error)
        case fetchFailed(Error)

        var errorDescription: String? {
            switch self {
            case .timeConflict:
                return String(localized: "error.timeConflict")
            case .invalidTimeSlot:
                return String(localized: "error.invalidTimeSlot")
            case .saveFailed(let error):
                return String(localized: "error.saveFailed \(error.localizedDescription)")
            case .fetchFailed(let error):
                return String(localized: "error.fetchFailed \(error.localizedDescription)")
            }
        }
    }
}
