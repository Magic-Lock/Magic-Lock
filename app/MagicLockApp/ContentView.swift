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
        VStack(alignment: .leading) {
            Text("MagicLock")
                .font(.largeTitle)
            Spacer()
            Text(verbatim: "Beacon Detection is \(btManager.beaconDetectionIsActive ? "active" : "not active")")
                .font(.subheadline)
                .padding()
            Text(verbatim: "Door is \(btManager.doorIsOpen ? "open" : "closed")")
                .font(.subheadline)
                .padding()
            Spacer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
