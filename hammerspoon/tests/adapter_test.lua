local t = require("test_helper")
local cheatsheet = require("cheatsheet")

local requiredMethods = {
    "realpath", "parent", "listRegularFiles", "readFile", "log", "notify",
    "showChooser", "setPasteboard", "openURL", "launchOrFocus",
    "openNewWindow", "runHashDialog", "editSheets", "modifiers",
}

local function fakeHs()
    local chooser = {}
    function chooser:width() return self end
    function chooser:rows() return self end
    return {
        configdir = "/tmp/.hammerspoon",
        chooser = { new = function() return chooser end },
        fs = {},
        pasteboard = { setContents = function() return true end },
        notify = {}, application = {}, timer = {}, eventtap = {},
        task = {}, image = {},
        logger = { new = function() return { e = function() end } end },
        osascript = { applescript = function() return true, "secret" end },
        urlevent = {},
    }
end

t.test("Hammerspoon adapter exposes the controller interface", function()
    local adapter = cheatsheet.hammerspoonAdapter(fakeHs())
    for _, method in ipairs(requiredMethods) do
        t.equal(type(adapter[method]), "function", method .. " must be a function")
    end
end)

t.test("hash reports task construction failure without throwing", function()
    local hs = fakeHs()
    hs.task.new = function() return nil end
    local adapter = cheatsheet.hammerspoonAdapter(hs)
    local callbackOk, callbackDetail

    local noThrow = pcall(function()
        adapter:runHashDialog(function(ok, detail)
            callbackOk, callbackDetail = ok, detail
        end)
    end)

    t.truthy(noThrow, "hash action must not throw")
    t.equal(callbackOk, false)
    t.truthy(callbackDetail and callbackDetail ~= "")
end)

t.test("editor reports task construction failure without throwing", function()
    local hs = fakeHs()
    hs.task.new = function() return nil end
    local adapter = cheatsheet.hammerspoonAdapter(hs)
    local callbackOk, callbackDetail

    local noThrow = pcall(function()
        adapter:editSheets("/repo", "Ghostty", "nvim", function(ok, detail)
            callbackOk, callbackDetail = ok, detail
        end)
    end)

    t.truthy(noThrow, "editor action must not throw")
    t.equal(callbackOk, false)
    t.truthy(callbackDetail and callbackDetail ~= "")
end)

t.test("hash rejects malformed successful output", function()
    local hs = fakeHs()
    local pasteboardWrites = 0
    hs.pasteboard.setContents = function()
        pasteboardWrites = pasteboardWrites + 1
        return true
    end
    hs.task.new = function(_, completion)
        local task = {}
        function task:setInput() return self end
        function task:start()
            completion(0, "abc123  -\n", "")
            return self
        end
        return task
    end
    local adapter = cheatsheet.hammerspoonAdapter(hs)
    local callbackOk

    adapter:runHashDialog(function(ok) callbackOk = ok end)

    t.equal(callbackOk, false)
    t.equal(pasteboardWrites, 0)
end)
