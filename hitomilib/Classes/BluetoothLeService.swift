import Foundation
import CoreBluetooth

public protocol BluetoothLeServiceDelegate {
    func bleDidUpdateState(_ ble: BluetoothLeService, state: BleCentralState)
    func bleDidDiscoverPeripherals(_ ble: BluetoothLeService, peripherals: [CBPeripheral])
    func bleDidFinishScanning(_ ble: BluetoothLeService)
    func bleDidConnectToPeripheral(_ ble: BluetoothLeService, peripheral: CBPeripheral)
    func bleFailedConnectToPeripheral(_ ble: BluetoothLeService, peripheral: CBPeripheral)
    func bleDidDisconnectFromPeripheral(_ ble: BluetoothLeService, peripheral: CBPeripheral)
    func bleDidReceiveData(_ ble: BluetoothLeService, peripheral: CBPeripheral, characteristic: String, data: Data?)
}


public enum BluetoothLeServiceError: Error {
    case UUIDNotFoundInAvailableCharacteristics
}

public enum BleCentralState: Int {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

public class BluetoothLeService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let TAG = "BluetoothLeService"
    
    public var debugMode: Bool = true
    public var delegate: BluetoothLeServiceDelegate?
    
    private(set) public var peripherals: [CBPeripheral] = [CBPeripheral]()
    
    private var usedCharacteristicsUUIDs: [CBUUID]? = nil
    private var serviceCBUUIDs: [CBUUID]?
    private var centralManager: CBCentralManager!
    private var activePeripheral: CBPeripheral?
    private var characteristics: [String : CBCharacteristic] = [String : CBCharacteristic]()
    private var rssiCompletionHandlers: [CBPeripheral: ((CBPeripheral, NSNumber?, Error?) -> ())]?
    
    override public init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: Debugging
    func log(_ message: String) {
        if self.debugMode {
            print("\(TAG) >>> \(message)")
        }
    }
    
    public var serviceUUID: String? {
        get {
            if (self.serviceCBUUIDs != nil && self.serviceCBUUIDs?.count == 1) {
                let uuid: CBUUID = (self.serviceCBUUIDs?.first)! as CBUUID
                return uuid.uuidString
            }
            else {
                return nil
            }
        }
        set (serviceUUID) {
            if (serviceUUID != nil) {
                self.serviceCBUUIDs = [CBUUID(string: serviceUUID!)]
            }
            else {
                self.serviceCBUUIDs = nil
            }
        }
    }
    
    // If not set, all characteristics will be discovered. This is a lengthy and expensive process
    public var characteristicsUUIDs: [String]? {
        get {
            if (self.usedCharacteristicsUUIDs != nil) {
                var uuidStrings: [String] = [String]()
                for uuid: CBUUID in self.usedCharacteristicsUUIDs! {
                    uuidStrings.append(uuid.uuidString)
                }
                return uuidStrings
            }
            else {
                return nil
            }
        }
        set (characteristicsUUIDs) {
            self.usedCharacteristicsUUIDs?.removeAll()
            if self.usedCharacteristicsUUIDs == nil {
                self.usedCharacteristicsUUIDs = [CBUUID] ()
            }
            if (characteristicsUUIDs != nil) {
                for uuid: String in characteristicsUUIDs! {
                    self.usedCharacteristicsUUIDs?.append(CBUUID(string: uuid))
                }
            }
        }
    }
    
    @objc private func scanTimeout() {
        self.log("Finished scanning")
        self.centralManager.stopScan()
        
        self.delegate?.bleDidFinishScanning(self)
    }
    
    // MARK: Public methods
    public func startScanning(timeout: TimeInterval, serviceUUIDs: [String]? = nil) -> Bool {
        if self.centralManager.state != .poweredOn {
            self.log("Unable to start scanning, device is powered off or not available")
            self.delegate?.bleDidFinishScanning(self)
            return false
        }
        
        if (self.centralManager.isScanning) {
            self.log("Already scanning for peripherals")
            self.delegate?.bleDidFinishScanning(self)
            return false
        }
        
        self.log("Scanning started")
        
        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(BluetoothLeService.scanTimeout), userInfo: nil, repeats: false)

