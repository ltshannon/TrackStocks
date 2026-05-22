//
//  Extensions.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/27/24.
//

import Foundation
import SwiftUI

enum StockPicks: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case topStock = "t.circle"
    case top5 = "5.circle"
    case hold = "h.circle"
    case sell = "s.circle"
    case new = "n.circle"
    case none = ""
    
    var description: String {
        switch self {
        case .topStock: return "Top Stock"
        case .top5: return "Top 5"
        case .hold: return "Hold"
        case .sell: return "Sell"
        case .new: return "New"
        case .none: return "None"
        }
    }
    
    func getStockPick(type: String) -> StockPicks {
        switch type {
        case "Top Stock": return .topStock
        case "Top 5": return .top5
        case "Hold": return .hold
        case "Sell": return .sell
        case "New": return .new
        default: return .none
        }

    }
    
    var id: Self { self }

}

public extension String {
    //Common
    static var empty: String { "" }
    static var space: String { " " }
    static var comma: String { "," }
    static var newline: String { "\n" }
    
    //Debug
    static var success: String { "🎉" }
    static var test: String { "🧪" }
    static var notice: String { "⚠️" }
    static var warning: String { "🚧" }
    static var fatal: String { "☢️" }
    static var reentry: String { "⛔️" }
    static var stop: String { "🛑" }
    static var boom: String { "💥" }
    static var sync: String { "🚦" }
    static var key: String { "🗝" }
    static var bell: String { "🔔" }
    
    var isNotEmpty: Bool {
        !isEmpty
    }
}

extension UIColor {
    static var accentColor: UIColor {
        UIColor(named: "AccentColor") ?? .blue
    }
}

extension Font {
    static let buttonText: Font = Font.system(size: 19, weight: .regular).leading(.loose)
}

extension String {
    func camelCaseToWords() -> String {
        return unicodeScalars.dropFirst().reduce(String(prefix(1))) {
            return CharacterSet.uppercaseLetters.contains($1)
                ? $0 + " " + String($1)
                : $0 + String($1)
        }
    }
    
    func getChartName(item: ItemData) -> String {
        if item.isSold {
            return "star.circle"
        }
        if let value = item.change, value < 0 {
            return "chart.line.downtrend.xyaxis"
        }
        if let value = item.change, value > 0 {
            return "chart.line.uptrend.xyaxis"
        }
        return "chart.line.flattrend.xyaxis"
    }
    
    func getSymbol() -> StockPicks {
        let sym = StockPicks.random()
        return sym
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {

    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else { return "" }
        return result
    }
}

extension CaseIterable {
    static func random<G: RandomNumberGenerator>(using generator: inout G) -> Self.AllCases.Element {
        return Self.allCases.randomElement(using: &generator)!
    }

    static func random() -> Self.AllCases.Element {
        var g = SystemRandomNumberGenerator()
        return Self.random(using: &g)
    }
}

func getColorOfChange(change: Double?, isSold: Bool = false) -> Color {
    if isSold {
        return .orange
    }
    if let value = change, value < 0 {
        return .red
    }
    return .green
}

func getColorOfStockPick(stockPick: StockPicks) -> Color {
    switch stockPick {
    case .hold: return .yellow
    case .new: return .green
    case .sell: return .red
    case .top5: return .teal
    case .topStock: return .blue
    case .none: return .clear
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

func getNotificationActionFromString(action: String) -> NotificationAction {
    switch action {
    case NotificationAction.lessThan.rawValue : return .lessThan
    case NotificationAction.greaterThan.rawValue : return .greaterThan
    case NotificationAction.equalTo.rawValue : return .equalTo
    case NotificationAction.lessThanOrEqualTo.rawValue : return .lessThanOrEqualTo
    case NotificationAction.greaterThanOrEqualTo.rawValue : return .greaterThanOrEqualTo
    default: return .notSelected
    }
    
}

func getNotificationTypeFromString(action: String)-> NotificationType {
    switch action {
    case NotificationType.price.rawValue : return .price
    case NotificationType.volume.rawValue : return .volume
    default: return .price
    }
    
}

func getNotificationFrequencyFromString(action: String) -> NotificationFrequency {
    switch action {
    case NotificationFrequency.once.rawValue : return .once
    case NotificationFrequency.repeated.rawValue : return .repeated
    default: return .once
    }
    
}

extension Date {
    func isWeekdayAndBetweenWorkHours() -> Bool {
        let calendar = Calendar.current
        
        // 1. Check if it's a weekday
        // Weekday values typically range from 1 (Sunday) to 7 (Saturday),
        // depending on the locale. isDateInWeekend() is more reliable.
        if calendar.isDateInWeekend(self) {
            return false
        }
        
        // 2. Check the time components
        let components = calendar.dateComponents([.hour, .minute], from: self)
        guard let hour = components.hour, let minute = components.minute else {
            return false
        }
        
        // Define the target time range
        let startHour = 9
        let startMinute = 30
        let endHour = 16 // 4 PM
        let endMinute = 30
        
        // Create comparable minute values
        let currentTimeInMinutes = hour * 60 + minute
        let startTimeInMinutes = startHour * 60 + startMinute
        let endTimeInMinutes = endHour * 60 + endMinute
        
        // Check if the current time falls within the range
        // Use a half-open range to include the start time but exclude the end time
        return currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes < endTimeInMinutes
    }
}




