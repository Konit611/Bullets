//
//  Item.swift
//  BulletJournal
//
//  Created by GEUNIL on 2026/01/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
