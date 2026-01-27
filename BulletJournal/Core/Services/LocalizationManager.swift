//
//  LocalizationManager.swift
//  BulletJournal
//

import SwiftUI
import Combine

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case system = ""
    case english = "en"
    case korean = "ko"
    case japanese = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return String(localized: "settings.language.system")
        case .english:
            return "English"
        case .korean:
            return "한국어"
        case .japanese:
            return "日本語"
        }
    }
}

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private let languageKey = "app_preferred_language"

    @Published private(set) var currentLanguage: SupportedLanguage

    private init() {
        let storedValue = UserDefaults.standard.string(forKey: languageKey) ?? ""
        self.currentLanguage = SupportedLanguage(rawValue: storedValue) ?? .system
    }

    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)

        if language == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }
    }

    var effectiveLocale: Locale {
        if currentLanguage == .system {
            return Locale.current
        } else {
            return Locale(identifier: currentLanguage.rawValue)
        }
    }
}
