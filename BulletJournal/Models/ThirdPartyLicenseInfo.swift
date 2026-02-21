//
//  ThirdPartyLicenseInfo.swift
//  BulletJournal
//

import Foundation

struct ThirdPartyLicenseInfo: Identifiable {
    let id = UUID()
    let libraryName: String
    let version: String
    let license: String
    let sourceURL: URL?

    static let all: [ThirdPartyLicenseInfo] = [
        ThirdPartyLicenseInfo(
            libraryName: "Google Mobile Ads SDK",
            version: "11.x",
            license: "Apache License 2.0",
            sourceURL: URL(string: "https://github.com/googleads/swift-package-manager-google-mobile-ads")
        ),
    ]
}
