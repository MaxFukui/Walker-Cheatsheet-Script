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
        failures = options.failures or {}, logs = {}, screens = {}, notifications = {},
        untargetedKeystrokes = 0,
    }, Fake)
end

function Fake.completeRepository()
    return Fake.new({
        files = {
            ["/repo/sheets/docker.md"] = "# Docker\nList | docker ps\n",
            ["/repo/sheets/git.md"] = "# Git\n## Branches\nCreate | git switch -c <name>\n",
            ["/repo/prompts/dev.md"] = "# Developer\nBody",
            ["/repo/links/general.md"] = "# Quick Links\nGitHub | https://github.com\n",
            ["/repo/links/work.md"] = "# Work\nDocs | https://example.com/docs\n",
            ["/repo/hammerspoon/apps/general.md"] = "Firefox | Firefox\n",
        },
    })
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

function Fake:showChooser(screen, callback)
    table.insert(self.screens, {
        records = screen.records, placeholder = screen.placeholder, callback = callback,
    })
end

function Fake:modifiers()
    return self.currentModifiers or {}
end

function Fake.findHome(fake, kind)
    for _, record in ipairs(fake.screens[1].records) do
        if record.kind == kind then return record end
    end
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
    self.hashDialogCalls = (self.hashDialogCalls or 0) + 1
    self.hashDialogOpened = true
    if self.failures.runHashDialog then callback(false, "hash task failed") else callback(true) end
end

function Fake:editSheets(root, terminal, editor, callback)
    self.editRequest = { root = root, terminal = terminal, editor = editor }
    if self.failures.editSheets then callback(false, "editor task failed") else callback(true) end
end

