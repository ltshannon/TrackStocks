//
//  PortfolioDetailView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/5/24.
//

import SwiftUI

struct PortfolioDetailView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @Environment(\.dismiss) private var dismiss
    @State var item: ItemData
    @State var portfolioName: String
    
    init(paramters: PortfolioDetailParameters) {
        self.item = paramters.item
        self.portfolioName = paramters.portfolioName
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    Image(systemName: String().getChartName(item: item))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50 , height: 50)
                        .foregroundStyle(getColorOfChange(change: item.change))
                    VStack {
                        Text(item.symbol)
                            .bold()
                    }
                    VStack(alignment: .leading) {
                        Text(String(format: "%.2f", item.price))
                        Text(item.change != nil ? String(format: "%.2f", item.change!) : "n/a")
                        Text(item.changesPercentage ?? 0, format: .percent.precision(.fractionLength(2)))
                    }
                    .font(.caption)
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
            Spacer()
        }
        .padding([.leading, .trailing], 20)
        .navigationTitle(portfolioName + " Details")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
        }
    }
}
