//
//  OscSender.swift
//  coremotion-osc
//
//  Copyright © 2024 Starling. All rights reserved.
//

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

