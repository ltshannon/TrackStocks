//
//  AddNewStockToPortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/3/24.
//

import SwiftUI

struct AddNewStockToPortfolioView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    var portfolioName: String = ""
    @State var basis: String = ""
    @State var quantity: String = ""
    @State var selectedStock = ""
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case symbol, quantity, basis
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        TextField("Quantity", text: $quantity)
                            .focused($focusedField, equals: .quantity)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Number of shares")
                    }
                    Section {
                        TextField("Basis", text: $basis)
                            .focused($focusedField, equals: .basis)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Cost Basis")
                    }
                }
            }
        }
        .navigationTitle(portfolioName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {

                } label: {
                    HStack {
                        Image(systemName: "plus.app")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
        }
    }
    
    func add() {
        let item = ItemData(firestoreId: "", symbol: selectedStock, basis: Float(basis) ?? 0, price: 0, gainLose: 0, percent: 0, quantity: Double(quantity) ?? 0, isSold: false)
        Task {
            dismiss()
            await portfolioService.addStock(listName: portfolioName, item: item)
        }
    }
    
        
}

#Preview {
    AddNewStockToPortfolioView()
}
