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
//            if UIDevice.current.userInterfaceIdiom != .pad {
                ScrollView(.horizontal) {
                    PortfolioDetailInfoView(item: item)
                }
                Divider()
                Text("Dividends")
//            }
            List {
                    Section {
                        ForEach(dividendList, id: \.id) { dividend in
                            if dividend.quantity.isEmpty == true {
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
                    } header: {
                        Text("Cash")
                    }
            }
            List {
                    Section {
                        ForEach(dividendList, id: \.id) { dividend in
                            if dividend.quantity.isNotEmpty {
                                HStack {
                                    Text("\(dividend.date)")
                                    Text("\(dividend.quantity)")
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
                    } header: {
                        Text("Shares")
                    }
            }
//            SymbolChartView(symbol: item.symbol)
            Spacer()
        }
        .padding([.leading, .trailing], 20)
        .navigationTitle(UIDevice.current.userInterfaceIdiom == .pad ? item.symbol + " Dividends" : item.symbol + " Details")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
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
                if value.count == 3 {
                    let item = DividendDisplayData(id: String(value[0]), symbol: item.symbol, date: String(value[1]), price: String(value[2]))
                    data.append(item)
                }
                if value.count == 4 {
                    let item = DividendDisplayData(id: String(value[0]), symbol: item.symbol, date: String(value[1]), price: String(value[2]), quantity: String(value[3]))
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
        }
    }
}
