import threading
from collections import deque
import time

class BusyWaitingThread(threading.Thread):
	def __init__(self):
		self._running = False
		self._tasks = deque([])
		threading.Thread.__init__(self)

	def run(self):
		self._running = True
		while self._running:
			if len(self._tasks) == 0:
				time.sleep(0.001)
				continue
			taskFn, afterTime = self._tasks[0]
			if time.time() > afterTime:
				# print("busyWaitingThread timeDiff (ms)", (time.time() - afterTime) * 1000)
				taskFn()
				self._tasks.popleft()

	def doTaskAfter(self, taskFn, afterTime):
		# Assume afterTime is always later than all existing tasks.
		self._tasks.append((taskFn, afterTime))

	def stop(self):
		self._running = False