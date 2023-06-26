//
//  BTManager.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 20.06.23.
//

import Foundation
import CoreBluetooth
import CoreLocation

class BTManager: NSObject {
    private let doorConnector = DoorConnector()
    
    private var peripheralManager: CBPeripheralManager?
    private var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        startManager()
    }
    
    private func startManager() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.requestWhenInUseAuthorization()
        print("Started BTManager")
    }
    
    private func monitorBeacons() {
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)
            && CLLocationManager.isRangingAvailable() {
            print("start ranging")
            let beaconConstraint = CLBeaconIdentityConstraint(uuid: Constants.doorUUID!)
            locationManager!.startRangingBeacons(satisfying: beaconConstraint)
        } else {
            assertionFailure("Device does not support BLE")
        }
    }
}

extension BTManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didRangeBeacons beacons: [CLBeacon],
                         in region: CLBeaconRegion) {
        if let beacon = beacons.first(where: {$0.uuid.uuidString == "636F3F8F-6491-4BEE-95F7-D8CC64A863B5"}) {
            guard beacon.rssi != 0 else { return }
            print("found beacon with rssi: \(beacon.rssi)")
            if beacon.rssi >= -50 {
                doorConnector.doorShouldBeUnlocked = true
            } else if beacon.rssi <= -50 {
                doorConnector.doorShouldBeUnlocked = false
            }
        }
    }
}

extension BTManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("New State: \(peripheral.state)")
        switch peripheral.state {
        case .poweredOn:
            print("peripheralManager is poweredOn")
            monitorBeacons()
            break
        case .unauthorized:
            print("peripheralManager is unauthorized")
            break
        case .unsupported:
            print("peripheralManager is unsupported")
            break
        default:
            print("peripheralManager is  something else")
            break
        }
    }
}
