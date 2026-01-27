//
//  DashboardModels.swift
//  BulletJournal
//

import Foundation

enum Dashboard {
    // MARK: - Load Statistics Use Case

    enum LoadStatistics {
        struct Request {}

        struct Response {
            let totalFocusSeconds: Int
            let weeklyData: WeeklyData
            let dailyRecords: [DailyRecord]
        }
    }

    // MARK: - Domain Models

    struct WeeklyData {
        let weekStartDate: Date  // Monday
        let dailyTotals: [DayTotal]  // 7 items (Mon-Sun)

        static let empty = WeeklyData(weekStartDate: Date(), dailyTotals: [])
    }

    struct DayTotal: Identifiable {
        let id: UUID
        let date: Date
        let totalSeconds: Int

        init(id: UUID = UUID(), date: Date, totalSeconds: Int) {
            self.id = id
            self.date = date
            self.totalSeconds = totalSeconds
        }
    }

    struct DailyRecord: Identifiable {
        let id: UUID
        let date: Date
        let totalFocusSeconds: Int
        let totalPlannedSeconds: Int

        var completionPercentage: Double {
            guard totalPlannedSeconds > 0 else { return 0 }
            return min(Double(totalFocusSeconds) / Double(totalPlannedSeconds), 1.0)
        }

        init(
            id: UUID = UUID(),
            date: Date,
            totalFocusSeconds: Int,
            totalPlannedSeconds: Int
        ) {
            self.id = id
            self.date = date
            self.totalFocusSeconds = totalFocusSeconds
            self.totalPlannedSeconds = totalPlannedSeconds
        }
    }

    // MARK: - ViewModels

    struct TotalFocusTimeViewModel: Equatable {
        let displayString: String

        static var empty: TotalFocusTimeViewModel {
            TotalFocusTimeViewModel(displayString: String(localized: "dashboard.noData"))
        }
    }

    struct WeeklyChartViewModel: Equatable {
        let bars: [BarData]

        struct BarData: Equatable, Identifiable {
            let id: UUID
            let weekday: String      // "Mon"
            let timeLabel: String    // "2h" or "1h45m"
            let heightRatio: Double  // 0.0 - 1.0 for bar height
            let seconds: Int

            init(
                id: UUID = UUID(),
                weekday: String,
                timeLabel: String,
                heightRatio: Double,
                seconds: Int
            ) {
                self.id = id
                self.weekday = weekday
                self.timeLabel = timeLabel
                self.heightRatio = heightRatio
                self.seconds = seconds
            }
        }

        static let empty = WeeklyChartViewModel(bars: [])
    }

    struct DailyRecordViewModel: Equatable, Identifiable {
        let id: UUID
        let dateString: String       // "1월 25일"
        let timeString: String       // "1h 30m"
        let percentageString: String // "14%"
        let emoji: String            // "😆"

        init(
            id: UUID = UUID(),
            dateString: String,
            timeString: String,
            percentageString: String,
            emoji: String
        ) {
            self.id = id
            self.dateString = dateString
            self.timeString = timeString
            self.percentageString = percentageString
            self.emoji = emoji
        }
    }
}
