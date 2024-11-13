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
    var item: ItemData
    var portfolioName: String
    @State var symbol: String = ""
    @State var selectedDate = ""
    @State var soldPrice: Decimal = 0
    @State var soldDate: String = ""
    @State var firestoreId: String = ""
    @State var showingDateSelector: Bool = false
    
    init(paramters: PortfolioUpdateParameters) {
        self.portfolioName = paramters.portfolioName
        self.item = paramters.item
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Text(symbol)
                } header: {
                    Text("Stock Symbol")
                }
                Section {
                    TextField("Sold Date", text: $selectedDate)
                        .textCase(.uppercase)
                        .disableAutocorrection(true)
                        .simultaneousGesture(TapGesture().onEnded {
                            showingDateSelector = true
                        })
                } header: {
                    Text("Sold Date")
                }
                Section {
                    TextField("Sold Price", value: $soldPrice, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Sold Price")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Update Portfolio Item")
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
            await firebaseService.soldItem(firestoreId: firestoreId, portfolioName: portfolioName, date: selectedDate, price: soldPrice)
        }
    }
}
