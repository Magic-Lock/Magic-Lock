//
//  BTManager.swift
//  MagicLockApp
//
//  Created by Gabriel Knoll on 20.06.23.
//

import CoreBluetooth
import CoreLocation
import SwiftUI

class BTManager: NSObject, ObservableObject {
    @Published var lastRSSI: Int = 0
    @Published var thresholdRSSI: Int = -55
    @Published var doorUUID = Constants.doorUUID!.uuidString {
        didSet {
            guard oldValue != "" else { return }
            print("new uuid")
            stopManager()
            startManager()
        }
    }
    @Published var beaconDetectionIsActive = false
    @Published var doorIsOpen = false
    @Published var shouldActivate = false {
        didSet {
            if shouldActivate {
                startManager()
            } else {
                stopManager()
            }
        }
    }
  
    private let doorConnector = DoorConnector()

    private var peripheralManager: CBPeripheralManager?
    private var locationManager: CLLocationManager?
    private var beaconConstraint: CLBeaconIdentityConstraint?
    private var beaconRegion: CLBeaconRegion?
    
    private func startManager() {
        guard shouldActivate else { return }
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.requestAlwaysAuthorization()
        locationManager!.activityType = .otherNavigation
        print("Started BTManager")
    }
    
    private func stopManager() {
        print("stop manager")
        if let region = beaconRegion {
            locationManager?.stopMonitoring(for: region)
        }
        if let constraint = beaconConstraint {
            locationManager?.stopRangingBeacons(satisfying: constraint)
        }
        beaconDetectionIsActive = false
    }
    
    private func monitorBeacons() {
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self)
            && CLLocationManager.isRangingAvailable() {
            print("start ranging")
            beaconConstraint = CLBeaconIdentityConstraint(uuid: UUID(uuidString: doorUUID)!)
            beaconRegion = CLBeaconRegion(beaconIdentityConstraint: beaconConstraint!, identifier: "DoorBeacon")
            beaconRegion!.notifyEntryStateOnDisplay = true
            beaconRegion!.notifyOnEntry = true
            locationManager!.startRangingBeacons(satisfying: beaconConstraint!)
            locationManager!.startMonitoring(for: beaconRegion!)
            beaconDetectionIsActive = true
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
            lastRSSI = beacon.rssi
            if beacon.rssi >= thresholdRSSI {
                doorConnector.doorShouldBeUnlocked = true
                doorIsOpen = true
            } else if beacon.rssi <= thresholdRSSI {
                doorConnector.doorShouldBeUnlocked = false
                doorIsOpen = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("entered region")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print("state")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("did update")
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
