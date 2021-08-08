//
//  ViewController.swift
//  TaikoController
//
//  Created by Jack on 18/11/2016.
//  Copyright © 2016 Jack. All rights reserved.
//

import UIKit

class TaikoViewController: UIViewController {
	var connection = TaikoConnection()

    @IBOutlet weak var leftDonView: CircularView!
    @IBOutlet weak var rightDonView: CircularView!
    @IBOutlet weak var leftKaView: AnimatedView!
    @IBOutlet weak var rightKaView: AnimatedView!
    
    @IBOutlet weak var taikoWidthConstriant: NSLayoutConstraint!
    @IBOutlet weak var taikoTopSpacingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		connection.delegate = self
		connection.startListening()
		UIApplication.shared.isIdleTimerDisabled = true
    }

    // MARK: Actions
    
    @IBAction func leftDon(_ sender: TouchDownRecognizer) {
        print("ldon")
        self.leftDonView.animateToTap()
        connection.sendCommand(command: TaikoCommand.LeftDon)
    }
    
    @IBAction func rightDon(_ sender: TouchDownRecognizer) {
        print("rdon")
        rightDonView.animateToTap()
		connection.sendCommand(command: TaikoCommand.RightDon)
    }
    
    @IBAction func leftKa(_ sender: TouchDownRecognizer) {
        print("lka")
        leftKaView.animateToTap()
		connection.sendCommand(command: TaikoCommand.LeftKa)
    }
    
    @IBAction func rightKa(_ sender: TouchDownRecognizer) {
        print("rka")
        rightKaView.animateToTap()
		connection.sendCommand(command: TaikoCommand.RightKa)
    }

    @IBAction func testHit(_ sender: TouchDownRecognizer) {
        print("testhit")
    }
    
    @IBAction func moveTaikoUp(_ sender: Any) {
        taikoTopSpacingConstraint.constant -= 50
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func moveTaikoDown(_ sender: Any) {
        taikoTopSpacingConstraint.constant += 50
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func makeTaikoLarger(_ sender: Any) {
        taikoWidthConstriant.constant += 50
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func makeTaikoSmaller(_ sender: Any) {
        taikoWidthConstriant.constant -= 50
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

	// MARK: Segue
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		connection.closeChannels()
	}

	@IBAction func unwindFromSettings(unwindSegue: UIStoryboardSegue) {
		if let settingsVC = unwindSegue.source as? TaikoSettingsController {
			settingsVC.closeConnection()
		}
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
			self.connection.startListening()
		}
	}
}

// MARK: TaikoConnectionDelegate

extension TaikoViewController: TaikoConnectionDelegate {
	func taikoConnectionListeningAttempted(_ connection: TaikoConnection,
										   error: Error?) {
		if error != nil {
			navigationItem.title = "Listening failed"
		} else {
			navigationItem.title = "Listening on port \(connection.portnum)"
		}
	}

	func taikoConnectionListeningStopped(_connection: TaikoConnection) {
		navigationItem.title = "Listening stopped"
	}

	func taikoConnectionConnected(_ connection: TaikoConnection,
								  address: PTAddress) {
		navigationItem.title = "Connected to \(address)"
	}

	func taikoConnectionReceived(_ connection: TaikoConnection) {
	}
	
	func taikoConnectionEnded(_ connection: TaikoConnection, error: Error?) {
		navigationItem.title = "Disconnected"
	}
}
