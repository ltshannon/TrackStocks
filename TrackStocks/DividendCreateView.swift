//
//  DividendCreateView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/20/24.
//

import SwiftUI

enum DividendType: String, CaseIterable, Identifiable {
    case cash = "Cash"
    case shares = "Shares"
    
    var id: Self { self }

}

struct DividendCreateView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    var item: ItemData
    var portfolio: Portfolio
    var isOnlyShares = false
    @State var symbol: String = ""
    @State var firestoreId: String = ""
    @State var selectedDate = ""
    @State var dividendAmount = ""
    @State var showingDateSelector: Bool = false
    @State var basis = ""
    @State var quantity = ""
    @State var showingMissingDate: Bool = false
    @State var showingMissingAmount: Bool = false
    @State var showingMissingQuantity: Bool = false
    @State var showingMissingBasis: Bool = false
    @State private var dividendType: DividendType = .cash
    
    init(parameters: DividendCreateParameters) {
        self.portfolio = parameters.portfolio
        self.item = parameters.item
        self.isOnlyShares = parameters.isOnlyShares
    }
    
    var body: some View {
        VStack {
            Form {
                if isOnlyShares == false {
                    Section {
                        Picker("Select Dividend Type", selection: $dividendType) {
                            ForEach(DividendType.allCases) { item in
                                Text("\(item.rawValue)")
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Select Dividend Type")
                    }
                }
                Section {
                    Text(symbol)
                } header: {
                    Text("Symbol")
                }
                Section {
                    if showDatePicker == true {
                        TextField("Dividend Date", text: $selectedDate)
                            .textCase(.uppercase)
                            .disableAutocorrection(true)
                            .simultaneousGesture(TapGesture().onEnded {
                                showingDateSelector = true
                            })
                    } else {
                        TextField("Dividend Date", text: $selectedDate)
                            .textCase(.uppercase)
                            .keyboardType(.numbersAndPunctuation)
                    }
                } header: {
                    Text("Date")
                }
                if dividendType == .cash {
                    Section {
                        TextField("Amount", text: $dividendAmount)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Enter an Amount")
                    }
                } else {
                    Section {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Number of shares")
                    }
                    Section {
                        TextField("Average Price", text: $basis)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Average Price per Share")
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Dividend")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addDividend()
                } label: {
                    Text("Save")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
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
        .alert("You are missing an amount", isPresented: $showingMissingAmount) {
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showingDateSelector) {
            StockDateSelectorView(selectedDate: $selectedDate)
        }
        .onAppear {
            symbol = item.symbol
            selectedDate = ""
            firestoreId = item.firestoreId
            if isOnlyShares == true {
                dividendType = .shares
            }
        }
    }
    
    func addDividend() {
        if selectedDate.isEmpty {
            showingMissingDate = true
            return
        }
        if dividendType == .cash {
            if dividendAmount.isEmpty {
                showingMissingAmount = true
                return
            }
        }
        if dividendType == .shares {
            if quantity.isEmpty {
                showingMissingQuantity = true
                return
            }
            if basis.isEmpty {
                showingMissingBasis = true
                return
            }
        }
        dismiss()
        Task {
            if dividendType == .cash {
                await firebaseService.addCashDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: firestoreId, dividendDate: selectedDate, dividendAmount: dividendAmount)
            } else {
                await firebaseService.addSharesDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: firestoreId, dividendDate: selectedDate, dividendAmount: basis, numberOfShares: quantity)
            }
        }
    }

}
