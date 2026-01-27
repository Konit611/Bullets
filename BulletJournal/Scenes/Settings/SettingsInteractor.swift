//
//  SettingsInteractor.swift
//  BulletJournal
//

import Foundation
import Combine

@MainActor
protocol SettingsInteractorProtocol: AnyObject {
    var settingsLoadedPublisher: AnyPublisher<Settings.LoadSettings.Response, Never> { get }
    func loadSettings()
}

@MainActor
final class SettingsInteractor: SettingsInteractorProtocol {

    // MARK: - Private Properties

    private let settingsLoadedSubject = PassthroughSubject<Settings.LoadSettings.Response, Never>()
    private let localizationManager: LocalizationManager

    // MARK: - Public Publishers

    var settingsLoadedPublisher: AnyPublisher<Settings.LoadSettings.Response, Never> {
        settingsLoadedSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init(localizationManager: LocalizationManager) {
        self.localizationManager = localizationManager
    }

    // MARK: - Public Methods

    func loadSettings() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let currentLanguage = localizationManager.currentLanguage.displayName

        let response = Settings.LoadSettings.Response(
            appVersion: appVersion,
            currentLanguage: currentLanguage,
            contactEmail: Settings.Configuration.contactEmail
        )

        settingsLoadedSubject.send(response)
    }
}
