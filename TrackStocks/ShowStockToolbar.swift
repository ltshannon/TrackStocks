//
//  ShowStockToolbar.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/14/24.
//

import SwiftUI

struct ShowStockToolbar: ToolbarContent {
    @EnvironmentObject var settingsService: SettingsService
    var simpleDataDisplay = false
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    settingsService.setShowActiveStocks()
                } label: {
                    Label("Show Active Stocks", systemImage: settingsService.displayStocks == .showActiveStocks ? "checkmark.circle" : "circle")
                }
                Button {
                    settingsService.setShowAllStocks()
                } label: {
                    Label("Show All Stocks", systemImage: settingsService.displayStocks == .showAllStocks ? "checkmark.circle" : "circle")
                }
                Button {
                    settingsService.setShowSoldStocks()
                } label: {
                    Label("Show Sold Stocks", systemImage: settingsService.displayStocks == .showSoldStocks ? "checkmark.circle" : "circle")
                }
                Button {
                    settingsService.setShowAfterHourPrice()
                } label: {
                    Label("Show After Hour Price", systemImage: settingsService.displayStocks == .showAfterHourPrice ? "checkmark.circle" : "circle")
                }
                Button {
                    
                } label: {
                    Text("Cancel")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }
}
