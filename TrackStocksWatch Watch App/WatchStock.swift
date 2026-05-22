//
//  WatchStock.swift
//  TrackStocks
//
//  Created by Larry Shannon on 1/29/26.
//

import Foundation

struct WatchStock: Identifiable, Hashable, Codable {
    var symbol: String
    var price: Double  = 0.0
    var change: Double = 0.0
    var gainLose: Double
    var id: String { UUID().uuidString }
    
    static var mockStock: [WatchStock] {
        [
            WatchStock(symbol: "APP", price: 400.0, change: 10.0, gainLose: 100),
            WatchStock(symbol: "TSLA", price: 300.0, change: 20.0, gainLose: 100)
        ]
    }
}
