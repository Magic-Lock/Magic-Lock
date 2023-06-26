//
//  MagicLockApp.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 20.06.23.
//

import NotificationCenter
import SwiftUI

@main
struct MagicLockApp: App {
    @State var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear(perform: notificationManager.requestPermission)
        }
    }
}