t.test("home keeps categories first and apps utilities immediate", function()
    local fake = Fake.completeRepository()
    local tree = cheatsheet.new(fake, config):buildNavigation()
    t.equal(tree.home[1].text, "Cheatsheets")
    t.equal(tree.home[2].text, "Prompts")
    t.equal(tree.home[3].text, "Links")
    t.equal(tree.home[4].kind, "app")
    t.equal(tree.home[#tree.home - 1].kind, "bwhash")
    t.equal(tree.home[#tree.home].kind, "editsheets")
end)

t.test("edit utility uses the verified compose system image", function()
    t.equal(config.icons.editsheets, "NSTouchBarComposeTemplate")
end)

t.test("cheatsheets and links drill through source files", function()
    local tree = cheatsheet.new(Fake.completeRepository(), config):buildNavigation()
    local sheets = tree.home[1]
    t.equal(#sheets.children, 2)
    t.equal(sheets.children[1].role, "navigation")
    t.equal(sheets.children[1].text, "Docker")
    t.equal(sheets.children[1].children[1].kind, "command")
    t.equal(sheets.children[1].children[1].payload, "docker ps")
    t.equal(sheets.children[2].text, "Git")
    t.equal(sheets.children[2].children[1].payload, "git switch -c <name>")
    local links = tree.home[3]
    t.equal(#links.children, 2)
    t.equal(links.children[1].text, "Quick Links")
    t.equal(links.children[1].children[1].kind, "link")
    t.equal(links.children[1].children[1].payload, "https://github.com")
    t.equal(links.children[2].text, "Work")
    t.equal(links.children[2].children[1].payload, "https://example.com/docs")
end)

t.test("prompts are direct child actions", function()
    local tree = cheatsheet.new(Fake.completeRepository(), config):buildNavigation()
    t.equal(tree.home[2].children[1].kind, "prompt")
    t.equal(tree.home[2].children[1].role, "action")
end)

t.test("link collection falls back to its basename without a heading", function()
    local fake = Fake.new({ files = {
        ["/repo/links/general.md"] = "GitHub | https://github.com\n",
    } })
    local tree = cheatsheet.new(fake, config):buildNavigation()
    t.equal(tree.home[3].children[1].text, "general.md")
end)

t.test("category diagnostics stay with sheets prompts and links", function()
    local promptPath = "/repo/prompts/private.md"
    local fake = Fake.new({
        files = {
            ["/repo/sheets/broken.md"] = "# Broken\nnot a record\n",
            [promptPath] = "# Private\nBody",
            ["/repo/links/broken.md"] = "# Broken\nnot a link\n",
        },
        unreadable = { [promptPath] = true },
    })
    local tree = cheatsheet.new(fake, config):buildNavigation()
    t.equal(tree.home[1].kind, "sheets")
    t.equal(tree.home[1].children[1].kind, "diagnostic")
    t.equal(tree.home[2].kind, "prompts")
    t.equal(tree.home[2].children[1].kind, "diagnostic")
    t.equal(tree.home[3].kind, "links")
    t.equal(tree.home[3].children[1].kind, "diagnostic")
end)

t.test("app diagnostics are prepended to home without changing relative home order", function()
    local fake = Fake.new({ files = {
        ["/repo/hammerspoon/apps/general.md"] =
            "Broken | App | invalid\nFirefox | Firefox\n",
    } })
    local home = cheatsheet.new(fake, config):buildNavigation().home
    t.equal(home[1].kind, "diagnostic")
    t.equal(home[2].kind, "sheets")
    t.equal(home[3].kind, "prompts")
    t.equal(home[4].kind, "links")
    t.equal(home[5].kind, "app")
    t.equal(home[#home - 1].kind, "bwhash")
    t.equal(home[#home].kind, "editsheets")
end)

t.test("empty repositories expose non-actionable category empty states", function()
    local tree = cheatsheet.new(Fake.new(), config):buildNavigation()
    for index = 1, 3 do
        local empty = tree.home[index].children[1]
        t.equal(empty.kind, "empty")
        t.equal(empty.role, "empty")
    end
end)

t.test("valid empty files expose non-actionable leaf empty states", function()
    local fake = Fake.new({ files = {
        ["/repo/sheets/empty.md"] = "# Empty\n",
        ["/repo/links/empty.md"] = "# Empty Links\n",
    } })
    local tree = cheatsheet.new(fake, config):buildNavigation()
    t.equal(tree.home[1].children[1].children[1].kind, "empty")
    t.equal(tree.home[1].children[1].children[1].role, "empty")
    t.equal(tree.home[3].children[1].children[1].kind, "empty")
    t.equal(tree.home[3].children[1].children[1].role, "empty")
end)

t.test("buildIndex excludes navigation and empty nodes while aggregating diagnostics", function()
    local fake = Fake.new({ missing = { ["/repo/sheets"] = true } })
    local result = cheatsheet.new(fake, config):buildIndex()
    t.equal(#result.diagnostics, 1)
    t.equal(#result.records, 3)
    t.equal(result.records[1].kind, "diagnostic")
    t.equal(result.records[2].kind, "bwhash")
    t.equal(result.records[3].kind, "editsheets")
    for _, record in ipairs(result.records) do
        t.truthy(record.role ~= "navigation")
        t.truthy(record.kind ~= "empty")
    end
end)

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

t.test("show opens home and navigation selections replace the screen", function()
    local fake = Fake.completeRepository()
    local controller = cheatsheet.new(fake, config)
    controller:show()
    t.equal(fake.screens[1].placeholder, "Cheatsheet")
    controller:select(fake.screens[1].records[1], {})
    t.equal(fake.screens[2].placeholder, "Choose a cheatsheet")
    controller:select(fake.screens[2].records[2], {})
    t.truthy(fake.screens[3].placeholder:match("Search .+ commands"))
end)

t.test("back returns one level and global show resets home", function()
    local fake = Fake.completeRepository()
    local controller = cheatsheet.new(fake, config)
    controller:show()
    controller:select(fake.screens[1].records[1], {})
    controller:select(fake.screens[2].records[2], {})
    controller:select(fake.screens[3].records[1], {})
    t.equal(fake.screens[4].placeholder, "Choose a cheatsheet")
    controller:show()
    t.equal(fake.screens[5].placeholder, "Cheatsheet")
    t.equal(#controller.navigationStack, 0)
end)

t.test("home app and utility records perform immediately", function()
    local fake = Fake.completeRepository()
    local controller = cheatsheet.new(fake, config)
    controller:show()
    controller:select(Fake.findHome(fake, "app"), { cmd = true })
    t.equal(fake.focusTarget, "Firefox")
    controller:select(Fake.findHome(fake, "bwhash"), {})
    t.equal(fake.hashDialogCalls, 1)
end)

t.test("show rebuilds and presents home", function()
    local fake = Fake.new({ files = { ["/repo/prompts/dev.md"] = "# Developer\nBody" } })
    local controller = cheatsheet.new(fake, config)
    controller:show()
    t.equal(#fake.screens, 1)
    t.equal(#fake.screens[1].records, 5)
end)

t.test("title-less sheets are diagnosed and skipped without crashing index build", function()
    local fake = Fake.new({ files = { ["/repo/sheets/broken.md"] = "Status | git status\n" } })
    local ok, result = pcall(function() return cheatsheet.new(fake, config):buildIndex() end)
    t.truthy(ok)
    t.equal(#result.diagnostics, 1)
    t.equal(result.records[1].kind, "diagnostic")
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
