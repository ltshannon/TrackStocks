//
//  SimplePortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/3/24.
//

import SwiftUI

struct SimplePortfolioView: View {
    var items: [ItemData]
    @State var searchText = ""
    @State var isPercent: Bool = false
    let columns: [GridItem] = [
                                GridItem(.fixed(55), spacing: 1),
                                GridItem(.fixed(50), spacing: 1),
                                GridItem(.fixed(80), spacing: 1),
                                GridItem(.fixed(80), spacing: 1),
                                GridItem(.fixed(100), spacing: 1),
                                ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading) {
                Group {
                    Text("Sym")
                    Text("Qty")
                    Text("Basis $")
                    Text("Price $")
                    Button {
                        isPercent.toggle()
                    } label: {
                        Text(isPercent ? "Gain %" : "Gain $")
                            .underline()
                    }
                }
                .underline()
                ForEach(items, id: \.id) { item in
                    Text("\(item.symbol)")
                        .foregroundStyle(item.isSold ? .orange : .primary)
                    Text(item.quantity.truncatingRemainder(dividingBy: 1) > 0 ? "\(item.quantity, specifier: "%.2f")" : "\(item.quantity, specifier: "%.0f")")
                    Text("\(String(format: "%.2f", item.basis))")
                    Text("\(String(format: "%.2f", item.price))").bold()
                    if isPercent {
                        Text(item.percent, format: .percent.precision(.fractionLength(2)))
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    } else {
                        Text(item.gainLose, format: .currency(code: "USD"))
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    }
                }
            }
        }
        .padding(1)
    }
}

#Preview {
    SimplePortfolioView(items: [])
}
