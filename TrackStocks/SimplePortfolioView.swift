//
//  SimplePortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/3/24.
//

import SwiftUI

struct SimplePortfolioView: View {
    var portfolio: Portfolio
    var items: [ItemData]
    @State var searchText = ""
    @State var isPercent: Bool = false
    let columns: [GridItem] = [
                                GridItem(.fixed(50), spacing: 1),
                                GridItem(.fixed(70), spacing: 1),
                                GridItem(.fixed(65), spacing: 1),
                                GridItem(.fixed(65), spacing: 1),
                                GridItem(.fixed(75), spacing: 1),
                                GridItem(.fixed(35), spacing: 1),
                                ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading) {
                Group {
                    Text("Sym")
                    Text("Position")
                    Text("Price")
                    Text("Change")
                    Button {
                        isPercent.toggle()
                    } label: {
                        Text(isPercent ? "Gain %" : "Gain $")
                            .underline()
                    }
                    Text("")
                }
                .underline()
                ForEach(items, id: \.id) { item in
                    Text("\(item.symbol)")
                        .foregroundStyle(item.isSold ? .orange : .primary)
                    Text(item.quantity.truncatingRemainder(dividingBy: 1) > 0 ? "\(item.quantity, specifier: "%.2f")" : "\(item.quantity, specifier: "%.0f")\n$\(String(format: "%.2f", item.basis))")
                        .font(.caption)
                    Text("\(String(format: "%.2f", item.price))").bold()
                    Text("\(String(format: "%.2f", item.change ?? 0))")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous).fill(item.change ?? 0 < 0 ?.red : .green)
                        )
                    if isPercent {
                        Text(item.percent, format: .number.precision(.fractionLength(2)))
                                //.percent.precision(.fractionLength(2)))
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    } else {
                        let gainLose = abs(item.gainLose)
                        Text(gainLose, format: .number.precision(.fractionLength(2)))
                                //.currency(code: "USD"))
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    }
                    View6(portfolio: portfolio, item: item)
                }
            }
        }
        .padding(.leading, 10)
    }
}
