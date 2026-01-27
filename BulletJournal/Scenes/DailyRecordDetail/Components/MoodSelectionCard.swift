//
//  MoodSelectionCard.swift
//  BulletJournal
//

import SwiftUI

struct MoodSelectionCard: View {
    @Binding var selectedEmoji: String?
    let onSelect: (String) -> Void

    private let availableEmojis = DailyRecordDetail.Configuration.moodEmojis

    private enum Layout {
        static let cardPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 12
        static let emojiSize: CGFloat = 40
        static let emojiSpacing: CGFloat = 12
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("dailyRecord.todayMood")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Emoji selection (editable)
            HStack(spacing: Layout.emojiSpacing) {
                ForEach(availableEmojis, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: Layout.emojiSize))
                            .frame(width: 56, height: 56)
                            .background(
                                selectedEmoji == emoji
                                    ? AppColors.progressGreen.opacity(0.3)
                                    : AppColors.emojiBackground
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        selectedEmoji == emoji
                                            ? AppColors.progressGreen
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: emoji))
                    .accessibilityAddTraits(selectedEmoji == emoji ? .isSelected : [])
                }
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }

    private func accessibilityLabel(for emoji: String) -> String {
        switch emoji {
        case "😩":
            return String(localized: "mood.veryBad")
        case "😑":
            return String(localized: "mood.bad")
        case "🙂":
            return String(localized: "mood.okay")
        case "☺️":
            return String(localized: "mood.good")
        case "😆":
            return String(localized: "mood.veryGood")
        default:
            return emoji
        }
    }
}

#Preview("Selected") {
    MoodSelectionCard(
        selectedEmoji: .constant("☺️"),
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.background)
}

#Preview("None Selected") {
    MoodSelectionCard(
        selectedEmoji: .constant(nil),
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.background)
}
