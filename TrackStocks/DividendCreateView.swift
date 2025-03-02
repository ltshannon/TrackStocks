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
    @State var dividendAmount = ""
    @State var showingDateSelector: Bool = false
    @State var basis = ""
    @State var quantity = ""
    @State var showingMissingDate: Bool = false
    @State var showingMissingAmount: Bool = false
    @State var showingMissingQuantity: Bool = false
    @State var showingMissingBasis: Bool = false
    @State private var dividendType: DividendType = .cash
    @State private var dobText: String = ""
    @State var textLen = 0
    
    init(parameters: DividendCreateParameters) {
        self.portfolio = parameters.portfolio
        self.item = parameters.item
        self.isOnlyShares = parameters.isOnlyShares
    }
    
    var body: some View {
        VStack {
            Form {
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
        .navigationTitle(isOnlyShares ? "Add shares to \(symbol)" : "Dividend for \(symbol)")
        .navigationBarTitleDisplayMode(.inline)
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
            StockDateSelectorView(selectedDate: $dobText)
        }
        .onAppear {
            symbol = item.symbol
            dobText = ""
            firestoreId = item.firestoreId
            if isOnlyShares == true {
                dividendType = .shares
            }
        }
    }
    
    func addDividend() {
        if dobText.isEmpty {
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
                await firebaseService.addCashDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: firestoreId, dividendDate: dobText, dividendAmount: dividendAmount)
            } else {
                await firebaseService.addSharesDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: firestoreId, dividendDate: dobText, dividendAmount: basis, numberOfShares: quantity)
            }
        }
    }

}
