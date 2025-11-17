#!/usr/bin/env python3
"""
Global scroll-to-right-click macro

Listens for global scroll events (up or down) and issues a right-click
at the current mouse position each time a scroll is detected.

Toggle the macro on/off with Ctrl+Alt+R.

Notes:
- Requires `pynput` (see `requirements.txt`).
- On macOS you must grant Accessibility permissions to the Python
  interpreter or terminal application you use to run this script.
"""
import logging
import threading
from pynput import mouse, keyboard
import sys
import time

controller = mouse.Controller()
enabled = threading.Event()
enabled.set()
# When we synthesize a cancelling scroll we set this so the listener ignores it
ignore_next_scroll = threading.Event()

def toggle():
	if enabled.is_set():
		enabled.clear()
		logging.info("Macro disabled")
	else:
		enabled.set()
		logging.info("Macro enabled")

def on_scroll(x, y, dx, dy):
	"""Called on global scroll events.

	dy != 0 indicates vertical scroll (positive usually up, negative down).
	We react to either direction and issue a right-click at the pointer.
	"""
	if not enabled.is_set():
		return
	# If this scroll was synthesized by us to cancel the visual scroll,
	# ignore it and clear the flag.
	if ignore_next_scroll.is_set():
		ignore_next_scroll.clear()
		logging.debug("Ignoring synthetic scroll event")
		return
	if dy == 0:
		return
	try:
		controller.click(mouse.Button.right, 1)
		# Visible output so you can see scrolls in the terminal while diagnosing
		print(f"SCROLL DETECTED at ({x},{y}) dx={dx} dy={dy} — issued right-click")
		sys.stdout.flush()
		logging.debug("Right-click at (%s, %s) for scroll (dx=%s, dy=%s)", x, y, dx, dy)
		# Send a cancelling scroll to negate the original scroll so the UI doesn't move.
		# Set the ignore flag so we don't react to the synthetic scroll we emit.
		ignore_next_scroll.set()
		# small pause to ensure ordering on some systems
		time.sleep(0.002)
		try:
			controller.scroll(-dx, -dy)
		except Exception:
			logging.exception("Failed to send cancelling scroll")
	except Exception:
		logging.exception("Failed to perform right-click")

def main():
	# Use DEBUG while diagnosing input permission / event delivery
	logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(levelname)s: %(message)s")
	logging.info("Starting scroll→right-click macro. Toggle with Ctrl+Alt+R")

	mouse_listener = mouse.Listener(on_scroll=on_scroll)
	# Global hotkey to toggle the macro (Ctrl+Alt+R)
	hotkeys = keyboard.GlobalHotKeys({"<ctrl>+<alt>+r": toggle})

	mouse_listener.start()
	hotkeys.start()

	try:
		mouse_listener.join()
	except KeyboardInterrupt:
		logging.info("Interrupted by user, exiting")
	finally:
		try:
			hotkeys.stop()
		except Exception:
			pass
		try:
			mouse_listener.stop()
		except Exception:
			pass

if __name__ == '__main__':
	main()

