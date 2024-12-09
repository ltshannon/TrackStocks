//
//  PortfolioSoldView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/12/24.
//

import SwiftUI

struct PortfolioSoldView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    var item: ItemData
    var portfolio: Portfolio
    @State var symbol: String = ""
    @State var selectedDate = ""
    @State var soldPrice: Decimal = 0
    @State var soldDate: String = ""
    @State var firestoreId: String = ""
    @State var showingDateSelector: Bool = false
    
    init(parameters: PortfolioUpdateParameters) {
        self.portfolio = parameters.portfolio
        self.item = parameters.item
    }
    
    var body: some View {
        VStack {
            Form {
                Section {

                    if showDatePicker == true {
                        TextField("Sold Date", text: $selectedDate)
                            .textCase(.uppercase)
                            .disableAutocorrection(true)
                            .simultaneousGesture(TapGesture().onEnded {
                                showingDateSelector = true
                            })
                    } else {
                        TextField("Date", text: $selectedDate)
                            .textCase(.uppercase)
                    }
                } header: {
                    Text("Sold Date")
                }
                Section {
                    TextField("Sold Price per Share", value: $soldPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Sold Price per Share")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Sell \(symbol)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    update()
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
            symbol = item.symbol
            selectedDate = item.purchasedDate
            soldDate = item.soldDate
            firestoreId = item.firestoreId
        }
        .fullScreenCover(isPresented: $showingDateSelector) {
            StockDateSelectorView(selectedDate: $selectedDate)
        }
    }
    
    func update() {

        Task {
            dismiss()
            await firebaseService.soldItem(firestoreId: firestoreId, portfolioName: portfolio.id ?? "n/a", date: selectedDate, price: soldPrice)
        }
    }
}
