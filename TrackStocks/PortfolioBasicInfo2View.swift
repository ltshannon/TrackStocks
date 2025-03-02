//
//  PortfolioBasicInfo2View.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/9/24.
//

import SwiftUI
                        
class ItemsClass: ObservableObject {
    @Published var items: [ItemData] = []
    
    enum SortType {
        case symbol
        case todaysLossGain
        case totalLossGain
        case currentValue
    }
    
    var sortType: SortType = .symbol
}

struct PortfolioBasicInfo2View: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    var portfolio: Portfolio
    var items: [ItemData]
    @StateObject var itemsClass: ItemsClass = ItemsClass()
    @State var dividendTotalAmount: Float = 0
    @State var dividendTotalShares: Float = 0
    @State var dividendSharesAmount: Float = 0
    @State var isPercent: Bool = false
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
                                GridItem(.fixed(65), spacing: 5),
                                GridItem(.fixed(65), spacing: 5),
                                GridItem(.fixed(65), spacing: 5),
                                GridItem(.fixed(70), spacing: 5),
                                GridItem(.fixed(100), spacing: 5),
                                GridItem(.fixed(95), spacing: 1),
                                GridItem(.fixed(110), spacing: 1),
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
                    Text("Price")
                    Text("Change")
                    Text("Percent")
                    Text("# of\nShares")
                    Text("Cost\nBasis")
                    Button {
                        itemsClass.sortType = .todaysLossGain
                        SortItems(ascending: isTodaysLossGainSortAscending, itemsClass: itemsClass)
                        isTodaysLossGainSortAscending.toggle()
                    } label: {
                        HStack(spacing: 1) {
                            Text("Today's\nGain/Loss")
                            SortArrow(isSortAscending: isTodaysLossGainSortAscending)
                        }
                        .underline()
                    }
                    Button {
                        itemsClass.sortType = .totalLossGain
                        SortItems(ascending: isTotalLossGainSortAscending, itemsClass: itemsClass)
                        isTotalLossGainSortAscending.toggle()
                    } label: {
                        HStack(spacing: 1) {
                            Text("Total\nGain/Loss")
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
                            Text("Current\nValue")
                            SortArrow(isSortAscending: isCurrentValueSortAscending)
                        }
                        .underline()
                    }
                    Text("")
                }
                    .underline()
                ForEach(itemsClass.items, id: \.id) { item in
                    Group {
                        View1(item: item)
                        PriceView(item: item)
                        ChangeView(item: item)
                        ChangesPercentageView(item: item)
                        NumberOfSharesView(item: item)
                        BasisView(item: item)
                        TodaysGainLossView(item: item)
                        GainLossView(gainLossTotal: $gainLossTotal, item: item)
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

func SortItems(ascending: Bool, itemsClass: ItemsClass) {
    
    if ascending == true {
        switch itemsClass.sortType {
        case .symbol: itemsClass.items.sort { $0.symbol < $1.symbol }
        case .todaysLossGain: itemsClass.items.sort { $0.todaysGainLoss < $1.todaysGainLoss }
        case .totalLossGain: itemsClass.items.sort { $0.gainLose < $1.gainLose }
        case .currentValue: itemsClass.items.sort { $0.totalValue < $1.totalValue }
        }
    } else {
        switch itemsClass.sortType {
        case .symbol: itemsClass.items.sort { $0.symbol > $1.symbol }
        case .todaysLossGain: itemsClass.items.sort { $0.todaysGainLoss > $1.todaysGainLoss }
        case .totalLossGain: itemsClass.items.sort { $0.gainLose > $1.gainLose }
        case .currentValue: itemsClass.items.sort { $0.totalValue > $1.totalValue }
        }
    }

}

func deleteItem(firestoreId: String, portfolio: Portfolio) {
    let firebaseService = FirebaseService.shared
    
    Task {
        await firebaseService.deletePortfolioStock(portfolioName: portfolio.id ?? "n/a", stockId: firestoreId)
    }
}

struct SortArrow: View {
    var isSortAscending: Bool
    
    var body: some View {
        Image(systemName: isSortAscending ? "arrow.down" : "arrow.up")
            .resizable()
            .scaledToFit()
            .frame(width: 15, height: 15)
    }
}

struct View1: View {
    var item: ItemData
    var isSoldPortfolio: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.symbol)
            .bold()
            .foregroundStyle(item.isSold && isSoldPortfolio == false ? .orange : .primary)
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

struct PriceView: View {
    var item: ItemData
    var isSoldPortfolio: Bool = false
    
    var body: some View {
        Text(item.price, format: .currency(code: "USD"))
            .foregroundStyle(isSoldPortfolio == false ? item.isSold ? .orange : .primary : .primary)
    }
    
}

struct ChangeView: View {
    var item: ItemData
    
    var body: some View {
        Text("\(String(format: "%.2f", item.change ?? 0))")
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous).fill(item.change ?? 0 < 0 ?.red : .green)
            )
    }
}

