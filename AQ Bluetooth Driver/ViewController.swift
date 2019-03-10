//
//  ViewController.swift
//  test driver
//
//  Created by Juan Ding on 2017/11/15.
//  Copyright © 2017 Juan Ding. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    @IBOutlet weak var logTX: UITextView!
    
    @IBOutlet weak var send2btn: UIButton!
    @IBOutlet weak var sendbtn: UIButton!
    @IBOutlet weak var powertime: UITextField!
    @IBOutlet weak var co2: UITextField!
    @IBOutlet weak var pm25: UITextField!
    static let kPeripheralServiceUUID: CBUUID        = CBUUID(data: Data(bytes: [0xF1,0xA0]))
    static let kPeripheralCharacteristicUUID: CBUUID = CBUUID(data: Data(bytes: [0xF1,0xA5]))
    var myCBManager: CBPeripheralManager!
    var myCharacter: CBMutableCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        NotificationCenter.default.addObserver(self, selector: #selector(self.kbFrameChanged(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
        setupBluetoothManager()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func kbFrameChanged(_ notification : Notification){
        let info = notification.userInfo
        let kbRect = (info?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let offsetY = kbRect.origin.y - UIScreen.main.bounds.height
        UIView.animate(withDuration: 0.3) {
            self.view.transform = CGAffineTransform(translationX: 0, y: offsetY)
        }
    }
    
    func setUpView() {
        self.logTX.layer.borderColor = UIColor.black.cgColor
        self.logTX.layer.borderWidth = 2
        self.sendbtn.layer.borderColor = UIColor.black.cgColor
        self.sendbtn.layer.borderWidth = 1
        self.send2btn.layer.borderColor = UIColor.black.cgColor
        self.send2btn.layer.borderWidth = 1
        self.send2btn.layer.cornerRadius = 5;
        self.sendbtn.layer.cornerRadius = 5;
    }
    func setupBluetoothManager(){
        // step 1 set up self as central manager
        myCBManager = CBPeripheralManager(delegate: self, queue: nil)
        
        
    }
    
    @IBAction func sendPMandCO2(_ sender: Any) {
        guard let _ = myCBManager else { return }
        let pmNum:UInt16 = UInt16(pm25.text!) ?? 0
        let co2Num:UInt16 = UInt16(co2.text!) ?? 0
        let powerNum:UInt32 = UInt32(powertime.text!) ?? 0
        
        let pmhigh = UInt8((pmNum & 0xFF00) >> 8 )  // redComponent  0xCC(204)
        let pmlow = UInt8(pmNum & 0x00FF)
        let cohigh = UInt8((co2Num & 0xFF00) >> 8 )  // redComponent  0xCC(204)
        let colow = UInt8(co2Num & 0x00FF)
        
        let aPower = UInt8((powerNum & 0xFF000000) >> 24)
        let bPower = UInt8((powerNum & 0x00FF0000) >> 16)   // redComponent  0xCC(204)
        let cPower = UInt8((powerNum & 0x0000FF00) >> 8)   // greenComponent  0x66(102)
        let dPower = UInt8(powerNum & 0x000000FF)
        let airQualityInput = Data(bytes: [0x5A,0x0d,0x01,pmhigh,pmlow,cohigh,colow,aPower,bPower,cPower,dPower,0xC9,0x99
            ])
        
        myCBManager.updateValue(airQualityInput, for: myCharacter , onSubscribedCentrals: nil)
        logTX.text = logTX.text+"already sent data request of pm2.5\n"
        
    }
    @IBAction func clearLog(_ sender: Any) {
        self.logTX.text = ""
    }
    
    @IBAction func sendPowertime(_ sender: Any) {
        let powerNum:UInt32 = UInt32(powertime.text!) ?? 0
        let aPower = UInt8((powerNum & 0xFF000000) >> 24)
        let bPower = UInt8((powerNum & 0x00FF0000) >> 16)   // redComponent  0xCC(204)
        let cPower = UInt8((powerNum & 0x0000FF00) >> 8)    // greenComponent  0x66(102)
        let dPower = UInt8(powerNum & 0x000000FF)
        
        let data = Data(bytes: [0x5A,0x09,0x02,aPower,bPower,cPower,dPower,0x85,0xFC])
        myCBManager.updateValue(data, for: myCharacter , onSubscribedCentrals: nil)
        logTX.text = logTX.text+"already sent data request of time power\n"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupSeverAndCharecter() {
        //create server
        let server = CBMutableService.init(type: CBUUID.init(data: Data(bytes: [0xFF,0xF0])), primary: true)
        //create charater
        let charater = CBUUID.init(data: Data(bytes: [0xFF,0xF6]))
        let characerMuTable = CBMutableCharacteristic.init(type: charater, properties: [ .read , .writeWithoutResponse , .notify], value: nil, permissions: [.readable ,.writeable])
        // add characteristics into server
        server.characteristics = [characerMuTable]
        // add server into manager
        myCBManager.add(server)
        // start to advertise
        myCharacter = characerMuTable
        myCBManager.startAdvertising([CBAdvertisementDataLocalNameKey : "Air Quality", CBAdvertisementDataServiceUUIDsKey:[CBUUID.init(data: Data(bytes: [0xFF,0xF0]))]])
    }
    
    
}

extension ViewController: CBPeripheralManagerDelegate{
    public func peripheralManagerDidUpdateState(_ central: CBPeripheralManager){
        switch central.state {
        case .unknown:
            print("error unknown")
        case .resetting:
            print("resetting")
            logTX.text = logTX.text+"bluetooth resetting \n"
        case .unsupported:
            print("unsupported")
            logTX.text = logTX.text+"unsupported\n"
        case .unauthorized:
            print("unauthorized")
            logTX.text = logTX.text+"unauthorized\n"
        case .poweredOff:
            print("poweredOff")
            setupSeverAndCharecter()
            logTX.text = logTX.text+"poweredOff\n"
        case .poweredOn:
            print("poweredOn")
            logTX.text = logTX.text+"poweredOn\n"
            setupSeverAndCharecter()
            
            //    myCBManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:CBUUID(data: Data(bytes: [0xFF,0xF0]))])
            //step 2 when central functon is available , scan the peripheral devices
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?){
        if let _ = error {
            logTX.text = logTX.text+"There's something wrong-%@\(error.debugDescription)"
            return
        }
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?){
        if let _ = error { return }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest){
        myCBManager.stopAdvertising()
        let data = request.characteristic.value
        request.value = data
        peripheral.respond(to: request, withResult: .success)
        
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]){
        guard let request = requests.first else { return }
        if(peripheral.state != .poweredOn){
            return;
        }
        if request.value == AirQualityRequstAirQuality().bytes {
            // request.value = airQualityInput
            logTX.text = logTX.text+"user requst for air quality\n"
            peripheral.respond(to: request, withResult: .success)
        }else if( request.value == AirQualityRequstFilterReset().bytes ){
            logTX.text = logTX.text+"user request to reset the filter \n"
            self.powertime.text = String(0)
            self.sendPowertime(UIButton())
            peripheral.respond(to: request, withResult: .success)
        }
    }
}
