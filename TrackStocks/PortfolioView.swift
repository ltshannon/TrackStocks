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
    @EnvironmentObject var portfolioService: PortfolioService
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var settingsService: SettingsService
    var portfolio: Portfolio
    @State var stocks: [ItemData] = []
    @State var change: Float = 0
    @State var total: Float = 0
    @State var totalBasis: Float = 0
    @State var totalSold: Float = 0
    @State var totalActive: Float = 0
    @State var dividendList: [DividendDisplayData] = []
    @State var itemToDelete: ItemData?
    @State var showingAddNewShockSheet: Bool = false
    @State var showingDeleteAlert = false
    @State var showingProgress = false
    
    init(paramters: PortfolioParameters) {
        self.portfolio = paramters.portfolio
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
            .fullScreenCover(isPresented: $showingAddNewShockSheet, onDismiss: didDismiss) {
                AddNewStockToPortfolioView(portfolioName: portfolio.id ?? "n/a")
            }
            .onChange(of: settingsService.displayStocks) { oldValue, newValue in
                updatePortfolio()
            }
            .refreshable {
                updatePortfolio()
            }
        }
    }
    
    func test() {
        lazy var functions = Functions.functions()
        
        functions.httpsCallable("test").call(["numberOfDays": "0"]) { result, error in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
//                    let code = FunctionsErrorCode(rawValue: error.code)
//                    let message = error.localizedDescription
//                    let details = error.userInfo[FunctionsErrorDetailsKey]
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
            let results = await portfolioService.getPortfolio(listName: portfolio.id ?? "n/a")
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
            await MainActor.run {
                showingProgress = true
            }
            let results = await portfolioService.getPortfolio(listName: portfolio.id ?? "n/a")
            await MainActor.run {
                stocks = results.0
                total = results.1
                totalBasis = results.2
                dividendList = results.3
                totalSold = results.4
                totalActive = results.5
                showingProgress = false
            }
        }
    }
}
