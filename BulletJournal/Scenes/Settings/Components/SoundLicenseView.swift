//
//  SoundLicenseView.swift
//  BulletJournal
//

import SwiftUI

struct SoundLicenseView: View {
    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 15
        static let cardPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 12
        static let titleFontSize: CGFloat = 16
        static let labelFontSize: CGFloat = 12
        static let valueFontSize: CGFloat = 14
        static let linkIconSize: CGFloat = 12
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Layout.cardSpacing) {
                ForEach(SoundLicenseInfo.all) { info in
                    soundCard(info)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationTitle(Text("soundLicense.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sound Card

    private func soundCard(_ info: SoundLicenseInfo) -> some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            // Sound name
            Text(info.soundName)
                .font(.system(size: Layout.titleFontSize, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            // Artist
            infoRow(
                label: String(localized: "soundLicense.artist"),
                value: info.artist
            )

            // License
            infoRow(
                label: String(localized: "soundLicense.license"),
                value: info.license
            )

            // Source link
            if let url = info.sourceURL {
                sourceLink(url)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.cardPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }

    // MARK: - Components

    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.labelSpacing) {
            Text(label)
                .font(.system(size: Layout.labelFontSize))
                .foregroundStyle(AppColors.secondaryText)

            Text(value)
                .font(.system(size: Layout.valueFontSize))
                .foregroundStyle(AppColors.primaryText)
        }
    }

    private func sourceLink(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: Layout.labelSpacing) {
            Text(String(localized: "soundLicense.source"))
                .font(.system(size: Layout.labelFontSize))
                .foregroundStyle(AppColors.secondaryText)

            Button {
                UIApplication.shared.open(url)
            } label: {
                HStack(spacing: 4) {
                    Text(url.host ?? url.absoluteString)
                        .font(.system(size: Layout.valueFontSize))
                        .lineLimit(1)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: Layout.linkIconSize))
                }
                .foregroundStyle(AppColors.progressGreen)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SoundLicenseView()
    }
}
