//
//  DisplayStockView.swift
//  TrackStocksWatch Watch App
//
//  Created by Larry Shannon on 1/29/26.
//

import SwiftUI

struct DisplayStockView: View {
    var stock: WatchStock
    
    var body: some View {
        HStack {
            Text(stock.symbol)
                .padding(.trailing, 20)
            VStack {
                Text("\(String(format: "%.2f", stock.price))")
                let gainLose = abs(stock.gainLose)
                Text(gainLose, format: .number.precision(.fractionLength(2)))
                        //.currency(code: "USD"))
                    .foregroundStyle(stock.gainLose < 0 ?.red : .green)
                Text("\(String(format: "%.2f", stock.change))")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous).fill(stock.change < 0 ?.red : .green)
                    )
            }
        }
    }
}

#Preview {
    DisplayStockView(stock: WatchStock(symbol: "APP", price: 400.0, change: 10.0, gainLose: 100))
}
