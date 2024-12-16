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
            PortfolioHomeView()
                .tabItem {
                    Label("Portfolios", systemImage: "rectangle.grid.2x2")
                }
                .tag(2)
            TotalsView()
                .tabItem {
                    Label("Totals", systemImage: "dollarsign.bank.building")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onReceive(userAuth.$fcmToken) { token in
            if token.isNotEmpty {
                Task {
                    await firebaseService.updateAddFCM(token: token)
                }
            }
        }
//        .onReceive(userAuth.$state) { state in
//            debugPrint("😍", "ContentView onReceive userAtuh.state: \(state)")
//            if state == .loggedOut {
//                tabSelection = 1
//            }
//            if state == .loggedIn {
//                Task {
//                    await firebaseService.createUser(token: userAuth.fcmToken)
//                    firebaseService.getUser()
//                    DispatchQueue.main.async {
//                        tabSelection = 2
//                    }
//                }
//
//            }
//        }
//        .fullScreenCover(isPresented: $showSignIn) {
//            SignInView()
//        }
    }
}

#Preview {
    ContentView()
}
