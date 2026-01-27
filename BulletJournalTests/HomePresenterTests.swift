//
//  HomePresenterTests.swift
//  BulletJournalTests
//

import XCTest
import SwiftData
import Combine
@testable import BulletJournal

@MainActor
final class HomePresenterTests: XCTestCase {
    private var sut: HomePresenter!
    private var interactor: HomeInteractor!
    private var mockTimerService: MockTimerService!
    private var mockAmbientSoundService: MockAmbientSoundService!
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

        mockTimerService = MockTimerService()
        mockAmbientSoundService = MockAmbientSoundService()

        interactor = HomeInteractor(
            modelContext: modelContext,
            timerService: mockTimerService,
            ambientSoundService: mockAmbientSoundService
        )

        sut = HomePresenter(interactor: interactor)
    }

    override func tearDown() async throws {
        cancellables.removeAll()
        sut = nil
        interactor = nil
        mockTimerService = nil
        mockAmbientSoundService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Task Loading Tests

    func testOnAppear_whenTaskExists_updatesTaskViewModel() {
        // Arrange
        let task = createTaskInCurrentTimeSlot(title: "Test Task")
        modelContext.insert(task)
        try? modelContext.save()

        let expectation = XCTestExpectation(description: "ViewModel updated")

        sut.$hasCurrentTask
            .dropFirst()
            .sink { hasTask in
                if hasTask {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        sut.onAppear()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(sut.hasCurrentTask)
        XCTAssertEqual(sut.taskViewModel.title, "Test Task")
    }

    func testOnAppear_whenNoTask_setsHasCurrentTaskToFalse() {
        // Arrange
        let expectation = XCTestExpectation(description: "ViewModel updated")

        sut.$taskViewModel
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.onAppear()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.hasCurrentTask)
        XCTAssertEqual(sut.taskViewModel, .empty)
    }

    // MARK: - Timer State Tests

    func testStartTimer_updatesTimerViewModelToRunning() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()
        sut.onAppear()

        let expectation = XCTestExpectation(description: "Timer state updated")

        sut.$timerViewModel
            .dropFirst()
            .sink { viewModel in
                if viewModel.state == .running {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        sut.startTimer()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.timerViewModel.state, .running)
    }

    func testPauseTimer_updatesTimerViewModelToPaused() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()
        sut.onAppear()
        sut.startTimer()

        let expectation = XCTestExpectation(description: "Timer paused")

        sut.$timerViewModel
            .dropFirst()
            .sink { viewModel in
                if viewModel.state == .paused {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        sut.pauseTimer()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.timerViewModel.state, .paused)
    }

    func testStopTimer_updatesTimerViewModelToIdle() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()
        sut.onAppear()
        sut.startTimer()

        let expectation = XCTestExpectation(description: "Timer stopped")

        sut.$timerViewModel
            .dropFirst()
            .sink { viewModel in
                if viewModel.state == .idle {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        sut.stopTimer()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.timerViewModel.state, .idle)
    }

    // MARK: - Timer Tick Tests

    func testTimerTick_updatesTimerDisplay() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()
        sut.onAppear()
        sut.startTimer()

        let expectation = XCTestExpectation(description: "Timer tick received")

        sut.$timerViewModel
            .dropFirst(2) // Skip initial and start state
            .sink { viewModel in
                if viewModel.timerDisplay == "00:05" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        mockTimerService.simulateTick(5)

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.timerViewModel.timerDisplay, "00:05")
    }

    // MARK: - Sound Selection Tests

    func testSelectSound_updatesSoundViewModel() {
        // Arrange
        let expectation = XCTestExpectation(description: "Sound updated")

        sut.$soundViewModel
            .dropFirst()
            .sink { viewModel in
                if viewModel.selectedSound == .rain {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        sut.selectSound(.rain)

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.soundViewModel.selectedSound, .rain)
        XCTAssertEqual(sut.soundViewModel.displayName, AmbientSound.rain.localizedName)
    }

    // MARK: - Error Handling Tests

    func testStartTimer_whenNoTask_setsError() {
        // Arrange
        let expectation = XCTestExpectation(description: "Error received")

        sut.$error
            .dropFirst()
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        sut.startTimer()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.error, .dataNotFound)
    }

    func testClearError_clearsError() {
        // Arrange
        sut.startTimer() // This will set an error since there's no task

        // Wait for error to be set
        let setExpectation = XCTestExpectation(description: "Error set")
        sut.$error
            .dropFirst()
            .sink { error in
                if error != nil {
                    setExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        wait(for: [setExpectation], timeout: 1.0)

        // Act
        sut.clearError()

        // Assert
        XCTAssertNil(sut.error)
    }

    // MARK: - Timer Display Formatting Tests

    func testTimerDisplay_formatsSecondsCorrectly() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()
        sut.onAppear()
        sut.startTimer()

        let testCases: [(Int, String)] = [
            (0, "00:00"),
            (59, "00:59"),
            (60, "01:00"),
            (125, "02:05"),
            (3599, "59:59"),
            (3600, "60:00"),
        ]

        for (seconds, expected) in testCases {
            let expectation = XCTestExpectation(description: "Timer display for \(seconds)")

            sut.$timerViewModel
                .dropFirst()
                .sink { viewModel in
                    if viewModel.timerDisplay == expected {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)

            // Act
            mockTimerService.simulateTick(seconds)

            // Assert
            wait(for: [expectation], timeout: 1.0)
            XCTAssertEqual(sut.timerViewModel.timerDisplay, expected, "Failed for \(seconds) seconds")

            cancellables.removeAll()
        }
    }

    // MARK: - User Actions Tests

    func testStartTimer_callsInteractorStart() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()
        sut.onAppear()

        // Act
        sut.startTimer()

        // Assert
        XCTAssertEqual(mockTimerService.startCallCount, 1)
    }

    func testPauseTimer_callsInteractorPause() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()
        sut.onAppear()
        sut.startTimer()

        // Act
        sut.pauseTimer()

        // Assert
        XCTAssertEqual(mockTimerService.pauseCallCount, 1)
    }

    func testSelectSound_callsInteractorSelectSound() {
        // Act
        sut.selectSound(.forest)

        // Assert
        XCTAssertEqual(mockAmbientSoundService.playCallCount, 1)
        XCTAssertEqual(mockAmbientSoundService.lastPlayedSound, .forest)
    }

    // MARK: - Helper Methods

    private func createTaskInCurrentTimeSlot(title: String = "Test Task") -> FocusTask {
        let now = Date()
        let calendar = Calendar.current
        let startTime = calendar.date(byAdding: .hour, value: -1, to: now)!
        let endTime = calendar.date(byAdding: .hour, value: 1, to: now)!

        return FocusTask(
            title: title,
            startTime: startTime,
            endTime: endTime
        )
    }
}
