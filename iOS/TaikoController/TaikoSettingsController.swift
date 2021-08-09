//
//  TaikoSettingsController.swift
//  TaikoController
//
//  Created by Jack on 2021/8/8.
//  Copyright © 2021 Jack. All rights reserved.
//

import UIKit

class TaikoSettingsController: UITableViewController {
	@IBOutlet weak var benchmarkButton: UIButton!
	@IBOutlet weak var benchmarkResultTextView: UITextView!
	
	private var connection = TaikoConnection()
	private var benchmark: TaikoBenchmark?
	
	override func viewDidLoad() {
		benchmarkButton.isEnabled = false
		benchmarkResultTextView.text = "Setting up connection..."
		connection.delegate = self
		connection.startListening()
	}

	private func char(for command: TaikoCommand) -> String {
		switch command {
		case .LeftDon, .RightDon: return "d"
		case .LeftKa, .RightKa: return "k"
		default: return "?"
		}
	}

	private func appendToResults(_ text: String) {
		DispatchQueue.main.async {
			if let t = self.benchmarkResultTextView.text {
				self.benchmarkResultTextView.text = t + text
			}
		}
	}

	private func setResultsText(_ text: String) {
		DispatchQueue.main.async {
			self.benchmarkResultTextView.text = text
		}
	}

	func closeConnection() {
		connection.closeChannels()
	}
	
	@IBAction func benchmarkButtonTapped(_ sender: Any) {
		if connection.peerChannel == nil { return }
		DispatchQueue.main.async {
			self.setResultsText("Benchmark started...\n")
			self.benchmarkButton.isEnabled = false
		}
		let benchmark = TaikoBenchmark()
		self.benchmark = benchmark
		benchmark.onComplete = { [weak self] summary in
			self?.appendToResults("\n\(summary)")
			self?.benchmark = nil
		}
		let queue = DispatchQueue(label: "TaikoBenchmark")
		queue.async {
			benchmark.start { cmd in
				self.appendToResults(self.char(for: cmd))
				self.connection.sendCommand(command: cmd)
			} shortPause: {
				self.appendToResults(" ")
			}
		}
	}
}

extension TaikoSettingsController: TaikoConnectionDelegate {
	func taikoConnectionListeningAttempted(_ connection: TaikoConnection,
										   error: Error?) {
		if error != nil {
			benchmarkResultTextView.text = "Failed to start listening"
		} else {
			benchmarkResultTextView.text = "Started listening"
		}
	}
	
	func taikoConnectionListeningStopped(_connection: TaikoConnection) {
		// No-op.
	}
	
	func taikoConnectionConnected(_ connection: TaikoConnection,
								  address: PTAddress) {
		benchmarkResultTextView.text = "Benchmark ready"
		benchmarkButton.isEnabled = true
	}

	func taikoConnectionReceived(_ connection: TaikoConnection) {
		self.benchmark?.receive(command: .LeftDon)
	}
	
	func taikoConnectionEnded(_ connection: TaikoConnection, error: Error?) {
		appendToResults("\nDisconneted")
		benchmarkButton.isEnabled = false
	}
}
