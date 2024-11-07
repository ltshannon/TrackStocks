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
    var name: String
    var price: Float
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

class StockDataService: ObservableObject {
    static let shared = StockDataService()
    
    func fetchStocks(tickers: String) async -> [StockData] {
        do {
            if let url = URL(string: "https://financialmodelingprep.com/api/v3/quote-order/" + tickers + "?apikey=ebsEkpswwWUGa5RgJG6YlMzG2lC0Tljf") {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                debugPrint("response: \(response.0)")
                let data = try JSONDecoder().decode([StockData].self, from: response.0)
                return data
            }
        }
        catch {
            debugPrint("StockDataService error for tickers: \(tickers) error: \(error)")
        }
        return []
    }
    
    func fetchSymbols() async -> [SymbolData] {
        do {
            if let url = URL(string: "https://financialmodelingprep.com/api/v3/stock/list?apikey=ebsEkpswwWUGa5RgJG6YlMzG2lC0Tljf") {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                debugPrint("response: \(response.0)")
                let data = try JSONDecoder().decode([SymbolData].self, from: response.0)
                return data
            }
        }
        catch {
            debugPrint("StockDataService error for fetchSymbols error: \(error)")
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

