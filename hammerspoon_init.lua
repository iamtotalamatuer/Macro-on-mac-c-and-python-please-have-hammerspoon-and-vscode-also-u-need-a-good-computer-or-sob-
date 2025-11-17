-- Hammerspoon init: suppress scroll and issue right-click
-- Toggle: Ctrl+Alt+H
-- Soft CPS cap toggle: Ctrl+Alt+C (when enabled, limits clicks to softCapCPS)

local eventtap = hs.eventtap
local types = eventtap.event.types
local props = eventtap.event.properties
local mouse = hs.mouse
local hotkey = hs.hotkey
local timer = hs.timer

-- Configuration
local enabled = true
local sensitivity = 0.5 -- scroll-units required to produce one click (lower = more clicks)
local scrollAccumulator = 0
local DEBUG_SCROLL = false
local lastScrollTime = 0
local scrollResetTimeout = 0.5 -- reset accumulator after 0.5s of no scrolling

-- Soft cap
local softCapEnabled = true  -- START ENABLED
local softCapCPS = 60  -- testing higher CPS cap
local softMinInterval = 1 / softCapCPS
local lastClickTime = 0

local function setSoftCapCPS(v)
  softCapCPS = math.max(1, v)
  softMinInterval = 1 / softCapCPS
  hs.alert.show(string.format("Hammerspoon softCPS=%d", softCapCPS))
end

local function rightClickHere()
  local pt = hs.mouse.absolutePosition()
  print(string.format("DEBUG: right-click at (%.1f, %.1f)", pt.x, pt.y))
  local down = eventtap.event.newMouseEvent(types.rightMouseDown, pt)
  local up = eventtap.event.newMouseEvent(types.rightMouseUp, pt)
  down:post()
  up:post()
end

local scrollTap = nil

local function startScrollTap()
  if scrollTap then
    scrollTap:stop()
  end
  scrollTap = eventtap.new({ types.scrollWheel }, function(ev)
    if not enabled then 
      return false  -- pass through if disabled
    end
    
    local now = timer.secondsSinceEpoch()
    -- Reset accumulator if too much time has passed since last scroll
    if now - lastScrollTime > scrollResetTimeout then
      scrollAccumulator = 0
    end
    lastScrollTime = now
    
    local dy = ev:getProperty(props.scrollWheelEventDeltaAxis1) or 0
    local dx = ev:getProperty(props.scrollWheelEventDeltaAxis2) or 0
    if dy == 0 and dx == 0 then 
      return true  -- suppress empty scrolls
    end

    local mag = math.abs(dy) + math.abs(dx)
    scrollAccumulator = scrollAccumulator + mag
    print(string.format("DEBUG: enabled=%s, acc=%.5f, mag=%.3f, dy=%.3f, dx=%.3f", tostring(enabled), scrollAccumulator, mag, dy, dx))

    local clicksAvailable = math.floor(scrollAccumulator / sensitivity)
    print(string.format("DEBUG: clicksAvailable=%d (need %.5f per click, have %.5f total)", clicksAvailable, sensitivity, scrollAccumulator))
    
    if clicksAvailable > 0 then
      for i = 1, clicksAvailable do
        if softCapEnabled then
          local now2 = timer.secondsSinceEpoch()
          if now2 - lastClickTime < softMinInterval then
            print("DEBUG: rate limited at click " .. i .. ", stopping early")
            scrollAccumulator = scrollAccumulator - (sensitivity * (i - 1))
            return true  -- suppress scroll and exit
          end
          lastClickTime = now2
        end
        print("DEBUG: emitting right-click #" .. i)
        rightClickHere()
      end
      scrollAccumulator = scrollAccumulator - (sensitivity * clicksAvailable)
    else
      print(string.format("DEBUG: not enough accumulated (need %.5f, have %.5f)", sensitivity, scrollAccumulator))
    end

    return true  -- ALWAYS suppress the original scroll event
  end)
  scrollTap:start()
  print("DEBUG: scroll tap started")
end

startScrollTap()

-- Toggle macro: Ctrl+Alt+H
hotkey.bind({"ctrl", "alt"}, "H", function()
  enabled = not enabled
  print(string.format("DEBUG: toggled enabled to %s", tostring(enabled)))
  hs.alert.show("Hammerspoon Scroll→RightClick: " .. (enabled and "Enabled" or "Disabled"))
end)

-- Toggle soft cap: Ctrl+Alt+C
hotkey.bind({"ctrl", "alt"}, "C", function()
  softCapEnabled = not softCapEnabled
  hs.alert.show("Hammerspoon soft cap: " .. (softCapEnabled and "Enabled" or "Disabled"))
end)

-- Optional CPS adjusters (Ctrl+Alt+Up/Down)
hotkey.bind({"ctrl", "alt"}, "Up", function() setSoftCapCPS(softCapCPS + 5) end)
hotkey.bind({"ctrl", "alt"}, "Down", function() setSoftCapCPS(math.max(1, softCapCPS - 5)) end)

-- Debug hotkey to restart the tap (Ctrl+Alt+Shift+R)
hotkey.bind({"ctrl", "alt", "shift"}, "R", function()
  print("DEBUG: manually restarting scroll tap")
  startScrollTap()
  hs.alert.show("Scroll tap restarted")
end)

hs.alert.show("Hammerspoon Scroll→RightClick loaded (Ctrl+Alt+H toggle)")
