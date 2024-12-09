//
//  DividendEditView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/20/24.
//

import SwiftUI

struct DividendEditView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    var item: ItemData
    var portfolio: Portfolio
    var dividendDisplayData: DividendDisplayData
    @State var dividendId = ""
    @State var dividendAmount = ""
    @State var dividendDate = ""
    @State var quantity = ""
    @State var showingDateSelector: Bool = false
    
    init(parameters: DividendEditParameters) {
        self.item = parameters.item
        self.portfolio = parameters.portfolio
        self.dividendDisplayData = parameters.dividendDisplayData
    }
    
    var body: some View {
        Form {
            Section {
                Text(item.symbol)
            } header: {
                Text("Symbol")
            }
            Section {
                if showDatePicker == true {
                    TextField("Dividend Date", text: $dividendDate)
                        .textCase(.uppercase)
                        .disableAutocorrection(true)
                        .simultaneousGesture(TapGesture().onEnded {
                            showingDateSelector = true
                        })
                } else {
                    TextField("Dividend Date", text: $dividendDate)
                        .textCase(.uppercase)
                        .keyboardType(.numbersAndPunctuation)
                }
            } header: {
                Text("Select a date")
            }
            if quantity.isEmpty {
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
                    TextField("Average Price", text: $dividendAmount)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Average Price per Share")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Update Dividend")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    updateDividend()
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
        .onAppear {
            dividendId = dividendDisplayData.id
            dividendDate = dividendDisplayData.date
            dividendAmount = dividendDisplayData.price
            quantity = dividendDisplayData.quantity
        }
        .fullScreenCover(isPresented: $showingDateSelector) {
            StockDateSelectorView(selectedDate: $dividendDate)
        }
    }
    
    func updateDividend() {
        Task {
            if quantity.isEmpty {
                await firebaseService.updateDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: item.firestoreId, dividendDisplayData: dividendDisplayData, dividendAmount: dividendAmount, dividendDate: dividendDate, numberOfShares: "")
            } else {
                await firebaseService.updateDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: item.firestoreId, dividendDisplayData: dividendDisplayData, dividendAmount: dividendAmount,  dividendDate: dividendDate, numberOfShares: quantity)
            }
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    func cancelDividend() {
        dismiss()
    }
}
