//
//  StockDataService.swift
//  TrackStocks
//
//  Created by Larry Shannon on 10/31/24.
//

import Foundation
import SwiftUI
import SwiftData

struct StockData: Identifiable, Codable, Hashable {
    var id: String
    var name: String?
    var price: Double
    var changesPercentage: Float?
    var change: Double?
    var dayLow: Float?
    var dayHigh: Float?
    var yearLow: Float?
    var yearHigh: Float?
    var marketCap: Float?
    var priceAvg50: Float?
    var priceAvg200: Float?
    var exchange: String?
    var volume: Int?
    var avgVolume: Float?
    var open: Float?
    var previousClose: Float?
    var eps: Float?
    var pe: Float?
    var earningsAnnouncement: String?
    var sharesOutstanding: Float?
    var timestamp: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "symbol"
        case name
        case price
        case changesPercentage
        case change
        case dayLow
        case dayHigh
        case yearLow
        case yearHigh
        case marketCap
        case priceAvg50
        case priceAvg200
        case exchange
        case volume
        case avgVolume
        case open
        case previousClose
        case eps
        case pe
        case earningsAnnouncement
        case sharesOutstanding
        case timestamp
    }
}

struct SymbolData: Identifiable, Codable, Hashable {
    var id: String
    var name: String?
    var price: Float?
    var exchange: String?
    var exchangeShortName: String?
    var type: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "symbol"
        case name
        case price
        case exchange
        case exchangeShortName
        case type
    }
}

enum TimeFrame: String {
    case oneMin = "1min"
    case fiveMin = "5min"
    case fifteenMin = "15min"
    case thirtyMin = "30min"
    case oneHour = "1hour"
    case fourHour = "4hour"
}

struct MarketSymbols: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var symbol: String
    var name: String
    var price: Float
    var exchange: String
    var exchangeShortName: String
    var type: String
    
    init(id: String = UUID().uuidString, symbol: String, name: String, price: Float, exchange: String, exchangeShortName: String, type: String) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.price = price
        self.exchange = exchange
        self.exchangeShortName = exchangeShortName
        self.type = type
    }
}

@Model
class SymbolStorage {
    var symbol: String
    var name: String
    var price: Float
    var exchange: String
    var exchangeShortName: String
    var type: String
    
    init(symbol: String, name: String, price: Float, exchange: String, exchangeShortName: String, type: String) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.exchange = exchange
        self.exchangeShortName = exchangeShortName
        self.type = type
    }
}

struct FetchChartData: Codable, Hashable {
    var date: String
    var open: Double
    var low: Double
    var high: Double
    var close: Double
    var volume: Double
    
    init(date: String, open: Double, low: Double, high: Double, close: Double, volume: Double) {
        self.date = date
        self.open = open
        self.low = low
        self.high = high
        self.close = close
        self.volume = volume
    }
}

struct ChartData: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var date: Date
    var open: Double
    var low: Double
    var high: Double
    var close: Double
    var volume: Double
    
    init(date: Date, open: Double, low: Double, high: Double, close: Double, volume: Double) {
        self.date = date
        self.open = open
        self.low = low
        self.high = high
        self.close = close
        self.volume = volume
    }
}

class StockDataService: ObservableObject {
    static let shared = StockDataService()
    var settingService = SettingsService.shared
    
    func fetchFullQuoteStocks(tickers: String) async -> [StockData] {
        var url = ""
        
        if settingService.displayStocks != .showAfterHourPrice {
            url += "https://financialmodelingprep.com/api/v3/quote-order/"
        } else {
            url += "https://financialmodelingprep.com/api/v4/batch-pre-post-market-trade/"
        }
        
        do {
            let ticker = url + tickers + "?apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q"
            debugPrint("🥸", "fetchFullQuoteStocks url: \(ticker)")
            if let url = URL(string: ticker) {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                debugPrint("fetchFullQuoteStocks response: \(response.0)")
                let data = try JSONDecoder().decode([StockData].self, from: response.0)
                return data
            }
        }
        catch {
            debugPrint("fetchFullQuoteStocks error for tickers: \(tickers) error: \(error)")
        }
        return []
    }
    
