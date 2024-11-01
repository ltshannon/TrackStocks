//
//  ContentView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 10/30/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userAuth: Authentication
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var showSignIn: Bool = false
    
    var body: some View {
        TabView {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
                .padding()
                .tabItem {
                    Label("Club Portfolio", systemImage: "rectangle.grid.2x2")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(7)
        }
        .onReceive(userAuth.$state) { state in
            debugPrint("😍", "ContentView onReceive userAtuh.state: \(state)")
            if state == .loggedOut {
                showSignIn = true
            }
            if state == .loggedIn {
                Task {
                    await firebaseService.createUser(token: userAuth.fcmToken)
                    firebaseService.getUser()
                }
                showSignIn = false
            }
        }
        .fullScreenCover(isPresented: $showSignIn) {
            SignInView()
        }
    }
}

#Preview {
    ContentView()
}
