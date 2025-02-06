//
//  PortfolioMoveView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 1/21/25.
//

import SwiftUI

struct PortfolioMoveView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) private var dismiss
    var portfolio: Portfolio
    var item: ItemData
    @State var portfolios: [Portfolio] = []
    
    init(parameters: PortfolioMoveParameters) {
        self.portfolio = parameters.portfolio
        self.item = parameters.item
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(portfolios, id: \.self) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        moveItemToPortfolio(portfolio: item)
                    }
                }
            }
            .navigationTitle("Select Portfolio to Move: \(item.symbol)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            let values = firebaseService.portfolioList.filter { $0.name != portfolio.name }
            self.portfolios = values
        }
    }
    
    func moveItemToPortfolio(portfolio: Portfolio) {
        debugPrint("Moving \(item.symbol) to \(portfolio.name)")
        Task {
            await firebaseService.moveStockToPortfolio(oldPortfolio: portfolio, newPortfolioName: portfolio.name, stock: item)
            await firebaseService.deletePortfolioStock(portfolioName: self.portfolio.id ?? "n/a", stockId: item.firestoreId)
            dismiss()
        }
    }
    
}
