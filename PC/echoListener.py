import usbmux
import threading
import struct
import binascii
import six

class PeerTalkThread(threading.Thread):
	def __init__(self,*args):
		self._psock = args[0]
		self._running = True
		threading.Thread.__init__(self)

	def run(self):
		framestructure = struct.Struct("! I I I I")
		print("listening to commands")
		while self._running:
			try:
				header = self._psock.recv(16)	# frame header
				print(len(header))
				print(header)
				if len(header) > 0:
					frame = framestructure.unpack(header)
					print("frame: ", frame)
					size = frame[3]			# get size of payload?
					payload = self._psock.recv(size)	# receive payload?
					if payload:
						print(len(payload))
						print(payload)
						command = binascii.hexlify(payload)
						print("received command", int(command))
						# send back data
						self._psock.send(header + payload)
					else:
						print("No data")
			except:
				pass

	def stop(self):
		self._running = False

print("starting...")
mux = usbmux.USBMux()

print("Waiting for devices...")
if not mux.devices:
	mux.process()	# search for devices with timeout=1.0?
if not mux.devices:
	print("No device found")

dev = mux.devices[0]	# get device found
print("connecting to device %s" % str(dev))
psock = mux.connect(dev, 2333)	# connect to device with port 2333
psock.setblocking(0)	# set to non-block
psock.settimeout(2)		# set timeout = 2

ptthread = PeerTalkThread(psock)
ptthread.start()

six.moves.input("press enter to exit")
print("exiting...")

# end connection and quit
ptthread.stop()
ptthread.join()
psock.close()