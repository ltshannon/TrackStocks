//
//  SettingsView.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/2/24.
//

import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseSignInWithApple

struct SettingsView: View {
    @Environment(\.firebaseSignInWithApple) private var firebaseSignInWithApple
    @EnvironmentObject var userAuth: Authentication
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showDatePicker") var showDatePicker = false
    @AppStorage("dividendDisplay") var isDividendDisplay = false
    @Query(sort: \SymbolStorage.symbol) var symbolStorage: [SymbolStorage]
    @State var showSignOut = false
    @State var showDeleteAccount = false
    @State var showingSheet: Bool = false
    @State var showSymbolUpdate = false
    let versionString: String = "Track Stocks: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "")(\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? ""))"
    
    var body: some View {
        
        ZStack {
            Color("Background-grey")
            VStack {
                FirebaseSignOutWithAppleButton {
                    FirebaseSignInWithAppleLabel(.signOut)
                }
                FirebaseDeleteAccountWithAppleButton {
                    FirebaseSignInWithAppleLabel(.deleteAccount)
                }
/*
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
*/
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
//                Toggle("Dividend view", isOn: $isDividendDisplay)
//                Button {
//                    firebaseService.callFirebaseCallableFunction(data: "This is a test")
//                } label: {
//                    Text("Test")
//                }
                Spacer()
                Text(versionString)
                    .padding(.bottom, 20)
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
