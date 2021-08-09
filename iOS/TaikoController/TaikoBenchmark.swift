//
//  TaikoBenchmark.swift
//  TaikoController
//
//  Created by Jack on 2021/8/8.
//  Copyright © 2021 Jack. All rights reserved.
//

import Foundation

private struct Counter {
	var current: Int = 0
	mutating func reset() { current = 0 }
	mutating func next() -> Int {
		let num = current
		current += 1
		return num
	}
}

class TaikoBenchmark {
	private var sendCounter = Counter()
	private var receiveCounter = Counter()
	private var sendTime: [Int: TimeInterval] = [:]
	private var receiveTime: [Int: TimeInterval] = [:]
	var onComplete: ((String) -> ())?
	let numCommands = 500
	
	func start(sendCommand: (TaikoCommand) -> (), shortPause: () -> ()) {
		sendTime.removeAll()
		receiveTime.removeAll()
		sendCounter.reset()
		receiveCounter.reset()
		let commands: [TaikoCommand] = [.LeftDon, .LeftKa, .RightDon, .RightKa]
		for _ in 0..<numCommands {
			let cmd = commands.randomElement()!
			sendTime[sendCounter.next()] = Date().timeIntervalSince1970
			sendCommand(cmd)
			if Double.random(in: 0...1) > 0.15 {
				Thread.sleep(forTimeInterval: Double.random(in: 0.02...0.04))
			} else {
				Thread.sleep(forTimeInterval: Double.random(in: 0.1...0.2))
				shortPause()
			}
		}
	}

	func receive(command: TaikoCommand) {
		// Since the connection is based on TCP, no need to check for ordering,
		// therefore counter does not need to be included in the message.
		let num = receiveCounter.next()
		receiveTime[num] = Date().timeIntervalSince1970
		let delay = receiveTime[num]! - sendTime[num]!
		print("Received mssage \(num) with delay: \(delay * 1000) ms")
		if num == numCommands - 1 {
			onComplete?(summary)
		}
	}

	private func avg<C: Collection>(_ collection: C) -> Double?
	where C.Element == Double {
		if collection.count == 0 { return nil }
		return collection.reduce(0.0, +) / Double(collection.count)
	}
	
	private func stddev<C: Collection>(_ collection: C) -> Double?
	where C.Element == Double {
		if collection.count == 0 { return nil }
		guard let mean = avg(collection) else { return nil }
		let sum = collection
			.map { pow($0 - mean, 2) }
			.reduce(0.0, +)
		return sqrt(sum / Double(collection.count))
	}

	private var summary: String {
		let delaysInMs = (0..<numCommands).map { num in
			(receiveTime[num]! - sendTime[num]!) * 1000
		}.sorted()
		let splitIdx = min(Int(Double(numCommands) * 0.99), numCommands - 1)
		let delaysInMs99 = delaysInMs[..<splitIdx]
		return """
			Stats (round trip time in ms):
			Max: \(delaysInMs.max()!)
			Min: \(delaysInMs.min()!)
			Average: \(avg(delaysInMs)!)
			Stddev: \(stddev(delaysInMs)!)
			Average lowest 99%: \(avg(delaysInMs99)!)
		"""
	}
}
