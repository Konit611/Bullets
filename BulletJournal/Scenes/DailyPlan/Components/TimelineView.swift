//
//  TimelineView.swift
//  BulletJournal
//

import SwiftUI

struct TimelineView: View {
    let rows: [DailyPlan.TimelineRowViewModel]
    let taskBlocks: [DailyPlan.TaskBlockViewModel]
    let currentTimePosition: CGFloat?
    let currentTimeString: String?
    let wakeHour: Int
    let bedHour: Int
    let onEmptySlotTapped: (Int, Int, Int, Int) -> Void  // (startHour, startMinute, endHour, endMinute)
    let onTaskTapped: (UUID) -> Void

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 10
        static let timeLabelWidth: CGFloat = 42
        static let lineLeadingPadding: CGFloat = 8
        static let hourHeight: CGFloat = 66
        static let lineHeight: CGFloat = 1
        static let taskLeadingOffset: CGFloat = 60
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background tap area for empty spaces
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            handleTap(at: value.location)
                        }
                )

            // Timeline rows (time labels + horizontal lines)
            timelineRowsView

            // Task blocks
            taskBlocksView

            // Current time indicator
            if let position = currentTimePosition, let timeString = currentTimeString {
                CurrentTimeIndicator(timeString: timeString)
                    .offset(y: position - 10) // Center the badge on the line
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(height: calculateTotalHeight(), alignment: .topLeading)
    }

    // MARK: - Tap Handling

    private func handleTap(at location: CGPoint) {
        // Check if tap is on a task block area (right side of timeline)
        guard location.x >= Layout.taskLeadingOffset else { return }

        // Check if tap is on an existing task block
        for block in taskBlocks {
            if location.y >= block.yPosition && location.y < block.yPosition + block.height {
                onTaskTapped(block.id)
                return
            }
        }

        // Calculate the tapped position in minutes from wake time
        let tappedMinutesFromWake = (location.y / Layout.hourHeight) * 60

        // Find the empty slot that contains this tap position
        let emptySlot = findEmptySlot(containingMinutesFromWake: tappedMinutesFromWake)

        onEmptySlotTapped(emptySlot.startHour, emptySlot.startMinute, emptySlot.endHour, emptySlot.endMinute)
    }

    private func findEmptySlot(containingMinutesFromWake: CGFloat) -> (startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        let tappedMinutes = Int(containingMinutesFromWake)

        // Snap to the hour boundary that contains the tap
        let tappedHourMinutes = (tappedMinutes / 60) * 60
        let proposedStartMinutes = tappedHourMinutes
        let proposedEndMinutes = tappedHourMinutes + 60

        // Timeline boundaries in minutes from wake
        let timelineEndMinutes = (bedHour - wakeHour) * 60

        // Clamp to timeline range
        let clampedStart = max(0, min(proposedStartMinutes, timelineEndMinutes))
        let clampedEnd = max(clampedStart, min(proposedEndMinutes, timelineEndMinutes))

        // Convert back to hours and minutes
        let startHour = wakeHour + clampedStart / 60
        let startMinute = clampedStart % 60
        let endHour = wakeHour + clampedEnd / 60
        let endMinute = clampedEnd % 60

        return (startHour, startMinute, endHour, endMinute)
    }

    // MARK: - Timeline Rows

    private var timelineRowsView: some View {
        ForEach(rows) { row in
            ZStack(alignment: .topLeading) {
                // Horizontal line - at the top of the row
                Rectangle()
                    .fill(AppColors.divider)
                    .frame(height: Layout.lineHeight)
                    .padding(.leading, Layout.timeLabelWidth + Layout.lineLeadingPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Time label - vertically centered on the line
                Text(row.timeLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(width: Layout.timeLabelWidth, alignment: .leading)
                    .offset(y: -6) // Center text on the line
            }
            .frame(height: Layout.hourHeight, alignment: .top)
            .frame(maxWidth: .infinity)
            .offset(y: row.yPosition)
        }
    }

    // MARK: - Task Blocks

    private var taskBlocksView: some View {
        ForEach(taskBlocks) { block in
            TaskBlockView(viewModel: block)
                .offset(x: Layout.taskLeadingOffset, y: block.yPosition)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Height Calculation

    private func calculateTotalHeight() -> CGFloat {
        guard let lastRow = rows.last else {
            // Default height based on configuration (wake to bed hours)
            let defaultHours = DailyPlan.Configuration.defaultTimelineEndHour - DailyPlan.Configuration.defaultWakeHour + 1
            return Layout.hourHeight * CGFloat(defaultHours)
        }
        return lastRow.yPosition + Layout.hourHeight
    }
}

// MARK: - Preview

#Preview {
    let wakeHour = DailyPlan.Configuration.defaultWakeHour
    let bedHour = DailyPlan.Configuration.defaultTimelineEndHour
    let hourHeight = DailyPlan.Configuration.hourHeight

    return ScrollView {
        TimelineView(
            rows: (wakeHour...bedHour).map { hour in
                DailyPlan.TimelineRowViewModel(
                    hour: hour,
                    timeLabel: String(format: "%02d:00", hour),
                    yPosition: CGFloat(hour - wakeHour) * hourHeight
                )
            },
            taskBlocks: [
                DailyPlan.TaskBlockViewModel(
                    id: UUID(),
                    title: "Morning Routine",
                    startTimeString: "07:00",
                    endTimeString: "08:30",
                    yPosition: 0,
                    height: hourHeight * 1.5,  // 1.5 hours
                    isCurrentTask: false,
                    progressPercentage: 0.5
                ),
                DailyPlan.TaskBlockViewModel(
                    id: UUID(),
                    title: "Work Session",
                    startTimeString: "09:00",
                    endTimeString: "12:00",
                    yPosition: hourHeight * 2,  // 2 hours from wake
                    height: hourHeight * 3,     // 3 hours duration
                    isCurrentTask: true,
                    progressPercentage: 0.3
                )
            ],
            currentTimePosition: hourHeight * 3.5,  // 10:30 (3.5 hours from 07:00)
            currentTimeString: "10:30",
            wakeHour: wakeHour,
            bedHour: bedHour,
            onEmptySlotTapped: { startHour, startMinute, endHour, endMinute in
                print("Empty slot: \(startHour):\(startMinute) - \(endHour):\(endMinute)")
            },
            onTaskTapped: { _ in }
        )
        .padding()
    }
    .background(AppColors.background)
}
