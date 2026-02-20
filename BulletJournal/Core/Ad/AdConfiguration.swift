//
//  AdConfiguration.swift
//  BulletJournal
//

import Foundation

enum AdConfiguration {
    // MARK: - Replace with your production Ad Unit ID from AdMob console
    private static let productionBannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"

    // MARK: - Google test Ad Unit ID (always shows test ads)
    private static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

    #if DEBUG
    static let bannerAdUnitID = testBannerAdUnitID
    #else
    static let bannerAdUnitID = productionBannerAdUnitID
    #endif
}
