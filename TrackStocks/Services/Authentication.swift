//
//  Authentication.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/3/24.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications
import AuthenticationServices
import CryptoKit

//Class to manage firebase configuration and backend authentication
@MainActor
class Authentication: ObservableObject {
    static let shared = Authentication()
    @Published var user: User?
    @Published var state: AuthState = .loggedOut
    @Published var isGuestUser = false
    @Published var firebaseUserId = ""
    @Published var email: String = ""
    @Published var username: String = ""
    @Published var fcmToken: String = ""
    @AppStorage("login-type") var loginType: LoginType = .unknown
    private var handler: AuthStateDidChangeListenerHandle? = nil
    private var currentNonce: String?
    
    enum AuthState: String {
        case waiting = "waiting"
        case accountSetup = "accountSetup"
        case loggedIn = "loggedIn"
        case loggedOut = "loggedOut"
    }
    
    enum LoginType: String {
        case usernamePassword = "Username & password"
        case google = "Google"
        case apple = "Apple"
        case unknown = "Unknown"
        case emailLink = "Email Link"
    }
    
    init() {
        
        handler = Auth.auth().addStateDidChangeListener { auth, user in
            debugPrint("🛎️", "Authentication Firebase auth state changed, logged in: \(auth.userIsLoggedIn)")
            
            self.user = user
            
            DispatchQueue.main.async {
                self.isGuestUser = false
                if let isAnonymous = user?.isAnonymous {
                    self.isGuestUser = isAnonymous
                }
            }
            
            //case where user loggedin but waiting account setup
            guard self.state != .accountSetup else {
                return
            }
            
            //case where no user auth, likely first run
            guard let currentUser = auth.currentUser else {
                self.state = .loggedOut
                return
            }
            
            var email = ""
            if let temp = currentUser.email {
                email = temp
            }
            
            self.state = auth.userIsLoggedIn ? .loggedIn : .loggedOut
            
            switch self.state {
            case .waiting, .accountSetup:
                break
                
            case .loggedIn:
                DispatchQueue.main.async {
                    self.firebaseUserId = user?.uid ?? ""
                    self.email = email
                }
            case .loggedOut:
                break
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("FCMToken"), object: nil, queue: nil) { notification in
            let newToken = notification.userInfo?["token"] as? String ?? ""
            Task {
                await MainActor.run {
                    self.fcmToken = newToken
                }
            }
        }
    }
    
    func setUser(user: User) {
        self.user = user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        DispatchQueue.main.async {
            self.loginType = .apple
        }
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let providerData = Auth.auth().currentUser?.providerData
        if let appleProviderData = providerData?.first(where: { $0.providerID == "apple.com" }) {
            Task {
                do {
                    let credentialState = try await appleIDProvider.credentialState(forUserID: appleProviderData.uid)
                    switch credentialState {
                    case .authorized:
                        break // The Apple ID credential is valid.
                    case .revoked, .notFound:
                        // The Apple ID credential is either revoked or was not found, so show the sign-in UI.
                        try self.signOut()
                    default:
                        break
                    }
                }
                catch {
                    debugPrint("🧨", "verifySignInWithAppleAuthenticationState failed")
                    DispatchQueue.main.async {
                        debugPrint(String.boom, error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let failure) = result {
            debugPrint(String.boom, failure.localizedDescription)
        }
        else if case .success(let authorization) = result {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: a login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    debugPrint("🧨", "Unable to fetdch identify token.")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    debugPrint("🧨", "Unable to serialise token string from data: \(appleIDToken.debugDescription)")
                    return
                }

                debugPrint("😍", "handleSignInWithAppleCompletion appleIDCredential.email: \(appleIDCredential.email ?? "no email") ")
                debugPrint("😍", "handleSignInWithAppleCompletion appleIDCredential.fullname: \(appleIDCredential.fullName?.familyName ?? "no name") ")
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                               rawNonce: nonce,
                                                               fullName: appleIDCredential.fullName)
                Task {
                    do {
                        let result = try await Auth.auth().signIn(with: credential)
                        DispatchQueue.main.async {
                            self.user = result.user
                            debugPrint(String.bell, "uid: \(self.user?.uid ?? "no uid")")
                            self.firebaseUserId = self.user?.uid ?? ""
                            self.username = appleIDCredential.user
                            self.email = appleIDCredential.email ?? ""
                        }
                    }
                    catch {
                        debugPrint(String.boom, "Error authenticating: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()

        return hashString
    }
}

extension Auth {
    var userIsLoggedIn: Bool {
        currentUser != nil
    }
}
