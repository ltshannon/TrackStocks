//
//  PortfolioBasicInfoView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/2/24.
//

import SwiftUI

struct PortfolioBasicInfoView: View {
    var item: ItemData
    
    var body: some View {
        HStack {
            Image(systemName: String().getChartName(item: item))
                .resizable()
                .scaledToFit()
                .frame(width: 40 , height: 40)
                .foregroundStyle(getColorOfChange(change: item.change, isSold: item.isSold))
            VStack {
                Text(item.symbol)
                    .bold()
                if item.isSold == false, let tag = item.stockTag {
                    let tag = StockPicks.hold.getStockPick(type: tag)
                    if tag != .none {
                        Image(systemName: tag.rawValue)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25 , height: 25)
                    }
                    //                                    .foregroundStyle((getColorOfStockPick(stockPick: sym)))
                }
            }
            VStack(alignment: .leading) {
                Text(item.price, format: .currency(code: "USD")).bold()
                if item.isSold == false {
                    if let change = item.change {
                        Text(change, format: .currency(code: "USD")).bold()
                    } else {
                        Text("n/a")
                    }
                    Text(item.changesPercentage ?? 0, format: .percent.precision(.fractionLength(2)))
                }
            }
            .font(.caption)
            .foregroundStyle(getColorOfChange(change: item.change, isSold: item.isSold))
            VStack(alignment: .leading) {
                Text("\(String(format: "%.0f", item.quantity))@\(String(format: "%.2f", item.basis))")
                    .font(.caption)
                Text(item.gainLose, format: .currency(code: "USD"))
                    .foregroundStyle(getColorOfChange(change: item.gainLose, isSold: item.isSold))
                    .bold()
                Text(item.percent, format: .percent.precision(.fractionLength(2)))
                    .foregroundStyle(getColorOfChange(change: item.gainLose, isSold: item.isSold))
                    .font(.caption)
            }
        }
    }
}

#Preview {
    PortfolioBasicInfoView(item: ItemData(firestoreId: "", symbol: "IBM", basis: 0, price: 0, gainLose: 0, percent: 0, quantity: 0, isSold: false, change: 1, purchasedDate: "12/12/24", soldDate: "12/12/24"))
}
