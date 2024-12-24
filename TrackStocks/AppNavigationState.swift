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
    var isOnlyShares: Bool
    
    init(item: ItemData, portfolio: Portfolio, isOnlyShares: Bool = false) {
        self.item = item
        self.portfolio = portfolio
        self.isOnlyShares = isOnlyShares
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

struct StocksNotificationParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString

}

struct DetailStocksNotificationParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var notificationData: NotificationData
}

enum PortfolioNavDestination: Hashable {
    case portfolioView(PortfolioParameters)
    case portfolioDetailView(PortfolioDetailParameters)
    case portfolioUpdateView(PortfolioUpdateParameters)
    case portfolioSoldView(PortfolioUpdateParameters)
    case dividendCreateView(DividendCreateParameters)
    case dividendEditView(DividendEditParameters)
    case stocksNotificationView(StocksNotificationParameters)
    case detailStocksNotificationView(DetailStocksNotificationParameters)
}

class AppNavigationState: ObservableObject {
    @Published var portfolioNavigation: [PortfolioNavDestination] = []
    
    func detailStocksNotificationView(parameters: DetailStocksNotificationParameters) {
        portfolioNavigation.append(PortfolioNavDestination.detailStocksNotificationView(parameters))
    }
    
    func stocksNotificationView(parameters: StocksNotificationParameters) {
        portfolioNavigation.append(PortfolioNavDestination.stocksNotificationView(parameters))
    }
    
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
