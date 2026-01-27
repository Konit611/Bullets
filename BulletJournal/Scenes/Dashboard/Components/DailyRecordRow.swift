//
//  DailyRecordRow.swift
//  BulletJournal
//

import SwiftUI

struct DailyRecordRow: View {
    let viewModel: Dashboard.DailyRecordViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.dateString)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.secondaryText)

                    HStack(spacing: 4) {
                        Text(viewModel.timeString)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)

                        Text("・")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.secondaryText)

                        Text(viewModel.percentageString)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                    }
                }

                Spacer()

                // Emoji badge
                Text(viewModel.emoji)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(AppColors.emojiBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(20)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("High Percentage") {
    DailyRecordRow(
        viewModel: Dashboard.DailyRecordViewModel(
            dateString: "1월 25일",
            timeString: "2h 30m",
            percentageString: "80%",
            emoji: "😆"
        ),
        onTap: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Medium Percentage") {
    DailyRecordRow(
        viewModel: Dashboard.DailyRecordViewModel(
            dateString: "1월 24일",
            timeString: "1h 30m",
            percentageString: "35%",
            emoji: "☺️"
        ),
        onTap: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Low Percentage") {
    DailyRecordRow(
        viewModel: Dashboard.DailyRecordViewModel(
            dateString: "1월 23일",
            timeString: "30m",
            percentageString: "10%",
            emoji: "😑"
        ),
        onTap: {}
    )
    .padding()
    .background(AppColors.background)
}
