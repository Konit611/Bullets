//
//  AmbientSound.swift
//  BulletJournal
//

import Foundation

enum AmbientSound: String, CaseIterable, Identifiable, Codable, Sendable {
    case none
    case whiteNoise
    case birds
    case nightForest
    case rain

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .none:
            return String(localized: "home.sound.none")
        case .whiteNoise:
            return String(localized: "home.sound.whiteNoise")
        case .birds:
            return String(localized: "home.sound.birds")
        case .nightForest:
            return String(localized: "home.sound.nightForest")
        case .rain:
            return String(localized: "home.sound.rain")
        }
    }

    var iconName: String {
        switch self {
        case .none:
            return "speaker.slash"
        case .whiteNoise:
            return "waveform"
        case .birds:
            return "bird"
        case .nightForest:
            return "moon.stars"
        case .rain:
            return "cloud.rain"
        }
    }

    var fileName: String? {
        switch self {
        case .none:
            return nil
        case .whiteNoise:
            return "white_noise"
        case .birds:
            return "birds"
        case .nightForest:
            return "night_forest"
        case .rain:
            return "rain"
        }
    }
}
