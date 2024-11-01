//
//  SettingsView.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/2/24.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var userAuth: Authentication
    @State var showSignOut = false
    @State var showDeleteAccount = false
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
                Spacer()
            }
            .padding([.top, .leading, .trailing])
        }
    }
    
}

#Preview {
    SettingsView()
}
