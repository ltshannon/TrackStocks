//
//  PortfolioDetailInfoView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/2/24.
//

import SwiftUI

struct PortfolioDetailInfoView: View {
    var item: ItemData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Bought: \(item.purchasedDate)")
                Text("Sold: \(item.soldDate)")
                Text("")
            }
            .font(.caption)
            VStack(alignment: .leading) {
                HStack {
                    Text("Open")
                    Text(item.open != nil ? String(format: "%.2f", item.open!) : "n/a")
                }
                HStack {
                    Text("High")
                    Text(item.dayHigh != nil ? String(format: "%.2f", item.dayHigh!) : "n/a")
                }
                HStack {
                    Text("Low")
                    Text(item.dayLow != nil ? String(format: "%.2f", item.dayLow!) : "n/a")
                }
            }
            .font(.caption)
            VStack(alignment: .leading) {
                HStack {
                    Text("52W H")
                    Text(item.yearHigh != nil ? String(format: "%.2f", item.yearHigh!) : "n/a")
                }
                HStack {
                    Text("52W L")
                    Text(item.yearLow != nil ? String(format: "%.2f", item.yearLow!) : "n/a")
                }
                HStack {
                    Text("Avg Vol")
                    Text(item.avgVolume != nil ? String(format: "%.2f", item.avgVolume!) : "n/a")
                }
            }
            .font(.caption)
            VStack(alignment: .leading) {
                HStack {
                    Text("Vol")
                    Text(item.volume != nil ? String(format: "%.2f", item.volume!) : "n/a")
                }
                HStack {
                    Text("P/E")
                    Text(item.pe != nil ? String(format: "%.2f", item.pe!) : "n/a")
                }
                HStack {
                    Text("Mkt Cap")
                    Text(item.marketCap != nil ? String(format: "%.2f", item.marketCap!) : "n/a")
                }
            }
            .font(.caption)
            Spacer()
        }
    }
}

#Preview {
    PortfolioBasicInfoView(item: ItemData(firestoreId: "", symbol: "IBM", basis: 0, price: 0, gainLose: 0, percent: 0, quantity: 0, isSold: false, change: 1, purchasedDate: "12/12/24", soldDate: "12/12/24"))
}
