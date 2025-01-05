//
//  StockNotificationView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/22/24.
//

import SwiftUI

enum NotificationType: String, Codable, CaseIterable, Identifiable, Hashable {
    case price = "Price"
    case volume = "Volume"
    
    var id: Self { self }
    
}

enum NotificationFrequency: String, Codable, CaseIterable, Identifiable, Hashable {
    case once = "Once"
    case repeated = "Repeated"
    
    var id: Self { self }
    
}

struct StockNotificationView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var appNavigationState: AppNavigationState
    @State var notificationData: [NotificationData] = []
    @State var showingAddNewStockNotification: Bool = false
    @State var selectedStockNotification: NotificationData = NotificationData()
    @State var showDeleteStockNotificationAlert = false
    
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
                        Text("Action by Price")
                    }
                    Section {
                        ForEach(notificationData, id: \.id) { item in
                            if item.notificationType == .volume {
                                DisplaynotificationDataView(item: item, selectedStockNotification: $selectedStockNotification, showDeleteStockNotificationAlert: $showDeleteStockNotificationAlert)
                            }
                        }
                    } header: {
                        Text("Action by Volume")
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
                self.notificationData = convertToNotificationData(data: data)

            }
        }
    }
    
    func updateDisplay() {
        let data = firebaseService.user.notifications
        self.notificationData = convertToNotificationData(data: data)

    }
    
    func convertToNotificationData(data: [String]?) -> [NotificationData] {
        var notificationData: [NotificationData] = []
        if let data = data {
            for item in data {
                let value = item.split(separator: ",")
                if value.count == 7 {
                    let symbol = String(value[0])
                    let notificationType = getNotificationTypeFromString(action: String(value[1]))
                    let notificationFrequency = getNotificationFrequencyFromString(action: String(value[2]))
                    let action = getNotificationActionFromString(action: String(value[3]))
                    let amount = Double(value[4]) ?? 0
                    let marketPrice = Double(value[5]) ?? 0
                    let volume = String(value[6])
                    let result = NotificationData(symbol: symbol, notificationType: notificationType, notificationFrequency: notificationFrequency, action: action, amount: amount, marketPrice: marketPrice, volume: volume)
                    notificationData.append(result)
                }
            }
            notificationData.sort { $0.symbol < $1.symbol }
        }
        return notificationData
        
    }
    
    func delete(item: NotificationData) {
        Task {
            await firebaseService.deleteStockNotification(item: item)
//            updateDisplay()
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
                Text(item.action.rawValue)
                if item.notificationType == .price {
                    Text(item.amount, format: .currency(code: "USD"))
                } else {
                    Text("\(String(format: "%.0f", item.amount))")
                }
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

