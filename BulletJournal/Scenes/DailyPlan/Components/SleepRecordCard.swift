//
//  SleepRecordCard.swift
//  BulletJournal
//

import SwiftUI

struct SleepRecordCard: View {
    let viewModel: DailyPlan.SleepRecordViewModel
    @Binding var isExpanded: Bool
    @Binding var selectedBedTime: Date
    @Binding var selectedWakeTime: Date
    @Binding var selectedSleepQuality: String?
    let onSave: () -> Void
    let isEditable: Bool

    // MARK: - Layout Constants

    private enum Layout {
        static let cardPadding: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let chevronSize: CGFloat = 12
        static let summaryEmojiSize: CGFloat = 20
        static let selectionEmojiSize: CGFloat = 28
        static let spacing: CGFloat = 12
        static let expandedPadding: CGFloat = 20
        static let timePickerHeight: CGFloat = 44
        static let emojiSelectionSize: CGFloat = 44
    }


    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditable {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }
                }

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Layout.cardPadding)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: Layout.spacing) {
            // Moon icon
            ZStack {
                Circle()
                    .fill(AppColors.chevronBackground)
                    .frame(width: 40, height: 40)

                Image(systemName: "moon.fill")
                    .font(.system(size: Layout.iconSize))
                    .foregroundStyle(AppColors.primaryText)
            }

            // Title + Sleep summary (vertical)
            VStack(alignment: .leading, spacing: 4) {
                Text("dailyPlan.sleepRecord")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                if !isExpanded {
                    sleepSummary
                }
            }

            Spacer()

            // Chevron
            if isEditable {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: Layout.chevronSize, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }

    // MARK: - Sleep Summary (Collapsed)

    private var sleepSummary: some View {
        HStack(spacing: 4) {
            if viewModel.bedTime != nil || viewModel.wakeTime != nil {
                // "22:00 취침 | 07:00 기상 | ☺️" format
                Text("\(viewModel.bedTimeString) \(String(localized: "dailyPlan.bedTime"))")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)

                Text("|")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)

                Text("\(viewModel.wakeTimeString) \(String(localized: "dailyPlan.wakeTime"))")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)

                if let emoji = viewModel.sleepQualityEmoji {
                    Text("|")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.secondaryText)

                    Text(emoji)
                        .font(.system(size: Layout.summaryEmojiSize))
                }
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 20) {
            Divider()
                .padding(.top, 12)

            // Time Pickers Row
            HStack(spacing: 16) {
                // Bed Time
                timePickerSection(
                    title: String(localized: "dailyPlan.bedTime"),
                    time: $selectedBedTime
                )

                // Wake Time
                timePickerSection(
                    title: String(localized: "dailyPlan.wakeTime"),
                    time: $selectedWakeTime
                )
            }

            // Sleep Quality Row
            sleepQualitySection

            // Save Button
            Button(action: onSave) {
                Text("dailyPlan.save")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.top, 4)
        }
        .padding(.top, 4)
    }

    // MARK: - Time Picker Section

    private func timePickerSection(title: String, time: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)

            HStack {
                DatePicker(
                    "",
                    selection: time,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "clock")
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.timePickerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sleep Quality Section

    private var sleepQualitySection: some View {
        let isAlreadySet = viewModel.sleepQualityEmoji != nil

        return VStack(alignment: .leading, spacing: 8) {
            Text("dailyPlan.sleepQuality")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 8) {
                ForEach(DailyPlan.Configuration.sleepEmojis, id: \.self) { emoji in
                    Button {
                        guard !isAlreadySet else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedSleepQuality == emoji {
                                selectedSleepQuality = nil
                            } else {
                                selectedSleepQuality = emoji
                            }
                        }
                    } label: {
                        Text(emoji)
                            .font(.system(size: Layout.selectionEmojiSize))
                            .frame(width: Layout.emojiSelectionSize, height: Layout.emojiSelectionSize)
                            .background(
                                selectedSleepQuality == emoji
                                    ? AppColors.selectedEmojiBackground
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .opacity(isAlreadySet && selectedSleepQuality != emoji ? 0.4 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .disabled(isAlreadySet)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview("Collapsed - With Data") {
    SleepRecordCard(
        viewModel: DailyPlan.SleepRecordViewModel(
            bedTimeString: "22:00",
            wakeTimeString: "07:00",
            sleepQualityEmoji: "☺️",
            bedTime: Date(),
            wakeTime: Date()
        ),
        isExpanded: .constant(false),
        selectedBedTime: .constant(Date()),
        selectedWakeTime: .constant(Date()),
        selectedSleepQuality: .constant("☺️"),
        onSave: {},
        isEditable: true
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Expanded") {
    SleepRecordCard(
        viewModel: .empty,
        isExpanded: .constant(true),
        selectedBedTime: .constant(Date()),
        selectedWakeTime: .constant(Date()),
        selectedSleepQuality: .constant(nil),
        onSave: {},
        isEditable: true
    )
    .padding()
    .background(AppColors.background)
}
