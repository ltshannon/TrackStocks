//
//  PortfolioiPadSoldView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 2/20/25.
//

import SwiftUI

struct PortfolioiPadSoldView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var appNavigationState: AppNavigationState
    @StateObject var itemsClass: ItemsClass = ItemsClass()
    var portfolio: Portfolio
    var items: [ItemData]
    @State var showingDeleteAlert = false
    @State var firestoreId: String = ""
    @State var grandTotal: Double = 0
    @State var gainLossTotal: Double = 0
    @State var isSymbolSortAscending: Bool = false
    @State var isTodaysLossGainSortAscending: Bool = false
    @State var isTotalLossGainSortAscending: Bool = false
    @State var isCurrentValueSortAscending: Bool = false
    let columns: [GridItem] = [
                                GridItem(.fixed(60), spacing: 1),
                                GridItem(.fixed(75), spacing: 1),
                                GridItem(.fixed(75), spacing: 1),
                                GridItem(.fixed(75), spacing: 1),
                                GridItem(.fixed(85), spacing: 5),
                                GridItem(.fixed(85), spacing: 5),
                                GridItem(.fixed(120), spacing: 1),
                                GridItem(.fixed(120), spacing: 1),
                                GridItem(.fixed(50), spacing: 1),
                                ]
    
    init(portfolio: Portfolio, items: [ItemData]) {
        self.portfolio = portfolio
        self.items = items
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
                Group {
                    Button {
                        itemsClass.sortType = .symbol
                        SortItems(ascending: isSymbolSortAscending, itemsClass: itemsClass)
                        isSymbolSortAscending.toggle()
                    } label: {
                        HStack(spacing: 1) {
                            Text("Sym")
                            SortArrow(isSortAscending: isSymbolSortAscending)
                        }
                        .underline()
                    }
                    Text("Shares")
                    Text("Basis")
                    Text("Price")
                    Text("Purchased")
                    Text("Sold")
                    Button {
                        itemsClass.sortType = .totalLossGain
                        SortItems(ascending: isTotalLossGainSortAscending, itemsClass: itemsClass)
                        isTotalLossGainSortAscending.toggle()
                    } label: {
                        HStack(spacing: 1) {
                            Text("Gain/Loss")
                            SortArrow(isSortAscending: isTotalLossGainSortAscending)
                        }
                        .underline()
                    }
                    Button {
                        itemsClass.sortType = .currentValue
                        SortItems(ascending: isCurrentValueSortAscending, itemsClass: itemsClass)
                        isCurrentValueSortAscending.toggle()
                    } label: {
                        HStack(spacing: 1) {
                            Text("Value")
                            SortArrow(isSortAscending: isCurrentValueSortAscending)
                        }
                        .underline()
                    }
                    Text("")
                }
                .underline()
                ForEach(itemsClass.items, id: \.id) { item in
                    Group {
                        View1(item: item, isSoldPortfolio: portfolio.isForSoldStocks ?? false)
                        NumberOfSharesView(item: item, isSoldPortfolio: true)
                        BasisView(item: item, isSoldPortfolio: true)
                        PriceView(item: item, isSoldPortfolio: true)
                        PurchaseDateView(item: item)
                        SoldDateView(item: item)
                        GainLossView(gainLossTotal: $gainLossTotal, item: item, isSoldPortfolio: portfolio.isForSoldStocks ?? false)
                        TotalView(grandTotal: $grandTotal, item: item)
                        View5(portfolio: portfolio, item: item, showingDeleteAlert: $showingDeleteAlert, firestoreId: $firestoreId)
                    }
                }
                Group {
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text("-----------")
                    Text("-----------")
                    Text("")
                }
                Group {
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text("")
                    Text(gainLossTotal, format: .currency(code: "USD"))
                    Text(grandTotal, format: .currency(code: "USD"))
                    Text("")
                }
            }
            .padding(.leading, 20)
        }
        .onChange(of: items, { oldValue, newValue in
            grandTotal = 0
            gainLossTotal = 0
            var items = newValue
            items.enumerated().forEach { (index, value) in
                if let previousClose = items[index].previousClose {
                    let value = (Double(previousClose) - items[index].price) * items[index].quantity
                    items[index].todaysGainLoss = value
                }
                let value = items[index].price * items[index].quantity
                items[index].totalValue = value
                gainLossTotal += items[index].gainLose
                grandTotal += items[index].totalValue
            }
            itemsClass.items = items
        })
        .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
            Button("OK", role: .destructive) {
                deleteItem(firestoreId: firestoreId, portfolio: self.portfolio)
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
}

struct PurchaseDateView: View {
    var item: ItemData
    @State var purchaseDateString = ""
    @State var purchaseDate: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(purchaseDateString)
        }
        .onAppear {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yy"
            let date = dateFormatter.date(from: item.purchasedDate) ?? Date()
            purchaseDateString = dateFormatter.string(from: date)
        }
    }
}

struct SoldDateView: View {
    var item: ItemData
    @State var soldDateString = ""
    @State var soldDate: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(soldDateString)
        }
        .onAppear {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yy"
            soldDate = dateFormatter.date(from: item.soldDate) ?? Date()
            soldDateString = dateFormatter.string(from: soldDate)
        }
    }
}
