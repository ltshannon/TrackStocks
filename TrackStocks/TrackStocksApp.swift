//
//  TrackStocksApp.swift
//  TrackStocks
//
//  Created by Larry Shannon on 10/30/24.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        debugPrint("Firebase started")
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()

        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        debugPrint("💈", "didRegisterForRemoteNotificationsWithDeviceToken")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        debugPrint("💈", "userNotificationCenter: willPresent")
        let userinfo = notification.request.content.userInfo
        
        if let messageID = userinfo[gcmMessageIDKey] {
            debugPrint("💈", "Message ID: \(messageID)")
        }
        
        debugPrint("💈", "userInfo: \(userinfo)")
        completionHandler([[.banner, .badge, .sound]])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        debugPrint("💈", "userNotificationCenter: didReceive")
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(
            name: Notification.Name("FCMNotification"),
            object: nil,
            userInfo: userInfo)
        completionHandler()
    }
    
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        debugPrint("👌", "Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        Messaging.messaging().token { token, error in
          if let error = error {
              debugPrint(String.fatal, "Error fetching FCM registration token: \(error)")
          } else if let token = token {
              debugPrint(String.success, "FCM registration token: \(token)")
          }
        }
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

@main
struct TrackStocksApp: App {
    @StateObject var userAuth = Authentication.shared
    @StateObject var firebaseService = FirebaseService.shared
    @StateObject var stockDataService = StockDataService.shared
    @StateObject var marketSymbolsService = MarketSymbolsService.shared
    @StateObject var appNavigationState = AppNavigationState()
    @StateObject var settingsService = SettingsService.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SignInView()
                .environmentObject(userAuth)
                .environmentObject(firebaseService)
                .environmentObject(stockDataService)
                .environmentObject(marketSymbolsService)
                .environmentObject(appNavigationState)
                .environmentObject(settingsService)
        }
        .modelContainer(for: [SymbolStorage.self])
    }
}
