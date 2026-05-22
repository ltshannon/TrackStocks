//
//  TrackStocksWatchApp.swift
//  TrackStocksWatch Watch App
//
//  Created by Larry Shannon on 1/29/26.
//

import SwiftUI

@main
struct TrackStocksWatch_Watch_AppApp: App {
    @State private var stockManager = StockManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stockManager)
        }
    }
}
