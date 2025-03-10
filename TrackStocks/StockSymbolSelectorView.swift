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
    @FocusState private var fieldFocused: Bool
    
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
                                symbol = item.symbol
                                dismiss()
                            }
                            Divider()
                        }
                    }
                }
                .padding([.leading, .trailing], 20)
                .searchable(text: $searchText, prompt: "Enter Stock Symbol")
//                .searchFocused($fieldFocused)
            }
            .navigationTitle("Select Stock")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
        .onAppear {
            symbols = marketSymbolsService.marketSymbols
            fieldFocused = true
        }
    }
    
    var searchResults: [MarketSymbols] {
        if searchText.isEmpty {
            return symbols
        } else {
            return symbols.filter { $0.symbol.contains(searchText.uppercased()) }
        }
    }
}

