//
//  CircularProgressView.swift
//  BulletJournal
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat

    private var animatedProgress: Double {
        min(max(progress, 0), 1)
    }

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 200
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AppColors.timerRingBackground,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AppColors.timerRing,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: animatedProgress)
        }
        .frame(width: size, height: size)
    }
}

#Preview("0%") {
    CircularProgressView(progress: 0)
        .padding()
        .background(AppColors.cardBackground)
}

#Preview("50%") {
    CircularProgressView(progress: 0.5)
        .padding()
        .background(AppColors.cardBackground)
}

#Preview("100%") {
    CircularProgressView(progress: 1.0)
        .padding()
        .background(AppColors.cardBackground)
}
