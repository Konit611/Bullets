//
//  HomeInteractorTests.swift
//  BulletJournalTests
//

import XCTest
import SwiftData
import Combine
@testable import BulletJournal

@MainActor
final class HomeInteractorTests: XCTestCase {
    private var sut: HomeInteractor!
    private var mockTimerService: MockTimerService!
    private var mockAmbientSoundService: MockAmbientSoundService!
    private var mockNowPlayingService: MockNowPlayingService!
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
        mockNowPlayingService = MockNowPlayingService()

        sut = HomeInteractor(
            modelContext: modelContext,
            timerService: mockTimerService,
            ambientSoundService: mockAmbientSoundService,
            nowPlayingService: mockNowPlayingService
        )
    }

    override func tearDown() async throws {
        cancellables.removeAll()
        sut = nil
        mockTimerService = nil
        mockAmbientSoundService = nil
        mockNowPlayingService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - loadCurrentTask Tests

    func testLoadCurrentTask_whenTaskExistsInTimeSlot_setsCurrentTask() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()

        let expectation = XCTestExpectation(description: "Task loaded")
        var loadedTask: FocusTask?

        sut.taskLoadedPublisher
            .sink { response in
                loadedTask = response.task
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadCurrentTask()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(sut.currentTask)
        XCTAssertEqual(sut.currentTask?.id, task.id)
        XCTAssertNotNil(loadedTask)
    }

    func testLoadCurrentTask_whenNoTaskInTimeSlot_setsCurrentTaskToNil() {
        // Arrange
        let expectation = XCTestExpectation(description: "Task loaded")
        var loadedTask: FocusTask? = FocusTask(title: "placeholder", startTime: Date(), endTime: Date())

        sut.taskLoadedPublisher
            .sink { response in
                loadedTask = response.task
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.loadCurrentTask()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(sut.currentTask)
        XCTAssertNil(loadedTask)
    }

    // MARK: - handleTimerAction Tests

    func testHandleTimerAction_start_whenTaskExists_startsTimerAndCreatesSession() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()

        let loadExpectation = XCTestExpectation(description: "Task loaded")
        sut.taskLoadedPublisher
            .sink { _ in loadExpectation.fulfill() }
            .store(in: &cancellables)

        sut.loadCurrentTask()
        wait(for: [loadExpectation], timeout: 1.0)

        // Act
        sut.handleTimerAction(.start)

        // Assert
        XCTAssertEqual(mockTimerService.startCallCount, 1)
        XCTAssertNotNil(sut.currentSession)
    }

    func testHandleTimerAction_start_whenNoTask_publishesError() {
        // Arrange
        let expectation = XCTestExpectation(description: "Error received")
        var receivedError: AppError?

        sut.errorPublisher
            .sink { error in
                receivedError = error
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        sut.handleTimerAction(.start)

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockTimerService.startCallCount, 0)
        XCTAssertEqual(receivedError, .dataNotFound)
    }

    func testHandleTimerAction_pause_pausesTimerAndUpdatesSession() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()

        let loadExpectation = XCTestExpectation(description: "Task loaded")
        sut.taskLoadedPublisher
            .sink { _ in loadExpectation.fulfill() }
            .store(in: &cancellables)

        sut.loadCurrentTask()
        wait(for: [loadExpectation], timeout: 1.0)

        sut.handleTimerAction(.start)
        mockTimerService.setElapsedSeconds(120)

        // Act
        sut.handleTimerAction(.pause)

        // Assert
        XCTAssertEqual(mockTimerService.pauseCallCount, 1)
        XCTAssertEqual(sut.currentSession?.status, .paused)
    }

    func testHandleTimerAction_resume_resumesTimer() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()

        let loadExpectation = XCTestExpectation(description: "Task loaded")
        sut.taskLoadedPublisher
            .sink { _ in loadExpectation.fulfill() }
            .store(in: &cancellables)

        sut.loadCurrentTask()
        wait(for: [loadExpectation], timeout: 1.0)

        sut.handleTimerAction(.start)
        sut.handleTimerAction(.pause)

        // Act
        sut.handleTimerAction(.resume)

        // Assert
        XCTAssertEqual(mockTimerService.resumeCallCount, 1)
    }

    func testHandleTimerAction_stop_stopsTimerAndCompletesSession() {
        // Arrange
        let task = createTaskInCurrentTimeSlot()
        modelContext.insert(task)
        try? modelContext.save()

        let loadExpectation = XCTestExpectation(description: "Task loaded")
        sut.taskLoadedPublisher
            .sink { _ in loadExpectation.fulfill() }
            .store(in: &cancellables)

        sut.loadCurrentTask()
        wait(for: [loadExpectation], timeout: 1.0)

        sut.handleTimerAction(.start)
        mockTimerService.setElapsedSeconds(180)

        let session = sut.currentSession

        // Act
        sut.handleTimerAction(.stop)

        // Assert
        XCTAssertEqual(mockTimerService.stopCallCount, 1)
        XCTAssertNil(sut.currentSession)
        XCTAssertEqual(session?.status, .completed)
    }

    // MARK: - selectSound Tests

    func testSelectSound_playsSelectedSound() {
        // Act
        sut.selectSound(.whiteNoise)

        // Assert
        XCTAssertEqual(mockAmbientSoundService.playCallCount, 1)
        XCTAssertEqual(mockAmbientSoundService.lastPlayedSound, .whiteNoise)
    }

    // MARK: - switchTask Tests

    func testSwitchTask_whenTimerRunning_stopsTimerAndSwitchesToNewTask() {
        // Arrange
        let task1 = createTaskInCurrentTimeSlot(title: "Task 1")
        let task2 = createTaskInCurrentTimeSlot(title: "Task 2")
        modelContext.insert(task1)
        modelContext.insert(task2)
        try? modelContext.save()

        let loadExpectation = XCTestExpectation(description: "Task loaded")
        sut.taskLoadedPublisher
            .first()
            .sink { _ in loadExpectation.fulfill() }
            .store(in: &cancellables)

        sut.loadCurrentTask()
        wait(for: [loadExpectation], timeout: 1.0)

        sut.handleTimerAction(.start)

        // Act
        sut.switchTask(to: task2)

        // Assert
        XCTAssertEqual(mockTimerService.stopCallCount, 1)
        XCTAssertEqual(sut.currentTask?.id, task2.id)
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
