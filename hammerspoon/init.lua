-- Auto reload config on file change
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hs.reload):start()

local gotoApplication = function(appName)
    return function()
        local app = hs.application.get(appName)
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
            hs.application.open(appName)
        end
    end
end

hs.hotkey.bind({ "rightalt" }, "-", gotoApplication("Ghostty"))

-- for the split keyboards
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "a", gotoApplication("Ghostty"))

hs.hotkey.bind({ "rightalt" }, "=", gotoApplication("Safari"))

hs.hotkey.bind({ "ctrl", "alt", "shift" }, "s", gotoApplication("Safari"))

-- Show notification on config load
hs.notify.new({ title = "Hammerspoon", informativeText = "Config loaded" }):send()
