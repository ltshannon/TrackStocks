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
    @State var showingStockSelector: Bool = false
    @State var showingDateSelector: Bool = false
    @State var showingMissingSymbol: Bool = false
    @State var showingMissingDate: Bool = false
    @State var showingMissingQuantity: Bool = false
    @State var showingMissingBasis: Bool = false
    @State private var selectedStockTagOption: StockPicks = .none
    @State var navigationLinkTriggerer: Bool? = nil
    @State private var dobText: String = ""
    @State var textLen = 0
    
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
                            TextField("MM/DD/YY", text: $dobText)
                                .textCase(.uppercase)
                                .disableAutocorrection(true)
                                .simultaneousGesture(TapGesture().onEnded {
                                    showingDateSelector = true
                                })
                        } else {
                            TextField("MM/DD/YY", text: $dobText)
                                .textCase(.uppercase)
                                .keyboardType(.numberPad)
                                .onChange(of: dobText) { oldValue, newValue in
                                    ProcessDate(newValue: newValue, dobText: &dobText, textLen: &textLen)
                                }
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
                StockDateSelectorView(selectedDate: $dobText)
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
        if dobText.isEmpty {
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
            await firebaseService.addItem(portfolioName: portfolioName, symbol: selectedStock.uppercased(), quantity: doubleQuantity, basis: doubleBasis, purchasedDate: dobText, soldDate: "n/a", stockTag: selectedStockTagOption.rawValue)
        }
    }
    
}

func ProcessDate(newValue: String, dobText: inout String, textLen: inout Int) {
    if newValue.count < textLen {
        dobText = ""
        textLen = 0
        return
    }
    // Check if the input length exceeds 8 characters
     guard newValue.count <= 8 else {
         dobText = String(newValue.prefix(8))
         return
     }
    
     // Handle backspace
     if newValue.count < dobText.count {
         dobText = ""
         return
     }
     if newValue.count >= 2 && !newValue.contains("/") {
         dobText.insert("/", at: dobText.index(dobText.startIndex, offsetBy: 2))
     }
     if newValue.count >= 5 && !newValue[dobText.index(dobText.startIndex, offsetBy: 5)...].contains("/") {
         dobText.insert("/", at: dobText.index(dobText.startIndex, offsetBy: 5))
     }
    textLen = dobText.count
}


#Preview {
    AddStockToPortfolioView()
}
