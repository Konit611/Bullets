//
//  SleepQualityDisplayCard.swift
//  BulletJournal
//

import SwiftUI

struct SleepQualityDisplayCard: View {
    let viewModel: DailyRecordDetail.SleepQualityViewModel

    private enum Layout {
        static let cardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let emojiSize: CGFloat = 36
    }

    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("dailyRecord.sleepQuality")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Emoji display (read-only)
            if let emoji = viewModel.emoji {
                Text(emoji)
                    .font(.system(size: Layout.emojiSize))
                    .frame(width: 56, height: 56)
                    .background(AppColors.emojiBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            } else {
                Text("dailyRecord.sleepQuality.notSet")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(height: 56)
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
}

#Preview("Side by Side") {
    HStack(spacing: 12) {
        SleepQualityDisplayCard(
            viewModel: DailyRecordDetail.SleepQualityViewModel(
                emoji: "☺️",
                isSet: true
            )
        )
        SleepQualityDisplayCard(
            viewModel: DailyRecordDetail.SleepQualityViewModel(
                emoji: nil,
                isSet: false
            )
        )
    }
    .padding()
    .background(AppColors.background)
}
