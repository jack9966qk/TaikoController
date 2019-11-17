//
//  ViewController.swift
//  TaikoController
//
//  Created by Jack on 18/11/2016.
//  Copyright © 2016 Jack. All rights reserved.
//

import UIKit

class TaikoViewController: UIViewController {
    let portnum = 2333
    var serverChannel : PTChannel?
    var peerChannel: PTChannel?

    @IBOutlet weak var LDonView: CircularView!
    @IBOutlet weak var RDonView: CircularView!
    @IBOutlet weak var LKaView: AnimatedView!
    @IBOutlet weak var RKaView: AnimatedView!
    
    @IBOutlet weak var taikoWidthConstriant: NSLayoutConstraint!
    @IBOutlet weak var taikoTopSpacingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupChannel()
    }

    func setupChannel() {
        serverChannel = PTChannel(delegate: self)
        serverChannel!.listen(onPort: 2333, iPv4Address: INADDR_LOOPBACK) {
            (error) in
            if let er = error {
                print("Listening failed with error: \(er)")
            } else {
                print("Listening on port 2333")
            }
        }
    }
    
    func sendCommand(command: TaikoCommand) {
        if let peerCh = peerChannel {
            var value = command.rawValue
            let ptr = UnsafeBufferPointer<UInt8>(start: &value, count: 1)
            let payload = DispatchData(bytes: ptr) as __DispatchData!
//            let data = TaikoCommandFrameWithValue(value)
            peerCh.sendFrame(ofType: TaikoMessageType.Command.rawValue, tag: PTFrameNoTag, withPayload: payload!) {
                (error) in
                if let e = error {
                    print("error while sending command: \(e)")
                } else {
                    print("command sent")
                }
            }
        }
    }
    
    // MARK: Actions
    
    @IBAction func leftDon(_ sender: TouchDownRecognizer) {
        print("ldon")
        self.LDonView.animateToTap()
        self.sendCommand(command: TaikoCommand.LeftDon)
    }
    
    @IBAction func rightDon(_ sender: TouchDownRecognizer) {
        print("rdon")
        RDonView.animateToTap()
        sendCommand(command: TaikoCommand.RightDon)
    }
    
    @IBAction func leftKa(_ sender: TouchDownRecognizer) {
        print("lka")
        LKaView.animateToTap()
        sendCommand(command: TaikoCommand.LeftKa)
    }
    
    @IBAction func rightKa(_ sender: TouchDownRecognizer) {
        print("rka")
        RKaView.animateToTap()
        sendCommand(command: TaikoCommand.RightKa)
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
}

// MARK: PTChannelDelegate

extension TaikoViewController: PTChannelDelegate {
    public func ioFrameChannel(_ channel: PTChannel!, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: PTData!) {
        return;
    }
    
    public func ioFrameChannel(_ channel: PTChannel!, shouldAcceptFrameOfType type: UInt32, tag: UInt32, payloadSize: UInt32) -> Bool {
        return false;
    }
    
    public func ioFrameChannel(_ channel: PTChannel!, didEndWithError error: Error!) {
        if let e = error {
            print("\(channel!) ended with error: \(e)")
        } else {
            print("Disconnected from \(String(describing: channel.userInfo))")
        }
    }
    
    // For listening channels, this method is invoked when a new connection has been
    // accepted.
    public func ioFrameChannel(_ channel: PTChannel!, didAcceptConnection otherChannel: PTChannel!, from address: PTAddress!) {
        // Cancel any other connection. We are FIFO, so the last connection
        // established will cancel any previous connection and "take its place".
        peerChannel?.cancel()
        
        // Weak pointer to current connection. Connection objects live by themselves
        // (owned by its parent dispatch queue) until they are closed.
        peerChannel = otherChannel
        peerChannel!.userInfo = address
        print("Connected to \(address!)")
        
        return;
    }
}
