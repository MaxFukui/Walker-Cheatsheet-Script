local t = require("test_helper")
local cheatsheet = require("cheatsheet")
local config = require("config")

local Fake = {}
Fake.__index = Fake

function Fake.new(options)
    options = options or {}
    return setmetatable({
        configDir = options.configDir or "/repo/hammerspoon",
        files = options.files or {}, missing = options.missing or {}, unreadable = options.unreadable or {},
        logs = {}, chooserCalls = {},
    }, Fake)
end

function Fake:realpath(path)
    return path
end

function Fake:parent(path)
    self.requestedRoot = path:match("^(.*)/[^/]+$")
    return self.requestedRoot
end

function Fake:listRegularFiles(directory)
    if self.missing[directory] then return nil, "directory is missing" end
    local result = {}
    for path in pairs(self.files) do
        if path:match("^(.*)/[^/]+$") == directory then table.insert(result, path) end
    end
    table.sort(result)
    return result
end

function Fake:readFile(path)
    if self.unreadable[path] then return nil, "permission denied" end
    return self.files[path]
end

function Fake:log(message)
    table.insert(self.logs, message)
end

function Fake:showChooser(records, callback)
    table.insert(self.chooserCalls, { records = records, callback = callback })
end

t.test("controller derives adjacent shared directories and indexes regular files", function()
    local fake = Fake.new({
        configDir = "/repo/hammerspoon",
        files = {
            ["/repo/sheets/git.md"] = "# Git\nStatus | git status\n",
            ["/repo/prompts/dev.md"] = "# Developer\nBody",
            ["/repo/links/general.md"] = "GitHub | https://github.com",
            ["/repo/hammerspoon/apps/general.md"] = "Firefox | Firefox",
        },
    })
    local result = cheatsheet.new(fake, config):buildIndex()
    t.equal(#result.records, 6)
    t.equal(fake.requestedRoot, "/repo")
    t.equal(result.records[1].kind, "command")
    t.equal(result.records[6].kind, "editsheets")
end)

t.test("missing required directory becomes a diagnostic record", function()
    local fake = Fake.new({ configDir = "/repo/hammerspoon", missing = { ["/repo/sheets"] = true } })
    local result = cheatsheet.new(fake, config):buildIndex()
    t.truthy(#result.diagnostics > 0)
    t.equal(result.records[1].kind, "diagnostic")
    t.equal(result.records[1].text, "Configuration needs attention")
    t.truthy(result.records[1].subText:find("1", 1, true))
    t.truthy(fake.logs[1]:find("/repo/sheets", 1, true))
end)

t.test("unreadable files are diagnosed with their source", function()
    local path = "/repo/prompts/private.md"
    local fake = Fake.new({ files = { [path] = "secret" }, unreadable = { [path] = true } })
    local result = cheatsheet.new(fake, config):buildIndex()
    t.equal(#result.diagnostics, 1)
    t.equal(result.diagnostics[1].source, path)
    t.truthy(fake.logs[1]:find(":1:", 1, true))
end)

t.test("show rebuilds and presents the unified index", function()
    local fake = Fake.new({ files = { ["/repo/prompts/dev.md"] = "# Developer\nBody" } })
    local controller = cheatsheet.new(fake, config)
    controller:show()
    t.equal(#fake.chooserCalls, 1)
    t.equal(#fake.chooserCalls[1].records, 3)
end)
