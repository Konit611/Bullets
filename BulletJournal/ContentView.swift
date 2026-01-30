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
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var selectedTab: Tab = .home
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    enum Tab: Hashable {
        case home
        case dashboard
        case settings
    }

    var body: some View {
        ZStack {
            mainContent

            if showOnboarding {
                OnboardingView(onComplete: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                })
                .ignoresSafeArea(edges: .all)
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(modelContext: modelContext)
            }
            .tabItem {
                Label {
                    Text("tab.home")
                } icon: {
                    Image(systemName: "house.fill")
                }
            }
            .tag(Tab.home)

            DashboardView(modelContext: modelContext)
                .tabItem {
                    Label {
                        Text("tab.dashboard")
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                .tag(Tab.dashboard)

            NavigationStack {
                SettingsView(localizationManager: localizationManager)
            }
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

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, FocusTask.self, FocusSession.self, DailyRecord.self], inMemory: true)
        .environmentObject(LocalizationManager.shared)
}
