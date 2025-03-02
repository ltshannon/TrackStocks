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
    @AppStorage("showDatePicker") var showDatePicker = false
    var item: ItemData
    var portfolio:Portfolio
    @State var symbol: String = ""
    @State var basis: Decimal = 0
    @State var price: String = ""
    @State var soldPrice: String = ""
    @State var quantity: Decimal = 0
    @State var purcahseDate: String = ""
    @State var soldDate: String = ""
    @State var firestoreId: String = ""
    @State var dividendDisplayData: [DividendDisplayData] = []
    @State var showingDateSelector: Bool = false
    @State private var selectedOption: StockPicks = .none
    @State private var dobText: String = ""
    @State var textLen = 0
    
    init(parameters: PortfolioUpdateParameters) {
        self.portfolio = parameters.portfolio
        self.item = parameters.item
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
                    Text("Purchase Date")
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
                    Text(soldDate)
                } header: {
                    Text("Sold Date")
                }
                if item.isSold == false {
                    Section {
                        Picker("Select a Tag", selection: $selectedOption) {
                            ForEach(StockPicks.allCases) { option in
                                Text(String(describing: option))
                            }
                        }
                    } header: {
                        Text("Tag")
                    }
                }
                if dividendDisplayData.count > 0 {
                    Section {
                        ForEach(dividendDisplayData, id: \.id) { item in
                            HStack {
                                Text(item.date)
                                if let dec = Float(item.price) {
                                    Text(dec, format: .currency(code: "USD"))
                                } else {
                                    Text("n/a")
                                }
                            }
                        }
                    } header: {
                        Text("Dividends")
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Update \(symbol)")
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
            quantity = Decimal(item.quantity)
            basis = Decimal(Double(item.basis))
            price = item.price.formatted(.currency(code: "USD"))
            dobText = item.purchasedDate
            soldDate = item.soldDate
            firestoreId = item.firestoreId
            if let stockPick = item.stockTag {
                selectedOption = selectedOption.getStockPick(type: stockPick)
            }
        }
        .fullScreenCover(isPresented: $showingDateSelector) {
            StockDateSelectorView(selectedDate: $dobText)
        }
        
    }

    func update() {
        Task {
            dismiss()
            await firebaseService.updateItem(firestoreId: firestoreId, portfolioName: portfolio.id ?? "n/a", quantity: quantity, basis: basis, date: dobText, stockTag: selectedOption.description)
        }
    }
    
}
