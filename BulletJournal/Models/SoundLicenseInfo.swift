//
//  SoundLicenseInfo.swift
//  BulletJournal
//

import Foundation

struct SoundLicenseInfo: Identifiable {
    let id = UUID()
    let soundName: String
    let artist: String
    let license: String
    let sourceURL: URL?

    // TODO: 실제 저작권 정보로 교체
    static let all: [SoundLicenseInfo] = [
        SoundLicenseInfo(
            soundName: "White Noise",
            artist: "—",
            license: "—",
            sourceURL: nil
        ),
        SoundLicenseInfo(
            soundName: "Birds",
            artist: "—",
            license: "—",
            sourceURL: nil
        ),
        SoundLicenseInfo(
            soundName: "Night Forest",
            artist: "—",
            license: "—",
            sourceURL: nil
        ),
        SoundLicenseInfo(
            soundName: "Rain",
            artist: "—",
            license: "—",
            sourceURL: nil
        ),
    ]
}
