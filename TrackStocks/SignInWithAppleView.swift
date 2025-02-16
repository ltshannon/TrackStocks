//
//  SignInWithAppleView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 2/13/25.
//

import SwiftUI
import FirebaseSignInWithApple

struct SignInWithAppleView: View {
    @Environment(\.firebaseSignInWithApple) private var firebaseSignInWithApple
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var userAuth: Authentication
    @State var showingContentView = false
    @State var showingSignInWithAppleLoginView = false
    @State var showingProgressView = false
    
    var body: some View {
        Group {
            ProgressView()
        }
        .onChange(of: firebaseSignInWithApple.state) { oldValue, newValue in
            debugPrint("❤️", "oldValue: \(oldValue) newValue: \(newValue)")
            if newValue == .authenticated {
                Task {
                    await firebaseService.createUser(token: userAuth.fcmToken)
                    firebaseService.getUser()
                    DispatchQueue.main.async {
                        showingContentView = true
                    }
                }
            }
            if newValue == .notAuthenticated {
                showingSignInWithAppleLoginView = true
            }
            if newValue == .authenticating {
                showingProgressView = true
            }
        }
        .fullScreenCover(isPresented: $showingContentView) {
            ContentView()
                .environmentObject(userAuth)
        }
        .fullScreenCover(isPresented: $showingSignInWithAppleLoginView) {
            SignInWithAppleLoginView()
        }
        .fullScreenCover(isPresented: $showingProgressView) {
            ProgressView()
        }
    }
}

#Preview {
    SignInWithAppleView()
}
