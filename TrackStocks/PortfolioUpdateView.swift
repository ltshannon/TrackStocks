//
//  PortfolioUpdateView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/10/24.
//

import SwiftUI

struct PortfolioUpdateView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) private var dismiss
    var item: ItemData
    var portfolioName: String
    @State var symbol: String = ""
    @State var selectedDate = ""
    @State var basis: Decimal = 0
    @State var price: String = ""
    @State var soldPrice: String = ""
    @State var quantity: Decimal = 0
    @State var purcahseDate: String = ""
    @State var soldDate: String = ""
    @State var firestoreId: String = ""
    @State var dividendDisplayData: [DividendDisplayData] = []
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
                    TextField("Date", text: $selectedDate)
                        .textCase(.uppercase)
                        .disableAutocorrection(true)
                        .simultaneousGesture(TapGesture().onEnded {
                            showingDateSelector = true
                        })
                } header: {
                    Text("Purchase Date")
                }
                Section {
                    TextField("Quantity", value: $quantity, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Number of shares")
                }
                Section {
                    TextField("Basis", value: $basis, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Cost Basis")
                }
                Section {
                    Text(soldDate)
                } header: {
                    Text("Sold Date")
                }
                if dividendDisplayData.count > 0 {
                    Section {
                        ForEach(dividendDisplayData, id: \.id) { item in
                            HStack {
                                Text(item.date)
                                Text(item.price, format: .currency(code: "USD"))
                            }
                        }
                    } header: {
                        Text("Dividends")
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Update")
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
            quantity = Decimal(item.quantity)
            basis = Decimal(Double(item.basis))
            price = item.price.formatted(.currency(code: "USD"))
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
            await firebaseService.updateItem(firestoreId: firestoreId, portfolioName: portfolioName, quantity: quantity, basis: basis, date: selectedDate)
        }
    }
    
}
