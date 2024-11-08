//
//  PortfolioService.swift
//  Platinum
//
//  Created by Larry Shannon on 6/20/24.
//

import Foundation
import SwiftUI

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
    var date: String
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
    
    func buildAStockList(listName: PortfolioType) async -> [StockData] {
        
        let value = await getStockList(listName: listName)
        let string: String = value.joined(separator: ",")
        let stocks = await stockDataService.fetchStocks(tickers: string)
        return stocks
    }
    
    func buildAllStocksList() async -> [StockData] {

        var list: [String] = []
        for item in PortfolioType.allCases {
            let value = await getStockList(listName: item)
            list += value
        }
        let string: String = list.joined(separator: ",")
        let stocks = await stockDataService.fetchStocks(tickers: string)
        return stocks
    }
    
    func getStockList(listName: PortfolioType) async -> [String] {
        
        let firebaseService = FirebaseService.shared
        var list: [String] = []
        
        let stockList = await firebaseService.getStockList(listName: listName.rawValue)

        for item in stockList {
            if let value = item.symbol {
                if list.contains(value) == false {
                    list.append(value)
                }
            } else {
                if let value = item.id, value.count <= 4 {
                    list.append(value)
                }
            }
        }
        return list
    }
    
    func getPortfolio(listName: String) async -> ([ItemData], Float, Float, [DividendDisplayData], Float) {
        
//        let a = await buildAllStocksList()
        let settingService = SettingsService.shared
        let stockList = await firebaseService.getStockList(listName: listName)
        let data = await firebaseService.getPortfolioList(stockList: stockList, listName: listName, displayStockState: settingService.displayStocks)
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
            let temp = ItemData(firestoreId: item.id ?? "n/a", symbol: value, basis: item.basis, price: soldPrice, gainLose: 0, percent: 0, quantity: item.quantity, dividend: item.dividend, isSold: isSold, date: item.date)
            items.append(temp)
        }
        
        var total: Float = 0
        var totalBasis: Float = 0
        let totalPercent: Float = 0
        var dividendList: [DividendDisplayData] = []
        var list: [String] = []
        for item in stockList {
            if let value = item.symbol, value.count <= 4 {
                list.append(value)
            }
        }
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
                    totalBasis += items[index].basis * Float(items[index].quantity)
                    if let dividends = items[index].dividend {
                        let _ = dividends.map {
                            let result = buildDividendList(array: $0, symbol: item.id)
                            dividendList.append(result.0)
                            items[index].gainLose += result.1
                        }
                    }
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
        
        return (items, total, totalBasis, dividendList, totalPercent)
    }
    
    func addSymbol(listName: String, symbol: String) async {
        
        await firebaseService.addSymbol(listName: listName, symbol: symbol)
    }
    
    func updateSymbol(listName: String, newSymbol: String, oldSymbol: String) async {
     
        await firebaseService.updateSymbol(listName: listName, oldSymbol: oldSymbol, newSymbol: newSymbol)
    }
    
    func deleteSymbol(listName: String, symbol: String) async {
        
        await firebaseService.deleteSymbol(listName: listName, symbol: symbol)
    }
    
    func addStock(listName: String, item: ItemData) async {
        
        await firebaseService.addItem(listName: listName, symbol: item.symbol, quantity: item.quantity, basis: item.basis, date: item.date)
    }
    
    func updateStock(firestoreId: String, listName: String, symbol: String, originalSymbol: String, quantity: Double, basis: String, date: Date) async {
        
        await firebaseService.updateItem(firestoreId: firestoreId, listName: listName, symbol: symbol, originalSymbol: originalSymbol, quantity: quantity, basis: basis, date: date)
    }
    
    func soldStock(firestoreId: String, listName: String, price: String) async  {
        
        await firebaseService.soldItem(firestoreId: firestoreId, listName: listName, price: price)
    }
    
    func deleteStock(listName: String, symbol: String) async {
        
        await firebaseService.deleteItem(portfolioName: listName, symbol: symbol)
    }
    
    func addDividend(listName: String, symbol: String, dividendDate: Date, dividendAmount: String) async {
        
        await firebaseService.addDividend(listName: listName, symbol: symbol, dividendDate: dividendDate, dividendAmount: dividendAmount)
    }
    
    func getDividend(key: PortfolioType, symbol: String) async {
        
        let array = await firebaseService.getDividend(listName: key.rawValue, symbol: symbol)
        var data: [DividendDisplayData] = []
        let _ = array.map {
            let value = $0.split(separator: ",")
            if value.count == 2 {
                if let dec = Float(String(value[1])) {
                    let item = DividendDisplayData(symbol: symbol, date: String(value[0]), price: dec)
                    data.append(item)
                }
            }
        }
        
        var dividendDisplayData: [DividendDisplayData] = []
//        switch key {
//        case .acceleratedProfits:
//            dividendDisplayData = acceleratedProfitsDividendList
//        case .breakthroughStocks:
//            dividendDisplayData = breakthroughDividendList
//        case .eliteDividendPayers:
//            dividendDisplayData = eliteDividendPayersDividendList
//        case .growthInvestor:
//            dividendDisplayData = growthInvestorDividendList
//        case .buy:
//            dividendDisplayData = buyDividendList
//        case .sell:
//            dividendDisplayData = sellDividendList
//        }
        
        var temp = dividendDisplayData.filter { $0.symbol != symbol }
        temp += data
        temp = temp.sorted { $0.symbol < $1.symbol }
        await MainActor.run {
            dividendDisplayData = temp
        }
    }

    func deleteDividend(listName: String, symbol: String, dividendDisplayData: DividendDisplayData) async {
        await firebaseService.deleteDividend(listName: listName, symbol: symbol, dividendDisplayData: dividendDisplayData)
    }
    
    func updateDividend(listName: String, symbol: String, dividendDisplayData: DividendDisplayData, dividendDate: Date, dividendAmount: String) async {
        
        await firebaseService.updateDividend(listName: listName, symbol: symbol, dividendDisplayData: dividendDisplayData, dividendAmount: dividendAmount, dividendDate: dividendDate)
    }
    
    func buildDividendList(array: String, symbol: String) -> (DividendDisplayData, Float) {
        var data = DividendDisplayData(date: "", price: 0)
        var total: Float = 0
        let value = array.split(separator: ",")
        if value.count == 2 {
            if let dec = Float(String(value[1])) {
                data = DividendDisplayData(symbol: symbol, date: String(value[0]), price: dec)
                total += dec
            }
        }
        return (data, total)
    }
    
    func computeDividendTotal(list: [DividendDisplayData]) -> Float {
        var total: Float = 0
        let _ = list.map {
            total += $0.price
        }
        return total
    }
    
    func getBasisForStockInPortfilio(portfolioType: PortfolioType, symbol: String) -> Float? {
        let list: [ItemData] = []
//        switch portfolioType {
//        case .acceleratedProfits:
//            list = acceleratedProfitsList;
//        case .breakthroughStocks:
//            list = breakthroughList
//        case .eliteDividendPayers:
//            list = eliteDividendPayersList
//        case.growthInvestor:
//            list = growthInvestorList
//        case.buy:
//            list = buyList
//        case.sell:
//            list = sellList
//        }
        let items = list.filter { $0.symbol == symbol }
        if let item = items.first {
            return item.basis
        }
        return nil
    }
    
}
