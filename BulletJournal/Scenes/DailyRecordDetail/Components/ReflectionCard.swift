//
//  ReflectionCard.swift
//  BulletJournal
//

import SwiftUI

struct ReflectionCard: View {
    let viewModel: DailyRecordDetail.ReflectionViewModel
    @Binding var text: String

    private enum Layout {
        static let cardPadding: CGFloat = 20
        static let cornerRadius: CGFloat = 12
        static let textEditorHeight: CGFloat = 120
        static let textEditorCornerRadius: CGFloat = 8
    }

    var body: some View {
        VStack(spacing: 12) {
            // Title and character count
            HStack {
                Text("dailyRecord.reflection")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                Text("\(text.count)/\(viewModel.maxLength)")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        text.count > viewModel.maxLength
                            ? AppColors.stopButton
                            : AppColors.secondaryText
                    )
            }

            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(height: Layout.textEditorHeight)
                    .padding(8)
                    .background(AppColors.chevronBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.textEditorCornerRadius))
                    .onChange(of: text) { _, newValue in
                        if newValue.count > viewModel.maxLength {
                            text = String(newValue.prefix(viewModel.maxLength))
                        }
                    }

                if text.isEmpty {
                    Text(viewModel.placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
}

#Preview("Empty") {
    ReflectionCard(
        viewModel: DailyRecordDetail.ReflectionViewModel(
            text: "",
            maxLength: 500,
            placeholder: "How was your day? Write a brief reflection..."
        ),
        text: .constant("")
    )
    .padding()
    .background(AppColors.background)
}

#Preview("With Text") {
    ReflectionCard(
        viewModel: DailyRecordDetail.ReflectionViewModel(
            text: "Today was productive. I managed to complete all my tasks and even had time for a short break.",
            maxLength: 500,
            placeholder: "How was your day? Write a brief reflection..."
        ),
        text: .constant("Today was productive. I managed to complete all my tasks and even had time for a short break.")
    )
    .padding()
    .background(AppColors.background)
}
