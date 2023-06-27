//
//  NotificationManager.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 26.06.23.
//

import Foundation
import NotificationCenter

class NotificationManager: NSObject {
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    public func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    public static func sendNotification(opened: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "MagicLock"
        content.body = "\(opened ? "Opened" : "Closed") Door!"
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.banner)
    }
}
