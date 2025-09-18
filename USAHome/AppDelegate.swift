import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize notification system
        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.setupNotificationCategories()
        
        // Request notification permissions
        NotificationService.shared.requestNotificationPermissions { granted in
            if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        }
        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "CONFIRM_APPOINTMENT":
            print("User confirmed appointment")
            
        case "RESCHEDULE_APPOINTMENT":
            print("User wants to reschedule appointment")
            
        case "CANCEL_APPOINTMENT":
            print("User cancelled appointment")
            
        case "VIEW_PROFESSIONAL":
            print("User wants to view professional profile")
            
        case "CONTACT_PROFESSIONAL":
            print("User wants to contact professional")
            
        case "VIEW_PRICES":
            print("User wants to view prices")
            
        case "COMPARE_PRICES":
            print("User wants to compare prices")
            
        case "REPLY_MESSAGE":
            if let textResponse = response as? UNTextInputNotificationResponse {
                print("User replied: \(textResponse.userText)")
            }
            
        case "MARK_READ":
            print("User marked message as read")
            
        default:
            print("Unknown notification action: \(response.actionIdentifier)")
        }
        
        completionHandler()
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // Send token to your server for push notifications
        // You can implement this to store the token for later use
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}