//
//  FocusTimeFormatterTests.swift
//  BulletJournalTests
//

import XCTest
@testable import BulletJournal

final class FocusTimeFormatterTests: XCTestCase {

    // MARK: - formatTotalTime Tests

    func testFormatTotalTime_zero_returnsNoDataString() {
        // Act
        let result = FocusTimeFormatter.formatTotalTime(0)

        // Assert
        XCTAssertEqual(result, String(localized: "dashboard.noData"))
    }

    func testFormatTotalTime_negativeValue_returnsNoDataString() {
        // Act
        let result = FocusTimeFormatter.formatTotalTime(-100)

        // Assert
        XCTAssertEqual(result, String(localized: "dashboard.noData"))
    }

    func testFormatTotalTime_onlyMinutes_showsMinutesOnly() {
        // Arrange
        let thirtyMinutes = 30 * 60

        // Act
        let result = FocusTimeFormatter.formatTotalTime(thirtyMinutes)

        // Assert - Should only show minutes, not "0h 30m"
        XCTAssertTrue(result.contains("30"))
        XCTAssertFalse(result.contains("0h") || result.contains("0시간"))
    }

    func testFormatTotalTime_oneHour_showsHourOnly() {
        // Arrange
        let oneHour = 3600

        // Act
        let result = FocusTimeFormatter.formatTotalTime(oneHour)

        // Assert
        XCTAssertTrue(result.contains("1"))
    }

    func testFormatTotalTime_hoursAndMinutes_showsBoth() {
        // Arrange
        let oneHourThirtyMinutes = 90 * 60

        // Act
        let result = FocusTimeFormatter.formatTotalTime(oneHourThirtyMinutes)

        // Assert
        XCTAssertTrue(result.contains("1"))
    }

    func testFormatTotalTime_multipleDays_showsDaysAndHours() {
        // Arrange
        let twoDaysFiveHours = (2 * 86400) + (5 * 3600)

        // Act
        let result = FocusTimeFormatter.formatTotalTime(twoDaysFiveHours)

        // Assert
        XCTAssertTrue(result.contains("2"))
        XCTAssertTrue(result.contains("5"))
    }

    func testFormatTotalTime_yearsMonthsDaysHours_showsAllUnits() {
        // Arrange
        let seconds = (365 * 86400) + (60 * 86400) + (3 * 86400) + (4 * 3600)

        // Act
        let result = FocusTimeFormatter.formatTotalTime(seconds)

        // Assert - Should contain all non-zero units
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - formatShortTime Tests

    func testFormatShortTime_zero_returnsDash() {
        // Act
        let result = FocusTimeFormatter.formatShortTime(0)

        // Assert
        XCTAssertEqual(result, "-")
    }

    func testFormatShortTime_thirtyMinutes_showsMinutesOnly() {
        // Arrange
        let thirtyMinutes = 30 * 60

        // Act
        let result = FocusTimeFormatter.formatShortTime(thirtyMinutes)

        // Assert
        XCTAssertTrue(result.contains("30"))
    }

    func testFormatShortTime_oneHour_showsHourOnly() {
        // Arrange
        let oneHour = 3600

        // Act
        let result = FocusTimeFormatter.formatShortTime(oneHour)

        // Assert
        XCTAssertTrue(result.contains("1"))
    }

    func testFormatShortTime_oneHourThirtyMinutes_showsBoth() {
        // Arrange
        let oneHourThirtyMinutes = 90 * 60

        // Act
        let result = FocusTimeFormatter.formatShortTime(oneHourThirtyMinutes)

        // Assert
        XCTAssertTrue(result.contains("1"))
        XCTAssertTrue(result.contains("30"))
    }

    // MARK: - formatDailyDate Tests

    func testFormatDailyDate_returnsLocalizedFormat() {
        // Arrange
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 25
        let date = calendar.date(from: components)!

        // Act
        let result = FocusTimeFormatter.formatDailyDate(date)

        // Assert - Should contain the day number
        XCTAssertTrue(result.contains("25"))
    }

    // MARK: - weekdayAbbreviation Tests

    func testWeekdayAbbreviation_returnsNonEmptyString() {
        // Arrange
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 22
        let monday = calendar.date(from: components)!

        // Act
        let result = FocusTimeFormatter.weekdayAbbreviation(for: monday)

        // Assert
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - startOfWeek Tests

    func testStartOfWeek_returnsMonday() {
        // Arrange
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 25 // Thursday
        let thursday = calendar.date(from: components)!

        // Act
        let result = FocusTimeFormatter.startOfWeek(for: thursday)

        // Assert
        let weekday = calendar.component(.weekday, from: result)
        XCTAssertEqual(weekday, 2) // Monday is 2
    }

    func testStartOfWeek_whenGivenMonday_returnsSameMonday() {
        // Arrange
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 22 // Monday
        let monday = calendar.date(from: components)!

        // Act
        let result = FocusTimeFormatter.startOfWeek(for: monday)

        // Assert
        XCTAssertTrue(calendar.isDate(result, inSameDayAs: monday))
    }

    func testStartOfWeek_whenGivenSunday_returnsPreviousMonday() {
        // Arrange
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 28 // Sunday
        let sunday = calendar.date(from: components)!

        // Act
        let result = FocusTimeFormatter.startOfWeek(for: sunday)

        // Assert - Should return Jan 22 (Monday)
        let dayComponent = calendar.component(.day, from: result)
        XCTAssertEqual(dayComponent, 22)
    }
}
