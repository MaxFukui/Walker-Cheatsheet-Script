require("hs.ipc")

local cheatsheet = require("cheatsheet")

hs.hotkey.bind({ "alt", "ctrl", "shift" }, "K", function()
    cheatsheet.show()
end)

hs.alert.show("Cheatsheet loaded")
