//
//  PortfolioBasicInfoView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/2/24.
//

import SwiftUI

struct DividendShares {
    var id = UUID().uuidString
    var string = ""
}

struct PortfolioBasicInfoView: View {
    var item: ItemData
    @State var dividendAmount: Float = 0
    @State var dividendShares: [DividendShares] = []
    @State var dividendSharesAmount: Float = 0
    let columns: [GridItem] = [
                                GridItem(.fixed(55), spacing: 1),
                                GridItem(.fixed(48), spacing: 1),
                                GridItem(.fixed(78), spacing: 1),
                                GridItem(.fixed(78), spacing: 1),
                                GridItem(.fixed(100), spacing: 1),
                                ]
    
    var body: some View {
        HStack {
            Image(systemName: String().getChartName(item: item))
                .resizable()
                .scaledToFit()
                .frame(width: 25 , height: 25)
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
            if dividendAmount > 0 {
                VStack(alignment: .leading) {
                    Text("Cash")
                    Text(dividendAmount, format: .currency(code: "USD"))
                    Text("")
                }
                .font(.caption)
            }
            if dividendShares.count > 0 {
                VStack(alignment: .leading) {
                    Text("Shares")
                    ForEach(dividendShares, id: \.id) { item in
                        Text(item.string)
                    }
                    Text("")
                }
                .font(.caption)
            }
        }
        .onAppear {
            dividendAmount = 0
            dividendShares = []
            dividendSharesAmount = 0
            for dividend in item.dividendList {
                if let dec = Float(dividend.price) {
                    if let quantity = Float(dividend.quantity) {
                        dividendSharesAmount += (dec * quantity) - item.price
                        let str = String(quantity) + "@" + String(dec)
                        let item = DividendShares(string: str)
                        dividendShares.append(item)
                    } else {
                        dividendAmount += dec
                    }
                }
            }
        }
    }
}

#Preview {
    PortfolioBasicInfoView(item: ItemData(firestoreId: "", symbol: "IBM", basis: 0, price: 0, gainLose: 0, percent: 0, quantity: 0, isSold: false, change: 1, purchasedDate: "12/12/24", soldDate: "12/12/24"))
}
