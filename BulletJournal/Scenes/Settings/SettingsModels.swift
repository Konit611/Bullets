//
//  SettingsModels.swift
//  BulletJournal
//

import Foundation

enum Settings {
    // MARK: - Configuration
    enum Configuration {
        static let contactEmail = "konit611@gmail.com"

        static func privacyPolicyURL(for language: SupportedLanguage) -> URL? {
            let effectiveLanguage: String = {
                if language == .system {
                    return Locale.current.language.languageCode?.identifier ?? "en"
                }
                return language.rawValue
            }()

            switch effectiveLanguage {
            case "ko":
                return URL(string: "https://ripe-chicory-8d6.notion.site/Bullet-Journal-30da2833b7de80789ca1d774ca1d3032")
            case "ja":
                return URL(string: "https://ripe-chicory-8d6.notion.site/Bullet-Journal-30da2833b7de809994a2fd573ff70abd")
            default:
                return URL(string: "https://ripe-chicory-8d6.notion.site/Bullet-Journal-Privacy-Policy-30da2833b7de80c59541eab83878ef56")
            }
        }
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
