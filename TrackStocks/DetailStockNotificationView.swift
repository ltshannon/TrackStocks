//
//  DetailStockNotificationView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/23/24.
//

import SwiftUI

struct DetailStockNotificationView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    var oldSymbol = ""
    var oldNotificationType: NotificationType = .price
    var oldAction: NotificationAction = .notSelected
    var oldAmount: Double = 0
    @State var selectedStock = ""
    @State var selectedNotificationType: NotificationType = .price
    @State var selectedNotificationAction: NotificationAction = .notSelected
    @State var amount: Double?
    @State var showingStockSelector: Bool = false
    @State var showingMissingSymbol: Bool = false
    @State var showingMissingAction: Bool = false
    @State var showingMissingAmount: Bool = false
    
    init(parameters: DetailStocksNotificationParameters) {
        let notificationData = parameters.notificationData
        oldSymbol = notificationData.symbol
        oldNotificationType = notificationData.notificationType
        oldAction = notificationData.action
        oldAmount = notificationData.amount
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Stock Symbol", text: $selectedStock)
                        .textCase(.uppercase)
                        .disableAutocorrection(true)
                        .simultaneousGesture(TapGesture().onEnded {
                            showingStockSelector = true
                        })
                } header: {
                    Text("Stock Symbol")
                }
                Section {
                    Picker("Select Notification Type", selection: $selectedNotificationType) {
                        ForEach(NotificationType.allCases) { item in
                            Text("\(item.rawValue)")
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Select Notification Type")
                }
                Section {
                    Picker("Select a Action", selection: $selectedNotificationAction) {
                        ForEach(NotificationAction.allCases) { option in
                            Text(option.rawValue)
                        }
                    }
                } header: {
                    Text("Select a Action")
                }
                Section {
                    TextField("Amount", value: $amount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Amount")
                }
            }
            .listSectionSpacing(1)
        }
        .navigationTitle("Add a Notification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    add()
                } label: {
                    Text("Save")
                }
            }
        }
        .onAppear {
            self.selectedStock = oldSymbol
            self.selectedNotificationType = oldNotificationType
            self.selectedNotificationAction = oldAction
            self.amount = oldAmount
        }
        .alert("You are missing a Stock Symbol", isPresented: $showingMissingSymbol) {
            Button("Cancel", role: .cancel) { }
        }
        .alert("You need to select an action", isPresented: $showingMissingAction) {
            Button("Cancel", role: .cancel) { }
        }
        .alert("You are missing an amount", isPresented: $showingMissingAmount) {
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showingStockSelector) {
            StockSymbolSelectorView(symbol: $selectedStock)
        }
    }
    
    func add() {
        if selectedStock.isEmpty {
            showingMissingSymbol = true
            return
        }
        if selectedNotificationAction == .notSelected {
            showingMissingAction = true
            return
        }
        if amount == nil {
            showingMissingAmount = true
            return
        }
        var doubleAmount: Double = 0
        if let a = amount {
            doubleAmount = a
        } else {
            showingMissingAmount = true
            return
        }

        Task {
            if oldSymbol == "" && oldNotificationType == .price && oldAction == .notSelected && oldAmount == 0 {
                await firebaseService.addStocksNotification(symbol: selectedStock, notificationType: selectedNotificationType, action: selectedNotificationAction, amount: doubleAmount)
            } else {
                let oldNotificationData = NotificationData(symbol: oldSymbol, notificationType: oldNotificationType, action: oldAction, amount: oldAmount)
                let newNotificationData = NotificationData(symbol: selectedStock, notificationType: selectedNotificationType,  action: selectedNotificationAction, amount: doubleAmount)
                await firebaseService.updateStocksNotification(oldNotificationData: oldNotificationData, newNotificationData: newNotificationData)
            }
            dismiss()
        }
    }
    
}
