//
//  TotalFocusTimeCard.swift
//  BulletJournal
//

import SwiftUI

struct TotalFocusTimeCard: View {
    let viewModel: Dashboard.TotalFocusTimeViewModel

    var body: some View {
        Text(viewModel.displayString)
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(AppColors.dashboardGreen)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
}

#Preview("With Data") {
    TotalFocusTimeCard(
        viewModel: Dashboard.TotalFocusTimeViewModel(
            displayString: "1년 2개월 24일 20시간"
        )
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Empty") {
    TotalFocusTimeCard(viewModel: .empty)
        .padding()
        .background(AppColors.background)
}
