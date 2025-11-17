#!/usr/bin/env bash
set -euo pipefail

echo "== Hammerspoon installer helper =="

if command -v brew >/dev/null 2>&1; then
  echo "Homebrew detected — installing Hammerspoon via brew cask..."
  brew install --cask hammerspoon
else
  echo "Homebrew not found — attempting to find Hammerspoon in ~/Downloads"
  DMG=$(ls ~/Downloads/Hammerspoon*.dmg 2>/dev/null | tail -n1 || true)
  ZIP=$(ls ~/Downloads/Hammerspoon*.zip 2>/dev/null | tail -n1 || true)
  APP=$(ls ~/Downloads/Hammerspoon.app 2>/dev/null | tail -n1 || true)

  if [[ -n "$APP" ]]; then
    echo "Found app: $APP — moving to /Applications (requires sudo)"
    sudo rm -rf /Applications/Hammerspoon.app || true
    sudo mv "$APP" /Applications/

  elif [[ -n "$ZIP" ]]; then
    echo "Found zip: $ZIP — extracting"
    TMP=$(mktemp -d)
    unzip -q "$ZIP" -d "$TMP"
    FOUND_APP=$(find "$TMP" -maxdepth 2 -name "Hammerspoon.app" -print -quit || true)
    if [[ -n "$FOUND_APP" ]]; then
      echo "Installing $FOUND_APP to /Applications (requires sudo)"
      sudo rm -rf /Applications/Hammerspoon.app || true
      sudo mv "$FOUND_APP" /Applications/
    else
      echo "Could not find Hammerspoon.app inside $ZIP"
      rm -rf "$TMP"
      exit 1
    fi
    rm -rf "$TMP"

  elif [[ -n "$DMG" ]]; then
    echo "Found dmg: $DMG — mounting"
    MOUNT=$(hdiutil attach "$DMG" -nobrowse -quiet)
    MOUNT_POINT=$(echo "$MOUNT" | awk '/\/Volumes\//{print $3; exit}')
    if [[ -z "$MOUNT_POINT" ]]; then
      echo "Failed to mount $DMG"
      exit 1
    fi
    echo "Copying Hammerspoon.app from $MOUNT_POINT to /Applications (requires sudo)"
    sudo rm -rf /Applications/Hammerspoon.app || true
    sudo cp -R "$MOUNT_POINT/Hammerspoon.app" /Applications/
    hdiutil detach "$MOUNT_POINT" -quiet || true

  else
    echo "No Homebrew and no Hammerspoon archive found in ~/Downloads."
    echo "Please download Hammerspoon from https://www.hammerspoon.org/ and place the .dmg/.zip or the app in ~/Downloads, then re-run this script."
    exit 1
  fi
fi

echo "Removing quarantine attribute (if any)..."
sudo xattr -dr com.apple.quarantine /Applications/Hammerspoon.app || true

echo "Copying config to ~/.hammerspoon/init.lua"
mkdir -p ~/.hammerspoon
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/hammerspoon_init.lua" ]]; then
  cp -f "$SCRIPT_DIR/hammerspoon_init.lua" ~/.hammerspoon/init.lua
  echo "Copied $SCRIPT_DIR/hammerspoon_init.lua -> ~/.hammerspoon/init.lua"
else
  echo "Warning: hammerspoon_init.lua not found beside this script. Please copy your config to ~/.hammerspoon/init.lua"
fi

echo "Restarting Hammerspoon and reloading config..."
osascript -e 'tell application "Hammerspoon" to quit' || true
open -a Hammerspoon || true
sleep 1
osascript -e 'tell application "Hammerspoon" to reload' || true

echo "Done. Now grant Accessibility and Input Monitoring for Hammerspoon in System Settings → Privacy & Security, then reload config if needed."
