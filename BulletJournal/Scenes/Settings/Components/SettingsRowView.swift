//
//  SettingsRowView.swift
//  BulletJournal
//

import SwiftUI

struct SettingsRowView: View {

    // MARK: - Layout Constants

    private enum Layout {
        static let iconSize: CGFloat = 18
        static let iconFrameSize: CGFloat = 40
        static let rowHeight: CGFloat = 60
        static let horizontalPadding: CGFloat = 20
        static let contentSpacing: CGFloat = 15
        static let chevronSize: CGFloat = 12
        static let valueTextSize: CGFloat = 12
        static let titleTextSize: CGFloat = 16
    }

    static let dividerLeadingPadding: CGFloat = Layout.horizontalPadding + Layout.iconFrameSize + Layout.contentSpacing

    // MARK: - Properties

    let icon: String
    let title: LocalizedStringKey
    let value: String?
    let showChevron: Bool
    let action: (() -> Void)?

    // MARK: - Initialization

    init(
        icon: String,
        title: LocalizedStringKey,
        value: String? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.showChevron = showChevron
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button {
            action?()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value ?? "")
        .accessibilityAddTraits(action != nil ? .isButton : [])
        .accessibilityHint(accessibilityHintText)
    }

    // MARK: - Private Views

    private var content: some View {
        HStack(spacing: Layout.contentSpacing) {
            iconView
            titleView
            Spacer()
            valueView
            chevronView
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(height: Layout.rowHeight)
        .contentShape(Rectangle())
    }

    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: Layout.iconSize))
            .foregroundStyle(AppColors.primaryText)
            .frame(width: Layout.iconFrameSize, height: Layout.iconFrameSize)
            .background(
                Circle()
                    .fill(AppColors.chevronBackground)
            )
    }

    private var titleView: some View {
        Text(title)
            .font(.system(size: Layout.titleTextSize, weight: .semibold))
            .foregroundStyle(AppColors.primaryText)
    }

    @ViewBuilder
    private var valueView: some View {
        if let value {
            Text(value)
                .font(.system(size: Layout.valueTextSize))
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    @ViewBuilder
    private var chevronView: some View {
        if showChevron {
            Image(systemName: "chevron.right")
                .font(.system(size: Layout.chevronSize, weight: .semibold))
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    // MARK: - Accessibility

    private var accessibilityHintText: Text {
        if action != nil && showChevron {
            return Text("accessibility.hint.tapToOpen")
        }
        return Text("")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        SettingsRowView(
            icon: "globe",
            title: "settings.language",
            value: "한국어",
            showChevron: true
        ) {
            print("Language tapped")
        }

        Divider()
            .padding(.leading, SettingsRowView.dividerLeadingPadding)

        SettingsRowView(
            icon: "info.circle",
            title: "settings.appVersion",
            value: "1.0.0"
        )

        Divider()
            .padding(.leading, SettingsRowView.dividerLeadingPadding)

        SettingsRowView(
            icon: "shield",
            title: "settings.privacyPolicy",
            showChevron: true
        ) {
            print("Privacy tapped")
        }

        Divider()
            .padding(.leading, SettingsRowView.dividerLeadingPadding)

        SettingsRowView(
            icon: "envelope",
            title: "settings.email",
            value: "konit611@gmail.com"
        )
    }
    .background(AppColors.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
    .background(AppColors.background)
}
