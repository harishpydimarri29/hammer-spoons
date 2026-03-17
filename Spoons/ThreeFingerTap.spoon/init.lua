--- ThreeFingerTap.spoon
--- Fires a configurable keyboard shortcut when the trackpad is tapped with 3+ fingers.
---
--- Usage:
---   hs.loadSpoon("ThreeFingerTap")
---   spoon.ThreeFingerTap:bindTo({"cmd", "shift"}, "C")
---   spoon.ThreeFingerTap:start()

local obj = {}
obj.__index = obj

obj.name     = "ThreeFingerTap"
obj.version  = "1.0"
obj.author   = "p0h043d"
obj.license  = "MIT"

--- ThreeFingerTap.mods
--- The modifier keys for the triggered shortcut (default: {"cmd", "shift"})
obj.mods = {"cmd", "shift"}

--- ThreeFingerTap.key
--- The key for the triggered shortcut (default: "C")
obj.key = "C"

--- ThreeFingerTap.moveThreshold
--- Normalized trackpad distance a finger must travel to cancel the tap (default: 0.05)
obj.moveThreshold = 0.05

--- ThreeFingerTap.timeLimit
--- Maximum seconds the gesture may last to count as a tap (default: 0.4)
obj.timeLimit = 0.4

--- ThreeFingerTap.cooldown
--- Minimum seconds between consecutive firings (default: 0.5)
obj.cooldown = 0.5

obj._state = nil
obj._tap   = nil

--- ThreeFingerTap:bindTo(mods, key)
--- Configure which shortcut to fire on a 3-finger tap.
---
--- Parameters:
---   mods - table of modifier key strings, e.g. {"cmd", "shift"}
---   key  - string key name, e.g. "C"
---
--- Returns:
---   The ThreeFingerTap object (for chaining)
function obj:bindTo(mods, key)
  self.mods = mods
  self.key  = key
  return self
end

--- ThreeFingerTap:start()
--- Start listening for 3-finger tap gestures.
---
--- Returns:
---   The ThreeFingerTap object (for chaining)
function obj:start()
  if self._tap then self._tap:stop() end

  local state = {
    tracking       = false,
    startTime      = 0,
    moved          = false,
    startPositions = {},
    lastFired      = 0,
  }
  self._state = state

  local mods         = self.mods
  local key          = self.key
  local moveThresh   = self.moveThreshold
  local timeLimit    = self.timeLimit
  local cooldown     = self.cooldown

  self._tap = hs.eventtap.new({ hs.eventtap.event.types.gesture }, function(e)
    local touches = e:getTouches()
    if not touches or type(touches) ~= "table" then return false end

    local active = {}
    for _, t in ipairs(touches) do
      if not t.resting then
        table.insert(active, t)
      end
    end
    local count = #active

    local anyStillTouching = false
    for _, t in ipairs(active) do
      local ended = false
      if t.phase then
        ended = (t.phase == "ended" or t.phase == "cancelled")
      elseif t.touching ~= nil then
        ended = not t.touching
      end
      if not ended then
        anyStillTouching = true
        break
      end
    end

    if count >= 3 and anyStillTouching then
      if not state.tracking then
        state.tracking       = true
        state.startTime      = hs.timer.secondsSinceEpoch()
        state.moved          = false
        state.startPositions = {}
        for _, t in ipairs(active) do
          if t.normalizedPosition then
            table.insert(state.startPositions, {
              x = t.normalizedPosition.x,
              y = t.normalizedPosition.y,
            })
          end
        end
      else
        for i, t in ipairs(active) do
          if t.normalizedPosition and state.startPositions[i] then
            local sp = state.startPositions[i]
            local dx = math.abs(t.normalizedPosition.x - sp.x)
            local dy = math.abs(t.normalizedPosition.y - sp.y)
            if dx > moveThresh or dy > moveThresh then
              state.moved = true
            end
          end
        end
      end
    elseif state.tracking then
      local now     = hs.timer.secondsSinceEpoch()
      local elapsed = now - state.startTime
      if not state.moved and elapsed < timeLimit
         and (now - state.lastFired) > cooldown then
        state.lastFired = now
        hs.timer.doAfter(0, function()
          hs.eventtap.keyStroke(mods, key)
        end)
      end
      state.tracking = false
    end

    if state.tracking then
      local elapsed = hs.timer.secondsSinceEpoch() - state.startTime
      if elapsed > timeLimit then
        state.tracking = false
      end
    end

    return false
  end)

  self._tap:start()
  return self
end

--- ThreeFingerTap:stop()
--- Stop listening for gestures.
---
--- Returns:
---   The ThreeFingerTap object (for chaining)
function obj:stop()
  if self._tap then
    self._tap:stop()
    self._tap = nil
  end
  return self
end

return obj
