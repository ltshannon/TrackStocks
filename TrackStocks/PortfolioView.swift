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
    @EnvironmentObject var firebaseService: FirebaseService
    var portfolioName: String
    @State var stocks: [ItemData] = []
    @State var change: Float = 0
    @State var showingSheet: Bool = false
    @State var showingDeleteAlert = false
    
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
                        Text(item.price, format: .currency(code: "USD"))
                        if let change = item.change {
                            Text(change, format: .currency(code: "USD"))
                        } else {
                            Text("n/a")
                        }
                        Text(item.changesPercentage ?? 0, format: .percent.precision(.fractionLength(2)))
                    }
                    .font(.caption)
                    .foregroundStyle(getColorOfChange(change: item.change))
                    VStack(alignment: .leading) {
                        Text("\(String(format: "%.0f", item.quantity))@\(String(format: "%.2f", item.basis))")
                        Text(item.gainLose, format: .currency(code: "USD"))
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
                .swipeActions(allowsFullSwipe: false) {
                    Button {
                        print("Dividend")
                    } label: {
                        Text("Dividend")
                    }
                    .tint(.orange)
                    Button {
                        print("Update")
                    } label: {
                        Text("Update")
                    }
                    .tint(.yellow)
                    Button {
                        print("Sold")
                    } label: {
                        Text("Sold")
                    }
                    .tint(.indigo)
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
                        Button("Yes", role: .cancel) {
                            deleteItem(item: item)
                        }
                    }
                }
            }
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
    
    func deleteItem(item: ItemData) {
        Task {
            await firebaseService.deletePortfolioStock(portfolioName: self.portfolioName, stockId: item.firestoreId)
        }
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
