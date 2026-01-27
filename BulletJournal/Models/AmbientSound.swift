//
//  AmbientSound.swift
//  BulletJournal
//

import Foundation

enum AmbientSound: String, CaseIterable, Identifiable, Codable, Sendable {
    case none
    case whiteNoise
    case rain
    case forest

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .none:
            return String(localized: "home.sound.none")
        case .whiteNoise:
            return String(localized: "home.sound.whiteNoise")
        case .rain:
            return String(localized: "home.sound.rain")
        case .forest:
            return String(localized: "home.sound.forest")
        }
    }

    var iconName: String {
        switch self {
        case .none:
            return "speaker.slash"
        case .whiteNoise:
            return "waveform"
        case .rain:
            return "cloud.rain"
        case .forest:
            return "leaf"
        }
    }

    var fileName: String? {
        switch self {
        case .none:
            return nil
        case .whiteNoise:
            return "white_noise"
        case .rain:
            return "rain"
        case .forest:
            return "forest"
        }
    }
}
