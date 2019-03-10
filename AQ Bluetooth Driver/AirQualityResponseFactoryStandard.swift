//
//  AirQualityResponseFactoryStandard.swift
//  djBluetoothTest
//
//  Created by Juan Ding on 2017/9/27.
//  Copyright © 2017 Juan Ding. All rights reserved.
//

//: Playground - noun: a place where people can play
//let input = Data(bytes: [0x6A,0x08,0x02,0x00,0x22,0x6f,0x64])

enum AirQualityRequstType:Int {
    case DeviceID   = 0
    case AirQuality = 1
    case FilterSet  = 2
}
import Foundation

fileprivate extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.characters.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
}

protocol AirQualityRequestFactory {
    func getRequestData(_ type : AirQualityRequstType) -> Data
}

class AirQualityRequestFactoryStandard: AirQualityRequestFactory{
    func getRequestData(_ type : AirQualityRequstType) -> Data {
        switch type {
        case .DeviceID  :
            return AirQualityRequstDeviceID().bytes
        case .AirQuality:
            return AirQualityRequstAirQuality().bytes
        case .FilterSet :
            return AirQualityRequstFilterReset().bytes
        }
    }
}

protocol AirQualityRequst {
    var bytes: Data { get }
}

extension AirQualityRequst{
    var header: UInt8 { return 0xA5 }
    
}

struct AirQualityRequstBase: AirQualityRequst {
    private let length: UInt8 = 0x05
    private let function: UInt8 = 0x00
    var bytes: Data {
        return Data(bytes: [header,length,function,0x62,0xb3])
    }
}

struct AirQualityRequstDeviceID: AirQualityRequst {
    private let length: UInt8 = 0x05
    private let function: UInt8 = 0x00
    var bytes: Data {
        return Data(bytes: [header,length,function,0x62,0xb3])
    }
}

struct AirQualityRequstAirQuality: AirQualityRequst {
    private let length: UInt8 = 0x05
    private let function: UInt8 =  0x01
    var bytes: Data {
        return Data(bytes:[header,length,function,0xA3,0x73] )
    }
}

struct AirQualityRequstFilterReset: AirQualityRequst {
    private let length: UInt8 = 0x05
    private let function: UInt8 = 0x02
    var bytes: Data {
        return Data(bytes: [header,length,function,0xE3,0x72])
    }
}

protocol AirQualityResponseFactory {
    func getResponse(for data: Data) -> AirQualityResponse
}

class AirQualityResponseFactoryStandard: AirQualityResponseFactory {
    func getResponse(for data: Data) -> AirQualityResponse {
        let basic = AirQualityResponseBasic(bytes: data)
        switch (basic.function) {
        case 0x00  : return AirQualityResponseDeviceID(bytes: data)
        case 0x01  : return AirQualityResponseAirQuality(bytes: data)
        case 0x02  : return AirQualityResponseFilterReset(bytes: data)
        default:  return basic
        }
    }
}

protocol AirQualityResponse: CustomStringConvertible {
    var header:   UInt8 { get }
    var length:   UInt8 { get }
    var function: UInt8 { get }
    var bytes:    Data  { get }
}

extension AirQualityResponse {
    var header:   UInt8 { return getByte(vector: 0) }
    var length:   UInt8 { return getByte(vector: 1) }
    var function: UInt8 { return getByte(vector: 2) }
    
    fileprivate func getByte(vector: Int) -> UInt8 {
        guard (vector < bytes.count) else { return 0 }
        return UInt8(bytes[vector])
    }
    
    fileprivate func getWord(vector: Int) -> UInt16 {
        guard ((vector + 1) < bytes.count) else { return 0 }
        let msb: UInt8 = bytes[vector]
        let lsb: UInt8 = bytes[vector + 1]
        return UInt16(msb) << 8 | UInt16(lsb)
    }
    
    fileprivate func getLong(vector: Int) -> UInt32 {
        return UInt32(getWord(vector: vector)) << 16 | UInt32(getWord(vector: vector + 2))
    }
    
    fileprivate func hexStr8(_ val: UInt8) -> String {
        return String(val, radix: 16, uppercase: true)
            .leftPadding(toLength: 2, withPad: "0")
    }
    fileprivate func hexStr16(_ val: UInt16) -> String {
        return String(val, radix: 16, uppercase: true)
            .leftPadding(toLength: 4, withPad: "0")
    }
    fileprivate func hexStr32(_ val: UInt32) -> String {
        return String(val, radix: 16, uppercase: true)
            .leftPadding(toLength: 8, withPad: "0")
    }
}

struct AirQualityResponseBasic: AirQualityResponse {
    var bytes: Data = Data()
    var description: String {
        return "AirQualityResponseBasic\n"
            + "Header   = \(hexStr8(header))\n"
            + "Length   = \(hexStr8(length))\n"
            + "Function = \(hexStr8(function))\n"
    }
}

struct AirQualityResponseDeviceID: AirQualityResponse {
    var bytes: Data = Data()
    var deviceID: UInt16 { return getWord(vector: 3) }
    var HWVersion: UInt8 { return getByte(vector: 5) }
    var SWVersion: UInt8 { return getByte(vector: 6) }
    var AGREVersion: UInt8 { return getByte(vector: 7) }
    var description: String {
        return "AirQualityResponseDeviceID\n"
            + "Header      = \(hexStr8(header))\n"
            + "Length      = \(hexStr8(length))\n"
            + "Function    = \(hexStr8(function))\n"
            + "DeviceID    = \(hexStr16(deviceID))\n"
            + "HWVersion   = \(hexStr8(function))\n"
            + "SWVersion   = \(hexStr8(function))\n"
            + "AGERVersion = \(hexStr8(function))\n"
    }
}

struct AirQualityResponseAirQuality: AirQualityResponse {
    var bytes: Data = Data()
    var pm25:  UInt16 { return getWord(vector: 3) }
    var co2:   UInt16 { return getWord(vector: 5) }
    var powerOnTime: UInt32 { return getLong(vector: 7) }
    var acStatus: UInt8 { return getByte(vector: 11) }
    var description: String {
        return "AirQualityResponse\n"
            + "Header      = \(hexStr8(header))\n"
            + "Length      = \(hexStr8(length))\n"
            + "Function    = \(hexStr8(function))\n"
            + "PM 2.5      = \(hexStr16(pm25))\n"
            + "CO2         = \(hexStr16(co2))\n"
            + "Pwr On Time = \(hexStr32(powerOnTime))\n"
        }
    
  //  5A0D01001407D20507040E1111"
}

struct AirQualityResponseFilterReset: AirQualityResponse {
    var bytes: Data = Data()
    var time: UInt32 { return getLong(vector: 3) }
    var description: String {
        return "AirQualityResponseFilterReset\n"
            + "Header   = \(hexStr8(header))\n"
            + "Length   = \(hexStr8(length))\n"
            + "Function = \(hexStr8(function))\n"
            + "Time     = \(hexStr32(time))\n"
    }
}



