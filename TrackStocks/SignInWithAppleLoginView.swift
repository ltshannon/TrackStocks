//
//  SignInWithAppleLoginView.swift
//  TrackStocks
//
//  Created by Larry Shannon on 2/13/25.
//

import SwiftUI
import FirebaseSignInWithApple

struct SignInWithAppleLoginView: View {
    @Environment(\.firebaseSignInWithApple) private var firebaseSignInWithApple
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("Background-grey").edgesIgnoringSafeArea(.all)
            VStack {
                FirebaseSignInWithAppleButton {
                    FirebaseSignInWithAppleLabel(.signIn)
                }
                .padding([.leading, .trailing], 20)
            }
        }
        .onChange(of: firebaseSignInWithApple.state) { oldValue, newValue in
            if newValue == .authenticated {
                dismiss()
            }
        }
    }
}

#Preview {
    SignInWithAppleLoginView()
}
