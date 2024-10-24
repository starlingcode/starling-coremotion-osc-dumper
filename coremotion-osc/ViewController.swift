//
//  ViewController.swift
//  CoreMotionExample
//
//  Copyright © 2024 Starling. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

	let motionManager = CMMotionManager()
	var timer: Timer!
    var oscSender = OSCSender(hostName: "10.0.0.25", port: 8000)
    var host: String = "10.0.0.25"
    var port: UInt16 = 8000
    let hostLabel = UILabel()
    let hostTextField = UITextField()
    let portLabel = UILabel()
    let portTextField = UITextField()
    let submitButton = UIButton(type: .system)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		motionManager.startAccelerometerUpdates()
		motionManager.startGyroUpdates()
		motionManager.startMagnetometerUpdates()
		motionManager.startDeviceMotionUpdates()
		
		timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        
        self.view.backgroundColor = UIColor.systemBackground
                
        hostLabel.text = "Host:"
        hostLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hostLabel)
        
        hostTextField.placeholder = host
        hostTextField.borderStyle = .roundedRect
        hostTextField.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hostTextField)
        
        portLabel.text = "Port:"
        portLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(portLabel)
        
        portTextField.placeholder = String(port)
        portTextField.borderStyle = .roundedRect
        portTextField.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(portTextField)
        
        submitButton.setTitle("Set", for: .normal)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        self.view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            hostLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            hostLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100),
            
            hostTextField.leadingAnchor.constraint(equalTo: hostLabel.trailingAnchor, constant: 10),
            hostTextField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            hostTextField.topAnchor.constraint(equalTo: hostLabel.topAnchor),
            hostTextField.widthAnchor.constraint(equalToConstant: 250),
            
            portLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            portLabel.topAnchor.constraint(equalTo: hostTextField.bottomAnchor, constant: 20),
            
            portTextField.leadingAnchor.constraint(equalTo: portLabel.trailingAnchor, constant: 10),
            portTextField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            portTextField.topAnchor.constraint(equalTo: portLabel.topAnchor),
            portTextField.widthAnchor.constraint(equalToConstant: 250),
            
            submitButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            submitButton.topAnchor.constraint(equalTo: portTextField.bottomAnchor, constant: 30),
        ])
        
	}

	@objc func update() {
		if let deviceMotion = motionManager.deviceMotion {
            let pitch = deviceMotion.attitude.pitch
            let roll = deviceMotion.attitude.roll
            let yaw = deviceMotion.attitude.yaw
            oscSender.sendOSCMessage(address: "/starling-cm-osc/pitch", arguments: [Float(pitch)])
            oscSender.sendOSCMessage(address: "/starling-cm-osc/roll", arguments: [Float(roll)])
            oscSender.sendOSCMessage(address: "/starling-cm-osc/yaw", arguments: [Float(yaw)])
		}
	}
    
    // Callback for button tap event
    @objc func buttonTapped() {
        host = hostTextField.text ?? "No Host"
        let portString = portTextField.text ?? "No Port"
        if let portNumber = UInt16(portString) {
            port = portNumber
            initializeOsc()
        } else {
            print("Invalid port number")
        }
    }
    
    func initializeOsc() {
        oscSender = OSCSender(hostName: host, port: port)
    }
	
}
