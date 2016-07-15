-- Load all plugins in the plugins dir
for dir in io.popen('ls ./plugins/*.lua| sed "s/\\.lua$//g"'):lines() do
  print("Loading plugin " .. dir)
  require(dir)
end

-- Disable animation
hs.window.animationDuration = 0

-- Set base key combo
righthyper  = {"alt","cmd"}
fullhyper   = {"ctrl","cmd","alt"}
centerhyper = {"ctrl","cmd"}

-- Sleep display/computer
hs.hotkey.bind(centerhyper, 'delete', function() hs.execute('pmset displaysleepnow')  end)

-- Reload hammerspoon config
hs.hotkey.bind(centerhyper, 'r', function() hs.reload() end)
