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
    var searchText: String
    
    init(portfolio: Portfolio, searchText: String) {
        self.portfolio = portfolio
        self.searchText = searchText
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

struct DividendEditParameters: Identifiable, Hashable, Encodable  {
    var id = UUID().uuidString
    var item: ItemData
    var portfolio: Portfolio
    var dividendDisplayData: DividendDisplayData
    
    init(item: ItemData, portfolio: Portfolio, dividendDisplayData: DividendDisplayData) {
        self.item = item
        self.portfolio = portfolio
        self.dividendDisplayData = dividendDisplayData
    }
}

enum PortfolioNavDestination: Hashable {
    case portfolioView(PortfolioParameters)
    case portfolioDetailView(PortfolioDetailParameters)
    case portfolioUpdateView(PortfolioUpdateParameters)
    case portfolioSoldView(PortfolioUpdateParameters)
    case dividendCreateView(DividendCreateParameters)
    case dividendEditView(DividendEditParameters)
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
    
    func dividendEditView(parameters: DividendEditParameters) {
        portfolioNavigation.append(PortfolioNavDestination.dividendEditView(parameters))
    }
    
}
