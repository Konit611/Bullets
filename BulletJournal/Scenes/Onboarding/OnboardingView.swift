//
//  OnboardingView.swift
//  BulletJournal
//

import SwiftUI

struct OnboardingView: View {
    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 30
        static let titleTopPadding: CGFloat = 186
        static let subtitleTopPadding: CGFloat = 24
        static let buttonBottomPadding: CGFloat = 88
        static let buttonHeight: CGFloat = 48
        static let buttonHorizontalPadding: CGFloat = 42
        static let buttonCornerRadius: CGFloat = 12
        static let titleFontSize: CGFloat = 48
        static let subtitleFontSize: CGFloat = 16
        static let buttonFontSize: CGFloat = 20
        static let lineSpacing: CGFloat = 8
    }

    // MARK: - Properties

    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background color
            AppColors.background
                .ignoresSafeArea()

            // Background illustration
            Image("onboarding_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(edges: .all)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                titleSection

                subtitleSection
                    .padding(.top, Layout.subtitleTopPadding)

                Spacer()

                startButton
                    .padding(.bottom, Layout.buttonBottomPadding)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.titleTopPadding)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Layout.lineSpacing) {
            Text("onboarding.title.line1")
                .font(.system(size: Layout.titleFontSize, weight: .thin))
                .foregroundStyle(AppColors.primaryText)

            Text("onboarding.title.line2")
                .font(.system(size: Layout.titleFontSize, weight: .thin))
                .foregroundStyle(AppColors.primaryText)

            Text("onboarding.title.line3")
                .font(.system(size: Layout.titleFontSize, weight: .semibold))
                .foregroundStyle(AppColors.onboardingAccent)
        }
    }

    // MARK: - Subtitle Section

    private var subtitleSection: some View {
        VStack(alignment: .leading, spacing: Layout.lineSpacing) {
            Text("onboarding.subtitle.line1")
                .font(.system(size: Layout.subtitleFontSize))
                .foregroundStyle(AppColors.secondaryText)

            Text("onboarding.subtitle.line2")
                .font(.system(size: Layout.subtitleFontSize))
                .foregroundStyle(AppColors.secondaryText)

            Text("onboarding.subtitle.line3")
                .font(.system(size: Layout.subtitleFontSize))
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: onComplete) {
            Text("onboarding.startButton")
                .font(.system(size: Layout.buttonFontSize, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.buttonHeight)
                .background(AppColors.focusCardCircle)
                .clipShape(RoundedRectangle(cornerRadius: Layout.buttonCornerRadius))
        }
        .padding(.horizontal, Layout.buttonHorizontalPadding - Layout.horizontalPadding)
        .accessibilityLabel(Text("onboarding.startButton"))
        .accessibilityHint(Text("onboarding.startButton.accessibility.hint"))
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
