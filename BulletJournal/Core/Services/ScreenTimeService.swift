//
//  ScreenTimeService.swift
//  BulletJournal
//

import Foundation
import FamilyControls
import ManagedSettings
import os.log

// MARK: - Protocol for Testability

@MainActor
protocol ScreenTimeServiceProtocol: AnyObject {
    var authorizationStatus: ScreenTimeService.AuthorizationStatus { get }
    var isShieldActive: Bool { get }

    func requestAuthorization() async -> Bool
    func checkAuthorizationStatus()
    func enableFocusShield()
    func disableFocusShield()
    func cleanupOnTerminate()
}

// MARK: - Implementation

@MainActor
final class ScreenTimeService: ObservableObject, ScreenTimeServiceProtocol {

    // MARK: - Singleton

    static let shared = ScreenTimeService()

    // MARK: - Constants

    private enum Keys {
        static let isShieldActive = "ScreenTimeService.isShieldActive"
    }

    // MARK: - Published State

    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published private(set) var isShieldActive: Bool = false

    // MARK: - Private Properties

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BulletJournal", category: "ScreenTimeService")

    // MARK: - Types

    enum AuthorizationStatus: Equatable {
        case notDetermined
        case denied
        case approved
    }

    // MARK: - Initialization

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        checkAuthorizationStatus()
        recoverShieldStateIfNeeded()
    }

    // For testing
    init(userDefaults: UserDefaults, center: AuthorizationCenter? = nil) {
        self.userDefaults = userDefaults
        checkAuthorizationStatus()
        recoverShieldStateIfNeeded()
    }

    // MARK: - Authorization

    /// Screen Time 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = .approved
            logger.info("Screen Time authorization approved")
            return true
        } catch {
            authorizationStatus = .denied
            logger.error("Screen Time authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    /// 현재 권한 상태 확인
    func checkAuthorizationStatus() {
        switch center.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .denied:
            authorizationStatus = .denied
        case .approved:
            authorizationStatus = .approved
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    // MARK: - Shield Management

    /// 집중 모드 시작 - 다른 앱 차단
    func enableFocusShield() {
        guard authorizationStatus == .approved else {
            logger.warning("Cannot enable shield: authorization not approved")
            return
        }

        store.shield.applications = .all()
        store.shield.applicationCategories = .all()
        store.shield.webDomains = .all()

        isShieldActive = true
        persistShieldState(true)
        logger.info("Focus shield enabled")
    }

    /// 집중 모드 종료 - 차단 해제
    func disableFocusShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        isShieldActive = false
        persistShieldState(false)
        logger.info("Focus shield disabled")
    }

    /// 앱 종료 시 안전하게 Shield 해제
    func cleanupOnTerminate() {
        if isShieldActive {
            disableFocusShield()
        }
    }

    // MARK: - Private Methods

    private func persistShieldState(_ isActive: Bool) {
        userDefaults.set(isActive, forKey: Keys.isShieldActive)
    }

    private func recoverShieldStateIfNeeded() {
        let wasShieldActive = userDefaults.bool(forKey: Keys.isShieldActive)
        if wasShieldActive {
            // Shield was active when app terminated unexpectedly
            // Disable it to recover clean state
            logger.warning("Recovering from unexpected termination - disabling orphaned shield")
            disableFocusShield()
        }
    }
}
