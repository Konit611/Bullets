//
//  TaskEditSheet.swift
//  BulletJournal
//

import SwiftUI

struct TaskEditSheet: View {
    @Binding var form: DailyPlan.TaskFormData
    let isEditing: Bool
    let onSave: () -> Void
    let onDelete: (() -> Void)?
    let hasConflict: (DailyPlan.TaskFormData) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var previousDuration: TimeInterval = 3600
    @FocusState private var isTitleFocused: Bool

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let verticalSpacing: CGFloat = 20
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 50
        static let inputCornerRadius: CGFloat = 8
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.verticalSpacing) {
                    taskTypeSection
                    titleSection
                    timeSection
                    if hasConflict(form) {
                        conflictWarning
                    }
                    actionButtons
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 20)
            }
            .background(AppColors.background)
            .navigationTitle(isEditing ? Text("dailyPlan.editTask") : Text("dailyPlan.newTask"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                    }
                    .accessibilityLabel(Text("accessibility.close"))
                }
            }
            .confirmationDialog(
                Text("dailyPlan.deleteConfirmTitle"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "dailyPlan.deleteTask"), role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button(String(localized: "dailyPlan.cancel"), role: .cancel) {}
            } message: {
                Text("dailyPlan.deleteConfirmMessage")
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            isTitleFocused = !isEditing
            previousDuration = form.endTime.timeIntervalSince(form.startTime)
        }
        .onChange(of: form.startTime) { oldValue, newValue in
            let duration = max(previousDuration, 5 * 60)
            var newEnd = newValue.addingTimeInterval(duration)
            newEnd = clampToSameDay(newEnd, referenceDate: newValue)
            newEnd = roundToNearest5Minutes(newEnd)
            form.endTime = newEnd
            previousDuration = form.endTime.timeIntervalSince(form.startTime)
        }
        .onChange(of: form.endTime) { oldValue, newValue in
            var endTime = clampToSameDay(newValue, referenceDate: form.startTime)
            endTime = roundToNearest5Minutes(endTime)
            if endTime != newValue {
                form.endTime = endTime
            }
            if endTime <= form.startTime {
                let duration = max(previousDuration, 5 * 60)
                let newStart = endTime.addingTimeInterval(-duration)
                form.startTime = roundToNearest5Minutes(newStart)
            }
            previousDuration = form.endTime.timeIntervalSince(form.startTime)
        }
    }

    // MARK: - Task Type Section

    private var taskTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("dailyPlan.taskType")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                taskTypeButton(
                    title: String(localized: "dailyPlan.taskType.focus"),
                    icon: "target",
                    isSelected: form.isFocusTask
                ) {
                    form.isFocusTask = true
                }

                taskTypeButton(
                    title: String(localized: "dailyPlan.taskType.general"),
                    icon: "calendar",
                    isSelected: !form.isFocusTask
                ) {
                    form.isFocusTask = false
                }
            }
        }
    }

    private func taskTypeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? AppColors.primaryText : AppColors.cardBackground)
            .foregroundStyle(isSelected ? .white : AppColors.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: Layout.inputCornerRadius))
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("dailyPlan.taskTitle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            TextField(
                String(localized: "dailyPlan.taskTitlePlaceholder"),
                text: $form.title
            )
            .font(.system(size: 16))
            .padding(12)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.inputCornerRadius))
            .focused($isTitleFocused)
        }
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(spacing: 16) {
            // Start Time
            HStack {
                Text("dailyPlan.startTime")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                DatePicker(
                    "",
                    selection: $form.startTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_GB"))
            }
            .padding(12)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.inputCornerRadius))

            // End Time
            HStack {
                Text("dailyPlan.endTime")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                DatePicker(
                    "",
                    selection: $form.endTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_GB"))
            }
            .padding(12)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.inputCornerRadius))
        }
    }

    // MARK: - Conflict Warning

    private var conflictWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text("dailyPlan.timeConflictWarning")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Layout.inputCornerRadius))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save Button
            Button(action: {
                onSave()
                dismiss()
            }) {
                Text("dailyPlan.save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.buttonHeight)
                    .background(form.isValid && !hasConflict(form) ? AppColors.primaryText : AppColors.secondaryText)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            }
            .disabled(!form.isValid || hasConflict(form))

            // Delete Button (only for editing)
            if isEditing, onDelete != nil {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("dailyPlan.deleteTask")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.stopButton)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.buttonHeight)
                        .background(AppColors.stopButton.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Time Helpers

    private func roundToNearest5Minutes(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let minute = components.minute else { return date }
        let rounded = (minute + 2) / 5 * 5
        var newComponents = components
        newComponents.minute = rounded
        newComponents.second = 0
        return calendar.date(from: newComponents) ?? date
    }

    private func clampToSameDay(_ date: Date, referenceDate: Date) -> Date {
        let calendar = Calendar.current
        let refDay = calendar.startOfDay(for: referenceDate)
        let dateDay = calendar.startOfDay(for: date)
        if dateDay > refDay {
            var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
            components.hour = 23
            components.minute = 55
            components.second = 0
            return calendar.date(from: components) ?? date
        }
        return date
    }
}

// MARK: - Preview

#Preview("New Task") {
    TaskEditSheet(
        form: .constant(DailyPlan.TaskFormData.empty(for: Date())),
        isEditing: false,
        onSave: {},
        onDelete: nil,
        hasConflict: { _ in false }
    )
}

#Preview("Edit Task") {
    TaskEditSheet(
        form: .constant(DailyPlan.TaskFormData(
            id: UUID(),
            title: "Work Session",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            isFocusTask: true
        )),
        isEditing: true,
        onSave: {},
        onDelete: {},
        hasConflict: { _ in false }
    )
}

#Preview("With Conflict") {
    TaskEditSheet(
        form: .constant(DailyPlan.TaskFormData(
            id: nil,
            title: "Conflicting Task",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            isFocusTask: false
        )),
        isEditing: false,
        onSave: {},
        onDelete: nil,
        hasConflict: { _ in true }
    )
}
