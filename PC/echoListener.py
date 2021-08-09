from peerTalkThread import PeerTalkThread, timestampFromPeerData
import struct
import time
import six

timeDiffs = []
def onReceive(header, payload, psock, timeOffset):
	if payload is not None:
		peerTime = timestampFromPeerData(payload)
		diff = (time.time() - (peerTime + timeOffset)) * 1000
		print("timeDiff", diff)
		timeDiffs.append(diff)
	psock.send(header if payload is None else header + payload)

ptThread = PeerTalkThread(onReceive, bufferMs=16)
ptThread.start()

six.moves.input("press enter to exit")
print("exiting...")

# end connection and quit
ptThread.stop()
ptThread.join()

if len(timeDiffs) > 0:
	print("min", min(timeDiffs))
	print("max", max(timeDiffs))
	print("max - min", max(timeDiffs) - min(timeDiffs))