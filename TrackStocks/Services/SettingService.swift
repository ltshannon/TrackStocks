//
//  SettingService.swift
//  Platinum
//
//  Created by Larry Shannon on 10/23/24.
//

import Foundation
import SwiftUI

enum DisplayStockState: String, Codable {
    case showActiveStocks
    case showAllStocks
    case showSoldStocks
    case showAfterHourPrice
}

class SettingsService: ObservableObject {
    static let shared = SettingsService()
    @Published var displayStocks: DisplayStockState = .showActiveStocks
    @AppStorage("displayStockState") var displayStockState: DisplayStockState = .showActiveStocks
    
    init() {
        self.displayStocks = displayStockState
    }

    func setShowActiveStocks() {
        displayStocks = .showActiveStocks
        displayStockState = .showActiveStocks
    }
    
    func setShowAllStocks() {
        displayStocks = .showAllStocks
        displayStockState = .showAllStocks
    }
    
    func setShowSoldStocks() {
        displayStocks = .showSoldStocks
        displayStockState = .showSoldStocks
    }
    
    func setShowAfterHourPrice() {
        displayStocks = .showAfterHourPrice
        displayStockState = .showAfterHourPrice
    }
}
