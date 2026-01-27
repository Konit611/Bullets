//
//  DailyRecordDetailModels.swift
//  BulletJournal
//

import Foundation

enum DailyRecordDetail {
    // MARK: - Configuration

    enum Configuration {
        static let moodEmojis = ["😩", "😑", "🙂", "☺️", "😆"]
        static let reflectionMaxLength = 500
    }

    // MARK: - Load Record Use Case

    enum LoadRecord {
        struct Request {
            let date: Date
        }

        struct Response {
            let record: DailyRecord?
            let goalAchievement: GoalAchievementData
            let date: Date
        }
    }

    // MARK: - Save Record Use Case

    enum SaveRecord {
        struct Request {
            let date: Date
            let moodEmoji: String?
            let reflectionText: String?
        }

        struct Response {
            let success: Bool
        }
    }

    // MARK: - Domain Models

    struct GoalAchievementData {
        let totalFocusSeconds: Int
        let totalPlannedSeconds: Int

        var percentage: Double {
            guard totalPlannedSeconds > 0 else { return 0 }
            return min(Double(totalFocusSeconds) / Double(totalPlannedSeconds), 1.0)
        }

        static let empty = GoalAchievementData(totalFocusSeconds: 0, totalPlannedSeconds: 0)
    }

    // MARK: - ViewModels

    struct ViewModel: Equatable {
        let dateString: String
        let goalAchievement: GoalAchievementViewModel
        let sleepQuality: SleepQualityViewModel
        let reflection: ReflectionViewModel

        static let empty = ViewModel(
            dateString: "",
            goalAchievement: .empty,
            sleepQuality: .empty,
            reflection: .empty
        )
    }

    struct GoalAchievementViewModel: Equatable {
        let percentageString: String
        let focusTimeString: String
        let plannedTimeString: String

        static let empty = GoalAchievementViewModel(
            percentageString: "0%",
            focusTimeString: "-",
            plannedTimeString: "-"
        )
    }

    struct SleepQualityViewModel: Equatable {
        let emoji: String?
        let isSet: Bool

        static let empty = SleepQualityViewModel(emoji: nil, isSet: false)
    }

    struct ReflectionViewModel: Equatable {
        let text: String
        let maxLength: Int
        let placeholder: String

        static let empty = ReflectionViewModel(
            text: "",
            maxLength: Configuration.reflectionMaxLength,
            placeholder: String(localized: "dailyRecord.reflection.placeholder")
        )
    }
}
