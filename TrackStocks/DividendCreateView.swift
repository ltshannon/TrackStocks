//
//  DividendCreateView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/20/24.
//

import SwiftUI

struct DividendCreateView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) private var dismiss
    var item: ItemData
    var portfolioName: String
    @State var symbol: String = ""
    @State var firestoreId: String = ""
    @State var selectedDate = ""
    @State var dividendAmount = ""
    @State var showingDateSelector: Bool = false
    
    init(paramters: DividendCreateParameters) {
        self.portfolioName = paramters.portfolioName
        self.item = paramters.item
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    Text(symbol)
                } header: {
                    Text("Symbol")
                }
                Section {
                    TextField("Dividend Date", text: $selectedDate)
                        .textCase(.uppercase)
                        .disableAutocorrection(true)
                        .simultaneousGesture(TapGesture().onEnded {
                            showingDateSelector = true
                        })
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
        .fullScreenCover(isPresented: $showingDateSelector) {
            StockDateSelectorView(selectedDate: $selectedDate)
        }
        .onAppear {
            symbol = item.symbol
            selectedDate = item.purchasedDate
            firestoreId = item.firestoreId
        }
    }
    
    func addDividend() {
        dismiss()
        Task {
//            await portfolioService.addDividend(listName: key.rawValue, symbol: symbol, dividendDate: dividendDate, dividendAmount: dividendAmount)
//            await firebaseService.addDividend(listName: listName, symbol: symbol, dividendDate: dividendDate, dividendAmount: dividendAmount)
        }
    }

}
