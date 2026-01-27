//
//  SleepQualityPromptView.swift
//  BulletJournal
//

import SwiftUI

struct SleepQualityPromptView: View {
    @Binding var isPresented: Bool
    let onSleepQualitySelected: (String) -> Void

    private let emojis = ["😩", "😑", "🙂", "☺️", "😆"]

    private enum Layout {
        static let emojiSize: CGFloat = 48
        static let emojiSpacing: CGFloat = 16
        static let cardPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 16
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("sleepQuality.title")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)

                Text("sleepQuality.subtitle")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Emoji Selection
            HStack(spacing: Layout.emojiSpacing) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        onSleepQualitySelected(emoji)
                        isPresented = false
                    } label: {
                        Text(emoji)
                            .font(.system(size: Layout.emojiSize))
                            .frame(width: 60, height: 60)
                            .background(AppColors.emojiBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: emoji))
                    .accessibilityHint(String(localized: "sleepQuality.accessibility.hint"))
                }
            }
        }
        .padding(Layout.cardPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private func accessibilityLabel(for emoji: String) -> String {
        switch emoji {
        case "😩":
            return String(localized: "sleepQuality.veryBad")
        case "😑":
            return String(localized: "sleepQuality.bad")
        case "🙂":
            return String(localized: "sleepQuality.okay")
        case "☺️":
            return String(localized: "sleepQuality.good")
        case "😆":
            return String(localized: "sleepQuality.veryGood")
        default:
            return emoji
        }
    }
}

#Preview {
    SleepQualityPromptView(
        isPresented: .constant(true),
        onSleepQualitySelected: { _ in }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
}
