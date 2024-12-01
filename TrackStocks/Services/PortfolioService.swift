//
//  PortfolioService.swift
//  Platinum
//
//  Created by Larry Shannon on 6/20/24.
//

import Foundation
import SwiftUI

/*
struct ItemData: Identifiable, Encodable, Decodable, Hashable {
    var id: String = UUID().uuidString
    var firestoreId: String
    var symbol: String
    var basis: Float
    var price: Float
    var gainLose: Float
    var percent: Float
    var quantity: Double
    var dividend: [String]?
    var isSold: Bool
    var changesPercentage: Float?
    var change: Float?
    var dayLow: Float?
    var dayHigh: Float?
    var yearLow: Float?
    var yearHigh: Float?
    var marketCap: Int?
    var priceAvg50: Float?
    var priceAvg200: Float?
    var exchange: String?
    var volume: Int?
    var avgVolume: Int?
    var open: Float?
    var previousClose: Float?
    var eps: Float?
    var pe: Float?
    var earningsAnnouncement: String?
    var sharesOutstanding: Float?
    var timestamp: Int?
    var purchasedDate: String
    var soldDate: String
    var stockTag: String?
    var dividendList: [DividendDisplayData] = []
}

enum PortfolioType: String, CaseIterable, Identifiable, Encodable {
    case acceleratedProfits = "AcceleratedProfits"
    case breakthroughStocks =  "BreakthroughStocks"
    case eliteDividendPayers = "EliteDividendPayers"
    case growthInvestor = "GrowthInvestor"
    case buy = "Buy"
    case sell = "Sell"
    
    var id: String { return self.rawValue }
}

enum GrowthClubPortfolio: String, CaseIterable, Identifiable, Encodable {
    case accelerated = "Accelerated"
    case breakthrough = "Breakthrough"
    case dividend = "Dividend"
    case growth = "Growth"
    case buy = "Buy"
    case sell = "Sell"
    
    var id: String { return self.rawValue }
}

@MainActor
class PortfolioService: ObservableObject {
    static let shared = PortfolioService()
    var firebaseService = FirebaseService.shared
    var stockDataService = StockDataService()
    @Published var showingProgress = false
    
    func loadPortfolios() {
        Task { @MainActor in
            showingProgress = true
        }
    }
    
    func getPortfolio(portfolioName: String) async -> ([ItemData], Float, Float, [DividendDisplayData], Float, Float) {
        let settingService = SettingsService.shared
        let results = await firebaseService.getStockList(portfolioName: portfolioName)
        let data = await firebaseService.getPortfolioList(stockList: results.1, portfolioName: portfolioName, displayStockState: settingService.displayStocks)
        var items: [ItemData] = []
        for item in data {
            var value = ""
            if let symbol = item.symbol {
                value = symbol
            }
            var soldPrice:Float = 0.0
            var isSold = false
            if let value = item.price {
                soldPrice = value
                isSold = true
            }
            let temp = ItemData(firestoreId: item.id ?? "n/a", symbol: value, basis: item.basis, price: soldPrice, gainLose: 0, percent: 0, quantity: item.quantity, dividend: item.dividends, isSold: isSold, purchasedDate: item.purchasedDate, soldDate: item.soldDate, stockTag: item.stockTag ?? "None")
            items.append(temp)
        }
        
        var total: Float = 0
        var totalBasis: Float = 0
        var totalSold: Float = 0
        var totalNotSold: Float = 0
        var dividendList: [DividendDisplayData] = []
        var set: Set <String> = []
        for item in results.0 {
            if item.count <= 4 {
                set.insert(item)
            }
        }
        let list = Array(set)
        let string: String = list.joined(separator: ",")
        let stockData = await stockDataService.fetchStocks(tickers: string)
        for item in stockData {
            items.indices.forEach { index in
                if item.id == items[index].symbol {
                    var price: Float = items[index].price
                    if items[index].isSold == false {
                        price = Float(Double(item.price))
                        items[index].price = price
                    }
                    let value = price - items[index].basis
                    items[index].percent = value / items[index].basis
                    let gainLose = Float(items[index].quantity) * value
                    items[index].gainLose = gainLose
                    total += gainLose
                    if items[index].isSold == true {
                        totalSold += gainLose
                    } else {
                        totalNotSold += gainLose
                    }
                    totalBasis += items[index].basis * Float(items[index].quantity)
                    dividendList = []
                    if let dividends = items[index].dividend {
                        let _ = dividends.map {
                            let result = buildDividendList(array: $0, symbol: item.id)
                            dividendList.append(result.0)
                            items[index].gainLose += result.1
                        }
                    }
                    items[index].dividendList = dividendList
                    items[index].changesPercentage = item.changesPercentage != nil ? item.changesPercentage! / 100 : 0
                    items[index].change = item.change
                    items[index].dayLow = item.dayLow
                    items[index].dayHigh = item.dayHigh
                    items[index].yearLow = item.yearLow
                    items[index].yearHigh = item.yearHigh
                    items[index].marketCap = item.marketCap
                    items[index].priceAvg50 = item.priceAvg50
                    items[index].priceAvg200 = item.priceAvg200
                    items[index].exchange = item.exchange
                    items[index].volume = item.volume
                    items[index].avgVolume = item.avgVolume
                    items[index].open = item.open
                    items[index].previousClose = item.previousClose
                    items[index].eps = item.eps
                    items[index].pe = item.pe
                    items[index].earningsAnnouncement = item.earningsAnnouncement
                    items[index].sharesOutstanding = item.sharesOutstanding
                    items[index].timestamp = item.timestamp
                }
            }
        }
        
        return (items, total, totalBasis, dividendList, totalSold, totalNotSold)
    }
    
    func buildDividendList(array: String, symbol: String) -> (DividendDisplayData, Float) {
        var data = DividendDisplayData(date: "", price: "")
        var total: Float = 0
        let value = array.split(separator: ",")
        if value.count == 2 {
            data = DividendDisplayData(symbol: symbol, date: String(value[0]), price: String(value[1]))
            if let dec = Float(String(value[1])) {
                total += dec
            }
        }
        return (data, total)
    }
    
}
*/
