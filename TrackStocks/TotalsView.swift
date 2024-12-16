//
//  TotalsView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/14/24.
//

import SwiftUI

struct PortfolioTotal: Identifiable {
    var id = UUID().uuidString
    var isRemovedFromList: Bool = false
    var name: String
    var stocks: [ItemData]
    var total: Double
    var totalBasis: Double
    var totalSold: Double
    var totalActive: Double
}

struct TotalsView: View {
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var firebaseService: FirebaseService
    @State var stocks: [ItemData] = []
    @State var total: Double = 0
    @State var totalBasis: Double = 0.0
    @State var totalSold: Double = 0.0
    @State var totalActive: Double = 0.0
    @State var portfolioTotals: [PortfolioTotal] = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                List {
                    ForEach(portfolioTotals.indices, id: \.self) { index in
                        HStack {
                            Button {
                                portfolioTotals[index].isRemovedFromList.toggle()
                                recomputeTotals()
                            } label: {
                                Image(systemName: portfolioTotals[index].isRemovedFromList ? "circle": "circle.fill")
                            }
                            VStack(alignment: .leading) {
                                Text("\(portfolioTotals[index].name)")
                                    .font(.headline)
                                if settingsService.displayStocks == .showAllStocks {
                                    Text("Active Gain/Loss: \(portfolioTotals[index].totalActive.formatted(.currency(code: "USD")))")
                                    Text("Sold Gain/Loss: \(portfolioTotals[index].totalSold.formatted(.currency(code: "USD")))")
                                }
                                Text("Total Gain/Loss: \(portfolioTotals[index].total.formatted(.currency(code: "USD")))")
                                Text("Cost Basis: \(portfolioTotals[index].totalBasis.formatted(.currency(code: "USD")))")
                                if portfolioTotals[index].totalBasis > 0 {
                                    let value = (portfolioTotals[index].total / portfolioTotals[index].totalBasis) * 100
                                    Text("Percent Change: \(value, specifier: "%.2f")%")
                                }
                            }
                        }
                    }
                }
                VStack(alignment: .leading) {
                    Text("Totals:")
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
                }
                .padding([.leading, .bottom], 20)
            }
            .listStyle(PlainListStyle())
            .toolbar {
                ShowStockToolbar()
            }
            .navigationTitle("Totals")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            refreshTotals()
        }
        .refreshable {
            refreshTotals()
        }
        .onChange(of: settingsService.displayStocks) { oldValue, newValue in
            recomputeTotals()
        }
    }
    
    func recomputeTotals() {
        var total: Double = 0
        var totalBasis: Double = 0.0
        var totalSold: Double = 0.0
        var totalActive: Double = 0.0
        
        for item in portfolioTotals {
            if item.isRemovedFromList == false {
                total += item.total
                totalBasis += item.totalBasis
                totalSold += item.totalSold
                totalActive += item.totalActive
            }
        }
        self.total = total
        self.totalBasis = totalBasis
        self.totalSold = totalSold
        self.totalActive = totalActive
        
    }
    
    func refreshTotals() {
        var items: [PortfolioTotal] = []
        var total: Double = 0
        var totalBasis: Double = 0.0
        var totalSold: Double = 0.0
        var totalActive: Double = 0.0
        
        Task {
            let portfolios = firebaseService.portfolioList
            for portfolio in portfolios {
                let results = await firebaseService.refreshPortfolio(portfolioName: portfolio.name)
                let item = PortfolioTotal(name: portfolio.name, stocks: results.0, total: results.1, totalBasis: results.2, totalSold: results.3, totalActive: results.4)
                total += item.total
                totalBasis += item.totalBasis
                totalSold += item.totalSold
                totalActive += item.totalActive
                
                items.append(item)
            }
            await MainActor.run {
                self.portfolioTotals = items
                self.total = total
                self.totalBasis = totalBasis
                self.totalSold = totalSold
                self.totalActive = totalActive
            }
        }
    }
}

#Preview {
    TotalsView()
}
