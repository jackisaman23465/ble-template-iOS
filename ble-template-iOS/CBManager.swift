//
//  AppDelegate.swift
//  ble-template-iOS
//
//  Created by 周子傑 on 2023/7/4.
//

import Foundation
import UIKit
import CoreBluetooth

class CBManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject{
    //客製化LED UUID
    let LED_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
    let State_Characteristic_UUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    let Brightness_Characteristic_UUID = CBUUID(string: "58761b6e-1575-11ee-be56-0242ac120002")
    let Mode_Characteristic_UUID = CBUUID(string: "b9fde1bc-1586-11ee-be56-0242ac120002")
    
    @Published var isConnected: Bool = false
    @Published var discoverPeripherals: [CBPeripheral] = []
    @Published var discoverServers: [CBService] = []
    @Published var discoverCharacteristics: [CBCharacteristic] = []
    
    @Published var stateCharacteristic: CBCharacteristic?
    @Published var brightnessCharacteristic: CBCharacteristic?
    @Published var modeCharacteristic: CBCharacteristic?
    
    @Published var state: Bool?
    @Published var brightness: UInt8?
    @Published var mode: UInt8?
    
    private var connectedPeripheral: CBPeripheral!
    var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        print("CBDelegate init")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connectPeripheral(_ selectPeripheral: CBPeripheral?) {
        guard let selectPeripheral = selectPeripheral else { return }
        connectedPeripheral = selectPeripheral
        connectedPeripheral?.delegate = self
        centralManager.connect(connectedPeripheral, options: nil)
    }
    
    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
    
    func writeState(_ state:Bool) {
        print("write state")
        guard let stateCharacteristic = stateCharacteristic else { return }
        connectedPeripheral?.writeValue( Data([state ? 0x01 : 0x00]) , for: stateCharacteristic, type: .withoutResponse)
    }
    
    func writeBrightness(_ brightness: UInt8) {
        guard let brightnessCharacteristic = brightnessCharacteristic else { return }
        connectedPeripheral?.writeValue( Data([brightness]) , for: brightnessCharacteristic, type: .withoutResponse)
    }
    
    func writeMode(_ mode: UInt8) {
        guard let modeCharacteristic = modeCharacteristic else { return }
        connectedPeripheral?.writeValue( Data([mode]) , for: modeCharacteristic, type: .withoutResponse)
    }
    
    //bt manager state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("bluetooth adapter state change: \(central.state.rawValue)")
        if central.state == .poweredOn {
            // 藍芽已開啟，開始掃描藍芽設備
            central.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    //discover peripherals
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(peripheral.name != nil && !discoverPeripherals.contains(peripheral)){
            print(peripheral.name ?? "")
            discoverPeripherals.append(peripheral)
            print(discoverPeripherals.count)
        }
    }
    
    //did connect peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connect peripheral")
        connectedPeripheral = peripheral
        isConnected = true
        peripheral.discoverServices(nil)
    }
    
    //did disconnect peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnect peripheral")
        connectedPeripheral = nil
        isConnected = false
    }
    
    //discover services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("discover services")
        peripheral.services?.forEach { service in
            discoverServers.append(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //discover characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("discover characteristics")
        service.characteristics?.forEach { characteristic in
            switch(characteristic.uuid){
            case State_Characteristic_UUID:
                print("find state characteristic")
                stateCharacteristic = characteristic
                break
            case Brightness_Characteristic_UUID:
                print("find brightness characteristic")
                brightnessCharacteristic = characteristic
                break
            case Mode_Characteristic_UUID:
                print("find mode characteristic")
                modeCharacteristic = characteristic
                break
            default:
                break
            }
            discoverCharacteristics.append(characteristic)
            peripheral.readValue(for: characteristic)
        }
    }
    
    //read characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error read characteristic: \(error.localizedDescription)")
            return
        }
        
        print("Characteristic read successful")
        
        if let characteristicValue = characteristic.value {
            let hexString = characteristicValue.map({ String(format:"%02x", $0) }).joined()
            print("Characteristic value: \(hexString)")
            
            switch(characteristic.uuid){
            case State_Characteristic_UUID:
                print("read state value")
                state = [UInt8](characteristicValue)[0] == 0x01
                break
            case Brightness_Characteristic_UUID:
                print("read brightness value")
                brightness = [UInt8](characteristicValue)[0]
                break
            case Mode_Characteristic_UUID:
                print("read mode value")
                mode = [UInt8](characteristicValue)[0]
                break
            default:
                break
            }
        }
    }
    
    //write characteristic
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing characteristic: \(error.localizedDescription)")
            return
        }
        
        print("Characteristic write successful")
        
        //        connectedPeripheral.readValue(for: characteristic)
        
        // 如果你需要獲取寫入的特徵值
        if let characteristicValue = characteristic.value {
            let hexString = characteristicValue.map({ String(format:"%02x", $0) }).joined()
            print("Characteristic value: \(hexString)")
        }
    }
}
