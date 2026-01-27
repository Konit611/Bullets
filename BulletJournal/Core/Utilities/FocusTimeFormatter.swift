//
//  FocusTimeFormatter.swift
//  BulletJournal
//

import Foundation

struct FocusTimeFormatter {
    // MARK: - Time Unit Constants

    private static let secondsPerMinute = 60
    private static let secondsPerHour = 3600
    private static let secondsPerDay = 86400
    private static let daysPerMonth = 30
    private static let daysPerYear = 365

    // MARK: - Cached DateFormatters

    private static let dailyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    // MARK: - Public Methods

    /// Formats total seconds into localized "1y 2mo 3d 4h" format
    /// Omits zero values (e.g., if only 30 minutes, shows "30m" not "0y 0mo 0d 0h 30m")
    static func formatTotalTime(_ totalSeconds: Int) -> String {
        guard totalSeconds > 0 else { return String(localized: "dashboard.noData") }

        let components = calculateTimeComponents(totalSeconds)
        var parts: [String] = []

        if components.years > 0 {
            parts.append(String(localized: "dashboard.year \(components.years)"))
        }
        if components.months > 0 {
            parts.append(String(localized: "dashboard.month \(components.months)"))
        }
        if components.days > 0 {
            parts.append(String(localized: "dashboard.day \(components.days)"))
        }
        if components.hours > 0 {
            parts.append(String(localized: "dashboard.hour \(components.hours)"))
        }

        // Show minutes only when no larger units exist (pure minutes display)
        let hasLargerUnits = !parts.isEmpty
        let isUnderOneHour = totalSeconds < secondsPerHour
        if components.minutes > 0 && (!hasLargerUnits || isUnderOneHour) {
            parts.append(String(localized: "dashboard.minute \(components.minutes)"))
        }

        return parts.isEmpty ? String(localized: "dashboard.noData") : parts.joined(separator: " ")
    }

    /// Formats seconds into short format "1h 30m" or "45m"
    static func formatShortTime(_ seconds: Int) -> String {
        guard seconds > 0 else { return "-" }

        let hours = seconds / secondsPerHour
        let minutes = (seconds % secondsPerHour) / secondsPerMinute

        if hours > 0 && minutes > 0 {
            return String(localized: "dashboard.hour \(hours)") + " " + String(localized: "dashboard.minute \(minutes)")
        } else if hours > 0 {
            return String(localized: "dashboard.hour \(hours)")
        } else {
            return String(localized: "dashboard.minute \(minutes)")
        }
    }

    /// Formats date for daily record display "1월 25일" / "Jan 25"
    static func formatDailyDate(_ date: Date) -> String {
        dailyDateFormatter.string(from: date)
    }

    /// Returns weekday abbreviation "Mon", "Tue", etc.
    static func weekdayAbbreviation(for date: Date) -> String {
        weekdayFormatter.string(from: date)
    }

    /// Returns the Monday of the week containing the given date (ISO week starts on Monday)
    static func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    // MARK: - Private Methods

    private struct TimeComponents {
        let years: Int
        let months: Int
        let days: Int
        let hours: Int
        let minutes: Int
    }

    private static func calculateTimeComponents(_ totalSeconds: Int) -> TimeComponents {
        var remaining = totalSeconds

        let totalDays = remaining / secondsPerDay
        remaining %= secondsPerDay

        let years = totalDays / daysPerYear
        var remainingDays = totalDays % daysPerYear

        let months = remainingDays / daysPerMonth
        remainingDays %= daysPerMonth

        let days = remainingDays
        let hours = remaining / secondsPerHour
        remaining %= secondsPerHour

        let minutes = remaining / secondsPerMinute

        return TimeComponents(
            years: years,
            months: months,
            days: days,
            hours: hours,
            minutes: minutes
        )
    }
}
