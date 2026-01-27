//
//  SettingsPresenter.swift
//  BulletJournal
//

import Foundation
import Combine

@MainActor
final class SettingsPresenter: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var viewModel: Settings.SettingsViewModel = .initial

    // MARK: - Private Properties

    private let interactor: SettingsInteractorProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(interactor: SettingsInteractorProtocol) {
        self.interactor = interactor
        bindInteractor()
    }

    // MARK: - Public Methods

    func loadSettings() {
        interactor.loadSettings()
    }

    // MARK: - Private Methods

    private func bindInteractor() {
        interactor.settingsLoadedPublisher
            .sink { [weak self] response in
                self?.presentSettings(response)
            }
            .store(in: &cancellables)
    }

    private func presentSettings(_ response: Settings.LoadSettings.Response) {
        viewModel = Settings.SettingsViewModel(
            appVersion: response.appVersion,
            currentLanguageDisplay: response.currentLanguage,
            contactEmail: response.contactEmail,
            isPrivacyPolicyAvailable: Settings.Configuration.privacyPolicyURL != nil
        )
    }
}
