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
    @State private var showSignIn: Bool = false
//    var parameters = DetailStocksNotificationParameters(notificationData: NotificationData(symbol: "", action: .notSelected, amount: 0))
    var parameters = StocksNotificationParameters()
    @State private var activity: Activity<StockTrackingAttributes>? = nil

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
        .onChange(of: firebaseService.user) { oldValue, newValue in
            if var newNotifications = newValue.notifications, newNotifications.count > 0 {
                if var oldNotifications = oldValue.notifications, oldNotifications.count == newNotifications.count {
                    newNotifications.sort(by: { $0 < $1 } )
                    oldNotifications.sort(by: { $0 < $1 } )
                    if newNotifications != oldNotifications {
                        sendActivity(notifications: newNotifications)
                    }
                } else {
                    sendActivity(notifications: newNotifications)
                }
            }
        }
        
    }
    
    func sendActivity(notifications: [String]) {
        let items = Array(firebaseService.convertToNotificationData(data: notifications).prefix(6))
        let state = StockTrackingAttributes.ContentState(items: items)
        
        if activity != nil {
            Task {
                await activity?.update(ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!))
            }
        } else {
            let attributes = StockTrackingAttributes()
            activity = try? Activity<StockTrackingAttributes>.request(attributes: attributes, content: ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!), pushType: nil)
        }
    }
}

#Preview {
    ContentView()
}
