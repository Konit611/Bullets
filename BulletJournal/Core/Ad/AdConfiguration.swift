//
//  AdConfiguration.swift
//  BulletJournal
//

import Foundation

enum AdConfiguration {
    // MARK: - Google test Ad Unit ID (always shows test ads)
    private static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

    static var bannerAdUnitID: String {
        #if DEBUG
        return testBannerAdUnitID
        #else
        guard let adUnitID = Bundle.main.object(forInfoDictionaryKey: "AdMobBannerAdUnitID") as? String,
              !adUnitID.isEmpty,
              !adUnitID.contains("your-") else {
            return testBannerAdUnitID
        }
        return adUnitID
        #endif
    }
}
