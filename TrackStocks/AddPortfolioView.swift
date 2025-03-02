//
//  AddPortfolioView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 2/20/25.
//

import SwiftUI

struct AddPortfolioView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    @State var selectedName = ""
    @State var showingMissingName: Bool = false
    @State var isSoldPortfolio: Bool = false
    
    init(parameters: PortfolioAddParameters) {

    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $selectedName)
                        .keyboardType(.default)
                } header: {
                    Text("Name")
                }
                Section {
                    Toggle(isOn: $isSoldPortfolio) {
                        Text("This Portfolio is for sold stocks")
                    }
                    .toggleStyle(iOSCheckboxToggleStyle())
                } header: {
                    Text("Portfolio Type")
                }
            }
        }
        .navigationTitle("Add a Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    add()
                } label: {
                    Text("Save")
                }
            }
        }
        .alert("You are missing a Portfolio Name", isPresented: $showingMissingName) {
            Button("Cancel", role: .cancel) { }
        }
    }
    
    func add() {
        if selectedName.isEmpty {
            showingMissingName = true
            return
        }
        
        Task {
            await firebaseService.addPortfolio(portfolioName: selectedName, isForSoldStocks: isSoldPortfolio)
            dismiss()
        }
    }
}
