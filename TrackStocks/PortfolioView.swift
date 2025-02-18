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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage("showDatePicker") var showDatePicker = false
    @AppStorage("dividendDisplay") var isDividendDisplay = false
    var portfolio: Portfolio
    var tempSearchText: String
    @State var stocks: [ItemData] = []
    @State var total: Double = 0
    @State var totalBasis: Double = 0.0
    @State var totalSold: Double = 0.0
    @State var totalActive: Double = 0.0
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
                if horizontalSizeClass == .compact {
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
                ShowStockToolbar()
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
            .fullScreenCover(isPresented: $showingAddNewShockSheet, onDismiss: refreshPrices) {
                AddStockToPortfolioView(portfolioName: portfolio.id ?? "n/a")
            }
            .onChange(of: settingsService.displayStocks) { oldValue, newValue in
                refreshPrices()
            }
            .refreshable {
                refreshPrices()
            }
            .onChange(of: firebaseService.masterSymbolList) { oldValue, newValue in
                refreshPrices()
            }
        }
    }
    
    func deleteItem(item: ItemData) {
        Task {
            await firebaseService.deletePortfolioStock(portfolioName: self.portfolio.id ?? "n/a", stockId: item.firestoreId)
        }
    }
    
    func refreshPrices() {
        Task {
            let results = await firebaseService.refreshPortfolio(portfolioName: self.portfolio.name)
            
            await MainActor.run {
                self.stocks = results.0
                self.total = results.1
                self.totalBasis = results.2
                self.totalSold = results.3
                self.totalActive = results.4
            }
        }
    }
    
/*
    func refreshPrices() {
        if let masterSymbol = firebaseService.masterSymbolList.filter({ $0.portfolioName == self.portfolio.name }).first {
            var items = masterSymbol.itemsData
            let list = masterSymbol.stockSymbols
            Task {
                let string: String = list.joined(separator: ",")
                var stockData: [StockData] = []
                stockData = await stockDataService.fetchFullQuoteStocks(tickers: string)
                for item in stockData {
                    items.indices.forEach { index in
                        if item.id == items[index].symbol {
                            debugPrint("🏓", "symbol: \(item.id) price: \(item.price)")
                            var price = items[index].price
                            for dividend in items[index].dividendList {
                                let dec = (dividend.price as NSString).doubleValue
                                if dec > 0 {
                                    let dividendQuantity = (dividend.quantity as NSString).doubleValue
                                    if dividendQuantity > 0 {
                                        let a = items[index].quantity * items[index].basis
                                        let b = dividendQuantity * dec
                                        let d = dividendQuantity + items[index].quantity
                                        if d > 0 {
                                            let c = (a + b) / d
                                            items[index].quantity = d
                                            items[index].basis = c
                                        }
                                    }
                                }
                            }
                            if items[index].isSold == false {
                                price = item.price
                                items[index].price = price
                            }
                            let value = price - items[index].basis
                            items[index].percent = (value / items[index].basis) * 100
                            let gainLose = items[index].quantity * value
                            items[index].gainLose = gainLose
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
                await computeTotals(itemsData: items)
            }
        }
        
    }
*/
    
/*
    func computeTotals(itemsData: [ItemData]) async {
        var result: [ItemData] = []
        let displayStockState = settingsService.displayStocks
        var total: Double = 0
        var totalBasis: Double = 0
        var totalSold: Double = 0
        var totalNotSold: Double = 0

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
            totalBasis += item.basis * item.quantity
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
*/
    
}
