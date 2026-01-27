//
//  SettingsModels.swift
//  BulletJournal
//

import Foundation

enum Settings {
    // MARK: - Configuration
    enum Configuration {
        static let contactEmail = "konit611@gmail.com"
        static let privacyPolicyURL: URL? = nil // TODO: Set actual privacy policy URL
    }

    // MARK: - Load Settings
    enum LoadSettings {
        struct Response {
            let appVersion: String
            let currentLanguage: String
            let contactEmail: String
        }
    }

    // MARK: - ViewModels
    struct SettingsViewModel: Equatable {
        let appVersion: String
        let currentLanguageDisplay: String
        let contactEmail: String
        let isPrivacyPolicyAvailable: Bool

        static let initial = SettingsViewModel(
            appVersion: "",
            currentLanguageDisplay: "",
            contactEmail: "",
            isPrivacyPolicyAvailable: false
        )
    }
}
