//
//  BulletJournalApp.swift
//  BulletJournal
//
//  Created by GEUNIL on 2026/01/26.
//

import SwiftUI
import SwiftData

@main
struct BulletJournalApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            FocusTask.self,
            FocusSession.self,
            DailyRecord.self,
        ])

        // Migrate existing DB to App Group if needed
        Self.migrateStoreIfNeeded()

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: AppConfiguration.sharedStoreURL,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private static func migrateStoreIfNeeded() {
        let fileManager = FileManager.default
        let destination = AppConfiguration.sharedStoreURL

        // Skip if App Group store already exists
        guard !fileManager.fileExists(atPath: destination.path) else { return }

        // Find default SwiftData store in Application Support
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let defaultStore = appSupport.appendingPathComponent("default.store")

        guard fileManager.fileExists(atPath: defaultStore.path) else { return }

        let suffixes = ["", "-wal", "-shm"]
        for suffix in suffixes {
            let srcPath = defaultStore.path + suffix
            let dstPath = destination.path + suffix

            guard fileManager.fileExists(atPath: srcPath) else { continue }
            do {
                try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
            } catch {
                // Migration failed for this file, continue
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, localizationManager.effectiveLocale)
                .environmentObject(localizationManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
