//
//  CurrentTimeIndicator.swift
//  BulletJournal
//

import SwiftUI

struct CurrentTimeIndicator: View {
    let timeString: String

    // MARK: - Layout Constants

    private enum Layout {
        static let badgeCornerRadius: CGFloat = 4
        static let badgeHorizontalPadding: CGFloat = 6
        static let badgeVerticalPadding: CGFloat = 2
        static let lineHeight: CGFloat = 2
        static let fontSize: CGFloat = 12
    }


    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Time badge
            Text(timeString)
                .font(.system(size: Layout.fontSize, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Layout.badgeHorizontalPadding)
                .padding(.vertical, Layout.badgeVerticalPadding)
                .background(AppColors.currentTimeIndicator)
                .clipShape(RoundedRectangle(cornerRadius: Layout.badgeCornerRadius))

            // Horizontal line
            Rectangle()
                .fill(AppColors.currentTimeIndicator)
                .frame(height: Layout.lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        CurrentTimeIndicator(timeString: "10:30")

        CurrentTimeIndicator(timeString: "14:45")

        CurrentTimeIndicator(timeString: "09:00")
    }
    .padding()
    .background(AppColors.background)
}
