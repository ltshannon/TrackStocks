//
//  SimplePortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 12/3/24.
//

import SwiftUI

struct SimplePortfolioView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    var portfolio: Portfolio
    var items: [ItemData]
    @State var searchText = ""
    @State var isPercent: Bool = false
    @State var isCurrent: Bool = false
    @State var showingDeleteAlert = false
    @State var firestoreId: String = ""
    let columns: [GridItem] = [
                                GridItem(.fixed(55), spacing: 1),
                                GridItem(.fixed(50), spacing: 1),
                                GridItem(.fixed(65), spacing: 1),
                                GridItem(.fixed(64), spacing: 5),
                                GridItem(.fixed(80), spacing: 1),
                                GridItem(.fixed(50), spacing: 1),
                                ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading) {
                Group {
                    Text("Sym")
                    Text("Hold")
                    Text("Price")
                    Button {
                        isCurrent.toggle()
                    } label: {
                        Text(isCurrent ? "Current" : "Change")
                            .underline()
                    }
                    Button {
                        isPercent.toggle()
                    } label: {
                        Text(isPercent ? "Gain %" : "Gain $")
                            .underline()
                    }
                    Text("")
                }
                .underline()
                ForEach(items, id: \.id) { item in
                    Text("\(item.symbol)")
                        .foregroundStyle(item.isSold ? .orange : .primary)
                    View8(item: item)
                    Text("\(String(format: "%.2f", item.price))").bold()
                    if isCurrent == true {
                        let value = item.price * item.quantity
                        Text("\(value, specifier: "%.2f")")
                            .font(.caption)
                    } else {
                        Text("\(String(format: "%.2f", item.change ?? 0))")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous).fill(item.change ?? 0 < 0 ?.red : .green)
                            )
                    }
                    if isPercent {
                        Text(item.percent, format: .number.precision(.fractionLength(2)))
                                //.percent.precision(.fractionLength(2)))
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    } else {
                        let gainLose = abs(item.gainLose)
                        Text(gainLose, format: .number.precision(.fractionLength(2)))
                                //.currency(code: "USD"))
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    }
                    View5(portfolio: portfolio, item: item, showingDeleteAlert: $showingDeleteAlert, firestoreId: $firestoreId)
                }
            }
        }
        .padding(.leading, 10)
        .alert("Are you sure you want to delete this?", isPresented: $showingDeleteAlert) {
            Button("OK", role: .destructive) {
                deleteItem(firestoreId: firestoreId)
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    func deleteItem(firestoreId: String) {
        Task {
            await firebaseService.deletePortfolioStock(portfolioName: self.portfolio.id ?? "n/a", stockId: firestoreId)
        }
    }
    
}

struct View8: View {
    var item: ItemData
    
    var body: some View {
        VStack {
            Text("\(item.quantity, specifier: "%.2f")@")
            Text("\(item.basis, specifier: "%.2f")")
        }
        .font(.caption)
    }
}
