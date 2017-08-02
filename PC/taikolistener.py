# taikolistener.py

import usbmux
import SocketServer
import select
from optparse import OptionParser
import sys
import threading
import struct
import binascii
import pyautogui
import ctypes
import time

pyautogui.PAUSE = 0
locks = {}
locks[0x21] = threading.Lock()
locks[0x24] = threading.Lock()
locks[0x20] = threading.Lock()
locks[0x25] = threading.Lock()
keysDown = {}
keysDown[0x21] = False
keysDown[0x24] = False
keysDown[0x20] = False
keysDown[0x25] = False

SendInput = ctypes.windll.user32.SendInput

# C struct redefinitions
PUL = ctypes.POINTER(ctypes.c_ulong)
class KeyBdInput(ctypes.Structure):
    _fields_ = [("wVk", ctypes.c_ushort),
                ("wScan", ctypes.c_ushort),
                ("dwFlags", ctypes.c_ulong),
                ("time", ctypes.c_ulong),
                ("dwExtraInfo", PUL)]

class HardwareInput(ctypes.Structure):
    _fields_ = [("uMsg", ctypes.c_ulong),
                ("wParamL", ctypes.c_short),
                ("wParamH", ctypes.c_ushort)]

class MouseInput(ctypes.Structure):
    _fields_ = [("dx", ctypes.c_long),
                ("dy", ctypes.c_long),
                ("mouseData", ctypes.c_ulong),
                ("dwFlags", ctypes.c_ulong),
                ("time",ctypes.c_ulong),
                ("dwExtraInfo", PUL)]

class Input_I(ctypes.Union):
    _fields_ = [("ki", KeyBdInput),
                 ("mi", MouseInput),
                 ("hi", HardwareInput)]

class Input(ctypes.Structure):
    _fields_ = [("type", ctypes.c_ulong),
                ("ii", Input_I)]

# Actuals Functions

def PressKey(hexKeyCode):
    extra = ctypes.c_ulong(0)
    ii_ = Input_I()
    ii_.ki = KeyBdInput( 0, hexKeyCode, 0x0008, 0, ctypes.pointer(extra) )
    x = Input( ctypes.c_ulong(1), ii_ )
    ctypes.windll.user32.SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))

def ReleaseKey(hexKeyCode):
    extra = ctypes.c_ulong(0)
    ii_ = Input_I()
    ii_.ki = KeyBdInput( 0, hexKeyCode, 0x0008 | 0x0002, 0, ctypes.pointer(extra) )
    x = Input( ctypes.c_ulong(1), ii_ )
    ctypes.windll.user32.SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))


def process_command(command):
	if command == 1:
		print "Left Don"
		press(0x21)
		# pyautogui.press("f")
	elif command == 2:
		print "Right Don"
		press(0x24)
		# pyautogui.press("j")
	elif command == 3:
		print "Left Ka"
		press(0x20)
		# pyautogui.press("d")
	elif command == 4:
		print "Right Ka"
		press(0x25)
		# pyautogui.press("k")

class PeerTalkThread(threading.Thread):
	def __init__(self,*args):
		self._psock = args[0]
		self._running = True
		threading.Thread.__init__(self)

	def run(self):
		framestructure = struct.Struct("! I I I I")
		print "listening to commands"
		while self._running:
			try:
				msg = self._psock.recv(16)	# frame header
				if len(msg) > 0:
					frame = framestructure.unpack(msg)
					# print "frame: ", frame
					size = frame[3]			# get size of payload?
					msgdata = self._psock.recv(size)	# receive payload?
					if msgdata:
						command = binascii.hexlify(msgdata)
						process_command(int(command))
					else:
						print "No data"
			except:
				pass

	def stop(self):
		self._running = False

def press(keycode):
		locks[keycode].acquire()
		# print "acquired lock for", keycode
		PressKey(keycode)
		# print "pressed", keycode
		keysDown[keycode] = True
		# print "set to true"
		locks[keycode].release()
		# print "released lock for", keycode


class KeyStrokeThread(threading.Thread):
	def __init__(self, *args):
		self._keycode = args[0]
		self._running = True
		threading.Thread.__init__(self)
	def run(self):
		while self._running:
			keycode = self._keycode
			if keysDown[keycode] == True:
				time.sleep(0.02)
				locks[keycode].acquire()
				# print "acquired lock for", keycode
				ReleaseKey(keycode)
				# print "released", keycode
				keysDown[keycode] = False
				locks[keycode].release()
				# print "released lock for", keycode
	def stop(self):
		self._running = False


print "starting..."
mux = usbmux.USBMux()

print "Waiting for devices..."
if not mux.devices:
    mux.process()	# search for devices with timeout=1.0?
if not mux.devices:
    print "No device found"

dev = mux.devices[0]	# get device found
print "connecting to device %s" % str(dev)
psock = mux.connect(dev, 2333)	# connect to device with port 2333
psock.setblocking(0)	# set to non-block
psock.settimeout(2)		# set timeout = 2


ptthread = PeerTalkThread(psock)
ptthread.start()

ldon = KeyStrokeThread(0x21)
ldon.start()

rdon = KeyStrokeThread(0x24)
rdon.start()

lka = KeyStrokeThread(0x20)
lka.start()

rka = KeyStrokeThread(0x25)
rka.start()

cmd = raw_input("press enter to exit")
print "exiting..."

# end connection and quit
ptthread.stop()
ptthread.join()
psock.close()

for p in [ldon, rdon, lka, rka]:
	p.stop()
	p.join()
