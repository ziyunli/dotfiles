-------------------------------------------------------------
-- Globals
-------------------------------------------------------------
hs.window.animationDuration = 0
hs.logger.defaultLogLevel = "info"

hyper = {"cmd", "alt", "ctrl"}
shift_hyper = {"cmd", "alt", "ctrl", "shift"}

col = hs.drawing.color.x11

-------------------------------------------------------------
-- SpoonInstall
-- this is the only spoon that needs to be manually installed
-- from https://www.hammerspoon.org/Spoons/SpoonInstall.html
-------------------------------------------------------------
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true
Install = spoon.SpoonInstall

-------------------------------------------------------------
-- Smart configuration reloading with Spoons
-------------------------------------------------------------
Install:andUse("ReloadConfiguration", {start = true})

-------------------------------------------------------------
-- WindowHalfsAndThirds for manipulating the size and position of windows
-- http://www.hammerspoon.org/Spoons/WindowHalfsAndThirds.html
-------------------------------------------------------------
Install:andUse("WindowHalfsAndThirds", {hotkeys = 'default'})

-------------------------------------------------------------
-- WindowScreenLeftAndRight for moving windows between multiple screens
-- http://www.hammerspoon.org/Spoons/WindowScreenLeftAndRight.html
-------------------------------------------------------------
Install:andUse("WindowScreenLeftAndRight", {hotkeys = 'default'})

Install:andUse("WindowGrid", {
    config = {gridGeometries = {{"6x4"}}},
    hotkeys = {show_grid = {hyper, "g"}},
    start = true
})
