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

struct SymbolChartParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var symbol: String
}

struct PortfolioMoveParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var item: ItemData
    var portfolio: Portfolio
    
    init(item: ItemData, portfolio: Portfolio) {
        self.item = item
        self.portfolio = portfolio
    }
}

struct PortfolioAddParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString

}


enum PortfolioNavDestination: Hashable {
    case portfolioView(PortfolioParameters)
    case portfolioDetailView(PortfolioDetailParameters)
    case portfolioUpdateView(PortfolioUpdateParameters)
    case portfolioSoldView(PortfolioUpdateParameters)
    case dividendCreateView(DividendCreateParameters)
    case dividendEditView(DividendEditParameters)
    case symbolChartView(SymbolChartParameters)
    case portfolioMoveView(PortfolioMoveParameters)
    case portfolioAddView(PortfolioAddParameters)
}

enum NavigationNavDestination: Hashable {
    case stocksNotificationView(StocksNotificationParameters)
    case detailStocksNotificationView(DetailStocksNotificationParameters)
}

class AppNavigationState: ObservableObject {
    @Published var portfolioNavigation: [PortfolioNavDestination] = []
    @Published var navigationNavigation: [NavigationNavDestination] = []
    
    func symbolChartView(parameters: SymbolChartParameters) {
        portfolioNavigation.append(PortfolioNavDestination.symbolChartView(parameters))
    }
    
    func detailStocksNotificationView(parameters: DetailStocksNotificationParameters) {
        navigationNavigation.append(NavigationNavDestination.detailStocksNotificationView(parameters))
    }
    
    func stocksNotificationView(parameters: StocksNotificationParameters) {
        navigationNavigation.append(NavigationNavDestination.stocksNotificationView(parameters))
    }
    
    func portfolioAddView(parameters: PortfolioAddParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioAddView(parameters))
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
    
    func portfolioMoveView(parameters: PortfolioMoveParameters) {
        portfolioNavigation.append(PortfolioNavDestination.portfolioMoveView(parameters))
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
