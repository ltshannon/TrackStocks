//
//  MyStocksListView.swift
//  TrackStocksWatch Watch App
//
//  Created by Larry Shannon on 1/29/26.
//

import SwiftUI

struct MyStocksListView: View {
    @Environment(StockManager.self) var stockManager
    @Environment(\.dismiss) var dismiss
    var body: some View {
        List(stockManager.stocks) { stock in
            Button {
                stockManager.selectedStock = stock
                dismiss()
            } label: {
                DisplayStockView(stock: stock)
            }
        }
    }
}

#Preview(traits: .mockData) {
    MyStocksListView()
}
