//
//  AddStockToPortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/3/24.
//

import SwiftUI
import SwiftData

enum FocusedField: Hashable {
    case symbol, date, quantity, basis
}

struct AddStockToPortfolioView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    var portfolioName: String = ""
    @State var basis: Double?
    @State var quantity: Double?
    @State var selectedStock = ""
    @State var selectedDate = ""
    @State var showingStockSelector: Bool = false
    @State var showingDateSelector: Bool = false
    @State var showingMissingSymbol: Bool = false
    @State var showingMissingDate: Bool = false
    @State var showingMissingQuantity: Bool = false
    @State var showingMissingBasis: Bool = false
    @State private var selectedStockTagOption: StockPicks = .none
    
    @State var navigationLinkTriggerer: Bool? = nil
    
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
                        if showDatePicker == true {
                            TextField("Date", text: $selectedDate)
                                .textCase(.uppercase)
                                .disableAutocorrection(true)
                                .simultaneousGesture(TapGesture().onEnded {
                                    showingDateSelector = true
                                })
                        } else {
                            TextField("Date", text: $selectedDate)
                                .textCase(.uppercase)
                                .keyboardType(.numbersAndPunctuation)
                        }
                    } header: {
                        Text("Date")
                    }
                    Section {
                        TextField("Quantity", value: $quantity, format: .number.precision(.fractionLength(3)))
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Number of shares")
                    }
                    Section {
                        TextField("Average Price", value: $basis, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Average Price per Share")
                    }
                    Section {
                        Picker("Select a Tag", selection: $selectedStockTagOption) {
                            ForEach(StockPicks.allCases) { option in
                                Text(String(describing: option))
                            }
                        }
                    } header: {
                        Text("Tag")
                    }
                }
                .listSectionSpacing(1)
            }
            .navigationTitle("Add a stock to \(portfolioName)")
            .navigationBarTitleDisplayMode(.inline)
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        add()
                    } label: {
                        Text("Save")
                    }
                }
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
        if quantity == nil {
            showingMissingQuantity = true
            return
        }
        if basis == nil {
            showingMissingBasis = true
            return
        }
        var doubleQuantity: Double = 0
        if let a = quantity {
            doubleQuantity = a
        } else {
            showingMissingQuantity = true
            return
        }
        var doubleBasis: Double = 0
        if let a = basis {
            doubleBasis = a
        } else {
            showingMissingBasis = true
            return
        }
        Task {
            dismiss()
            await firebaseService.addItem(portfolioName: portfolioName, symbol: selectedStock.uppercased(), quantity: doubleQuantity, basis: doubleBasis, purchasedDate: selectedDate, soldDate: "n/a", stockTag: selectedStockTagOption.rawValue)
        }
    }
    
}

#Preview {
    AddStockToPortfolioView()
}
