//
//  DoorConnector.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 26.06.23.
//

import Foundation

class DoorConnector {
    public var doorShouldBeUnlocked = false {
        didSet {
            guard oldValue != doorShouldBeUnlocked else { return }
            if doorShouldBeUnlocked {
                openDoor()
            } else {
                closeDoor()
            }
        }
    }
    
    private func openDoor() {
        print("openDoor")
        sendGetRequest(with: Constants.openUrl!)
    }
    
    private func closeDoor() {
        print("closeDoor")
        sendGetRequest(with: Constants.closeUrl!)
    }
    
    private func sendGetRequest(with url: URL) {
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            // Process the response data
            if let data = data {
                let responseString = String(data: data, encoding: .utf8)
                print("Response: \(responseString ?? "")")
            }
        }
        
        task.resume()
    }
}
