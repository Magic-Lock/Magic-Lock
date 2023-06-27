//
//  ContentView.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 20.06.23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var btManager = BTManager()

    var body: some View {
        NavigationView {
                Form {
                    Section(header: Text("Door Status")) {
                        HStack {
                            Text(verbatim: "Door is \(btManager.doorIsOpen ? "open" : "closed")")
                            Spacer()
                            Image(systemName: "\(btManager.doorIsOpen ? "door.left.hand.open" : "door.left.hand.closed")")
                        }
                        Text("Last RSSI: \(btManager.lastRSSI)")
                    }
                    Section(header: Text("BLE Beacon")) {
                        HStack {
                            Text(verbatim: "Beacon Detection is \(btManager.beaconDetectionIsActive ? "active" : "not active")")
                            Spacer()
                            if btManager.beaconDetectionIsActive {
                                ProgressView()
                            }
                        }
                        Toggle("Activate Beacon Detection", isOn: $btManager.shouldActivate)
                    }
                }
                .navigationTitle("MagicLock")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Color {
    static let offWhite = Color(red: 225 / 255, green: 225 / 255, blue: 235 / 255)
}
