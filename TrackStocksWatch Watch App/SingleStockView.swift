//
//  SingleStockView.swift
//  TrackStocksWatch Watch App
//
//  Created by Larry Shannon on 1/29/26.
//

import SwiftUI
import WidgetKit

struct SingleStockView: View {
    @Environment(StockManager.self) var stockManager
    var body: some View {
        if stockManager.selectedStock != nil {
            DisplayStockView(stock: stockManager.selectedStock!)
        }
    }
}

#Preview(traits: .mockData) {
    SingleStockView()
}
