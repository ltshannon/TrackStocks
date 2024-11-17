//
//  AppNavigationState.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/6/24.
//

import Foundation

struct PortfolioParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var portfolio: Portfolio
    
    init(portfolio: Portfolio) {
        self.portfolio = portfolio
    }
}

struct PortfolioDetailParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: ItemData
    var portfolio: Portfolio
    
    init(item: ItemData, portfolio: Portfolio) {
        self.item = item
        self.portfolio = portfolio
    }
}

struct PortfolioUpdateParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: ItemData
    var portfolio: Portfolio
    
    init(item: ItemData, portfolio: Portfolio) {
        self.item = item
        self.portfolio = portfolio
    }
}

struct DividendCreateParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: ItemData
    var portfolio: Portfolio
    
    init(item: ItemData, portfolio: Portfolio) {
        self.item = item
        self.portfolio = portfolio
    }
}

enum PortfolioNavDestination: Hashable {
    case portfolioView(PortfolioParameters)
    case portfolioDetailView(PortfolioDetailParameters)
    case portfolioUpdateView(PortfolioUpdateParameters)
    case portfolioSoldView(PortfolioUpdateParameters)
    case dividendCreateView(DividendCreateParameters)
}

class AppNavigationState: ObservableObject {
    @Published var portfolioNavigation: [PortfolioNavDestination] = []
    
    func portfolioView(parameters: PortfolioParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioView(parameters))
    }
    
    func portfolioDetailView(parameters: PortfolioDetailParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioDetailView(parameters))
    }
    
    func portfolioUpdateView(parameters: PortfolioUpdateParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioUpdateView(parameters))
    }
    
    func portfolioSoldView(parameters: PortfolioUpdateParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioSoldView(parameters))
    }
    
    func dividendCreateView(parameters: DividendCreateParameters) {
        portfolioNavigation.append(PortfolioNavDestination.dividendCreateView(parameters))
    }
    
}
