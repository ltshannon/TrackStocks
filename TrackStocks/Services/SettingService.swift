//
//  SettingService.swift
//  Platinum
//
//  Created by Larry Shannon on 10/23/24.
//

import Foundation

enum DisplayStockState: String, Codable {
    case showActiveStocks
    case showAllStocks
    case showSoldStocks
}

class SettingsService: ObservableObject {
    static let shared = SettingsService()
    @Published var displayStocks: DisplayStockState = .showActiveStocks

    func setShowActiveStocks() {
        displayStocks = .showActiveStocks
    }
    
    func setShowAllStocks() {
        displayStocks = .showAllStocks
    }
    
    func setShowSoldStocks() {
        displayStocks = .showSoldStocks
    }
}
