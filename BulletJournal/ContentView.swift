//
//  ContentView.swift
//  BulletJournal
//
//  Created by GEUNIL on 2026/01/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home

    enum Tab: Hashable {
        case home
        case dashboard
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(modelContext: modelContext)
                .tabItem {
                    Label {
                        Text("tab.home")
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }
                .tag(Tab.home)

            DashboardPlaceholderView()
                .tabItem {
                    Label {
                        Text("tab.dashboard")
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                .tag(Tab.dashboard)

            SettingsPlaceholderView()
                .tabItem {
                    Label {
                        Text("tab.settings")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                .tag(Tab.settings)
        }
        .tint(AppColors.primaryText)
    }
}

// MARK: - Placeholder Views

struct DashboardPlaceholderView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.secondaryText)

                Text("tab.dashboard")
                    .font(.title2)
                    .foregroundStyle(AppColors.primaryText)
            }
        }
    }
}

struct SettingsPlaceholderView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: Binding(
                        get: { localizationManager.currentLanguage },
                        set: { localizationManager.setLanguage($0) }
                    )) {
                        ForEach(SupportedLanguage.allCases) { language in
                            Text(language.displayName)
                                .tag(language)
                        }
                    } label: {
                        Label {
                            Text("settings.language")
                        } icon: {
                            Image(systemName: "globe")
                        }
                    }
                }
            }
            .navigationTitle(Text("tab.settings"))
            .background(AppColors.background)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, FocusTask.self, FocusSession.self], inMemory: true)
        .environmentObject(LocalizationManager.shared)
}
