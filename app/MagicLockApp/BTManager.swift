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
    var peripheral: CBPeripheralManager!
    var locationManager: CLLocationManager!
    var centralManager: CBCentralManager!
    var shouldOpen = false
    
    override init() {
        super.init()
        startManager()
    }

    private func startManager() {
        peripheral = CBPeripheralManager(delegate: self, queue: DispatchQueue.main)
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        //centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        print("Created Manager")
    }
    
    private func startBeacon() {
        print("starting beacon")
        let region = createBeaconRegion()
        print("obtained region \(region)")
        advertiseDevice(region: region!)
        //fu()
    }
    
    func fu() {
        DispatchQueue.main.async {
            while(true) {
                print("new loop")
                if self.shouldOpen {
                    self.openDoor()
                } else {
                    self.closeDoor()
                }
                sleep(3)
            }
        }
    }
    private func createBeaconRegion() -> CLBeaconRegion? {
        let proximityUUID = UUID(uuidString:
                                    MagicLockApp.BTUUID)
        let major : CLBeaconMajorValue = 100
        let minor : CLBeaconMinorValue = 1
        let beaconID = "com.example.myDeviceRegion.kdibjhbhjkbhjxbhbhbhjbhjjhhdhdhdhdhdhdhdhdhdhdhdhdhdhdhdhdhhdhdhdhddh"
        
        return CLBeaconRegion(proximityUUID: proximityUUID!,
                              major: major, minor: minor, identifier: beaconID)
    }
    
    private func advertiseDevice(region : CLBeaconRegion) {
        let peripheralData = region.peripheralData(withMeasuredPower: nil)
        
        peripheral!.startAdvertising(((peripheralData as NSDictionary) as! [String : Any]))
    }
    
    
    private func monitorBeacons() {
        print("started monitoring")
        if CLLocationManager.isMonitoringAvailable(for:
                                                    CLBeaconRegion.self) {
            print("is available")
            // Match all beacons with the specified UUID
            let proximityUUID = UUID(uuidString: "636F3F8F-6491-4BEE-95F7-D8CC64A863B5")
            //let beaconID = "com.example.myBeaconRegion"
            
            // Create the region and begin monitoring it.
            let region = CLBeaconRegion(proximityUUID: proximityUUID!,
                                        identifier: "")
            self.locationManager!.startMonitoring(for: region)
            
            if CLLocationManager.isRangingAvailable() {
                print("start ranging")
                locationManager.startRangingBeacons(in: region)
            }
        }
    }
    
    private func openDoor() {
        print("openDoor")
        let openUrl = URL(string: "http://192.168.248.241:8080/unlock")
//        openedDoor = true
        sendGetRequest(with: openUrl!)
    }
    
    private func closeDoor() {
        print("closeDoor")
        let closeUrl = URL(string: "http://192.168.248.241:8080/lock")
//        openedDoor = false
        sendGetRequest(with: closeUrl!)
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

extension BTManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("New State: \(peripheral.state)")
        switch peripheral.state {
        case .poweredOn:
            print("poweredOn")
            //startBeacon()
            monitorBeacons()
            break
        case .unauthorized:
            print("unauthorized")
            break
        case .unsupported:
            print("unsupported")
            break
        default:
            print("something else")
            break
        }
    }
}

extension BTManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
                         didEnterRegion region: CLRegion) {
        print("Did enter region")
        if region is CLBeaconRegion {
            // Start ranging only if the devices supports this service.
            if CLLocationManager.isRangingAvailable() {
                manager.startRangingBeacons(in: region as! CLBeaconRegion)
                
                
                // Store the beacon so that ranging can be stopped on demand.
                //beaconsToRange.append(region as! CLBeaconRegion)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didRangeBeacons beacons: [CLBeacon],
                         in region: CLBeaconRegion) {
        print("Start ranging")
        if beacons.count > 0 {
            let nearestBeacon = beacons.first!
            for beacon in beacons {
                if beacon.uuid.uuidString == "636F3F8F-6491-4BEE-95F7-D8CC64A863B5" {
                    print(beacon.rssi)
                    guard beacon.rssi != 0 else { return }
                    if beacon.rssi >= -50{
                        openDoor()
                        //shouldOpen = true
                    } else if beacon.rssi <= -50 {
                        closeDoor()
                        //shouldOpen = false
                    }
                }
            }
            //                let major = CLBeaconMajorValue(nearestBeacon.major)
            //                let minor = CLBeaconMinorValue(nearestBeacon.minor)
            //
            //                switch nearestBeacon.proximity {
            //                case .near, .immediate:
            //                    print("major: \(major), minor: \(minor)")
            //                    print(beacon.uuid)
            //                    print(beacon.proximity)
            
            // Display information about the relevant exhibit.
            //displayInformationAboutExhibit(major: major, minor: minor)
            
        }
    }
}

//extension BTManager: CBCentralManagerDelegate {
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        print("called delegate")
//        if central.state == .poweredOn {
//            // Bluetooth is powered on, start scanning for iBeacons
//            let uuid = UUID(uuidString: "636F3F8F-6491-4BEE-95F7-D8CC64A863B5")!
//            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "BeaconIdentifier")
//            let beaconUUIDCB = CBUUID(string: uuid.uuidString)
//            //centralManager.scanForPeripherals(withServices: [beaconUUIDCB])
//            central.scanForPeripherals(withServices: nil)
//            print("start scanning")
//        } else if central.state == .unauthorized {
//            print("unauthorized")
//        } else if central.state == .unsupported {
//            print("unsupported")
//        } else {
//            print(central.state)
//        }
//    }
//
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        // Process discovered peripherals (iBeacons)
//        // Extract necessary information from advertisementData and RSSI
//        // Example: let proximityUUID = advertisementData[CBAdvertisementDataManufacturerDataKey]
//        //print("detected something: \(peripheral.discoverServices(nil))")
//        //print("services: \(peripheral.discoverServices(nil))")
//        peripheral.delegate = self
//        peripheral.discoverServices(nil)
//        //print("advertisment\(advertisementData)")
//        if (peripheral.identifier.uuidString == "6E1CBF7A-3832-DB12-CC71-C77A11C91841") {
//            print("Detected dings")
//            print(RSSI)
//            guard RSSI != 0 else { return }
//            if Int(RSSI) >= -85 {
//                openDoor()
//            } else if Int(RSSI) <= -90 {
//                closeDoor()
//            }
//            print("\n\n\n\n")
//        }
//        //            print(peripheral)
//        //            print(advertisementData[CBAdvertisementDataLocalNameKey])
//        //            print(adverti sementData[CBAdvertisementDataServiceDataKey])
//        //            print(advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey])
//        //            print(advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey])
//        //            print("\n\n\n\n")
//    }
//}

extension BTManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("services:\n")
        for service in peripheral.services! {
            print(service)
        }
        print("\n\n\n\n")
    }
}
