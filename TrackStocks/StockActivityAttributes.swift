//
//  StockActivityAttributes.swift
//  TrackStocks
//
//  Created by Larry Shannon on 1/12/25.
//

import Foundation
import ActivityKit

struct StockActivityAttributes: ActivityAttributes {
    public typealias StockActivityStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var items: [ActivityData]
    }
}
