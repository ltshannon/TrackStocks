//
//  StockNotificationView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/22/24.
//

import SwiftUI

struct StockNotificationView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var appNavigationState: AppNavigationState
    @State var notificationData: [NotificationData] = []
    @State var showingAddNewStockNotification: Bool = false
    @State var selectedStockNotification: NotificationData = NotificationData()
    @State var showUpdateStockNotification = false
    @State var showDeleteStockNotificationAlert = false
    
    init(parameters: StocksNotificationParameters) {
        self.selectedStockNotification = NotificationData()
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(notificationData, id: \.id) { item in
                        HStack {
                            Text(item.symbol)
                            Text(item.action.rawValue)
                            Text("\(String(format: "%.2f", item.amount))")
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
        .navigationTitle("Add Stock Notifications")
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
        .fullScreenCover(isPresented: $showUpdateStockNotification, onDismiss: updateDisplay) {
            let parameters = DetailStocksNotificationParameters(notificationData: selectedStockNotification)
            DetailStockNotificationView(parameters: parameters)
        }
    }
    
    func updateDisplay() {
        Task {
            let data = await firebaseService.getStocksNotification()
            await MainActor.run {
                notificationData = data
            }
        }
    }
    
    func delete(item: NotificationData) {
        Task {
            await firebaseService.deleteStockNotification(item: item)
            updateDisplay()
        }
    }
    
}
