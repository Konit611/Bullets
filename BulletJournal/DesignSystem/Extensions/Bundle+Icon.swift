//
//  Bundle+Icon.swift
//  BulletJournal
//

import UIKit

extension Bundle {
    var icon: UIImage? {
        guard let iconsDictionary = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcons = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcons["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last else {
            return nil
        }
        return UIImage(named: lastIcon)
    }
}
