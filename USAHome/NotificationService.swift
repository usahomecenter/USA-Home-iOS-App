import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject {
    
    static let shared = NotificationService()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(title: String, body: String, identifier: String, timeInterval: TimeInterval = 0, userInfo: [String: Any]? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger: UNNotificationTrigger?
        if timeInterval > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        } else {
            trigger = nil // Immediate notification
        }
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully: \(identifier)")
            }
        }
    }
    
    func scheduleServiceReminderNotification(serviceType: String, professionalName: String, appointmentDate: Date) {
        let calendar = Calendar.current
        let reminderTime = calendar.date(byAdding: .hour, value: -1, to: appointmentDate) ?? appointmentDate
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Service Appointment"
        content.body = "Your \(serviceType) appointment with \(professionalName) is in 1 hour"
        content.sound = .default
        content.categoryIdentifier = "SERVICE_REMINDER"
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "service_reminder_\(Int(appointmentDate.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling service reminder notification: \(error)")
            } else {
                print("Service reminder notification scheduled successfully: \(identifier)")
            }
        }
    }
    
    func scheduleNewProfessionalNotification(serviceType: String, location: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Professional Available"
        content.body = "A new \(serviceType) professional is now available in \(location)"
        content.sound = .default
        content.categoryIdentifier = "NEW_PROFESSIONAL"
        content.userInfo = ["service_type": serviceType, "location": location]
        
        let identifier = "new_professional_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling new professional notification: \(error)")
            } else {
                print("New professional notification scheduled successfully: \(identifier)")
            }
        }
    }
    
    func schedulePriceAlertNotification(serviceType: String, newPrice: String, change: String) {
        let content = UNMutableNotificationContent()
        content.title = "Price Alert: \(serviceType)"
        content.body = "Price \(change) to \(newPrice). Tap to view updated pricing."
        content.sound = .default
        content.categoryIdentifier = "PRICE_ALERT"
        content.userInfo = ["service_type": serviceType, "new_price": newPrice]
        
        let identifier = "price_alert_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling price alert notification: \(error)")
            } else {
                print("Price alert notification scheduled successfully: \(identifier)")
            }
        }
    }
    
    // MARK: - Notification Categories and Actions
    
    func setupNotificationCategories() {
        // Service Reminder Category
        let serviceReminderCategory = createServiceReminderCategory()
        
        // New Professional Category
        let newProfessionalCategory = createNewProfessionalCategory()
        
        // Price Alert Category
        let priceAlertCategory = createPriceAlertCategory()
        
        // Message Category
        let messageCategory = createMessageCategory()
        
        let categories: Set<UNNotificationCategory> = [
            serviceReminderCategory,
            newProfessionalCategory,
            priceAlertCategory,
            messageCategory
        ]
        
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }
    
    private func createServiceReminderCategory() -> UNNotificationCategory {
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM_APPOINTMENT",
            title: "Confirm",
            options: [.foreground]
        )
        
        let rescheduleAction = UNNotificationAction(
            identifier: "RESCHEDULE_APPOINTMENT",
            title: "Reschedule",
            options: [.foreground]
        )
        
        let cancelAction = UNNotificationAction(
            identifier: "CANCEL_APPOINTMENT",
            title: "Cancel",
            options: [.destructive]
        )
        
        return UNNotificationCategory(
            identifier: "SERVICE_REMINDER",
            actions: [confirmAction, rescheduleAction, cancelAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    private func createNewProfessionalCategory() -> UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_PROFESSIONAL",
            title: "View Profile",
            options: [.foreground]
        )
        
        let contactAction = UNNotificationAction(
            identifier: "CONTACT_PROFESSIONAL",
            title: "Contact Now",
            options: [.foreground]
        )
        
        return UNNotificationCategory(
            identifier: "NEW_PROFESSIONAL",
            actions: [viewAction, contactAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    private func createPriceAlertCategory() -> UNNotificationCategory {
        let viewPricesAction = UNNotificationAction(
            identifier: "VIEW_PRICES",
            title: "View Prices",
            options: [.foreground]
        )
        
        let compareAction = UNNotificationAction(
            identifier: "COMPARE_PRICES",
            title: "Compare",
            options: [.foreground]
        )
        
        return UNNotificationCategory(
            identifier: "PRICE_ALERT",
            actions: [viewPricesAction, compareAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    private func createMessageCategory() -> UNNotificationCategory {
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_MESSAGE",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message..."
        )
        
        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ",
            title: "Mark as Read",
            options: []
        )
        
        return UNNotificationCategory(
            identifier: "MESSAGE",
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: []
        )
    }
    
    // MARK: - Notification Permissions
    
    func checkNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.setupNotificationCategories()
                }
                completion(granted)
            }
        }
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    func incrementBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber += 1
        }
    }
    
    // MARK: - Notification Management
    
    func removeNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    func getDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications)
            }
        }
    }
}