//
//  AddNewStockToPortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/3/24.
//

import SwiftUI
import SwiftData

struct AddNewStockToPortfolioView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) var dismiss
    var portfolioName: String = ""
    @State var basis: String = ""
    @State var quantity: String = ""
    @State var selectedStock = ""
    @State var selectedDate = ""
    @State var showingStockSelector: Bool = false
    @State var showingDateSelector: Bool = false
    @State var showingMissingSymbol: Bool = false
    @State var showingMissingDate: Bool = false
    @State var showingMissingQuantity: Bool = false
    @State var showingMissingBasis: Bool = false

    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case symbol, quantity, basis
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        TextField("Stock Symbol", text: $selectedStock)
                            .textCase(.uppercase)
                            .disableAutocorrection(true)
                            .simultaneousGesture(TapGesture().onEnded {
                                showingStockSelector = true
                            })
                    } header: {
                        Text("Stock Symbol")
                    }
                    Section {
                        TextField("Date", text: $selectedDate)
                            .textCase(.uppercase)
                            .disableAutocorrection(true)
                            .simultaneousGesture(TapGesture().onEnded {
                                showingDateSelector = true
                            })
                    } header: {
                        Text("Select a date")
                    }
                    Section {
                        TextField("Quantity", text: $quantity)
//                            .focused($focusedField, equals: .quantity)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Number of shares")
                    }
                    Section {
                        TextField("Basis", text: $basis)
//                            .focused($focusedField, equals: .basis)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Cost Basis")
                    }
                }
                Button {
                    add()
                } label: {
                    Text("Add")
                }
                .buttonStyle(.borderedProminent)
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle(portfolioName)
            .alert("You are missing a Stock Symbol", isPresented: $showingMissingSymbol) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("You are missing a Date", isPresented: $showingMissingDate) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("You are missing a Number of Shares", isPresented: $showingMissingQuantity) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("You are missing a Cost Basis", isPresented: $showingMissingBasis) {
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showingStockSelector) {
                StockSymbolSelectorView(symbol: $selectedStock)
            }
            .fullScreenCover(isPresented: $showingDateSelector) {
                StockDateSelectorView(selectedDate: $selectedDate)
            }
        }
    }
    
    func add() {
        if selectedStock.isEmpty {
            showingMissingSymbol = true
            return
        }
        if selectedDate.isEmpty {
            showingMissingDate = true
            return
        }
        if quantity.isEmpty {
            showingMissingQuantity = true
            return
        }
        if basis.isEmpty {
            showingMissingBasis = true
            return
        }
        let item = ItemData(firestoreId: "", symbol: selectedStock.uppercased(), basis: Float(basis) ?? 0, price: 0, gainLose: 0, percent: 0, quantity: Double(quantity) ?? 0, isSold: false, date: selectedDate)
        Task {
            dismiss()
            await portfolioService.addStock(listName: portfolioName, item: item)
        }
    }
    
}

#Preview {
    AddNewStockToPortfolioView()
}
