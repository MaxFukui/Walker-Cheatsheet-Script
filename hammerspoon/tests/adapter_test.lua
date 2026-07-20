local t = require("test_helper")
local cheatsheet = require("cheatsheet")

local requiredMethods = {
    "realpath", "parent", "listRegularFiles", "readFile", "log", "notify",
    "showChooser", "setPasteboard", "openURL", "launchOrFocus",
    "openNewWindow", "runHashDialog", "editSheets", "modifiers",
}

local function fakeHs()
    local chooser = { choiceSets = {} }
    function chooser:width() return self end
    function chooser:rows() return self end
    function chooser:choices(rows) table.insert(self.choiceSets, rows); return self end
    function chooser:show() return self end
    function chooser:queryChangedCallback(fn) self.queryCallback = fn; return self end
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

t.test("chooser filters unified metadata while preserving readable rows", function()
    local hs = fakeHs()
    hs.image.imageFromName = function(name) return "image:" .. name end
    local adapter = cheatsheet.hammerspoonAdapter(hs)
    adapter:showChooser({
        { text = "Create", subText = "Git › Branches · Copy command", searchText = "git branches create git branch -c command" },
        { text = "Firefox", subText = "App · Open new window", searchText = "app browser firefox new" },
    }, function() end)
    local chooser = hs.chooser.new()
    chooser.queryCallback("git branch")
    t.equal(#chooser.choiceSets[#chooser.choiceSets], 1)
    t.equal(chooser.choiceSets[#chooser.choiceSets][1].text, "Create")
    t.equal(chooser.choiceSets[#chooser.choiceSets][1].subText, "Git › Branches · Copy command")
    chooser.queryCallback("app firefox")
    t.equal(#chooser.choiceSets[#chooser.choiceSets], 1)
    t.equal(chooser.choiceSets[#chooser.choiceSets][1].text, "Firefox")
end)

t.test("configured icons request distinct documented system image names with safe fallback", function()
    local hs = fakeHs()
    local requested = {}
    hs.image.imageFromName = function(name)
        table.insert(requested, name)
        if name == "NSCaution" then return "fallback" end
    end
    local adapter = cheatsheet.hammerspoonAdapter(hs)
    local config = require("config")
    local records = {}
    local seen = {}
    for kind, name in pairs(config.icons) do
        t.truthy(name:match("^NS"), kind .. " icon must be a named AppKit image")
        t.truthy(not seen[name], "icons must be distinct")
        seen[name] = true
        table.insert(records, { kind = kind, text = kind, subText = kind, image = name })
    end
    adapter:showChooser(records, function() end)
    for _, name in pairs(config.icons) do
        local found = false
        for _, requestedName in ipairs(requested) do if requestedName == name then found = true end end
        t.truthy(found, "must request " .. name)
    end
    t.truthy(#requested > #records, "missing icons must request fallback")
end)

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

t.test("failed tasks replace empty stderr with actionable fallback detail", function()
    local hs = fakeHs()
    local completion
    hs.task.new = function(_, callback)
        completion = callback
        return { start = function(self) return self end, setInput = function(self) return self end }
    end
    local adapter = cheatsheet.hammerspoonAdapter(hs)
    local hashDetail
    adapter:runHashDialog(function(_, detail) hashDetail = detail end)
    completion(1, "", "")
    t.equal(hashDetail, "shasum failed")

    local editorDetail
    adapter:editSheets("/repo", "Ghostty", "nvim", function(_, detail) editorDetail = detail end)
    completion(1, "", "")
    t.equal(editorDetail, "editor launch failed")
end)

t.test("adapter retains running tasks only until their completion callbacks", function()
    local hs = fakeHs()
    local completions = {}
    hs.task.new = function(_, callback)
        table.insert(completions, callback)
        return { start = function(self) return self end, setInput = function(self) return self end }
    end
    local adapter = cheatsheet.hammerspoonAdapter(hs)
    adapter:runHashDialog(function() end)
    local running = 0
    for _ in pairs(adapter.activeTasks) do running = running + 1 end
    t.equal(running, 1)
    completions[1](1, "", "")
    running = 0
    for _ in pairs(adapter.activeTasks) do running = running + 1 end
    t.equal(running, 0)
end)
