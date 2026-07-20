require("hs.ipc")

local config = require("config")
local cheatsheet = require("cheatsheet")

hs.hotkey.bind(config.hotkey.modifiers, config.hotkey.key, cheatsheet.show)

local validation = cheatsheet.validate()
if #validation.diagnostics > 0 then
    hs.notify.new({
        title = "Cheatsheet Configuration",
        informativeText = string.format("%d issue%s found; see Hammerspoon logs",
            #validation.diagnostics, #validation.diagnostics == 1 and "" or "s"),
    }):send()
end
