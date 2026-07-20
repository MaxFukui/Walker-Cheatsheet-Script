local t = require("test_helper")
local cheatsheet = require("cheatsheet")

local requiredMethods = {
    "realpath", "parent", "listRegularFiles", "readFile", "log", "notify",
    "showChooser", "setPasteboard", "openURL", "launchOrFocus",
    "openNewWindow", "runHashDialog", "editSheets", "modifiers",
}

t.test("Hammerspoon adapter exposes the controller interface", function()
    local chooser = {}
    function chooser:width() return self end
    function chooser:rows() return self end
    local fakeHs = {
        configdir = "/tmp/.hammerspoon",
        chooser = { new = function() return chooser end },
        fs = {}, pasteboard = {}, notify = {}, application = {},
        timer = {}, eventtap = {}, task = {}, image = {}, logger = {},
        osascript = {}, urlevent = {},
    }
    fakeHs.logger.new = function() return { e = function() end } end

    local adapter = cheatsheet.hammerspoonAdapter(fakeHs)
    for _, method in ipairs(requiredMethods) do
        t.equal(type(adapter[method]), "function", method .. " must be a function")
    end
end)