        var services:[CBUUID] = []
        if (self.serviceUUID != nil) {
            services.append(CBUUID(string: self.serviceUUID!))
        }
        if (serviceUUIDs != nil && serviceUUIDs?.count ?? 0 > 0) {
            for i in 0 ..< serviceUUIDs!.count {
                let uuid: CBUUID = CBUUID(string: serviceUUIDs![i] as String)
                services.append(uuid)
            }
        }
        self.log("ScanWithServices : \(services)")
        self.centralManager.scanForPeripherals(withServices: services, options: nil) // consider for scan in background
        return true
    }
    
    public func connectToPeripheral(peripheral: CBPeripheral) {
        if (self.centralManager.state != .poweredOn) {
            self.log("Couldn´t connect to peripheral")
            return
        }
        
        self.log("Connecting to \(peripheral.name ?? "Unknown") - \(peripheral.identifier.uuidString)")
        self.centralManager.connect(peripheral, options: nil)

    }
    
    public func disconnectFromPeripheral(_ peripheral: CBPeripheral) -> Bool {
        if (self.centralManager.state != .poweredOn) {
            self.log("BlueTooth is powered off or not available, can not disconnect peripheral")
            return false
        }
        
        self.centralManager.cancelPeripheralConnection(peripheral)
        
        return true
    }
    
    public func disconnectActivePeripheral() {
        if (self.activePeripheral != nil) {
            _ = self.disconnectFromPeripheral(self.activePeripheral!)
        }
    }
    
    public func read(characteristicsUUID: String) throws {
        guard let char: CBCharacteristic = self.characteristics[characteristicsUUID] else {
            throw BluetoothLeServiceError.UUIDNotFoundInAvailableCharacteristics
        }
        
        self.activePeripheral?.readValue(for: char)
    }
    
    public func write(data: Data, characteristicsUUID: String, writeType: CBCharacteristicWriteType = .withResponse) throws {
        guard let char: CBCharacteristic = self.characteristics[characteristicsUUID] else {
            throw BluetoothLeServiceError.UUIDNotFoundInAvailableCharacteristics
        }
        self.activePeripheral?.writeValue(data, for: char, type: writeType)
    }
    
    public func enableNotifications(enable: Bool, characteristicsUUID: String) throws {
        guard let char: CBCharacteristic = self.characteristics[characteristicsUUID] else {
            throw BluetoothLeServiceError.UUIDNotFoundInAvailableCharacteristics
        }
        self.log("enableNotifications >>> characteristics (\(characteristicsUUID))")
        self.activePeripheral?.setNotifyValue(enable, for: char)
    }
    
    public func readRSSI(peripheral: CBPeripheral, completion: @escaping (_ peripheral: CBPeripheral, _ RSSI: NSNumber?, _ error: Error?) -> ()) {
        self.rssiCompletionHandlers = [peripheral: completion]
        self.activePeripheral?.readRSSI()
    }
    
    // MARK: CBCentralManager delegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            self.log("Central manager state: Unknown")
            break
            
        case .resetting:
            self.log("Central manager state: Resetting")
            break
            
        case .unsupported:
            self.log("Central manager state: Unsupported")
            break
            
        case .unauthorized:
            self.log("Central manager state: Unauthorized")
            break
            
        case .poweredOff:
            self.log("Central manager state: Powered off")
            break
            
        case .poweredOn:
            self.log("Central manager state: Powered on")
            break
        }
        self.delegate?.bleDidUpdateState(self, state: BleCentralState(rawValue: central.state.rawValue)!)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.log("Found \(peripheral.name ?? "Unknown"): \(peripheral.identifier.uuidString) RSSI: \(RSSI)")
        
        for i in 0 ..< self.peripherals.count {
            let p = self.peripherals[i] as CBPeripheral
            if (p.identifier.uuidString == peripheral.identifier.uuidString) {
                self.peripherals[i] = peripheral
                return
            }
        }
        self.peripherals.append(peripheral)
        self.delegate?.bleDidDiscoverPeripherals(self, peripherals: self.peripherals)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.log("Connected to service \(peripheral.name!) \(peripheral.identifier.uuidString)")
        self.centralManager.stopScan()
        
        self.activePeripheral = peripheral
        self.activePeripheral?.delegate = self
        self.activePeripheral?.discoverServices(self.serviceCBUUIDs)
    }
    
    // connect fail
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.log("Could not connect to \(peripheral.name!) (\(peripheral.identifier.uuidString)): \(error.debugDescription)")
        
        self.delegate?.bleFailedConnectToPeripheral(self, peripheral: peripheral)
    }
    
    // disconnect
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        var text = "Disconnected from \(peripheral.name!) - \(peripheral.identifier.uuidString)"
        
        if (error != nil) {
            text += ". Error: \(error.debugDescription)"
        }
        
        self.log(text)
        disconnectActivePeripheral()
        self.activePeripheral?.delegate = nil
        self.activePeripheral = nil
        self.characteristics.removeAll(keepingCapacity: false)
        
        self.delegate?.bleDidDisconnectFromPeripheral(self, peripheral: peripheral)
    }
    
    // MARK: CBPeripheral delegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            self.log("Error discovering services for \(peripheral.name!): \(error.debugDescription)")
            return
        }
        
        self.log("Found services for \(peripheral.name!): \(peripheral.services!)")
        for service: CBService in peripheral.services! {
            peripheral.discoverCharacteristics(self.usedCharacteristicsUUIDs, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            self.log("Error discovering characteristics for \(peripheral.name!): \(error.debugDescription)")
            return
        }
        for characteristic in service.characteristics! {
            self.log("Found characteristics with Name : \(peripheral.name!), UIID : \(characteristic.uuid.uuidString)")
            self.characteristics[characteristic.uuid.uuidString] = characteristic
            if self.characteristicsUUIDs?.contains(characteristic.uuid.uuidString) ?? false {
                try? enableNotifications(enable: true, characteristicsUUID: characteristic.uuid.uuidString)
            }
        }
        self.delegate?.bleDidConnectToPeripheral(self, peripheral: peripheral)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("ReceiveResponseData")
        if (error != nil) {
            self.log("Error updating value on \(peripheral.name!): \(error.debugDescription)")
            return
        }
        
        self.delegate?.bleDidReceiveData(self, peripheral: peripheral, characteristic: characteristic.uuid.uuidString, data: characteristic.value)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("キャラクタリスティックデータ書き込み時エラー：\(String(describing: error))")
            // 失敗処理
            return
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if (self.rssiCompletionHandlers![peripheral] != nil) {
            self.rssiCompletionHandlers![peripheral]?(peripheral, RSSI, error)
            self.rssiCompletionHandlers![peripheral] = nil
        }
    }
    
}
