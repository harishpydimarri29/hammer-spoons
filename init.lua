hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

-- 3-finger tap → trigger a keyboard shortcut
hs.loadSpoon("ThreeFingerTap")
spoon.ThreeFingerTap:bindTo({"cmd", "shift"}, "C"):start()

-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
--     hs.notify.new({title="Hammerspoon", informativeText="Hello World"}):send()
-- end)
hs.alert.show("Hammerspoon re-loaded with spoon")