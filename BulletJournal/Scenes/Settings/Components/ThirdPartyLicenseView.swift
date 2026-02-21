//
//  ThirdPartyLicenseView.swift
//  BulletJournal
//

import SwiftUI

struct ThirdPartyLicenseView: View {
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
                ForEach(ThirdPartyLicenseInfo.all) { info in
                    licenseCard(info)
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationTitle(Text("thirdPartyLicense.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - License Card

    private func licenseCard(_ info: ThirdPartyLicenseInfo) -> some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            Text(info.libraryName)
                .font(.system(size: Layout.titleFontSize, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            infoRow(
                label: String(localized: "thirdPartyLicense.version"),
                value: info.version
            )

            infoRow(
                label: String(localized: "thirdPartyLicense.license"),
                value: info.license
            )

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
            Text(String(localized: "thirdPartyLicense.source"))
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
        ThirdPartyLicenseView()
    }
}
