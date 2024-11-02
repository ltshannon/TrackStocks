//
//  StockDataService.swift
//  TrackStocks
//
//  Created by Larry Shannon on 10/31/24.
//

import Foundation

struct StockData: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var price: Float
    var changePercentage: Float?
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
        case changePercentage
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

