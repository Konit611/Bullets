//
//  AppConfiguration.swift
//  BulletJournal
//

import Foundation

enum AppConfiguration {
    static let appGroupIdentifier = "group.com.geunil.BulletJournal"

    static var appGroupContainerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return url
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    static var sharedStoreURL: URL {
        appGroupContainerURL.appendingPathComponent("BulletJournal.store")
    }
}
