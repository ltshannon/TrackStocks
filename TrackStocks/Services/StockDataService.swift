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
    var open: Float
    var low: Float
    var high: Float
    var close: Float
    var volume: Float
    
    init(date: String, open: Float, low: Float, high: Float, close: Float, volume: Float) {
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
    var open: Float
    var low: Float
    var high: Float
    var close: Float
    var volume: Float
    
    init(date: Date, open: Float, low: Float, high: Float, close: Float, volume: Float) {
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
    
    func fetchFullQuoteStocks(tickers: String) async -> [StockData] {
        do {
            if let url = URL(string: "https://financialmodelingprep.com/api/v3/quote-order/" + tickers + "?apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q") {
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
        do {
            if let url = URL(string: "https://financialmodelingprep.com/api/v3/quote-short/" + tickers + "?apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q") {
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
    
    func fetchChartData(symbol: String) async -> [ChartData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        do {
            if let url = URL(string: "https://financialmodelingprep.com/api/v3/historical-chart/5min/" + symbol + "?from=2024-12-11&to=2024-12-11&apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q") {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                debugPrint("response: \(response.0)")
                let fetchChartData = try JSONDecoder().decode([FetchChartData].self, from: response.0)
                
                var chartData = fetchChartData.map {
                    let date = dateFormatter.date(from: $0.date) ?? Date()
                    return ChartData(date: date, open: $0.open, low: $0.low, high: $0.high, close: $0.close, volume: $0.volume)
                }
                chartData = chartData.reversed()
                return chartData
            }
        } catch {
            debugPrint("fetchChartData error for Symbol \(symbol) error: \(error)")
        }
        return []
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

extension Array: @retroactive RawRepresentable where Element: Codable {

    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else { return "" }
        return result
    }
}

