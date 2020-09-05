-- Copy-pasta from https://github.com/zzamboni/dot-hammerspoon/blob/master/init.org
-------------------------------------------------------------
-- Globals
-------------------------------------------------------------
hs.window.animationDuration = 0
hs.logger.defaultLogLevel = 'info'

hyper = {'cmd', 'alt', 'ctrl'}
shift_hyper = {'cmd', 'alt', 'ctrl', 'shift'}

col = hs.drawing.color.x11

-------------------------------------------------------------
-- SpoonInstall
-- this is the only spoon that needs to be manually installed
-- from https://www.hammerspoon.org/Spoons/SpoonInstall.html
-------------------------------------------------------------
hs.loadSpoon('SpoonInstall')
spoon.SpoonInstall.use_syncinstall = true
Install = spoon.SpoonInstall

-- Smart configuration reloading with Spoons
Install:andUse('ReloadConfiguration', {start = true})

-- WindowHalfsAndThirds for manipulating the size and position of windows
-- http://www.hammerspoon.org/Spoons/WindowHalfsAndThirds.html
Install:andUse('WindowHalfsAndThirds', {hotkeys = 'default'})

-- WindowScreenLeftAndRight for moving windows between multiple screens
-- http://www.hammerspoon.org/Spoons/WindowScreenLeftAndRight.html
Install:andUse('WindowScreenLeftAndRight', {hotkeys = 'default'})

-- WindowGrid sets up a key binding (Hyper-g here) to overlay a grid
-- that allows resizing windows by specifying their opposite corners.
-- http://www.hammerspoon.org/Spoons/WindowGrid.html
Install:andUse('WindowGrid', {
    config = {gridGeometries = {{'6x4'}}},
    hotkeys = {show_grid = {hyper, 'g'}},
    start = true
})

-- ToggleScreenRotation sets up a key binding to rotate the external screen
-- (the spoon can set up keys for multiple screens if needed, but by default
-- it rotates the first external screen).
-- http://www.hammerspoon.org/Spoons/ToggleScreenRotation.html
Install:andUse('ToggleScreenRotation', {hotkeys = {first = {hyper, 'f15'}}})

-- TextClipboardHistory: a clipboard history only for text items.
-- http://www.hammerspoon.org/Spoons/TextClipboardHistory.html
-- Install:andUse('TextClipboardHistory', {
--     config = {show_in_menubar = false},
--     hotkeys = {toggle_clipboard = {{'cmd', 'shift'}, 'v'}},
--     disable = true,
--     start = true
-- })

-- http://www.hammerspoon.org/Spoons/Caffeine.html
-- Install:andUse('Caffeine', {start = true, hotkeys = {toggle = {hyper, '1'}}})

-- http://www.hammerspoon.org/Spoons/MenubarFlag.html
Install:andUse('MenubarFlag', {
    config = {
        colors = {
            ['U.S.'] = {},
            ['Pinyin - Simplified'] = {col.red, col.yellow}
        }
    },
    start = true
})

-- http://www.hammerspoon.org/Spoons/WiFiTransitions.html
Install:andUse('WiFiTransitions', {
    config = {
        actions = {
            {
                -- Test action just to see the SSID transitions
                fn = function(_, _, prev_ssid, new_ssid)
                    hs.notify.show('SSID change', string.format(
                                       "From '%s' to '%s'", prev_ssid, new_ssid),
                                   '')
                end
            }
        }
    },
    start = true
})

-- http://www.hammerspoon.org/Spoons/PopupTranslateSelection.html
local wm = hs.webview.windowMasks
Install:andUse('PopupTranslateSelection', {
    -- disable = true,
    config = {
        popup_style = wm.utility | wm.HUD | wm.titled | wm.closable |
            wm.resizable
    },
    hotkeys = {
        translate_to_en = {hyper, 'e'}
        -- translate_to_zh_CN = {hyper, 'c'}
        -- translate_to_de = {hyper, 'd'},
        -- translate_to_es = {hyper, 's'},
        -- translate_de_en = {shift_hyper, 'e'},
        -- translate_en_de = {shift_hyper, 'd'}
    }
})

-- http://www.hammerspoon.org/Spoons/UnsplashZ.html
-- Install:andUse('UnsplashZ')

-- https://www.hammerspoon.org/Spoons/FadeLogo.html
Install:andUse('FadeLogo', {start = true})
