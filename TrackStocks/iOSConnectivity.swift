//
//  iOSConnectivity.swift
//  TrackStocks
//
//  Created by Larry Shannon on 1/29/26.
//

import Foundation
import WatchConnectivity
import SwiftUI
import BackgroundTasks

@Observable
class iOSConnectivity: NSObject, WCSessionDelegate {
    static let shared = iOSConnectivity()
    var count: Int64 = 0
    var task: BGContinuedProcessingTask?
    var timer: Timer?
    var shouldContinue = false
    var lastRegularSession: [ItemData] = []
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            debugPrint("🦉", "Watch Connectivity is available")
        }
        
    }
    
    func stopWatchOSDataFeed() {
        shouldContinue = false
        
    }
    
    func startWatchOSDataFeed() {
        @AppStorage("taskId") var taskIdCount = 0
        let firebaseService = FirebaseService.shared
        count = 0
        shouldContinue = true
        taskIdCount += 1
        let taskId = "com.breakawaydesign.TrackStocks.backgroundTask." + String(taskIdCount)
        let request = BGContinuedProcessingTaskRequest(
                                                        identifier: taskId,
                                                        title: "Update Stocks on Watch",
                                                        subtitle: "When in the background, keep the stocks up to date."
                                                       )
        request.strategy = .fail
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskId, using: .main) { value in
            
            self.task = value as? BGContinuedProcessingTask
            self.task!.expirationHandler = {
                self.shouldContinue = false
            }
            self.task!.progress.totalUnitCount = 100000
            self.task!.progress.completedUnitCount = 0
            debugPrint("🦉", "Start Watch timer")
            self.timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { timer in
                self.count += 1
                self.task!.progress.completedUnitCount = self.count
                debugPrint("🦉", "Timer fired. count: \(self.count)")
                let portfolio: Portfolio = Portfolio(name: "WatchOS")
                if self.checkMarketHours(for: Date()) == .regularSession {
                    Task {
                        let results = await firebaseService.refreshPortfolio(portfolio: portfolio, isMarketHours: true)
                        self.sendUpdatedStocks(stocks: results.0)
                        self.lastRegularSession = results.0
                    }
                } else { //if self.checkMarketHours(for: Date()) == .afterHours || self.checkMarketHours(for: Date()) == .preMarket {
                    Task {
                        let results = await firebaseService.refreshPortfolio(portfolio: portfolio, isMarketHours: false)
                        self.sendUpdatedStocks(stocks: results.0)
                    }
                }
                if self.shouldContinue == false {
                    debugPrint("🦉", "Watch update timer stopped")
                    timer.invalidate()
                    BGTaskScheduler.shared.cancelAllTaskRequests()
                    self.task!.setTaskCompleted(success: true)
                }
            }
        }
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            debugPrint("🤢", "Background task could not be scheduled")
        }
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in
            if activationState == .activated {
                if session.isWatchAppInstalled {
                    debugPrint("😀", "Watch app is installed")
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func setContext(to payload: [String : Any]) {
        let session = WCSession.default
        if session.activationState == .activated {
            do {
                try session.updateApplicationContext(payload)
            } catch {
                print("Updating context failed")
            }
        }
        
    }
    
    func sendUpdatedStocks(stocks: [ItemData]) {
        let watchStocks = stocks.map { WatchStock(symbol: $0.symbol, price: $0.price, change: $0.change ?? 0, gainLose: $0.gainLose) }
        if let stockData = try? JSONEncoder().encode(watchStocks) {
            let stocksPayload: [String : Any] = ["stocks" : stockData]
            setContext(to: stocksPayload)
        }
        
    }
    
    enum marketHours: Codable {
        case preMarket
        case regularSession
        case afterHours
        case closed
    }
    
    func checkMarketHours(for date: Date) -> marketHours {
        var calendar = Calendar.current
        // Set the time zone to US/Eastern
        if let easternTimeZone = TimeZone(identifier: "America/New_York") {
            calendar.timeZone = easternTimeZone
        } else {
            // Handle error or use a default time zone if Eastern not found
            return .closed
        }

        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        
        guard let weekday = components.weekday,
              let hour = components.hour,
              let minute = components.minute else {
            return .closed
        }

        // Check if it's a weekday (Monday=2 to Friday=6 in most calendars)
        // Note: Calendar.current usually uses 1 for Sunday, 2 for Monday, etc.
        let isWeekday = (weekday >= 2 && weekday <= 6)

        if !isWeekday {
            return .closed
        }

        // Check if the time is between 9:30 AM (9:30) and 4:30 PM (16:30)
        var startTimeHour = 9
        var startTimeMinute = 30
        var endTimeHour = 16 // 4 PM in 24-hour format
        var endTimeMinute = 30

        var timeInMinutes = hour * 60 + minute
        var startTimeInMinutes = startTimeHour * 60 + startTimeMinute
        var endTimeInMinutes = endTimeHour * 60 + endTimeMinute

        if (timeInMinutes >= startTimeInMinutes && timeInMinutes <= endTimeInMinutes) {
            return .regularSession
        }
        
        // Check if the time is between 4:00 AM and 9:30 AM
        startTimeHour = 4
        startTimeMinute = 0
        endTimeHour = 9
        endTimeMinute = 30

        timeInMinutes = hour * 60 + minute
        startTimeInMinutes = startTimeHour * 60 + startTimeMinute
        endTimeInMinutes = endTimeHour * 60 + endTimeMinute

        if (timeInMinutes >= startTimeInMinutes && timeInMinutes <= endTimeInMinutes) {
            return .preMarket
        }
        
        // Check if the time is between 4:00 PM and 8:00 PM
        startTimeHour = 16
        startTimeMinute = 30
        endTimeHour = 20
        endTimeMinute = 0

        timeInMinutes = hour * 60 + minute
        startTimeInMinutes = startTimeHour * 60 + startTimeMinute
        endTimeInMinutes = endTimeHour * 60 + endTimeMinute

        if (timeInMinutes >= startTimeInMinutes && timeInMinutes <= endTimeInMinutes) {
            return .afterHours
        }
        
        return .closed
    }

    
}
