//
//  SignInView.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/3/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import ActivityKit

struct SignInView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var userAuth: Authentication
    @Environment(\.colorScheme) var colorScheme
    @State var showingContentView: Bool = false
    @State private var activity: Activity<StockTrackingAttributes>? = nil
    
    var body: some View {
        VStack {
            SignInWithAppleButton(.signIn) { request in
                userAuth.handleSignInWithAppleRequest(request)
            } onCompletion: { result in
                userAuth.handleSignInWithAppleCompletion(result)
                debugPrint("🦁", "user signed in with apple")
            }
            .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
            .frame(height: 50)
            .cornerRadius(8)
        }
        .padding([.leading, .trailing], 20)
        .onReceive(userAuth.$state) { state in
            debugPrint("😍", "ContentView onReceive userAtuh.state: \(state)")
            if state == .loggedOut {

            }
            if state == .loggedIn {
                Task {
                    await firebaseService.createUser(token: userAuth.fcmToken)
                    firebaseService.getUser()
//                    let notifications = firebaseService.user.notifications
//                    let items = firebaseService.convertToNotificationData(data: notifications)
//                    let state = StockTrackingAttributes.ContentState(items: items)
//                    let attributes = StockTrackingAttributes()
//                    activity = try? Activity<StockTrackingAttributes>.request(attributes: attributes, content: ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .minute, value: 1, to: Date())!), pushType: nil)
                    DispatchQueue.main.async {
                        showingContentView = true
                    }
                }

            }
        }
        .fullScreenCover(isPresented: $showingContentView) {
            ContentView()
        }
    }
}

#Preview {
    SignInView()
}
