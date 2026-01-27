//
//  DashboardPresenterTests.swift
//  BulletJournalTests
//

import XCTest
import SwiftData
import Combine
@testable import BulletJournal

@MainActor
final class DashboardPresenterTests: XCTestCase {
    private var sut: DashboardPresenter!
    private var mockInteractor: MockDashboardInteractor!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() async throws {
        try await super.setUp()
        mockInteractor = MockDashboardInteractor()
        sut = DashboardPresenter(interactor: mockInteractor)
    }

    override func tearDown() async throws {
        cancellables.removeAll()
        sut = nil
        mockInteractor = nil
        try await super.tearDown()
    }

    // MARK: - Total Focus Time Formatting Tests

    func testOnAppear_callsInteractorLoadStatistics() {
        // Act
        sut.onAppear()

        // Assert
        XCTAssertEqual(mockInteractor.loadStatisticsCallCount, 1)
    }

    func testPresenter_updatesViewModelsOnStatisticsLoaded() {
        // Arrange
        let expectation = XCTestExpectation(description: "ViewModel updated")

        sut.$totalFocusTimeViewModel
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 3600,
            weeklyData: .empty,
            dailyRecords: []
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotEqual(sut.totalFocusTimeViewModel, .empty)
    }

    func testPresenter_withNoData_showsEmptyState() {
        // Arrange
        let expectation = XCTestExpectation(description: "ViewModel updated")

        sut.$totalFocusTimeViewModel
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 0,
            weeklyData: .empty,
            dailyRecords: []
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.totalFocusTimeViewModel.displayString, String(localized: "dashboard.noData"))
    }

    // MARK: - Weekly Chart Tests

    func testPresenter_weeklyChartHas7Bars() {
        // Arrange
        let expectation = XCTestExpectation(description: "Weekly chart updated")
        let weeklyData = Dashboard.WeeklyData(
            weekStartDate: Date(),
            dailyTotals: (0..<7).map { Dashboard.DayTotal(date: Date(), totalSeconds: $0 * 1000) }
        )

        sut.$weeklyChartViewModel
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 0,
            weeklyData: weeklyData,
            dailyRecords: []
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.weeklyChartViewModel.bars.count, 7)
    }

    func testPresenter_weeklyChartCalculatesHeightRatios() {
        // Arrange
        let expectation = XCTestExpectation(description: "Weekly chart updated")
        let weeklyData = Dashboard.WeeklyData(
            weekStartDate: Date(),
            dailyTotals: [
                Dashboard.DayTotal(date: Date(), totalSeconds: 7200),
                Dashboard.DayTotal(date: Date(), totalSeconds: 3600),
                Dashboard.DayTotal(date: Date(), totalSeconds: 0),
                Dashboard.DayTotal(date: Date(), totalSeconds: 0),
                Dashboard.DayTotal(date: Date(), totalSeconds: 0),
                Dashboard.DayTotal(date: Date(), totalSeconds: 0),
                Dashboard.DayTotal(date: Date(), totalSeconds: 0)
            ]
        )

        sut.$weeklyChartViewModel
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 0,
            weeklyData: weeklyData,
            dailyRecords: []
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)

        let maxBar = sut.weeklyChartViewModel.bars.max { $0.seconds < $1.seconds }
        XCTAssertEqual(maxBar?.heightRatio, 1.0, accuracy: 0.01)

        let halfBar = sut.weeklyChartViewModel.bars.first { $0.seconds == 3600 }
        XCTAssertEqual(halfBar?.heightRatio ?? 0, 0.5, accuracy: 0.01)
    }

    // MARK: - Daily Records Tests

    func testPresenter_mapsDailyRecordsCorrectly() {
        // Arrange
        let expectation = XCTestExpectation(description: "Records updated")
        let records = [
            Dashboard.DailyRecord(
                date: Date(),
                totalFocusSeconds: 3600,
                totalPlannedSeconds: 7200
            )
        ]

        sut.$dailyRecordViewModels
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 0,
            weeklyData: .empty,
            dailyRecords: records
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.dailyRecordViewModels.count, 1)
        XCTAssertEqual(sut.dailyRecordViewModels.first?.percentageString, "50%")
    }

    // MARK: - Emoji Logic Tests

    func testPresenter_emojiForLowPercentage() {
        // Arrange
        let expectation = XCTestExpectation(description: "Records updated")
        let records = [
            Dashboard.DailyRecord(
                date: Date(),
                totalFocusSeconds: 1000,
                totalPlannedSeconds: 10000 // 10%
            )
        ]

        sut.$dailyRecordViewModels
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 0,
            weeklyData: .empty,
            dailyRecords: records
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.dailyRecordViewModels.first?.emoji, "😑")
    }

    func testPresenter_emojiForMediumPercentage() {
        // Arrange
        let expectation = XCTestExpectation(description: "Records updated")
        let records = [
            Dashboard.DailyRecord(
                date: Date(),
                totalFocusSeconds: 3500,
                totalPlannedSeconds: 10000 // 35%
            )
        ]

        sut.$dailyRecordViewModels
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 0,
            weeklyData: .empty,
            dailyRecords: records
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.dailyRecordViewModels.first?.emoji, "☺️")
    }

    func testPresenter_emojiForHighPercentage() {
        // Arrange
        let expectation = XCTestExpectation(description: "Records updated")
        let records = [
            Dashboard.DailyRecord(
                date: Date(),
                totalFocusSeconds: 7500,
                totalPlannedSeconds: 10000 // 75%
            )
        ]

        sut.$dailyRecordViewModels
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        mockInteractor.simulateStatisticsLoaded(
            totalSeconds: 0,
            weeklyData: .empty,
            dailyRecords: records
        )

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.dailyRecordViewModels.first?.emoji, "😆")
    }
}

// MARK: - Mock Interactor

@MainActor
final class MockDashboardInteractor: DashboardInteractorProtocol {
    private let statisticsLoadedSubject = PassthroughSubject<Dashboard.LoadStatistics.Response, Never>()

    var statisticsLoadedPublisher: AnyPublisher<Dashboard.LoadStatistics.Response, Never> {
        statisticsLoadedSubject.eraseToAnyPublisher()
    }

    private(set) var loadStatisticsCallCount = 0

    func loadStatistics() {
        loadStatisticsCallCount += 1
    }

    func simulateStatisticsLoaded(
        totalSeconds: Int,
        weeklyData: Dashboard.WeeklyData,
        dailyRecords: [Dashboard.DailyRecord]
    ) {
        let response = Dashboard.LoadStatistics.Response(
            totalFocusSeconds: totalSeconds,
            weeklyData: weeklyData,
            dailyRecords: dailyRecords
        )
        statisticsLoadedSubject.send(response)
    }
}
