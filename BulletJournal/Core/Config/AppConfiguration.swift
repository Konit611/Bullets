//
//  AppConfiguration.swift
//  BulletJournal
//

import Foundation

enum AppConfiguration {
    static let appGroupIdentifier = "group.com.geunil.BulletJournal"

    static var appGroupContainerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("App Group container not found for: \(appGroupIdentifier)")
        }
        return url
    }

    static var sharedStoreURL: URL {
        appGroupContainerURL.appendingPathComponent("BulletJournal.store")
    }
}
