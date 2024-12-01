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
    @FocusState private var isSearchFieldFocused: Bool
    
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
//                Button {
//                    test()
//                } label: {
//                    Text("test")
//                }
            } .padding()
            if showingProgress {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                    .padding(.trailing, 30)
            }
            List {
                ForEach(searchResults, id: \.id) { item in
                    HStack {
                        Image(systemName: String().getChartName(item: item))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50 , height: 50)
                            .foregroundStyle(getColorOfChange(change: item.change, isSold: item.isSold))
                        VStack {
                            Text(item.symbol)
                                .bold()
                            if item.isSold == false, let tag = item.stockTag {
                                let tag = StockPicks.hold.getStockPick(type: tag)
                                Image(systemName: tag.rawValue)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25 , height: 25)
//                                    .foregroundStyle((getColorOfStockPick(stockPick: sym)))
                            }
                        }
                        VStack(alignment: .leading) {
                            Text(item.price, format: .currency(code: "USD")).bold()
                            if item.isSold == false {
                                if let change = item.change {
                                    Text(change, format: .currency(code: "USD")).bold()
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
                                .font(.caption)
                            Text(item.gainLose, format: .currency(code: "USD"))
                                .foregroundStyle(getColorOfChange(change: item.gainLose, isSold: item.isSold))
                                .bold()
                            Text(item.percent, format: .percent.precision(.fractionLength(2)))
                                .foregroundStyle(getColorOfChange(change: item.gainLose, isSold: item.isSold))
                                .font(.caption)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Show")
                            Text("Detail")
                        }
                        .font(.caption)
                        .onTapGesture {
                            let parameters = PortfolioDetailParameters(item: item, portfolio: portfolio)
                            appNavigationState.portfolioDetailView(parameters: parameters)
                        }
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button {
                            let parameters = DividendCreateParameters(item: item, portfolio: portfolio)
                            appNavigationState.dividendCreateView(parameters: parameters)
                        } label: {
                            Text("Add Dividend")
                        }
                        .tint(.orange)
                        Button {
                            let parameters = PortfolioUpdateParameters(item: item, portfolio: portfolio)
                            appNavigationState.portfolioUpdateView(parameters: parameters)
                        } label: {
                            Text("Update")
                        }
                        .tint(.yellow)
                        Button {
                            let parameters = PortfolioUpdateParameters(item: item, portfolio: portfolio)
                            appNavigationState.portfolioSoldView(parameters: parameters)
                        } label: {
                            Text("Sell")
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
            .searchable(text: $searchText, prompt: "Enter Stock Symbol")
//            .searchFocused($isSearchFieldFocused)
            .onAppear {
                searchText = tempSearchText
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
            .fullScreenCover(isPresented: $showingAddNewShockSheet, onDismiss: didDismiss) {
                AddNewStockToPortfolioView(portfolioName: portfolio.id ?? "n/a")
            }
            .onChange(of: settingsService.displayStocks) { oldValue, newValue in
                updatePortfolio()
            }
            .refreshable {
                await refreshPrices()
            }
            .onChange(of: firebaseService.masterSymbolList) { oldValue, newValue in
                updatePortfolio()
            }
        }
    }
    
    func test() {
        lazy var functions = Functions.functions()
        
        functions.httpsCallable("test").call(["numberOfDays": "0"]) { result, error in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {

                }
                // ...
            }
            if let data = result?.data {
                debugPrint("result: \(data)")
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
    
    func refreshPrices() async {
        
        if let masterSymbol = firebaseService.masterSymbolList.filter({ $0.portfolioName == self.portfolio.name }).first {
            var items = masterSymbol.itemsData
            let list = masterSymbol.stockSymbols
            Task {
                let string: String = list.joined(separator: ",")
                let stockData = await stockDataService.fetchStocks(tickers: string)
                for item in stockData {
                    items.indices.forEach { index in
                        if item.id == items[index].symbol {
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
                updatePortfolio()
            }
        }
        
    }
    
    @MainActor
    func updatePortfolio() {
        
        if let masterSymbol = firebaseService.masterSymbolList.filter({ $0.portfolioName == self.portfolio.name }).first {
            var result: [ItemData] = []
            let displayStockState = settingsService.displayStocks
            var total: Float = 0
            var totalBasis: Float = 0
            var totalSold: Float = 0
            var totalNotSold: Float = 0
            for item in masterSymbol.itemsData {
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
            
            self.stocks = result
            self.total = total
            self.totalBasis = totalBasis
            self.totalSold = totalSold
            self.totalActive = totalNotSold
            
        }

    }
}