struct ChangesPercentageView: View {
    var item: ItemData
    
    var body: some View {
        Text(item.changesPercentage ?? 0, format: .percent.precision(.fractionLength(0)))
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous).fill(item.change ?? 0 < 0 ?.red : .green)
            )
    }
    
}

struct NumberOfSharesView: View {
    var item: ItemData
    var isSoldPortfolio: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(String(format: "%.2f", item.quantity))")
        }
        .foregroundStyle(isSoldPortfolio == false ? item.isSold ? .orange : .primary : .primary)
    }
}

struct BasisView: View {
    var item: ItemData
    var isSoldPortfolio: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.basis, format: .currency(code: "USD"))
        }
        .foregroundStyle(isSoldPortfolio == false ? item.isSold ? .orange : .primary : .primary)
    }
}

struct TodaysGainLossView: View {
    var item: ItemData
    
    var body: some View {
        VStack(alignment: .leading) {
            let todaysGainLoss = abs(item.todaysGainLoss)
            Text(todaysGainLoss, format: .currency(code: "USD"))
                .foregroundStyle(item.isSold ? .orange : (item.change ?? 0 >= 0 ? .green : .red))
        }
    }
}

struct GainLossView: View {
    @Binding var gainLossTotal: Double
    var item: ItemData
    var isSoldPortfolio: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
//            if item.isSold == false || isSoldPortfolio == true {
                let gainLose = abs(item.gainLose)
                Text(gainLose, format: .currency(code: "USD"))
                    .foregroundStyle(item.gainLose >= 0 ? .green : .red)
//            } else {
//                Text(item.gainLose, format: .currency(code: "USD"))
//                    .foregroundStyle(.orange)
//            }
        }
    }
}

struct TotalView: View {
    @Binding var grandTotal: Double
    var item: ItemData
    var isSoldPortfolio: Bool = false
    
    var body: some View {
        VStack {
            Text(item.totalValue, format: .currency(code: "USD"))
        }
        .onAppear {
//            grandTotal += item.totalValue
        }
    }

}

struct View3: View {
    var item: ItemData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(String(format: "%.2f", item.quantity))@\n\(String(format: "%.2f", item.basis))")
            Text(item.gainLose, format: .currency(code: "USD"))
            Text(item.percent, format: .percent.precision(.fractionLength(2)))
        }
        .font(.caption)
        .foregroundStyle(item.isSold ? .orange : (item.gainLose >= 0 ? .green : .red))
    }
}

struct View4: View {
    var item: ItemData
    @State var total: Double = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(total, format: .currency(code: "USD"))
                .font(.caption)
            .bold()
            .foregroundStyle(item.isSold ? .orange : (total >= 0 ? .green : .red))
        }
        .onAppear {
            var dividendAmount: Double = 0
            for dividend in item.dividendList {
                if dividend.quantity.isEmpty {
                    let dec = (dividend.price as NSString).doubleValue
                    if dec > 0 {
                        dividendAmount += dec
                    }
                }
            }
            total = item.gainLose
            if dividendAmount > 0 {
                total += dividendAmount
            }
        }
    }
}

struct View5: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    var portfolio: Portfolio
    var item: ItemData
    @Binding var showingDeleteAlert: Bool
    @Binding var firestoreId: String
//    @State var showingDeleteAlert = false
    
    var body: some View {
        VStack{
            Group {
                Menu {
                    Button {
                        let parameters = PortfolioDetailParameters(item: item, portfolio: portfolio)
                        appNavigationState.portfolioDetailView(parameters: parameters)
                    } label: {
                        Text("Stock Details").lineLimit(nil)
                    }
                    Button {
                        let parameters = SymbolChartParameters(symbol: item.symbol)
                        appNavigationState.symbolChartView(parameters: parameters)
                    } label: {
                        Text("Daily Chart").lineLimit(nil)
                    }
                    Button {
                        let parameters = PortfolioMoveParameters(item: item, portfolio: portfolio)
                        appNavigationState.portfolioMoveView(parameters: parameters)
                    } label: {
                        Text("Move to another portfolio")
                    }
                    if item.isSold == false {
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
                    }
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                        firestoreId = item.firestoreId
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                } label: {
                    Circle()
                        .fill(.gray.opacity(0.15))
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 13.0, weight: .semibold))
                                .foregroundColor(.blue)
                                .padding()
                        }
                }
                .font(.caption)
                .padding(0)
            }
        }
    }

}

struct View6: View {
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
