//
//  PortfolioHomeView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/1/24.
//

import SwiftUI
import SwiftData

struct PortfolioHomeView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var stockDataService: StockDataService
    @EnvironmentObject var marketSymbolsService: MarketSymbolsService
    @Environment(\.modelContext) var context
    @AppStorage("stock-exchange-list") var stockExchangeList: [String] = ["NASDAQ", "NYSE", "AMEX", "OTC"]
    @Query(sort: \SymbolStorage.symbol) var symbolStorage: [SymbolStorage]
    @State var showAddPortfolioAlert = false
    @State var showRenamePortfolioAlert = false
    @State var showDeletePortfolioAlert = false
    @State var portfolioName: String = ""
    @State var newName: String = ""
    @State var firstTime = true
    @State var selectedPortfolio: Portfolio = Portfolio(id: "", name: "")
    @State var searchText = ""
    @State var portfolioList: [Portfolio] = []
    
    var searchResults: [Portfolio] {
        if searchText.isEmpty {
            return firebaseService.portfolioList
        } else {
            var list: [Portfolio] = []
            let _ = firebaseService.masterSymbolList.map { item in
                if item.stockSymbols.filter({ $0.contains(searchText.uppercased()) }).isEmpty == false {
                    let portfolio = Portfolio(id: item.portfolioId, name: item.portfolioName)
                    list.append(portfolio)
                }
            }
            return list
        }
    }

    var body: some View {
        NavigationStack(path: $appNavigationState.portfolioNavigation) {
            List {
                ForEach(searchResults, id: \.id) { item in
                    HStack {
                        Text(item.name)
                            .font(.title2)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let parameters = PortfolioParameters(portfolio: item, searchText: searchText)
                        appNavigationState.portfolioView(parameters: parameters)
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button {
                            selectedPortfolio = item
                            showRenamePortfolioAlert = true
                        } label: {
                            Text("Rename")
                        }
                        .tint(.indigo)
                        Button(role: .destructive) {
                            selectedPortfolio = item
                            showDeletePortfolioAlert = true
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
            .navigationTitle("Portfolios")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPortfolioAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.app")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
            .navigationDestination(for: PortfolioNavDestination.self) { state in
                switch state {
                case .portfolioView(let parameters):
                    PortfolioView(parameters: parameters)
                case .portfolioDetailView(let parameters):
                    PortfolioDetailView(parameters: parameters)
                case .portfolioUpdateView(let parameters):
                    PortfolioUpdateView(parameters: parameters)
                case .portfolioSoldView(let parameters):
                    PortfolioSoldView(parameters: parameters)
                case .dividendCreateView(let parameters):
                    DividendCreateView(parameters: parameters)
                case .dividendEditView(let parameters):
                    DividendEditView(parameters: parameters)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Enter Portfolio Name")
        .onAppear {
            if firstTime {
                firstTime = false
                Task {
                    await firebaseService.listenerForPortfolios()
                }
            }
            if symbolStorage.isEmpty {
                let set = Set(stockExchangeList)
                Task {
                    let results = await stockDataService.fetchSymbols()
                    var array: [SymbolStorage] = []
                    for item in results {
                        if let shortName = item.exchangeShortName, set.contains(shortName) {
                            let value = SymbolStorage(symbol: item.id, name: item.name ?? "", price: item.price ?? 0, exchange: item.exchange ?? "", exchangeShortName: item.exchangeShortName ?? "", type: item.type ?? "")
                            context.insert(value)
                            array.append(value)
                        }
                    }
                    try! context.save()
                    marketSymbolsService.makeList(symbolStorage: array)
                }
            } else {
                marketSymbolsService.makeList(symbolStorage: symbolStorage)
            }
        }
        .alert("Add Portfolio", isPresented: $showAddPortfolioAlert) {
            TextField("Name", text: $portfolioName)
                .keyboardType(.default)
            Button("OK", action: add)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the name of the portfolio.")
        }
        .alert("Rename Portfolio", isPresented: $showRenamePortfolioAlert) {
            TextField("Name", text: $newName)
                .keyboardType(.default)
            Button("OK") {
                rename(item: selectedPortfolio)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the new name of the portfolio")
        }
        .alert("Are you sure you want to delete this?", isPresented: $showDeletePortfolioAlert) {
            Button("OK", role: .destructive) {
                delete(item: selectedPortfolio)
            }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: firebaseService.portfolioList) { oldValue, newValue in
            if newValue.count > oldValue.count {
                let difference = oldValue.difference(from: newValue)
                for item in difference {
                    Task {
                        await firebaseService.listenerForStockSymbols(portfolioId: item.id ?? "n/a", portfolioName: item.name)
                    }
                }
            } else if newValue.count < oldValue.count {
                let difference = newValue.difference(from: oldValue)
                for item in difference {
                    if let id = item.id, let index = firebaseService.masterSymbolList.firstIndex(where: { $0.portfolioId == id }) {
                        DispatchQueue.main.async {
                            firebaseService.masterSymbolList.remove(at: index)
                        }
                    }
                }
            }
            self.portfolioList = newValue
        }
        .onChange(of: firebaseService.masterSymbolList) { oldValue, newValue in
//            debugPrint("👤", "onChange masterSymbolList called")
//            for item in newValue {
//                debugPrint("🤡", "masterSymbolList: portfolio name: \(item.portfolioName)")
//                for item2 in item.stockSymbols {
//                    debugPrint("masterSymbolList: symbol: \(item2)")
//                }
//            }
        }

    }
    
    func add() {
        Task {
            await firebaseService.addPortfolio(portfolioName: portfolioName)
            portfolioName = ""
        }
    }
    
    func rename(item: Portfolio) {
        Task {
            await firebaseService.renamePortfolio(portfolioId: item.id ?? "n/a", portfolioName: newName)
            newName = ""
        }
    }

    func delete(item: Portfolio) {
        Task {
            await firebaseService.deletePortfolio(portfolioName: item.id ?? "n/a")
        }
    }
}

#Preview {
    PortfolioHomeView()
}
