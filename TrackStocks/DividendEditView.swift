//
//  DividendEditView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/20/24.
//

import SwiftUI

struct DividendEditView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    var item: ItemData
    var portfolio: Portfolio
    var dividendDisplayData: DividendDisplayData
    @State var dividendAmount = ""
    @State var dividendDate = ""
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
            Section {
                TextField("Amount", text: $dividendAmount)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Enter an Amount")
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
            dividendDate = dividendDisplayData.date
//            if let dec = Float(dividendDisplayData.price) {
//                dividendAmount = dec.formatted(.currency(code: "USD"))
//            }
            dividendAmount = dividendDisplayData.price
        }
        .fullScreenCover(isPresented: $showingDateSelector) {
            StockDateSelectorView(selectedDate: $dividendDate)
        }
    }
    
    func updateDividend() {
        Task {
//            await portfolioService.updateDividend(listName: key.rawValue, symbol: dividendDisplayData.symbol, dividendDisplayData: dividendDisplayData, dividendDate: dividendDate, dividendAmount: dividendAmount)
//            await portfolioService.getDividend(key: key, symbol: dividendDisplayData.symbol)
            await firebaseService.updateDividend(portfolioName: portfolio.id ?? "n/a", firestoreId: item.firestoreId, dividendDisplayData: dividendDisplayData, dividendAmount: dividendAmount, dividendDate: dividendDate)
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    func cancelDividend() {
        dismiss()
    }
}
