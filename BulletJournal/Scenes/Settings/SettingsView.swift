//
//  SettingsView.swift
//  BulletJournal
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var presenter: SettingsPresenter
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var showLanguagePicker = false

    // MARK: - Initialization

    init(localizationManager: LocalizationManager) {
        let interactor = SettingsInteractor(localizationManager: localizationManager)
        _presenter = StateObject(wrappedValue: SettingsPresenter(interactor: interactor))
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                titleView
                languageCard
                generalSettingsCard
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .onAppear {
            presenter.loadSettings()
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            presenter.loadSettings()
        }
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerSheet
        }
    }

    // MARK: - Title

    private var titleView: some View {
        Text("settings.title")
            .font(.system(size: 32, weight: .bold))
            .foregroundStyle(AppColors.primaryText)
    }

    // MARK: - Language Card

    private var languageCard: some View {
        SettingsRowView(
            icon: "globe",
            title: "settings.language",
            value: presenter.viewModel.currentLanguageDisplay,
            showChevron: true
        ) {
            showLanguagePicker = true
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }

    // MARK: - General Settings Card

    private var generalSettingsCard: some View {
        VStack(spacing: 0) {
            appVersionRow
            settingsDivider
            privacyPolicyRow
            settingsDivider
            soundLicenseRow
            settingsDivider
            emailRow
        }
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }

    private var appVersionRow: some View {
        SettingsRowView(
            icon: "info.circle",
            title: "settings.appVersion",
            value: presenter.viewModel.appVersion
        )
    }

    private var privacyPolicyRow: some View {
        SettingsRowView(
            icon: "shield",
            title: "settings.privacyPolicy",
            showChevron: presenter.viewModel.isPrivacyPolicyAvailable,
            action: presenter.viewModel.isPrivacyPolicyAvailable ? { openPrivacyPolicy() } : nil
        )
    }

    private var soundLicenseRow: some View {
        NavigationLink(destination: SoundLicenseView()) {
            SettingsRowView(
                icon: "music.note",
                title: "settings.soundLicense",
                showChevron: true,
                asLabel: true
            )
        }
        .buttonStyle(.plain)
    }

    private var emailRow: some View {
        SettingsRowView(
            icon: "envelope",
            title: "settings.email",
            value: presenter.viewModel.contactEmail
        )
    }

    private var settingsDivider: some View {
        Divider()
            .background(AppColors.divider)
            .padding(.leading, SettingsRowView.dividerLeadingPadding)
    }

    // MARK: - Language Picker Sheet

    private var languagePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(SupportedLanguage.allCases) { language in
                    Button {
                        localizationManager.setLanguage(language)
                        showLanguagePicker = false
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .foregroundStyle(AppColors.primaryText)

                            Spacer()

                            if localizationManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.progressGreen)
                            }
                        }
                    }
                    .accessibilityLabel(Text(language.displayName))
                    .accessibilityAddTraits(localizationManager.currentLanguage == language ? .isSelected : [])
                }
            }
            .navigationTitle(Text("settings.language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLanguagePicker = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .accessibilityLabel(Text("accessibility.close"))
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func openPrivacyPolicy() {
        guard let url = Settings.Configuration.privacyPolicyURL else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview("Default") {
    SettingsView(localizationManager: .shared)
        .environmentObject(LocalizationManager.shared)
}

#Preview("Korean") {
    let manager = LocalizationManager.shared
    return SettingsView(localizationManager: manager)
        .environmentObject(manager)
        .environment(\.locale, Locale(identifier: "ko"))
}

#Preview("Japanese") {
    let manager = LocalizationManager.shared
    return SettingsView(localizationManager: manager)
        .environmentObject(manager)
        .environment(\.locale, Locale(identifier: "ja"))
}
