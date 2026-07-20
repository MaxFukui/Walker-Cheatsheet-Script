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
        failures = options.failures or {}, logs = {}, chooserCalls = {}, notifications = {},
        untargetedKeystrokes = 0,
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

function Fake:setPasteboard(value)
    if self.failures.setPasteboard then return false, "pasteboard unavailable" end
    self.clipboard = value
    return true
end

function Fake:notify(title, text)
    table.insert(self.notifications, { title = title, text = text })
end

function Fake:openURL(url)
    self.openedURL = url
    if self.failures.openURL then return false, "URL rejected" end
    return true
end

function Fake:launchOrFocus(appName)
    self.focusTarget = appName
    if self.failures.launchOrFocus then return false, "application unavailable" end
    return true
end

function Fake:openNewWindow(appName, retryInterval, timeout, callback)
    self.newWindowTarget = appName
    self.newWindowRetryInterval = retryInterval
    self.newWindowTimeout = timeout
    if self.failures.openNewWindow then
        callback(false, "application unavailable")
    else
        callback(true)
    end
end

function Fake:runHashDialog(callback)
    self.hashDialogOpened = true
    if self.failures.runHashDialog then callback(false, "hash task failed") else callback(true) end
end

function Fake:editSheets(root, terminal, editor, callback)
    self.editRequest = { root = root, terminal = terminal, editor = editor }
    if self.failures.editSheets then callback(false, "editor task failed") else callback(true) end
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

t.test("commands and prompts copy without exposing content", function()
    local fake = Fake.new({})
    local controller = cheatsheet.new(fake, config)
    controller:perform({ kind = "command", text = "Status", payload = "git status" }, {})
    t.equal(fake.clipboard, "git status")
    t.equal(fake.notifications[1].text, "Copied Status")
    t.equal(fake.notifications[1].text:find("git status", 1, true), nil)

    controller:perform({ kind = "prompt", text = "Secret", payload = "private body" }, {})
    t.equal(fake.clipboard, "private body")
    t.equal(fake.notifications[2].text, "Copied Secret")
    t.equal(fake.notifications[2].text:find("private body", 1, true), nil)
end)

t.test("links use the default browser", function()
    local fake = Fake.new({})
    cheatsheet.new(fake, config):perform(
        { kind = "link", text = "GitHub", payload = "https://github.com" }, {}
    )
    t.equal(fake.openedURL, "https://github.com")
    t.equal(fake.requestedBrowser, nil)
end)

t.test("app enter opens targeted new window and cmd enter focuses", function()
    local fake = Fake.new({})
    local controller = cheatsheet.new(fake, config)
    local app = { kind = "app", text = "Firefox", payload = { app = "Firefox", mode = "new" } }
    controller:perform(app, {})
    t.equal(fake.newWindowTarget, "Firefox")
    t.equal(fake.newWindowRetryInterval, config.newWindow.retryInterval)
    t.equal(fake.newWindowTimeout, config.newWindow.timeout)
    controller:perform(app, { cmd = true })
    t.equal(fake.focusTarget, "Firefox")
    t.equal(fake.untargetedKeystrokes, 0)
end)

t.test("app focus mode does not request a new window", function()
    local fake = Fake.new({})
    cheatsheet.new(fake, config):perform(
        { kind = "app", text = "Mail", payload = { app = "Mail", mode = "focus" } }, {}
    )
    t.equal(fake.focusTarget, "Mail")
    t.equal(fake.newWindowTarget, nil)
end)

t.test("notes diagnostics and utilities route through adapters", function()
    local fake = Fake.new({})
    local controller = cheatsheet.new(fake, config)
    controller:perform({ kind = "note", text = "Remember this", payload = "Remember this" }, {})
    controller:perform({ kind = "diagnostic", text = "Configuration needs attention" }, {})
    controller:perform({ kind = "bwhash", text = "BW Hash" }, {})
    controller:perform({ kind = "editsheets", text = "Edit Sheets" }, {})
    t.equal(fake.notifications[1].text, "Remember this")
    t.equal(fake.notifications[2].text, "See Hammerspoon logs for details")
    t.truthy(fake.hashDialogOpened)
    t.equal(fake.editRequest.root, "/repo")
    t.equal(fake.editRequest.terminal, config.terminal)
    t.equal(fake.editRequest.editor, config.editor)
end)

t.test("failed actions report failure rather than success", function()
    local fake = Fake.new({ failures = { openURL = true } })
    local result = cheatsheet.new(fake, config):perform(
        { kind = "link", text = "Bad", payload = "bad://url" }, {}
    )
    t.equal(result, false)
    t.equal(fake.notifications[1].title, "Cheatsheet Error")
    t.truthy(fake.logs[1]:find("URL rejected", 1, true))
end)

t.test("callback failures are reported without a success notification", function()
    local fake = Fake.new({ failures = { openNewWindow = true } })
    local result = cheatsheet.new(fake, config):perform(
        { kind = "app", text = "Missing", payload = { app = "Missing", mode = "new" } }, {}
    )
    t.equal(result, true)
    t.equal(#fake.notifications, 1)
    t.equal(fake.notifications[1].title, "Cheatsheet Error")
    t.equal(fake.untargetedKeystrokes, 0)
end)
