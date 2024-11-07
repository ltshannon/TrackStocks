//
//  AppNavigationState.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/6/24.
//

import Foundation

struct PortfolioParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var portfolioName: String
    
    init(portfolioName: String) {
        self.portfolioName = portfolioName
    }
}

struct PortfolioDetailParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: ItemData
    var portfolioName: String
    
    init(item: ItemData, portfolioName: String) {
        self.item = item
        self.portfolioName = portfolioName
    }
}

enum PortfolioNavDestination: Hashable {
    case portfolioView(PortfolioParameters)
    case portfolioDetailView(PortfolioDetailParameters)
}

class AppNavigationState: ObservableObject {
    @Published var portfolioNavigation: [PortfolioNavDestination] = []
    
    func portfolioView(parameters: PortfolioParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioView(parameters))
    }
    
    func portfolioDetailView(parameters: PortfolioDetailParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioDetailView(parameters))
    }
    
}