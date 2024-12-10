//
//  PortfolioBasicInfo2View.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/9/24.
//

import SwiftUI

struct PortfolioBasicInfo2View: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    var portfolio: Portfolio
    var items: [ItemData]
    @State var dividendTotalAmount: Float = 0
    @State var dividendTotalShares: Float = 0
    @State var dividendSharesAmount: Float = 0
    @State var isPercent: Bool = false
    let columns: [GridItem] = [
                                GridItem(.fixed(55), spacing: 1),
                                GridItem(.fixed(60), spacing: 1),
                                GridItem(.fixed(90), spacing: 1),
//                                GridItem(.fixed(60), spacing: 1),
                                GridItem(.fixed(80), spacing: 1),
                                GridItem(.fixed(35), spacing: 1),
                                GridItem(.fixed(35), spacing: 1),
                                ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
                Group {
                    Text("Sym")
                    Text("Price")
                    Text("Position")
                    Text("Plus Div")
                    Text("")
                    Text("")
                }
                .font(.caption)
                    .underline()
                ForEach(items, id: \.id) { item in
                    Group {
                        View1(item: item)
                        View2(item: item)
                        View3(item: item)
                        View4(item: item)
                        View6(portfolio: portfolio, item: item)
                        View7(portfolio: portfolio, item: item)
                    }

                }
            }
            .padding(.leading, 20)
        }
    }
}

struct View1: View {
    var item: ItemData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.symbol)
            .font(.caption)
            .bold()
            .foregroundStyle(item.isSold ? .orange : .primary)
            if item.isSold == false, let tag = item.stockTag {
                let tag = StockPicks.hold.getStockPick(type: tag)
                if tag != .none {
                    Image(systemName: tag.rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25 , height: 25)
                }
            }
        }
    }
}

struct View2: View {
    var item: ItemData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.price, format: .currency(code: "USD"))
            if item.isSold == false {
                if let change = item.change {
                    Text(change, format: .currency(code: "USD"))
                } else {
                    Text("n/a")
                }
                Text(item.changesPercentage ?? 0, format: .percent.precision(.fractionLength(0)))
            }
        }
        .font(.caption)
        .foregroundStyle(getColorOfChange(change: item.change, isSold: item.isSold))
    }
}

struct View3: View {
    var item: ItemData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(String(format: "%.0f", item.quantity))@\(String(format: "%.2f", item.basis))")
            Text(item.gainLose, format: .currency(code: "USD"))
            Text(item.percent, format: .percent.precision(.fractionLength(2)))
        }
        .font(.caption)
        .foregroundStyle(item.isSold ? .orange : (item.gainLose >= 0 ? .green : .red))
    }
}

struct View4: View {
    var item: ItemData
    @State var total: Float = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(total, format: .currency(code: "USD"))
                .font(.caption)
            .bold()
            .foregroundStyle(item.isSold ? .orange : (total >= 0 ? .green : .red))
        }
        .onAppear {
            var countOfShares: Float = 0
            var sharePrice: Float = 0
            var dividendAmount: Float = 0
            for dividend in item.dividendList {
                if let dec = Float(dividend.price) {
                    if let quantity = Float(dividend.quantity) {
                        countOfShares += quantity
                        sharePrice += dec * quantity
                    } else {
                        dividendAmount += dec
                    }
                }
            }
            total = item.gainLose
            if dividendAmount > 0 {
                total += dividendAmount
            }
            if countOfShares > 0 {
                total += ((sharePrice / countOfShares) - item.price) * countOfShares
            }
        }
    }
}

struct View6: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var appNavigationState: AppNavigationState
    var portfolio: Portfolio
    var item: ItemData
    @State var showingDeleteAlert = false
    
    var body: some View {
        Group {
            Menu("EDIT") {
                Button {
                    let parameters = DividendCreateParameters(item: item, portfolio: portfolio, isOnlyShares: true)
                    appNavigationState.dividendCreateView(parameters: parameters)
                } label: {
                    Text("Add to Position").lineLimit(nil)
                }
                Button {
                    let parameters = DividendCreateParameters(item: item, portfolio: portfolio)
                    appNavigationState.dividendCreateView(parameters: parameters)
                } label: {
                    Text("Add Dividend").lineLimit(nil)
                }
                Button {
                    let parameters = PortfolioUpdateParameters(item: item, portfolio: portfolio)
                    appNavigationState.portfolioUpdateView(parameters: parameters)
                } label: {
                    Text("Update")
                }
                Button {
                    let parameters = PortfolioUpdateParameters(item: item, portfolio: portfolio)
                    appNavigationState.portfolioSoldView(parameters: parameters)
                } label: {
                    Text("Sell")
                }
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
            .font(.caption)
            .padding(0)
        }
        .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
            Button("OK", role: .destructive) {
                deleteItem(item: item)
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    func deleteItem(item: ItemData) {
        Task {
            await firebaseService.deletePortfolioStock(portfolioName: self.portfolio.id ?? "n/a", stockId: item.firestoreId)
        }
    }
    
}

struct View7: View {
    var portfolio: Portfolio
    var item: ItemData
    @EnvironmentObject var appNavigationState: AppNavigationState
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "info.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 25 , height: 25)
        }
        .onTapGesture {
            let parameters = PortfolioDetailParameters(item: item, portfolio: portfolio)
            appNavigationState.portfolioDetailView(parameters: parameters)
        }
    }
}
