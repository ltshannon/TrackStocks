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
    
    var body: some View {
        VStack {
            Chart {
                ForEach(chartData) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Close", item.close)
                    )
                }
            }
            .frame(height: 300)
        }
        .onAppear {
            Task {
                chartData = await stockDataService.fetchChartData(symbol: symbol)
            }
        }
    }
}
