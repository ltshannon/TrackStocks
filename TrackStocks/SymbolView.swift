//
//  HomeView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/1/24.
//

import SwiftUI

struct SymbolView: View {
    @EnvironmentObject var stockDataService: StockDataService
    @State var symbols: [SymbolData] = []
    @State var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(searchResults, id: \.id) { item in
                        Text(item.id)
                    }
                }
                .padding()
                .searchable(text: $searchText, prompt: "Enter Stock Symbol")
//                .task {
//                    let results = await stockDataService.fetchSymbols()
//                    await MainActor.run {
//                        symbols = results
//                    }
//                }
            }
        }
        .navigationTitle("Symbol Search")
    }
    
    var searchResults: [SymbolData] {
        if searchText.isEmpty {
            return symbols
        } else {
            return symbols.filter { $0.id.contains(searchText.uppercased()) }
        }
    }
}

#Preview {
    SymbolView()
}
