//
//  Constants.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 26.06.23.
//

import Foundation

struct Constants {
    public static let doorUUID = UUID(uuidString: "636F3F8F-6491-4BEE-95F7-D8CC64A863B5")
    public static let openUrl = URL(string: "http://192.168.248.241:8080/unlock")
    public static let closeUrl = URL(string: "http://192.168.248.241:8080/lock")
}
