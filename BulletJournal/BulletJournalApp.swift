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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, localizationManager.effectiveLocale)
                .environmentObject(localizationManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
