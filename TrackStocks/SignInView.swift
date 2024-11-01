//
//  SignInView.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/3/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct SignInView: View {
    @EnvironmentObject var userAuth: Authentication
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State var errorMessage = ""
    @State var showError = false
    
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
        .alert("Error", isPresented: $showError) {
            Button("Ok", role: .cancel) {  }
        } message: {
            Text("Error: \(errorMessage)")
        }
    }
}

#Preview {
    SignInView()
}
