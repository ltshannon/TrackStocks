//
//  PortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/1/24.
//

import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var stockDataService: StockDataService
    @State var stocks: [StockData] = []
    @State var change: Float = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(stocks, id: \.id) { item in
                        HStack {
                            Image(systemName: getChartName(item: item)).foregroundStyle(getColorOfChange(item: item))
                            VStack {
                                HStack {
                                    Text(item.id)
                                    Text(String(format: "%.2f", item.price))
                                }
                            }
                        }
                    }
                }
                .padding()
                .task {
                    let stockList = "MSFT,PGR,SEZL,SFM,SMCI"
                    let results = await stockDataService.fetchStocks(tickers: stockList)
                    await MainActor.run {
                        stocks = results
                    }
                }
            }
        }
        .navigationTitle("Track Stocks")
    }
    
    func getChartName(item: StockData) -> String {
        if let value = item.change, value < 0 {
            return "chart.line.downtrend.xyaxis"
        }
        if let value = item.change, value > 0 {
            return "chart.line.uptrend.xyaxis"
        }
        return "chart.line.flattrend.xyaxis"
    }
    
    func getColorOfChange(item: StockData) -> Color {
        if let value = item.change, value < 0 {
            return .red
        }
        return .green
    }
}

#Preview {
    PortfolioView()
}
