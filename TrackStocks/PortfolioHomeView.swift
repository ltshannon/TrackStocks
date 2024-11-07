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
    @State var showAlert = false
    @State var portfolioName: String = ""
    @State var firstTime = true
    
    var body: some View {
        NavigationStack(path: $appNavigationState.portfolioNavigation) {
//            ScrollView {
                List {
                    ForEach(firebaseService.portfolioList, id: \.id) { item in
                        VStack {
                            Text(item.name)
                                .font(.title2)
//                            Divider()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            let parameters = PortfolioParameters(portfolioName: item.name)
                            appNavigationState.portfolioView(parameters: parameters)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .toolbar {
                     EditButton()
                 }
//            }
            .navigationTitle("Portfolios")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAlert = true
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
                    PortfolioView(paramters: parameters)
                case .portfolioDetailView(let parameters):
                    PortfolioDetailView(paramters: parameters)
                }
            }
        }
        .onAppear {
            if firstTime {
                firstTime = false
                firebaseService.listenerForPortfolios()
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
        .alert("Add Portfolio", isPresented: $showAlert) {
            TextField("Name", text: $portfolioName)
                .keyboardType(.decimalPad)
            Button("OK", action: add)
            Button("Cancel", role: .cancel) { }
         } message: {
            Text("Enter the name of the portfolio.")
         }
    }
    
    func add() {
        Task {
            await firebaseService.addPortfolio(portfolioName: portfolioName)
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
}

#Preview {
    PortfolioHomeView()
}
