//
//  watchOSConnectivity.swift
//  TrackStocksWatch Watch App
//
//  Created by Larry Shannon on 1/29/26.
//

import Foundation
import WatchConnectivity
import SwiftUI
import WidgetKit

class watchOSConnectivity: NSObject, WCSessionDelegate {
    static let shared = watchOSConnectivity()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("😈", "OSWatch: didReceiveApplicationContext")
        Task { @MainActor in
            let stockManager = StockManager.shared
            if let watchStocks = applicationContext["stocks"] as? Data {
                if let decodedStocks = try? JSONDecoder().decode([WatchStock].self, from: watchStocks) {
                    debugPrint("💚", decodedStocks)
                    stockManager.stocks = decodedStocks
                    stockManager.selectedStock = decodedStocks.first
                    SharedStocks.update(stock: stockManager.selectedStock)
                    WidgetCenter.shared.reloadAllTimelines()
                } else {
                    print("Failed to decode stocks from JSON")
                }
            }
//            else {
//                if let updatedTally = applicationContext["update"] as? Data {
//                    if let decodedUpdate = try? JSONDecoder().decode(WatchTally.self, from: updatedTally) {
//                        if let index = tallyManager.tallies.firstIndex(where: {$0.name == decodedUpdate.name}) {
//                            tallyManager.tallies[index].value = decodedUpdate.value
//                            if tallyManager.selectedTally?.name == decodedUpdate.name {
//                                withAnimation {
//                                    tallyManager.selectedTally?.value = decodedUpdate.value
//                                    SharedTally.update(tally: tallyManager.selectedTally)
//                                    WidgetCenter.shared.reloadAllTimelines()
//                                }
//                            }
//                        }
//                    }
//                }
//            }
        }
    }
    
}
