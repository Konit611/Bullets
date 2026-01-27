//
//  DashboardInteractorTests.swift
//  BulletJournalTests
//

import XCTest
import SwiftData
import Combine
@testable import BulletJournal

@MainActor
final class DashboardInteractorTests: XCTestCase {
    private var sut: DashboardInteractor!
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() async throws {
        try await super.setUp()

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: FocusTask.self, FocusSession.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)

        sut = DashboardInteractor(modelContext: modelContext)
    }

    override func tearDown() async throws {
        cancellables.removeAll()
        sut = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Total Focus Time Tests

    func testLoadStatistics_calculatesCorrectTotalTime() {
        // Arrange
        let session1 = createCompletedSession(elapsedSeconds: 3600)
        let session2 = createCompletedSession(elapsedSeconds: 1800)
        let session3 = createCompletedSession(elapsedSeconds: 900)
        modelContext.insert(session1)
        modelContext.insert(session2)
        modelContext.insert(session3)
        try? modelContext.save()

        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedResponse?.totalFocusSeconds, 6300)
    }

    func testLoadStatistics_excludesInProgressSessions() {
        // Arrange
        let completedSession = createCompletedSession(elapsedSeconds: 3600)
        let inProgressSession = FocusSession(
            startedAt: Date(),
            elapsedSeconds: 1800,
            status: .inProgress
        )
        modelContext.insert(completedSession)
        modelContext.insert(inProgressSession)
        try? modelContext.save()

        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedResponse?.totalFocusSeconds, 3600)
    }

    func testLoadStatistics_emptyData_returnsZeroTotalTime() {
        // Arrange
        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedResponse?.totalFocusSeconds, 0)
    }

    // MARK: - Weekly Data Tests

    func testLoadStatistics_weeklyDataStartsOnMonday() {
        // Arrange
        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)

        guard let weekStart = receivedResponse?.weeklyData.weekStartDate else {
            XCTFail("Week start date should exist")
            return
        }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: weekStart)
        XCTAssertEqual(weekday, 2, "Week should start on Monday (weekday = 2)")
    }

    func testLoadStatistics_weeklyDataHas7Days() {
        // Arrange
        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedResponse?.weeklyData.dailyTotals.count, 7)
    }

    func testLoadStatistics_weeklyDataGroupsSessionsByDay() {
        // Arrange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let session1 = createCompletedSession(elapsedSeconds: 1800, startedAt: today)
        let session2 = createCompletedSession(
            elapsedSeconds: 1200,
            startedAt: calendar.date(byAdding: .hour, value: 2, to: today)!
        )
        modelContext.insert(session1)
        modelContext.insert(session2)
        try? modelContext.save()

        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)

        let todayTotal = receivedResponse?.weeklyData.dailyTotals
            .first { calendar.isDate($0.date, inSameDayAs: today) }

        XCTAssertEqual(todayTotal?.totalSeconds, 3000)
    }

    // MARK: - Daily Records Tests

    func testLoadStatistics_dailyRecordsGroupedByDay() {
        // Arrange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let todayTask = FocusTask(
            title: "Today",
            startTime: today,
            endTime: calendar.date(byAdding: .hour, value: 8, to: today)!
        )
        let todaySession = createCompletedSession(elapsedSeconds: 3600, startedAt: today)
        todayTask.focusSessions.append(todaySession)

        let yesterdayTask = FocusTask(
            title: "Yesterday",
            startTime: yesterday,
            endTime: calendar.date(byAdding: .hour, value: 8, to: yesterday)!
        )
        let yesterdaySession = createCompletedSession(elapsedSeconds: 7200, startedAt: yesterday)
        yesterdayTask.focusSessions.append(yesterdaySession)

        modelContext.insert(todayTask)
        modelContext.insert(todaySession)
        modelContext.insert(yesterdayTask)
        modelContext.insert(yesterdaySession)
        try? modelContext.save()

        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)

        let records = receivedResponse?.dailyRecords ?? []
        XCTAssertGreaterThanOrEqual(records.count, 2)

        if records.count >= 2 {
            XCTAssertTrue(records[0].date > records[1].date)
        }
    }

    func testLoadStatistics_dailyRecordCalculatesPercentageCorrectly() {
        // Arrange
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let task = FocusTask(
            title: "Test",
            startTime: today,
            endTime: calendar.date(byAdding: .hour, value: 8, to: today)!
        )
        let session = createCompletedSession(elapsedSeconds: 7200, startedAt: today)
        task.focusSessions.append(session)

        modelContext.insert(task)
        modelContext.insert(session)
        try? modelContext.save()

        let expectation = XCTestExpectation(description: "Statistics loaded")
        var receivedResponse: Dashboard.LoadStatistics.Response?

        sut.statisticsLoadedPublisher
            .sink { response in
                receivedResponse = response
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadStatistics()

        // Assert
        wait(for: [expectation], timeout: 1.0)

        let todayRecord = receivedResponse?.dailyRecords
            .first { calendar.isDate($0.date, inSameDayAs: today) }

        XCTAssertNotNil(todayRecord)
        XCTAssertEqual(todayRecord?.completionPercentage ?? 0, 0.25, accuracy: 0.01)
    }

    // MARK: - Helper Methods

    private func createCompletedSession(
        elapsedSeconds: Int,
        startedAt: Date = Date()
    ) -> FocusSession {
        FocusSession(
            startedAt: startedAt,
            endedAt: Date(),
            elapsedSeconds: elapsedSeconds,
            status: .completed
        )
    }
}
