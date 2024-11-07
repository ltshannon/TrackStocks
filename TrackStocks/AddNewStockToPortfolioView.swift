//
//  AddNewStockToPortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/3/24.
//

import SwiftUI
import SwiftData

struct AddNewStockToPortfolioView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @EnvironmentObject var marketSymbolsService: MarketSymbolsService
    @Environment(\.dismiss) var dismiss
    var portfolioName: String = ""
    @State var basis: String = ""
    @State var quantity: String = ""
    @State var selectedStock = ""
    @State var searchText = ""
    @State var symbols: [MarketSymbols] = []
    @State var date: Date = Date()
    @State var showingMissingSymbol: Bool = false
    @State var showingMissingQuantity: Bool = false
    @State var showingMissingBasis: Bool = false

    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case symbol, quantity, basis
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack{
                        ForEach(searchResults, id: \.id) { item in
                            VStack(alignment: .leading)  {
                                HStack {
                                    Text(item.symbol)
                                        .font(.title2)
                                        .bold()
                                    Text(item.name)
                                }
                                .onTapGesture {
                                    selectedStock = item.symbol
                                }
                                Divider()
                            }
                        }
                    }
                    .padding([.leading, .trailing], 20)
                }
                Form {
                    Section {
                        TextField("Stock Symbol", text: $selectedStock)
                            .textCase(.uppercase)
                            .disableAutocorrection(true)
                            .disabled(true)
                    } header: {
                        Text("Stock Symbol")
                    }
                    Section {
                        DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(maxHeight: 200)
                    } header: {
                        Text("Select a date")
                    }
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
                Button {
                    add()
                } label: {
                    Text("Add")
                }
                .buttonStyle(.borderedProminent)
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle(portfolioName)
            .searchable(text: $searchText, prompt: "Enter Stock Symbol")
            .onAppear {
                symbols = marketSymbolsService.marketSymbols
            }
            .alert("You are missing a Stock Symbol", isPresented: $showingMissingSymbol) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("You are missing a Number of Shares", isPresented: $showingMissingQuantity) {
                Button("Cancel", role: .cancel) { }
            }
            .alert("You are missing a Cost Basis", isPresented: $showingMissingBasis) {
                Button("Cancel", role: .cancel) { }
            }
        }

    }
    
    var searchResults: [MarketSymbols] {
        if searchText.isEmpty {
            return []
        } else {
            return symbols.filter { $0.symbol.contains(searchText.uppercased()) }
        }
    }
    
    func add() {
        if selectedStock.isEmpty {
            showingMissingSymbol = true
            return
        }
        if quantity.isEmpty {
            showingMissingQuantity = true
            return
        }
        if basis.isEmpty {
            showingMissingBasis = true
            return
        }
        let formatter1 = DateFormatter()
        formatter1.dateStyle = .short
        let str = formatter1.string(from: date)
        let item = ItemData(firestoreId: "", symbol: selectedStock.uppercased(), basis: Float(basis) ?? 0, price: 0, gainLose: 0, percent: 0, quantity: Double(quantity) ?? 0, isSold: false, date: str)
        Task {
            dismiss()
            await portfolioService.addStock(listName: portfolioName, item: item)
        }
    }
    
}

#Preview {
    AddNewStockToPortfolioView()
}
