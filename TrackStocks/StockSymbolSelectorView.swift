//
//  StockSymbolSelectorView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/8/24.
//

import SwiftUI

struct StockSymbolSelectorView: View {
    @EnvironmentObject var marketSymbolsService: MarketSymbolsService
    @Environment(\.dismiss) private var dismiss
    @Binding var symbol: String
    @State var symbols: [MarketSymbols] = []
    @State var searchText = ""
    @State var selectedStock = ""
    @State var showingNotSelectedAlert = false
    
    var body: some View {
        NavigationStack {
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
            }
            Button {
                if selectedStock.isEmpty {
                    showingNotSelectedAlert = true
                    return
                }
                symbol = selectedStock
                dismiss()
            } label: {
                Text("Done")
            }
            .buttonStyle(.borderedProminent)
            Button {
                dismiss()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(.borderedProminent)
        }
        .searchable(text: $searchText, prompt: "Enter Stock Symbol")
        .onAppear {
            symbols = marketSymbolsService.marketSymbols
        }
        .alert("You haven't entered a Stock Symbol", isPresented: $showingNotSelectedAlert) {
            Button("Cancel", role: .cancel) { }
        }
    }
    
    var searchResults: [MarketSymbols] {
        if searchText.isEmpty {
            return []
        } else {
            return symbols.filter { $0.symbol.contains(searchText.uppercased()) }
        }
    }
}

