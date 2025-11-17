# Scroll-to-Right-Click Macro

This script listens for global scroll events (vertical mouse wheel) and issues a right-click at the current pointer position each time a scroll is detected.

Requirements
- Python 3.8+
- `pynput` (install with `pip install -r requirements.txt`)

macOS accessibility
1. Open System Settings → Privacy & Security → Accessibility.
2. Add and enable the Terminal (or the Python interpreter you use), or the app you use to run this script.
3. You may need to restart the Terminal app after granting permission.

Usage
```bash
pip3 install -r requirements.txt
python3 macro.py
```

Toggle the macro on/off with `Ctrl+Alt+R`.

Notes
- The script does not suppress the original scroll event; it issues an additional right-click on each vertical scroll.
- Use with caution: a continuous scroll will generate many right-clicks.

No-admin installs (pip / pipx / venv)
If you don't have admin rights you can still run `macro.py` using one of these methods.

- `pip --user` (quick):
	- Install the dependency for your user only:
		```bash
		python3 -m pip install --user pynput
		```
	- Find your user base binary dir and ensure it's in `PATH` (example shows how to print it):
		```bash
		python3 -m site --user-base
		# On macOS the executables are typically in:
		# $(python3 -m site --user-base)/bin
		# e.g. add to ~/.zshrc:
		export PATH="$(python3 -m site --user-base)/bin:$PATH"
		source ~/.zshrc
		```
	- Run the script:
		```bash
		python3 macro.py
		```

- `pipx` (recommended for CLI-style isolation):
	- Install `pipx` for your user and ensure the shim path is enabled:
		```bash
		python3 -m pip install --user pipx
		python3 -m pipx ensurepath
		exec $SHELL
		```
	- Install packages into isolated environments and run them via `pipx` or use `pipx run` for one-offs. For this script you still run the file directly but can use `pipx` to install tools you need globally for your user.

- `venv` (clean project-local environment):
	- Create and activate a venv inside your home or project (no admin required):
		```bash
		python3 -m venv ~/.venvs/macro    # or ./venv
		source ~/.venvs/macro/bin/activate
		pip install --upgrade pip
		pip install pynput
		python macro.py
		```

Pick whichever approach you prefer. If you'd like, I can add a small `run-macro.sh` script or a `Makefile` target to simplify starting the macro from your project directory.

Hammerspoon (recommended) — completely suppress scroll
If your goal is to stop the scroll from happening altogether while the macro runs, Hammerspoon is the simplest and most reliable way on macOS. Hammerspoon's `eventtap` can intercept and suppress events so the original scroll never reaches apps.

1) Install Hammerspoon (no admin required):
	- Download the latest DMG from: https://www.hammerspoon.org/
	- Open the DMG and drag the Hammerspoon app to your `Applications` folder.

2) Grant permissions:
	- Open System Settings → Privacy & Security.
	- Under `Accessibility` add `Hammerspoon.app` and enable it.
	- Under `Input Monitoring` add `Hammerspoon.app` and enable it.
	- Quit and re-open Hammerspoon after granting permissions.

3) Install the config:
	- Copy the file `hammerspoon_init.lua` from this project into your Hammerspoon config location:
	  ```bash
	  mkdir -p ~/.hammerspoon
	  cp /Users/ATM/Downloads/Vscode/hammerspoon_init.lua ~/.hammerspoon/init.lua
	  ```
	- Reload Hammerspoon config by clicking the Hammerspoon menu bar icon → `Reload Config`, or run in Hammerspoon console `hs.reload()`.

4) Behavior and controls:
	- While enabled, any vertical or horizontal scroll will be suppressed and will instead trigger a right-click at the mouse pointer.
	- Toggle the behavior with `Ctrl+Alt+R` (configurable in the `init.lua`).
	- The script debounces scroll bursts so it won't create excessive clicks during a continuous scroll.

Why use Hammerspoon?
- It can suppress events natively; Python-based listeners (e.g., `pynput`) cannot reliably prevent the original scroll from being delivered to apps.
- No need to build `pyobjc-core` or grant permission to specific Python binaries.

If you'd like, I can modify `hammerspoon_init.lua` to change the toggle shortcut, debounce interval, or to only suppress scroll while holding a modifier key. Tell me which behavior you prefer and I will update the file.