    func fetchShortQuoteStocks(tickers: String) async -> [StockData] {
        var url = "https://financialmodelingprep.com/api/v3/"
        
        if settingService.displayStocks != .showAfterHourPrice {
            url += "quote-short/"
        } else {
            url += "batch-pre-post-market-trade/"
        }
        
        do {
            let ticker = url + tickers + "?apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q"
            debugPrint("🥸", "fetchShortQuoteStocks url: \(ticker)")
            if let url = URL(string: ticker) {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                debugPrint("fetchShortQuoteStocks response: \(response.0)")
                let data = try JSONDecoder().decode([StockData].self, from: response.0)
                return data
            }
        }
        catch {
            debugPrint("fetchShortQuoteStocks error for tickers: \(tickers) error: \(error)")
        }
        return []
    }
    
    func fetchSymbols() async -> [SymbolData] {
        do {
            if let url = URL(string: "https://financialmodelingprep.com/api/v3/stock/list?apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q") {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                debugPrint("response: \(response.0)")
                let data = try JSONDecoder().decode([SymbolData].self, from: response.0)
                return data
            }
        }
        catch {
            debugPrint("fetchSymbols error for fetchSymbols error: \(error)")
        }
        return []
    }
    
    func fetchChartData(symbol: String, timeFrame: TimeFrame) async -> (Double, Double, [ChartData]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        do {
//            var date = Date()
//            if let lastWeekDate = NSCalendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) {
//                date = lastWeekDate
//            }
//            var components = date.get(.day, .month, .year)
//            var strMonth = convertMonthToString(month: components.month ?? 1)
//            var strDay = convertDayToString(day: components.day ?? 1)
//            let startDate = "\(String(components.year ?? 1969))-\(strMonth)-\(strDay)"
            let components = Date().get(.day, .month, .year)
            let strMonth = convertMonthToString(month: components.month ?? 1)
            let strDay = convertDayToString(day: components.day ?? 1)
            let startDate = "\(String(components.year ?? 1969))-\(strMonth)-\(strDay)"
            let endDate = "\(String(components.year ?? 1969))-\(strMonth)-\(strDay)"
            let string = "https://financialmodelingprep.com/api/v3/historical-chart/" + timeFrame.rawValue + "/" + symbol + "?from=" + startDate + "&to=" + endDate + "&apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q"
            if let url = URL(string: string) {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                debugPrint("response: \(response.0)")
                let fetchChartData = try JSONDecoder().decode([FetchChartData].self, from: response.0)
                
                var low: Double = 0
                var high: Double = 0
                var firstTime = true
                var chartData = fetchChartData.map {
                    if firstTime == true {
                        low = $0.open
                        high = $0.open
                        firstTime = false
                    }
                    if $0.open < low { low = $0.open }
                    if $0.open > high { high = $0.open }
                    let date = dateFormatter.date(from: $0.date) ?? Date()
                    return ChartData(date: date, open: $0.open, low: $0.low, high: $0.high, close: $0.close, volume: $0.volume)
                }
                chartData = chartData.reversed()
                return (high, low, chartData)
            }
        } catch {
            debugPrint("fetchChartData error for Symbol \(symbol) error: \(error)")
        }
        return (0, 0, [])
    }
    
    func convertMonthToString(month: Int) -> String {
        var strMonth = String(month)
        if month < 10 {
            strMonth = "0" + strMonth
        }
        return strMonth
    }
    
    func convertDayToString(day: Int) -> String {
        var strDay = String(day)
        if day < 10 {
            strDay = "0" + strDay
        }
        return strDay
    }
    
}

class MarketSymbolsService: ObservableObject {
    static let shared = MarketSymbolsService()
    @Published var marketSymbols: [MarketSymbols] = []
    @AppStorage("stock-exchange-list") var stockExchangeList: [String] = ["NASDAQ", "NYSE", "AMEX", "OTC"]
    
    func makeList(symbolStorage: [SymbolStorage]) {
        var array: [MarketSymbols] = []
//        let set = Set(stockExchangeList)
        for item in symbolStorage {
//            if set.contains(item.exchange) {
            let marketSymbol = MarketSymbols(symbol: item.symbol, name: item.name, price: item.price, exchange: item.exchange, exchangeShortName: item.exchangeShortName, type: item.type)
                array.append(marketSymbol)
//            }
        }
        DispatchQueue.main.async {
            self.marketSymbols = array
        }
    }
}

