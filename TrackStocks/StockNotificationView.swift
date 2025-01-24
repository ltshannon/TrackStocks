//
//  StockNotificationView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/22/24.
//

import SwiftUI
import ActivityKit

struct StockNotificationView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var activiyStatus: ActivityStatus
    @State var notificationData: [NotificationData] = []
    @State var showingAddNewStockNotification: Bool = false
    @State var selectedStockNotification: NotificationData = NotificationData()
    @State var showDeleteStockNotificationAlert = false
    @State var showingActivityStatus: Bool = false
    @State var activityStatus: String = "Activities started successfully"
    
    init(parameters: StocksNotificationParameters) {
        self.selectedStockNotification = NotificationData()
    }
    
    var body: some View {
        NavigationStack(path: $appNavigationState.navigationNavigation) {
            VStack {
                Form {
                    Section {
                        ForEach(notificationData, id: \.id) { item in
                            if item.notificationType == .price {
                                DisplaynotificationDataView(item: item, selectedStockNotification: $selectedStockNotification, showDeleteStockNotificationAlert: $showDeleteStockNotificationAlert)
                            }
                        }
                    } header: {
                        Text("Stocks")
                    }
                    Section {
                        Group {
                            if activiyStatus.activityActive == false {
                                Button {
                                    Task {
                                        await startActivity()
                                        showingActivityStatus = true
                                    }
                                } label: {
                                    Text("Start Activity")
                                }
                            }
                            if activiyStatus.activityActive == true {
                                Button {
                                    Task {
                                        await endActivity()
                                    }
                                } label: {
                                    Text("End Activity")
                                }
                            }
                        }
                        .buttonStyle(PlainTextButtonStyle())
                    }
                }

            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let notificationData = NotificationData(symbol: "", action: .notSelected, amount: 0)
                        let parameters = DetailStocksNotificationParameters(notificationData: notificationData)
                        appNavigationState.detailStocksNotificationView(parameters: parameters)
                    } label: {
                        Image(systemName: "plus.app")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .onAppear {
                checkActivityStatus()
            }
            .navigationTitle("Stock Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                updateDisplay()
            }
            .alert("Are you sure you want to delete this?", isPresented: $showDeleteStockNotificationAlert) {
                Button("OK", role: .destructive) {
                    delete(item: selectedStockNotification)
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert(activityStatus, isPresented: $showingActivityStatus) {
                Button("OK", role: .destructive) {}
            }
            .fullScreenCover(isPresented: $showingAddNewStockNotification, onDismiss: updateDisplay) {
                let notificationData = NotificationData(symbol: "", action: .notSelected, amount: 0)
                let parameters = DetailStocksNotificationParameters(notificationData: notificationData)
                DetailStockNotificationView(parameters: parameters)
            }
            .navigationDestination(for: NavigationNavDestination.self) { state in
                switch state {
                case .stocksNotificationView(let parameters):
                    StockNotificationView(parameters: parameters)
                case .detailStocksNotificationView(let parameters):
                    DetailStockNotificationView(parameters: parameters)
                }
            }
            .onChange(of: firebaseService.user) { oldValue, newValue in
                let data = firebaseService.user.notifications
                self.notificationData = firebaseService.convertToNotificationData(data: data)
            }
            
        }
    }
    
    func checkActivityStatus() {
        Task {
            if let activity = activiyStatus.activity {
                await observeActivity(activity: activity)
            }
        }
    }
    
    @MainActor
    func observeActivity(activity: Activity<StockActivityAttributes>) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                for await activityState in activity.activityStateUpdates {
                    debugPrint("👔", "activityState: ", activityState)
                    if ActivityKit.ActivityState.active == .active {
                        activiyStatus.activityActive = true
                    }
                    if ActivityKit.ActivityState.active == .dismissed {
                        activiyStatus.activityActive = false
                    }
                }
            }
        }
    }
    
    func startActivity() async {
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let items = await Array(firebaseService.getStocksNotification().prefix(6))
            
            var activityArray: [ActivityData] = []
            for item in items {
                let activityItem = ActivityData(symbol: item.symbol, marketPrice: item.marketPrice, change: item.change)
                activityArray.append(activityItem)
            }
            let state = StockActivityAttributes.ContentState(items: activityArray)
            let attributes = StockActivityAttributes()
            let components = Calendar.current.date(byAdding: .year, value: 1, to: Date.now)
            
            do {
                activiyStatus.activity = try Activity<StockActivityAttributes>.request(attributes: attributes, content: ActivityContent(state: state, staleDate: components ?? Date.now), pushType: .token)
            } catch {
                debugPrint("Error starting activity: \(error)")
                activityStatus = "Failed to start activity"
            }
            Task {
                for await pushToken in activiyStatus.activity!.pushTokenUpdates {
                    let pushTokenString = pushToken.reduce("") {
                        $0 + String(format: "%02x", $1)
                    }
                    debugPrint("🦉, New push token: \(pushTokenString)")
                    await firebaseService.updateAddActivity(token: pushTokenString)
                }
            }
            activityStatus = "Activities started successfully"
            activiyStatus.activityActive = true
        } else {
            activityStatus = "Activities are not enabled. Go to settings and enable Live Activities for this app"
            activiyStatus.activityActive = false
        }

    }
    
    func endActivity() async {
        let state = StockActivityAttributes.ContentState(items: [])
        let dismissalPolicy: ActivityUIDismissalPolicy = .immediate
        if let activity = activiyStatus.activity {
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: dismissalPolicy)
            activiyStatus.activityActive = false
        }
        
    }
    
    func updateDisplay() {
        let data = firebaseService.user.notifications
        self.notificationData = firebaseService.convertToNotificationData(data: data)

    }
    
    func delete(item: NotificationData) {
        Task {
            await firebaseService.deleteStockNotification(item: item)
        }
        
    }
    
}

struct DisplaynotificationDataView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    var item: NotificationData
    @Binding var selectedStockNotification: NotificationData
    @Binding var showDeleteStockNotificationAlert: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text(item.symbol)
//                Text(item.action.rawValue)
//                if item.notificationType == .price {
//                    Text(item.amount, format: .currency(code: "USD"))
//                } else {
//                    Text("\(String(format: "%.0f", item.amount))")
//                }
                Text(item.marketPrice, format: .currency(code: "USD"))
                Text("\(item.volume)")
            }
            .swipeActions(allowsFullSwipe: false) {
                Button {
                    let parameters = DetailStocksNotificationParameters(notificationData: item)
                    appNavigationState.detailStocksNotificationView(parameters: parameters)
                } label: {
                    Text("Update")
                }
                .tint(.indigo)
                Button(role: .destructive) {
                    selectedStockNotification = item
                    showDeleteStockNotificationAlert = true
                } label: {
                    Text("Delete")
                }
            }
        }
    }
    
}

