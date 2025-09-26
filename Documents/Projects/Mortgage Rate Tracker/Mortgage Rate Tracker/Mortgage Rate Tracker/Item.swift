//
//  Item.swift
//  Mortgage Rate Tracker
//
//  Created by Robert Wood on 9/25/25.
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
