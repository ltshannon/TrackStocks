//
//  SymbolChartView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/10/24.
//

import SwiftUI
import Charts

struct SymbolChartView: View {
    @EnvironmentObject var stockDataService: StockDataService
    var symbol: String
    @State var chartData: [ChartData] = []
    @State var high: Double = 0
    @State var low: Double = 0
    
    init(parameters: SymbolChartParameters) {
        self.symbol = parameters.symbol
    }
    
    var body: some View {
        VStack {
            if chartData.isEmpty {
                Text("No chart data available currently")
            } else {
                Chart {
                    ForEach(chartData) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Close", item.close)
                        )
                    }
                }
                .frame(height: 300)
                .chartYScale(domain: [low, high])
            }
        }
        .onAppear {
            Task {
                let results = await stockDataService.fetchChartData(symbol: symbol, timeFrame: .oneMin)
                chartData = results.2
                high = results.0
                low = results.1
            }
        }
    }
}
