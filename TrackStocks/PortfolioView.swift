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
    @EnvironmentObject var settingsService: SettingsService
    var portfolioName: String
    @State var stocks: [ItemData] = []
    @State var change: Float = 0
    @State var total: Float = 0
    @State var totalBasis: Float = 0
    @State var totalSold: Float = 0
    @State var totalActive: Float = 0
    @State var dividendList: [DividendDisplayData] = []
    @State var itemToDelete: ItemData?
    @State var showingSheet: Bool = false
    @State var showingDeleteAlert = false
    
    init(paramters: PortfolioParameters) {
        self.portfolioName = paramters.portfolioName
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Total Active: \(totalActive.formatted(.currency(code: "USD")))")
                Text("Total Sold: \(totalSold.formatted(.currency(code: "USD")))")
                Text("Total: \(total.formatted(.currency(code: "USD")))")
                Text("Total Basis: \(totalBasis.formatted(.currency(code: "USD")))")
            } .padding()
            List {
                ForEach(stocks, id: \.id) { item in
                    HStack {
                        Image(systemName: String().getChartName(item: item))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50 , height: 50)
                            .foregroundStyle(getColorOfChange(change: item.change, isSold: item.isSold))
                        VStack {
                            Text(item.symbol)
                                .bold()
                        }
                        VStack(alignment: .leading) {
                            Text(item.price, format: .currency(code: "USD"))
                            if item.isSold == false {
                                if let change = item.change {
                                    Text(change, format: .currency(code: "USD"))
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
                            Text(item.gainLose, format: .currency(code: "USD"))
                                .foregroundStyle(getColorOfChange(change: item.gainLose, isSold: item.isSold))
                            Text(item.percent, format: .percent.precision(.fractionLength(2)))
                                .foregroundStyle(getColorOfChange(change: item.gainLose, isSold: item.isSold))
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
                            let parameters = DividendCreateParameters(item: item, portfolioName: portfolioName)
                            appNavigationState.dividendCreateView(parameters: parameters)
                        } label: {
                            Text("Dividend")
                        }
                        .tint(.orange)
                        Button {
                            let parameters = PortfolioUpdateParameters(item: item, portfolioName: portfolioName)
                            appNavigationState.portfolioUpdateView(parameters: parameters)
                        } label: {
                            Text("Update")
                        }
                        .tint(.yellow)
                        Button {
                            let parameters = PortfolioUpdateParameters(item: item, portfolioName: portfolioName)
                            appNavigationState.portfolioSoldView(parameters: parameters)
                        } label: {
                            Text("Sold")
                        }
                        .tint(.indigo)
                        Button(role: .destructive) {
                            itemToDelete = item
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSheet = true
                    } label: {
                        Image(systemName: "plus.app")
                            .resizable()
                            .scaledToFit()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            settingsService.setShowActiveStocks()
                        } label: {
                            Label("Show Active Stocks", systemImage: settingsService.displayStocks == .showActiveStocks ? "checkmark.circle" : "circle")
                        }
                        Button {
                            settingsService.setShowAllStocks()
                        } label: {
                            Label("Show All Stocks", systemImage: settingsService.displayStocks == .showAllStocks ? "checkmark.circle" : "circle")
                        }
                        Button {
                            settingsService.setShowSoldStocks()
                        } label: {
                            Label("Show Sold Stocks", systemImage: settingsService.displayStocks == .showSoldStocks ? "checkmark.circle" : "circle")
                        }
                        Button {
                            
                        } label: {
                            Text("Cancel")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .navigationTitle(portfolioName)
            .onAppear {
                updatePortfolio()
            }
            .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
                Button("OK", role: .destructive) {
                    if let item = itemToDelete {
                        deleteItem(item: item)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
                AddNewStockToPortfolioView(portfolioName: portfolioName)
            }
            .onChange(of: settingsService.displayStocks) { oldValue, newValue in
                updatePortfolio()
            }
        }
    }
    
    func deleteItem(item: ItemData) {
        Task {
            await firebaseService.deletePortfolioStock(portfolioName: self.portfolioName, stockId: item.firestoreId)
            let results = await portfolioService.getPortfolio(listName: portfolioName)
            await MainActor.run {
                stocks = results.0
                total = results.1
                totalBasis = results.2
                dividendList = results.3
                totalSold = results.4
                totalActive = results.5
            }
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
                total = results.1
                totalBasis = results.2
                dividendList = results.3
                totalSold = results.4
                totalActive = results.5
            }
        }
    }
}
