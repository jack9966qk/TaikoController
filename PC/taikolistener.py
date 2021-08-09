# taikolistener.py

import threading
from peerTalkThread import PeerTalkThread, readPeerTalkHeader
import ctypes
import time
import six

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
		print("Left Don")
		press(0x21)
		# pyautogui.press("f")
	elif command == 2:
		print("Right Don")
		press(0x24)
		# pyautogui.press("j")
	elif command == 3:
		print("Left Ka")
		press(0x20)
		# pyautogui.press("d")
	elif command == 4:
		print("Right Ka")
		press(0x25)
		# pyautogui.press("k")

def press(keycode):
		locks[keycode].acquire()
		# print("acquired lock for", keycode)
		PressKey(keycode)
		# print("pressed", keycode)
		keysDown[keycode] = True
		# print("set to true")
		locks[keycode].release()
		# print("released lock for", keycode)


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
				# print("acquired lock for", keycode)
				ReleaseKey(keycode)
				# print("released", keycode)
				keysDown[keycode] = False
				locks[keycode].release()
				# print("released lock for", keycode)
	def stop(self):
		self._running = False

def onReceive(header, payload, psock, timeOffset):
	unpackedHeader = readPeerTalkHeader(header)
	command = unpackedHeader.tag
	print("received commnad", command)
	process_command(command)

ptThread = PeerTalkThread(onReceive)
ptThread.start()

ldon = KeyStrokeThread(0x21)
ldon.start()

rdon = KeyStrokeThread(0x24)
rdon.start()

lka = KeyStrokeThread(0x20)
lka.start()

rka = KeyStrokeThread(0x25)
rka.start()

six.moves.input("press enter to exit")
print("exiting...")

# end connection and quit
ptThread.stop()
ptThread.join()

for p in [ldon, rdon, lka, rka]:
	p.stop()
	p.join()
