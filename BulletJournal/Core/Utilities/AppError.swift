//
//  AppError.swift
//  BulletJournal
//

import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case dataNotFound
    case fetchFailed(String)
    case saveFailed(String)
    case timerAlreadyRunning
    case timerNotRunning
    case audioPlaybackFailed(String)
    case invalidTimeSlot
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return String(localized: "error.dataNotFound")
        case .fetchFailed(let detail):
            return String(localized: "error.fetchFailed \(detail)")
        case .saveFailed(let detail):
            return String(localized: "error.saveFailed \(detail)")
        case .timerAlreadyRunning:
            return String(localized: "error.timerAlreadyRunning")
        case .timerNotRunning:
            return String(localized: "error.timerNotRunning")
        case .audioPlaybackFailed(let detail):
            return String(localized: "error.audioPlaybackFailed \(detail)")
        case .invalidTimeSlot:
            return String(localized: "error.invalidTimeSlot")
        case .unknown(let detail):
            return String(localized: "error.unknown \(detail)")
        }
    }

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.dataNotFound, .dataNotFound):
            return true
        case (.fetchFailed(let l), .fetchFailed(let r)):
            return l == r
        case (.saveFailed(let l), .saveFailed(let r)):
            return l == r
        case (.timerAlreadyRunning, .timerAlreadyRunning):
            return true
        case (.timerNotRunning, .timerNotRunning):
            return true
        case (.audioPlaybackFailed(let l), .audioPlaybackFailed(let r)):
            return l == r
        case (.invalidTimeSlot, .invalidTimeSlot):
            return true
        case (.unknown(let l), .unknown(let r)):
            return l == r
        default:
            return false
        }
    }
}
