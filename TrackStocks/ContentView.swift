//
//  ContentView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 10/30/24.
//

import SwiftUI
import WidgetKit
import ActivityKit

struct ContentView: View {
    @EnvironmentObject var userAuth: Authentication
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.firebaseSignInWithApple) private var firebaseSignInWithApple
    @Environment(\.dismiss) var dismiss
    @State private var showSignIn: Bool = false
    var parameters = StocksNotificationParameters()
    @State private var activity: Activity<StockTrackingAttributes>? = nil
    @State private var activityToken: Activity<StockActivityAttributes>? = nil

    var body: some View {
        TabView {
            PortfolioHomeView()
                .tabItem {
                    Label("Portfolios", systemImage: "rectangle.grid.2x2")
                }
                .tag(1)
            StockNotificationView(parameters: parameters)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .tag(2)
            TotalsView()
                .tabItem {
                    Label("Totals", systemImage: "dollarsign.bank.building")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onReceive(userAuth.$fcmToken) { token in
            if token.isNotEmpty {
                Task {
                    await firebaseService.updateAddFCM(token: token)
                }
            }
        }
        .onChange(of: firebaseSignInWithApple.state) { oldValue, newValue in
            if newValue == .notAuthenticated {
                dismiss()
            }
        }
    }
    
}

#Preview {
    ContentView()
}
