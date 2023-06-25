//
//  MagicLockApp.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 20.06.23.
//

import SwiftUI

@main
struct MagicLockApp: App {
    public static let BTUUID = "F7A3D4B5-ACA0-46A0-8448-A963371EC34D"
    public let btManager = BTManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    
}
