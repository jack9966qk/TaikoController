//
//  TaikoConnection.swift
//  TaikoController
//
//  Created by Jack on 2021/8/8.
//  Copyright © 2021 Jack. All rights reserved.
//

import Foundation

enum TaikoConnectionError: String, Error {
	case failedSettingUpServerChannel = "Failed setting up server channel"
}

protocol TaikoConnectionDelegate: class {
	func taikoConnectionListeningAttempted(_ connection: TaikoConnection,
										   error: Error?)
	func taikoConnectionListeningStopped(_connection: TaikoConnection)
	func taikoConnectionConnected(_ connection: TaikoConnection,
								  address: PTAddress)
	func taikoConnectionReceived(_ connection: TaikoConnection)
	func taikoConnectionEnded(_ connection: TaikoConnection, error: Error?)
}

class TaikoConnection: NSObject {
	let portnum: UInt16 = 2333
	private(set) var serverChannel : PTChannel?
	private(set) var peerChannel: PTChannel?
	weak var delegate: TaikoConnectionDelegate?

	func startListening() {
		if serverChannel != nil { return }
		serverChannel = PTChannel(delegate: self)
		guard let serverCh = serverChannel else {
			let error = TaikoConnectionError.failedSettingUpServerChannel
			delegate?.taikoConnectionEnded(self, error: error)
			return
		}
		serverCh.listen(onPort: portnum,
						iPv4Address: INADDR_LOOPBACK) { error in
			self.delegate?.taikoConnectionListeningAttempted(self, error: error)
			if let er = error {
				print("Listening failed with error: \(er)")
			} else {
				print("Listening on port \(self.portnum)")
			}
		}
	}

	func closeChannels() {
		serverChannel?.close()
		peerChannel?.close()
	}

	private var currentTimestampData: __DispatchData {
		let now = Date().timeIntervalSince1970
		return withUnsafeBytes(of: now) { bytes in
			DispatchData(bytes: bytes) as __DispatchData
		}
	}

	func sendCommand(command: TaikoCommand) {
		guard let peerCh = peerChannel else { return }
		peerCh.sendFrame(ofType: TaikoMessageType.Command.rawValue,
						 tag: command.rawValue,
						 withPayload: currentTimestampData) { error in
			if let e = error {
				print("error while sending command: \(e)")
			} else {
				print("command sent")
			}
		}
	}
}

// MARK: PTChannelDelegate

extension TaikoConnection: PTChannelDelegate {
	public func ioFrameChannel(_ channel: PTChannel!,
							   didReceiveFrameOfType type: UInt32,
							   tag: UInt32,
							   payload: PTData?) {
		print("Received frame of type \(type) and tag \(tag), payload length: \(payload?.length ?? 0)")
		if (type == TaikoMessageType.TimeSync.rawValue) {
			guard let peerCh = peerChannel else { return }
			peerCh.sendFrame(ofType: TaikoMessageType.TimeSync.rawValue,
							 tag: PTFrameNoTag,
							 withPayload: currentTimestampData,
							 callback: nil)
		}
		self.delegate?.taikoConnectionReceived(self)
		return;
	}
	
	public func ioFrameChannel(_ channel: PTChannel!,
							   shouldAcceptFrameOfType type: UInt32,
							   tag: UInt32,
							   payloadSize: UInt32) -> Bool {
		return true;
	}
	
	public func ioFrameChannel(_ channel: PTChannel!,
							   didEndWithError error: Error!) {
		if channel === serverChannel {
			serverChannel = nil
			print("Stopped listening")
			delegate?.taikoConnectionListeningStopped(_connection: self)
		}
		if channel === peerChannel {
			peerChannel = nil
			self.delegate?.taikoConnectionEnded(self, error: error)
			if let e = error {
				print("\(channel!) ended with error: \(e)")
			} else {
				print("Disconnected from \(String(describing: channel.userInfo))")
			}
		}
	}
	
	// For listening channels, this method is invoked when a new connection has been
	// accepted.
	public func ioFrameChannel(_ channel: PTChannel!,
							   didAcceptConnection otherChannel: PTChannel!,
							   from address: PTAddress!) {
		// Cancel any other connection. We are FIFO, so the last connection
		// established will cancel any previous connection and "take its place".
		peerChannel?.cancel()
		
		// Weak pointer to current connection. Connection objects live by themselves
		// (owned by its parent dispatch queue) until they are closed.
		peerChannel = otherChannel
		peerChannel!.userInfo = address
		print("Connected to \(address!)")
		delegate?.taikoConnectionConnected(self, address: address!)
	}
}
