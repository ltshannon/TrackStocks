//
//  ContentView.swift
//  TrackStocksWatch Watch App
//
//  Created by Larry Shannon on 1/29/26.
//

import SwiftUI

struct ContentView: View {
    let connectivity = watchOSConnectivity.shared
    @Environment(StockManager.self) var stockManager
    @State private var changeSelected = false
    
    var body: some View {
        NavigationStack {
            Group {
                if stockManager.stocks.isEmpty {
                    ContentUnavailableView("Launch the app on the iPhone", image: "CUImage")
                } else {
                    MyStocksListView()
                }
            }
//            .sheet(isPresented: $changeSelected) {
//                MyStocksListView()
//            }
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button {
//                        changeSelected.toggle()
//                    } label: {
//                        Image(systemName: "list.bullet")
//                    }
//                }
//            }
        }
    }
}

#Preview(traits: .mockData) {
    ContentView()
}

struct MockData: PreviewModifier {
    func body(content: Content, context: Void) -> some View {
        @Previewable @State var stockManager = StockManager()
        stockManager.updateStocks(stocks: WatchStock.mockStock)
        return content
            .environment(stockManager)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var mockData: Self = .modifier(MockData())
}
