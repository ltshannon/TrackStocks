//
//  ActivityStatus.swift
//  TrackStocks
//
//  Created by Larry Shannon on 1/19/25.
//

import Foundation
import ActivityKit

class ActivityStatus: ObservableObject {
    @Published var activity: Activity<StockActivityAttributes>? = nil
    @Published var activityActive: Bool = false
    
}
