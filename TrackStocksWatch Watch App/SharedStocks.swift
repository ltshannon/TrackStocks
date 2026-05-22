//
//  SharedStocks.swift
//  TrackStocks
//
//  Created by Larry Shannon on 2/2/26.
//

import Foundation

class SharedStocks {
    static let defaultsGroup: UserDefaults? = UserDefaults(suiteName: "group.com.breakawaydesign.trackstocks")
    static var key = "stocks"
    
    static func update(stock: WatchStock?) {
        if let stock {
            if let stockData = try? JSONEncoder().encode(stock) {
                let stockJSON = String(data: stockData, encoding: .utf8)
                defaultsGroup?.set(stockJSON, forKey: key)
            }
        }
    }
    
    static func getStock() -> WatchStock? {
        if let stockJSON = defaultsGroup?.string(forKey: key) {
            let stockData = Data(stockJSON.utf8)
            return try? JSONDecoder().decode(WatchStock.self, from: stockData)
        }
        return nil
    }
}
