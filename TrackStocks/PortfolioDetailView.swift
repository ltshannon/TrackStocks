//
//  PortfolioDetailView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/5/24.
//

import SwiftUI

struct PortfolioDetailView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) private var dismiss
    @State var item: ItemData
    @State var portfolio: Portfolio
    @State var dividendList: [DividendDisplayData] = []
    @State var showDeleteDividendAlert = false
    @State var dividendToDelete: DividendDisplayData = DividendDisplayData()
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        return formatter
    }()
    
    init(parameters: PortfolioDetailParameters) {
        self.item = parameters.item
        self.portfolio = parameters.portfolio
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
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
                        Text(String(format: "%.2f", item.price))
                        Text(item.change != nil ? String(format: "%.2f", item.change!) : "n/a")
                        Text(item.changesPercentage ?? 0, format: .percent.precision(.fractionLength(2)))
                    }
                    .font(.caption)
                    VStack(alignment: .leading) {
                        Text("Bought: \(item.purchasedDate)")
                        Text("Sold: \(item.soldDate)")
                        Text("")
                    }
                    .font(.caption)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Open")
                            Text(item.open != nil ? String(format: "%.2f", item.open!) : "n/a")
                        }
                        HStack {
                            Text("High")
                            Text(item.dayHigh != nil ? String(format: "%.2f", item.dayHigh!) : "n/a")
                        }
                        HStack {
                            Text("Low")
                            Text(item.dayLow != nil ? String(format: "%.2f", item.dayLow!) : "n/a")
                        }
                    }
                    .font(.caption)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("52W H")
                            Text(item.yearHigh != nil ? String(format: "%.2f", item.yearHigh!) : "n/a")
                        }
                        HStack {
                            Text("52W L")
                            Text(item.yearLow != nil ? String(format: "%.2f", item.yearLow!) : "n/a")
                        }
                        HStack {
                            Text("Avg Vol")
                            Text(item.avgVolume != nil ? String(format: "%.2f", item.avgVolume!) : "n/a")
                        }
                    }
                    .font(.caption)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Vol")
                            Text(item.volume != nil ? String(format: "%.2f", item.volume!) : "n/a")
                        }
                        HStack {
                            Text("P/E")
                            Text(item.pe != nil ? String(format: "%.2f", item.pe!) : "n/a")
                        }
                        HStack {
                            Text("Mkt Cap")
                            Text(item.marketCap != nil ? String(format: "%.2f", item.marketCap!) : "n/a")
                        }
                    }
                    .font(.caption)
                    Spacer()
                }
            }
            Divider()
            Text("Dividends")
            List {
                ForEach(dividendList, id: \.id) { dividend in
                    HStack {
                        Text("\(dividend.date)")
                        if let dec = Float(dividend.price) {
                            Text(dec, format: .currency(code: "USD"))
                        } else {
                            Text("n/a")
                        }
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button {
                            let parameters = DividendEditParameters(item: item, portfolio: portfolio, dividendDisplayData: dividend)
                            appNavigationState.dividendEditView(parameters: parameters)
                        } label: {
                            Text("Update")
                        }
                        .tint(.orange)
                        Button(role: .destructive) {
                            dividendToDelete = dividend
                            showDeleteDividendAlert = true
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
            Spacer()
        }
        .padding([.leading, .trailing], 20)
        .navigationTitle(item.symbol + " Details")
        .navigationBarBackButtonHidden(true)
        .alert("Are you sure you want to delete this?", isPresented: $showDeleteDividendAlert) {
            Button("OK", role: .destructive) {
                delete(dividend: dividendToDelete)
            }
            Button("Cancel", role: .cancel) { }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
        }
        .onAppear {
            dividendList = item.dividendList
        }
        .onChange(of: firebaseService.masterSymbolList) { oldValue, newValue in
            if let masterSymbol = newValue.filter({ $0.portfolioName == self.portfolio.name }).first {
                let portfolioItems = masterSymbol.portfolioItems
                if let item = portfolioItems.filter({ $0.symbol == self.item.symbol }).first {
                    Task {
                        await updateDividends(array: item.dividends)
                    }
                }
            }
        }
        
    }
    
    func updateDividends(array: [String]?) async {
        if let array = array {
            var data: [DividendDisplayData] = []
            let _ = array.map {
                let value = $0.split(separator: ",")
                if value.count == 2 {
                    let item = DividendDisplayData(symbol: item.symbol, date: String(value[0]), price: String(value[1]))
                    data.append(item)
                }
            }
            await MainActor.run {
                dividendList = data
            }
        }
    }
    
    func delete(dividend: DividendDisplayData) {
        Task {
            await firebaseService.deleteDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: item.firestoreId, dividendDisplayData: dividend)
//            for item in dividendList {
//                if item.id == dividend.id {
//                    let index = dividendList.firstIndex(of: item)
//                    let _ = await MainActor.run {
//                        dividendList.remove(at: index!)
//                    }
//                }
//            }
//            await updateDividends()
        }
    }
}
