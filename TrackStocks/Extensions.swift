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

extension CaseIterable {
    static func random<G: RandomNumberGenerator>(using generator: inout G) -> Self.AllCases.Element {
        return Self.allCases.randomElement(using: &generator)!
    }

    static func random() -> Self.AllCases.Element {
        var g = SystemRandomNumberGenerator()
        return Self.random(using: &g)
    }
}

func getColorOfChange(change: Float?, isSold: Bool = false) -> Color {
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

