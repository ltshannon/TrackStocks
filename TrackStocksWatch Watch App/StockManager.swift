//
//  StockManager.swift
//  TrackStocks
//
//  Created by Larry Shannon on 1/29/26.
//

import Foundation

@Observable
class StockManager {
    static let shared = StockManager()
    var stocks: [WatchStock] = []
    var selectedStock: WatchStock?
    
    func updateStocks(stocks: [WatchStock]) {
        self.stocks = stocks
        self.selectedStock = stocks.first
    }
    
}
