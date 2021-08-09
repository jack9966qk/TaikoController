from busyWaitingThread import BusyWaitingThread
import threading
import usbmux
import struct
from collections import namedtuple
import time

PeerTalkHeader = namedtuple("PeerTalkHeader", ["version", "type", "tag", "payloadSize"])

headerFrame = struct.Struct("! I I I I")

def readPeerTalkHeader(headerData):
	version, type, tag, payloadSize = headerFrame.unpack(headerData)
	return PeerTalkHeader(version, type, tag, payloadSize)

def makePeerTalkHeaderData(header):
	h = header
	return headerFrame.pack(h.version, h.type, h.tag, h.payloadSize)

def timestampFromPeerData(payload):
	(peerTime,) = struct.Struct("d").unpack(payload)
	return peerTime

def payloadFromTimestamp(timestamp):
	return struct.Struct("d").pack(timestamp)

class PeerTalkThread(threading.Thread):
	def __init__(self, onReceive, bufferMs=None):
		self._running = False
		self._onReceive = onReceive
		self._psock = None
		self._bufferMs = None
		self._timeOffset = None
		if bufferMs is not None:
			self._bufferMs = float(bufferMs)
			self._busyWaitingThread = BusyWaitingThread()
			self._busyWaitingThread.start()
		else:
			self._busyWaitingThread = None
		threading.Thread.__init__(self)

	def readMessage(self):
		if self._psock is None: return None
		headerData = self._psock.recv(16)
		if len(headerData) == 0: return None
		payload = None
		print("received header of length", len(headerData))
		header = readPeerTalkHeader(headerData)
		size = header.payloadSize
		if size > 0:
			payload = self._psock.recv(size)
		return (header, payload)

	def timeSync(self):
		if self._psock is None: return
		print("determine time offset")
		header = makePeerTalkHeaderData(PeerTalkHeader(1, 2, 0, 0))
		t0 = time.time()
		self._psock.send(header)
		payload = None
		while True:
			message = self.readMessage()
			if message is None:
				time.sleep(0.1)
			else:
				header, payload = message
				if header.type != 2: continue
				t3 = time.time()
				if payload: break
		t1 = timestampFromPeerData(payload)
		# TODO: Update peer to include two timestamps.
		t2 = t1
		self._timeOffset = -((t1 - t0) + (t2 - t3)) / 2
		print("determined time offset", self._timeOffset)

	def run(self):
		self._running = True
		print("starting...")
		mux = usbmux.USBMux()
		print("Waiting for devices...")
		if not mux.devices:
			mux.process()	# search for devices with timeout=1.0?
		if not mux.devices:
			print("No device found")

		dev = mux.devices[0]	# get device found
		print("connecting to device %s" % str(dev))
		self._psock = mux.connect(dev, 2333)	# connect to device with port 2333
		self._psock.setblocking(0)	# set to non-block
		self._psock.settimeout(2)		# set timeout = 2

		self.timeSync()

		print("listening")
		while self._running:
			try:
				header = self._psock.recv(16)
				if len(header) == 0: continue
				payload = None; peerTime = None
				if len(header) > 0:
					print("received header of length", len(header))
					unpackedHeader = readPeerTalkHeader(header)
					size = unpackedHeader.payloadSize
					if size > 0:
						payload = self._psock.recv(size)
						print("received payload of length", len(payload))
						if self._bufferMs is not None:
							peerTime = timestampFromPeerData(payload)
				if (peerTime is not None and
					self._bufferMs is not None and
					self._busyWaitingThread is not None and
					self._timeOffset is not None):
					print(peerTime, self._timeOffset, (self._bufferMs / 1000), time.time())
					print("need to wait (ms)", (peerTime + self._timeOffset + (self._bufferMs / 1000) - time.time()) * 1000)
					self._busyWaitingThread.doTaskAfter(
						lambda: self._onReceive(header, payload, self._psock, self._timeOffset),
						peerTime + self._timeOffset + (self._bufferMs / 1000))
				else:							
					self._onReceive(header, payload, self._psock, self._timeOffset)
			except:
				pass

	def stop(self):
		self._running = False
		if self._busyWaitingThread is not None:
			self._busyWaitingThread.stop()
			self._busyWaitingThread.join()
		if self._psock is not None: self._psock.close()
