//
//  PortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/1/24.
//

import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var stockDataService: StockDataService
//    @EnvironmentObject var portfolioService: PortfolioService
    var portfolioService = PortfolioService()
    var portfolioName: String = ""
    @State var stocks: [ItemData] = []
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
                                    Text(item.symbol)
                                    Text(String(format: "%.2f", item.price))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(portfolioName)
        .onAppear {
            Task {
                let results = await portfolioService.getPortfolio(listName: portfolioName)
                await MainActor.run {
                    stocks = results.0
                }
            }
        }
    }
    
    func getChartName(item: ItemData) -> String {
        if let value = item.change, value < 0 {
            return "chart.line.downtrend.xyaxis"
        }
        if let value = item.change, value > 0 {
            return "chart.line.uptrend.xyaxis"
        }
        return "chart.line.flattrend.xyaxis"
    }
    
    func getColorOfChange(item: ItemData) -> Color {
        if let value = item.change, value < 0 {
            return .red
        }
        return .green
    }
}

#Preview {
    PortfolioView()
}
