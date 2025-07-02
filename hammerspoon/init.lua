-- Auto reload config on file change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

-- App switching shortcuts (using right command key)
hs.hotkey.bind({"rightcmd"}, "-", function()
  local app = hs.application.get("Ghostty")
  if app then
    app:activate()
    -- Wait a bit for activation then go fullscreen
    hs.timer.doAfter(0.1, function()
      app:mainWindow()
      local win = app:mainWindow()
      if win and not win:isFullScreen() then
        win:setFullScreen(true)
      end
    end)
  else
    hs.application.open("Ghostty")
  end
end)

hs.hotkey.bind({"rightcmd"}, "=", function()
  local app = hs.application.get("Safari")
  if app then
    app:activate()
    -- Wait a bit for activation then go fullscreen
    hs.timer.doAfter(0.1, function()
      app:mainWindow()
      local win = app:mainWindow()
      if win and not win:isFullScreen() then
        win:setFullScreen(true)
      end
    end)
  else
    hs.application.open("Safari")
  end
end)

-- Show notification on config load
hs.notify.new({title="Hammerspoon", informativeText="Config loaded"}):send()
