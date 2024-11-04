//
//  PortfolioHomeView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 11/1/24.
//

import SwiftUI

struct PortfolioHomeView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @State var showAlert = false
    @State var portfolioName: String = ""
    @State var firstTime = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(firebaseService.portfolioList, id: \.id) { item in
                        NavigationLink(destination: PortfolioView(portfolioName: item.name)) {
                            VStack {
                                Text(item.name)
                            }
                        }

                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.app")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
        }
        .onAppear {
            if firstTime {
                firstTime = false
                firebaseService.listenerForPortfolios()
            }
        }
        .alert("Add Portfolio", isPresented: $showAlert) {
            TextField("Name", text: $portfolioName)
                .keyboardType(.decimalPad)
            Button("OK", action: add)
            Button("Cancel", role: .cancel) { }
         } message: {
            Text("Enter the name of the portfolio.")
         }
    }
    
    func add() {
        Task {
            await firebaseService.addPortfolio(portfolioName: portfolioName)
        }
    }
}

#Preview {
    PortfolioHomeView()
}
