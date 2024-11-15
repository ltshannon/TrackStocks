//
//  SettingsView.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/2/24.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var userAuth: Authentication
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    @Query(sort: \SymbolStorage.symbol) var symbolStorage: [SymbolStorage]
    @State var showSignOut = false
    @State var showDeleteAccount = false
    @State var showingSheet: Bool = false
    @State var showSymbolUpdate = false
    
    
    var body: some View {
        
        ZStack {
            Color("Background-grey")
            VStack {
                Button("Sign Out") {
                    showSignOut = true
                }
                .buttonStyle(PlainTextButtonStyle())
                .disabled(!Auth.auth().userIsLoggedIn)
                .alert("Sign Out?", isPresented: $showSignOut) {
                    Button("Cancel", role: .cancel) { }
                    Button("Sign Out", role: .destructive) {
                        do {
                            try Auth.auth().signOut()
                        } catch let error {
                            debugPrint("Error signing out: \(error)")
                        }
                    }
                } message: {
                    Text("Are you sure you want to sign out of your account?")
                }
                Button("Delete Account") {
                    showDeleteAccount = true
                }
                .buttonStyle(PlainTextButtonStyle())
                .alert("Delete Account?", isPresented: $showDeleteAccount) {
                    Button("Cancel", role: .cancel) {  }
                    Button("Delete", role: .destructive) {
                        Task {
                            guard let user = Auth.auth().currentUser else {
                                debugPrint(String.boom, "Delete User could not auth current user")
                                return
                            }
                            do {
                                try await user.delete()
                            } catch {
                                debugPrint(String.boom, "Delete User could not delete user: \(error)")
                                try? Auth.auth().signOut()
                            }
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete your account?")
                }
                Button("Market Symbols Update") {
                    showSymbolUpdate = true
                }
                .buttonStyle(PlainTextButtonStyle())
                .alert("Update Market Symbols?", isPresented: $showSymbolUpdate) {
                    Button("Cancel", role: .cancel) { }
                    Button("Update", role: .destructive) {
                        for symbol in symbolStorage {
                            context.delete(symbol)
                        }
                        try! context.save()
                    }
                } message: {
                    Text("Are you sure you want to update the Market Symbols, this will take a while?")
                }
                Toggle("Use Date Picker", isOn: $showDatePicker)
                Spacer()
            }
            .padding([.top, .leading, .trailing])
            .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
                
            }
        }
    }
    
    func didDismiss() {
        dismiss()
    }
    
}

#Preview {
    SettingsView()
}
