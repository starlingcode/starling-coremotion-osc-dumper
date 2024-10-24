//
//  ViewController.swift
//  CoreMotionExample
//
//  Created by Maxim Bilan on 1/21/16.
//  Copyright © 2016 Maxim Bilan. All rights reserved.
//

import UIKit
import CoreMotion

import Foundation
import Network

class OSCSender {
    private var connection: NWConnection?
    private let port: UInt16
    private let hostName: String
    
    init(hostName: String, port: UInt16) {
        self.hostName = hostName
        self.port = port
        setupConnection()
    }
    
    private func setupConnection() {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(hostName), port: NWEndpoint.Port(integerLiteral: port))
        connection = NWConnection(to: endpoint, using: .udp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Connection ready")
            case .failed(let error):
                print("Connection failed: \(error)")
                self?.reconnect()
            default:
                break
            }
        }
        
        connection?.start(queue: .global())
    }
    
    private func reconnect() {
        connection?.cancel()
        setupConnection()
    }
    
    func sendOSCMessage(address: String, arguments: [Any]) {
        var data = Data()
        
        // Add OSC Address Pattern
        data.append(alignedString(address))
        
        // Add Type Tag String
        var typeTagString = ","
        for argument in arguments {
            switch argument {
            case is Int32: typeTagString += "i"
            case is Float: typeTagString += "f"
            case is String: typeTagString += "s"
            default: continue
            }
        }
        data.append(alignedString(typeTagString))
        
        // Add Arguments
        for argument in arguments {
            switch argument {
            case let intValue as Int32:
                var bigEndian = intValue.bigEndian
                data.append(Data(bytes: &bigEndian, count: MemoryLayout<Int32>.size))
            case let floatValue as Float:
                var bigEndian = floatValue.bitPattern.bigEndian
                data.append(Data(bytes: &bigEndian, count: MemoryLayout<UInt32>.size))
            case let stringValue as String:
                data.append(alignedString(stringValue))
            default:
                continue
            }
        }
        
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send message: \(error)")
            }
        })
    }
    
    private func alignedString(_ string: String) -> Data {
        var data = string.data(using: .utf8) ?? Data()
        let padding = 4 - (data.count % 4)
        if padding < 4 {
            data.append(contentsOf: Array(repeating: 0, count: padding))
        }
        return data
    }
}

class ViewController: UIViewController {

	let motionManager = CMMotionManager()
	var timer: Timer!
    let oscSender = OSCSender(hostName: "192.168.50.37", port: 8000)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		motionManager.startAccelerometerUpdates()
		motionManager.startGyroUpdates()
		motionManager.startMagnetometerUpdates()
		motionManager.startDeviceMotionUpdates()
		
		timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        
        // Create an instance
        
	}

	@objc func update() {
//		if let accelerometerData = motionManager.accelerometerData {
//			print(accelerometerData)
//		}
//		if let gyroData = motionManager.gyroData {
//			print(gyroData)
//		}
//		if let magnetometerData = motionManager.magnetometerData {
//			print(magnetometerData)
//		}
		if let deviceMotion = motionManager.deviceMotion {
			print(deviceMotion)
            let x = deviceMotion.attitude.pitch
            let y = deviceMotion.attitude.roll
            let z = deviceMotion.attitude.yaw
            oscSender.sendOSCMessage(address: "/itsme/skeeter/pitch", arguments: [Float(x)])
            oscSender.sendOSCMessage(address: "/itsme/skeeter/roll", arguments: [Float(y)])
            oscSender.sendOSCMessage(address: "/itsme/skeeter/yaw", arguments: [Float(z)])
		}
	}
	
}
