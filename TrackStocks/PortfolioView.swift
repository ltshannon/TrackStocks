//
//  PortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/1/24.
//

import SwiftUI
import Firebase
import FirebaseFunctions

struct PortfolioView: View {
    @EnvironmentObject var stockDataService: StockDataService
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var settingsService: SettingsService
    @AppStorage("showDatePicker") var showDatePicker = false
    @AppStorage("simpleDisplay") var simpleDataDisplay = false
    var portfolio: Portfolio
    var tempSearchText: String
    @State var stocks: [ItemData] = []
    @State var total: Float = 0
    @State var totalBasis: Float = 0
    @State var totalSold: Float = 0
    @State var totalActive: Float = 0
    @State var itemToDelete: ItemData?
    @State var showingAddNewShockSheet: Bool = false
    @State var showingDeleteAlert = false
    @State var showingProgress = false
    @State private var selectedOption: StockPicks = .none
    @State var searchText = ""
    
    var searchResults: [ItemData] {
        if searchText.isEmpty {
            return stocks
        } else {
            return stocks.filter { $0.symbol.contains(searchText.uppercased()) }
        }
    }
    
    init(parameters: PortfolioParameters) {
        self.portfolio = parameters.portfolio
        self.tempSearchText = parameters.searchText
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                if settingsService.displayStocks == .showAllStocks {
                    Text("Active Gain/Loss: \(totalActive.formatted(.currency(code: "USD")))")
                    Text("Sold Gain/Loss: \(totalSold.formatted(.currency(code: "USD")))")
                }
                Text("Total Gain/Loss: \(total.formatted(.currency(code: "USD")))")
                Text("Cost Basis: \(totalBasis.formatted(.currency(code: "USD")))")
                if totalBasis > 0 {
                    let value = (total / totalBasis) * 100
                    Text("Percent Change: \(value, specifier: "%.2f")%")
                }
            } .padding()
            if showingProgress {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                    .padding(.trailing, 30)
            }
            Group {
                if simpleDataDisplay == true {
                    SimplePortfolioView(portfolio: portfolio, items: searchResults)
                } else {
                    PortfolioBasicInfo2View(portfolio: portfolio, items: searchResults)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddNewShockSheet = true
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
            .navigationTitle(portfolio.name)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Enter Stock Symbol")
            .onAppear {
                searchText = tempSearchText
                refreshPrices()
            }
            .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
                Button("OK", role: .destructive) {
                    if let item = itemToDelete {
                        deleteItem(item: item)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showingAddNewShockSheet, onDismiss: didDismiss) {
                AddNewStockToPortfolioView(portfolioName: portfolio.id ?? "n/a")
            }
            .onChange(of: settingsService.displayStocks) { oldValue, newValue in
                updatePortfolio()
            }
            .refreshable {
                refreshPrices()
            }
            .onChange(of: firebaseService.masterSymbolList) { oldValue, newValue in
                updatePortfolio()
            }
        }
    }
    
    func deleteItem(item: ItemData) {
        Task {
            await firebaseService.deletePortfolioStock(portfolioName: self.portfolio.id ?? "n/a", stockId: item.firestoreId)
        }
    }
    
    func didDismiss() {
        updatePortfolio()
    }
    
    func refreshPrices() {
        
        if let masterSymbol = firebaseService.masterSymbolList.filter({ $0.portfolioName == self.portfolio.name }).first {
            var items = masterSymbol.itemsData
            let list = masterSymbol.stockSymbols
            Task {
                let string: String = list.joined(separator: ",")
                var stockData: [StockData] = []
                if simpleDataDisplay == true {
                    stockData = await stockDataService.fetchShortQuoteStocks(tickers: string)
                } else {
                    stockData = await stockDataService.fetchFullQuoteStocks(tickers: string)
                }
                for item in stockData {
                    items.indices.forEach { index in
                        if item.id == items[index].symbol {
                            debugPrint("🏓", "symbol: \(item.id) price: \(item.price)")
                            var price: Float = items[index].price
                            var dividendAmount: Float = 0
                            for dividend in items[index].dividendList {
                                if let dec = Float(dividend.price) {
                                    if let quantity = Float(dividend.quantity) {
                                        dividendAmount += (dec * quantity) - price
                                    } else {
                                        dividendAmount += dec
                                    }
                                }
                            }
                            if items[index].isSold == false {
                                price = Float(Double(item.price))
                                items[index].price = price
                            }
                            let value = price - items[index].basis
                            items[index].percent = value / items[index].basis
                            let gainLose = Float(items[index].quantity) * value
                            items[index].gainLose = gainLose + (simpleDataDisplay == true ? dividendAmount : 0.0)
                            if simpleDataDisplay == false {
                                items[index].changesPercentage = item.changesPercentage != nil ? item.changesPercentage! / 100 : 0
                                items[index].change = item.change
                                items[index].dayLow = item.dayLow
                                items[index].dayHigh = item.dayHigh
                                items[index].yearLow = item.yearLow
                                items[index].yearHigh = item.yearHigh
                                items[index].marketCap = item.marketCap
                                items[index].priceAvg50 = item.priceAvg50
                                items[index].priceAvg200 = item.priceAvg200
                                items[index].exchange = item.exchange
                                items[index].volume = item.volume
                                items[index].avgVolume = item.avgVolume
                                items[index].open = item.open
                                items[index].previousClose = item.previousClose
                                items[index].eps = item.eps
                                items[index].pe = item.pe
                                items[index].earningsAnnouncement = item.earningsAnnouncement
                                items[index].sharesOutstanding = item.sharesOutstanding
                                items[index].timestamp = item.timestamp
                            }
                        }
                    }
                }
                await computeTotals(itemsData: items)
            }
        }
        
    }
    
    func updatePortfolio() {
        if let _ = firebaseService.masterSymbolList.filter({ $0.portfolioName == self.portfolio.name }).first {
            refreshPrices()
        }

    }
    
    func computeTotals(itemsData: [ItemData]) async {
        var result: [ItemData] = []
        let displayStockState = settingsService.displayStocks
        var total: Float = 0
        var totalBasis: Float = 0
        var totalSold: Float = 0
        var totalNotSold: Float = 0

        for item in itemsData {
            if displayStockState == .showSoldStocks && item.isSold == false {
                continue
            }
            if item.isSold == true, displayStockState == .showActiveStocks {
                continue
            }

            let gainLose = item.gainLose
            total += gainLose
            if item.isSold == true {
                totalSold += gainLose
            } else {
                totalNotSold += gainLose
            }
            totalBasis += item.basis * Float(item.quantity)
            result.append(item)
        }
        
        await MainActor.run {
            self.stocks = result
            self.total = total
            self.totalBasis = totalBasis
            self.totalSold = totalSold
            self.totalActive = totalNotSold
        }
        
    }
}
