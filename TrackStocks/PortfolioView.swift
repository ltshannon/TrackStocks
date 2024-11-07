//
//  PortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/1/24.
//

import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var stockDataService: StockDataService
    @EnvironmentObject var portfolioService: PortfolioService
    @EnvironmentObject var appNavigationState: AppNavigationState
    var portfolioName: String
    @State var stocks: [ItemData] = []
    @State var change: Float = 0
    @State var showingSheet: Bool = false
    
    init(paramters: PortfolioParameters) {
        self.portfolioName = paramters.portfolioName
    }
    
    var body: some View {
        List {
            ForEach(stocks, id: \.id) { item in
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
                    .foregroundStyle(getColorOfChange(change: item.change))
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.0f", item.quantity))@\(String(format: "%.2f", item.basis))")
                        Text(String(format: "%.2f", item.gainLose))
                            .foregroundStyle(getColorOfChange(change: item.change))
                        Text(item.percent, format: .percent.precision(.fractionLength(2)))
                            .foregroundStyle(getColorOfChange(change: item.change))
                    }
                    .font(.caption)
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Show")
                        Text("Detail")
                    }
                    .font(.caption)
                    .onTapGesture {
                        let parameters = PortfolioDetailParameters(item: item, portfolioName: portfolioName)
                        appNavigationState.portfolioDetailView(parameters: parameters)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .toolbar {
            EditButton()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.app")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
        }
        .navigationTitle(portfolioName)
        .onAppear {
            updatePortfolio()
        }
        .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
            AddNewStockToPortfolioView(portfolioName: portfolioName)
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
    
    func didDismiss() {
        updatePortfolio()
    }
    
    func updatePortfolio() {
        Task {
            let results = await portfolioService.getPortfolio(listName: portfolioName)
            await MainActor.run {
                stocks = results.0
            }
        }
    }
}
