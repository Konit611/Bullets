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

    static let all: [SoundLicenseInfo] = [
        SoundLicenseInfo(
            soundName: "White Noise",
            artist: "Mixkit",
            license: "Mixkit Sound Effects Free License",
            sourceURL: URL(string: "https://mixkit.co/license/#sfxFree")
        ),
        SoundLicenseInfo(
            soundName: "Birds",
            artist: "Mixkit",
            license: "Mixkit Sound Effects Free License",
            sourceURL: URL(string: "https://mixkit.co/license/#sfxFree")
        ),
        SoundLicenseInfo(
            soundName: "Night Forest",
            artist: "Mixkit",
            license: "Mixkit Sound Effects Free License",
            sourceURL: URL(string: "https://mixkit.co/license/#sfxFree")
        ),
        SoundLicenseInfo(
            soundName: "Rain",
            artist: "Mixkit",
            license: "Mixkit Sound Effects Free License",
            sourceURL: URL(string: "https://mixkit.co/license/#sfxFree")
        ),
    ]
}
