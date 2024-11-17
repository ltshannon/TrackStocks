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
    
    var body: some View {
        NavigationStack(path: $appNavigationState.portfolioNavigation) {
            List {
                ForEach(firebaseService.portfolioList, id: \.id) { item in
                    HStack {
                        Text(item.name)
                            .font(.title2)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let parameters = PortfolioParameters(portfolio: item)
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
                    PortfolioView(paramters: parameters)
                case .portfolioDetailView(let parameters):
                    PortfolioDetailView(paramters: parameters)
                case .portfolioUpdateView(let parameters):
                    PortfolioUpdateView(paramters: parameters)
                case .portfolioSoldView(let parameters):
                    PortfolioSoldView(paramters: parameters)
                case .dividendCreateView(let parameters):
                    DividendCreateView(paramters: parameters)
                }
            }
        }
        .onAppear {
            if firstTime {
                if firebaseService.listenerForPortfolios() {
                    firstTime = false
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
                  debugPrint("😀", "Deleting portfolio: \(selectedPortfolio.name)")
                  delete(item: selectedPortfolio)
              }
              Button("Cancel", role: .cancel) { }
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
