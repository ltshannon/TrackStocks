//
//  StockTrackingAttributes.swift
//  TrackStocks
//
//  Created by Larry Shannon on 1/8/25.
//

import Foundation
import ActivityKit

struct StockTrackingAttributes: ActivityAttributes {
    public typealias StockTrackingStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var items: [NotificationData]
    }
}
