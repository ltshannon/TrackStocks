//
//  TrackStocksApp.swift
//  TrackStocks
//
//  Created by Larry Shannon on 10/30/24.
//

import SwiftUI
import FirebaseCore
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        debugPrint("Firebase started")
        return true
    }
}

@main
struct TrackStocksApp: App {
    @StateObject var userAuth = Authentication.shared
    @StateObject var firebaseService = FirebaseService.shared
    @StateObject var stockDataService = StockDataService.shared
    @StateObject var marketSymbolsService = MarketSymbolsService.shared
    @StateObject var appNavigationState = AppNavigationState()
    @StateObject var settingsService = SettingsService.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SignInView()
                .environmentObject(userAuth)
                .environmentObject(firebaseService)
                .environmentObject(stockDataService)
                .environmentObject(marketSymbolsService)
                .environmentObject(appNavigationState)
                .environmentObject(settingsService)
        }
        .modelContainer(for: [SymbolStorage.self])
    }
}
