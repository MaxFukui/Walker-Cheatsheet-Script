local core = require("core")

local M = {}
local Controller = {}
Controller.__index = Controller

local function basename(path)
    return path:match("([^/]+)$") or path
end

local function append(target, values)
    for _, value in ipairs(values) do table.insert(target, value) end
end

local function utility(kind, text, subText, icons)
    return {
        kind = kind, text = text, subText = subText, source = "",
        searchText = ("utility " .. text):lower(), image = icons[kind],
    }
end

local function action(record)
    record.role = "action"
    return record
end

local function navigation(kind, text, subText, placeholder, children, image)
    return {
        role = "navigation", kind = kind, text = text, subText = subText,
        placeholder = placeholder, children = children, image = image,
        searchText = string.lower(table.concat({ kind, text, subText or "" }, " ")),
    }
end

local function diagnosticNode(count, icons)
    return action({
        kind = "diagnostic", text = "Configuration needs attention",
        subText = string.format("%d diagnostic%s · See Hammerspoon logs", count,
            count == 1 and "" or "s"),
        source = "", searchText = "diagnostic configuration attention",
        image = icons.diagnostic,
    })
end

local function emptyNode(label, icons)
    return {
        role = "empty", kind = "empty", text = "No " .. label .. " found",
        subText = "Add content to the repository", source = "",
        searchText = ("empty no " .. label):lower(), image = icons.empty,
    }
end

function M.hammerspoonAdapter(hsApi)
    local adapter = { configDir = hsApi.configdir, activeTasks = {} }
    local log = hsApi.logger.new("cheatsheet")
    local imageCache = {}
    local chooserCallback
    local chooser = hsApi.chooser.new(function(choice)
        if choice and chooserCallback then chooserCallback(choice._record or choice) end
    end)

    local function nonEmpty(value, fallback)
        return value and value ~= "" and value or fallback
    end

    local function isSubsequence(needle, haystack)
        local position = 1
        for index = 1, #needle do
            position = haystack:find(needle:sub(index, index), position, true)
            if not position then return false end
            position = position + 1
        end
        return true
    end

    local function matchesSearch(record, query)
        local haystack = (record.searchText or ((record.text or "") .. " " .. (record.subText or ""))):lower()
        for token in (query or ""):lower():gmatch("%S+") do
            if not isSubsequence(token, haystack) then return false end
        end
        return true
    end

    function adapter:realpath(path)
        return hsApi.fs.pathToAbsolute(path)
    end

    function adapter:parent(path)
        return path and path:match("^(.*)/[^/]+$")
    end

    function adapter:listRegularFiles(directory)
        local ok, iterator, state = pcall(hsApi.fs.dir, directory)
        if not ok then return nil, iterator end
        local files = {}
        for name in iterator, state do
            if name ~= "." and name ~= ".." then
                local path = directory .. "/" .. name
                if hsApi.fs.attributes(path, "mode") == "file" then
                    table.insert(files, path)
                end
            end
        end
        table.sort(files)
        return files
    end

    function adapter:readFile(path)
        local file, openError = io.open(path, "r")
        if not file then return nil, openError end
        local content = file:read("*a")
        file:close()
        return content
    end

    function adapter:log(message)
        log.e(message)
    end

    function adapter:notify(title, message)
        hsApi.notify.new({ title = title, informativeText = message }):send()
    end

    function adapter:showChooser(records, callback)
        local function rowsFor(query)
            local rows = {}
            for _, record in ipairs(records) do
                if matchesSearch(record, query) then
                    local icon
                    if record.image then
                        if imageCache[record.image] == nil then
                            imageCache[record.image] = hsApi.image.imageFromName(record.image)
                                or hsApi.image.imageFromName("NSAdvanced") or false
                        end
                        icon = imageCache[record.image] or nil
                    end
                    table.insert(rows, {
                        text = record.text,
                        subText = record.subText,
                        image = icon,
                        _record = record,
                    })
                end
            end
            return rows
        end
        chooserCallback = callback
        chooser:queryChangedCallback(function(query)
            chooser:choices(rowsFor(query))
        end)
        -- Setting the field does not invoke queryChangedCallback; reset stale state before repopulating.
        chooser:query("")
        chooser:choices(rowsFor(""))
        chooser:show()
    end

    function adapter:setPasteboard(content)
        local ok = hsApi.pasteboard.setContents(content)
        return ok, ok and nil or "pasteboard rejected content"
    end

    function adapter:openURL(url)
        local ok = hsApi.urlevent.openURL(url)
        return ok, ok and nil or "URL could not be opened"
    end

    function adapter:launchOrFocus(appName)
        local ok = hsApi.application.launchOrFocus(appName)
        return ok, ok and nil or "application could not be launched"
    end

    function adapter:openNewWindow(appName, retryInterval, timeout, callback)
        local launched = hsApi.application.launchOrFocus(appName)
        if not launched then
            callback(false, "application could not be launched")
            return
        end

        local finished = false
        local waitTimer
        local timeoutTimer
        local function finish(ok, detail)
            if finished then return end
            finished = true
            if waitTimer then waitTimer:stop() end
            if timeoutTimer then timeoutTimer:stop() end
            callback(ok, detail)
        end

        waitTimer = hsApi.timer.waitUntil(function()
            return hsApi.application.get(appName) ~= nil
        end, function()
            local app = hsApi.application.get(appName)
            if not app then return finish(false, "application disappeared") end
            hsApi.eventtap.keyStroke({ "cmd" }, "n", 0, app)
            finish(true)
        end, retryInterval)
        timeoutTimer = hsApi.timer.doAfter(timeout, function()
            finish(false, "timed out waiting for " .. appName)
        end)
    end

    function adapter:runHashDialog(callback)
        local ok, input, detail = hsApi.osascript.applescript(
            'display dialog "Enter your Bitwarden passphrase:" default answer "" ' ..
            'with hidden answer with title "Bitwarden"\ntext returned of result'
        )
        if not ok then return callback(false, detail or "dialog cancelled") end
        if input == nil or input == "" then return callback(false, "no input supplied") end

        local task
        task = hsApi.task.new("/usr/bin/shasum", function(exitCode, stdOut, stdErr)
            adapter.activeTasks[task] = nil
            local hash = stdOut and stdOut:match("^(%x+)")
            if exitCode ~= 0 or not hash or #hash ~= 64 then
                return callback(false, nonEmpty(stdErr, "shasum failed"))
            end
            local copied = hsApi.pasteboard.setContents(hash)
            callback(copied, copied and nil or "pasteboard rejected hash")
        end, { "-a", "256" })
        if not task then return callback(false, "shasum task could not be created") end
        task:setInput(input)
        adapter.activeTasks[task] = true
        if not task:start() then
            adapter.activeTasks[task] = nil
            callback(false, "shasum could not start")
        end
    end

    function adapter:editSheets(root, terminal, editor, callback)
        local task
        task = hsApi.task.new("/usr/bin/open", function(exitCode, _, stdErr)
            adapter.activeTasks[task] = nil
            callback(exitCode == 0, exitCode == 0 and nil or nonEmpty(stdErr, "editor launch failed"))
        end, {
            "-na", terminal, "--args", "--working-directory=" .. root,
            "-e", editor, ".",
        })
        if not task then return callback(false, "editor task could not be created") end
        adapter.activeTasks[task] = true
        if not task:start() then
            adapter.activeTasks[task] = nil
            callback(false, "editor launch could not start")
        end
    end

    function adapter:modifiers()
        return hsApi.eventtap.checkKeyboardModifiers()
    end

    local config = require("config")
    chooser:width(config.chooser.width)
    chooser:rows(config.chooser.rows)
    return adapter
end

function M.new(adapter, config)
    assert(adapter, "adapter is required")
    assert(config, "config is required")
    local configPath = adapter:realpath(adapter.configDir)
    return setmetatable({
        adapter = adapter,
        config = config,
        root = adapter:parent(configPath),
    }, Controller)
end

function Controller:buildNavigation()
    local diagnostics = {}
    local icons = self.config.icons or {}
    local home, sheetFiles, prompts, linkFiles, apps = {}, {}, {}, {}, {}

    local function load(directory, consume)
        local affected = {}
        local files, listError = self.adapter:listRegularFiles(directory)
        if not files then
            local item = {
                source = directory, line = 1,
                message = "required directory unavailable" .. (listError and ": " .. listError or ""),
            }
            table.insert(diagnostics, item)
            table.insert(affected, item)
        else
            for _, path in ipairs(files) do
                local content, readError = self.adapter:readFile(path)
                if content == nil then
                    local item = {
                        source = path, line = 1,
                        message = "file is unreadable" .. (readError and ": " .. readError or ""),
                    }
                    table.insert(diagnostics, item)
                    table.insert(affected, item)
                else
                    local parsed = consume(content, path)
                    append(diagnostics, parsed.diagnostics)
                    append(affected, parsed.diagnostics)
                end
            end
        end
        return affected
    end

    local sheetDiagnostics = load(self.root .. "/sheets", function(content, path)
        local parsed = core.parseSheet(content, path)
        local children = core.sheetRecords(parsed, path, icons)
        for index, record in ipairs(children) do children[index] = action(record) end
        if parsed.title and parsed.title ~= "" then
            if #children == 0 then table.insert(children, emptyNode("commands", icons)) end
            table.insert(sheetFiles, navigation("sheet", parsed.title, basename(path),
                "Search " .. parsed.title .. " commands", children, icons.sheet))
        end
        return parsed
    end)
    if #sheetDiagnostics > 0 then table.insert(sheetFiles, 1, diagnosticNode(#sheetDiagnostics, icons)) end
    if #sheetFiles == 0 then table.insert(sheetFiles, emptyNode("cheatsheets", icons)) end

    local promptDiagnostics = load(self.root .. "/prompts", function(content, path)
        local parsed = core.parsePrompt(content, basename(path), path)
        table.insert(prompts, action(core.promptRecord(parsed, path, icons)))
        return parsed
    end)
    if #promptDiagnostics > 0 then table.insert(prompts, 1, diagnosticNode(#promptDiagnostics, icons)) end
    if #prompts == 0 then table.insert(prompts, emptyNode("prompts", icons)) end

    local linkDiagnostics = load(self.root .. "/links", function(content, path)
        local parsed = core.parseLinks(content, path)
        local children = core.linkRecords(parsed, path, icons)
        for index, record in ipairs(children) do children[index] = action(record) end
        if #children == 0 then table.insert(children, emptyNode("links", icons)) end
        local label = parsed.title or basename(path)
        table.insert(linkFiles, navigation("linkfile", label, basename(path),
            "Search " .. label .. " links", children, icons.link))
        return parsed
    end)
    if #linkDiagnostics > 0 then table.insert(linkFiles, 1, diagnosticNode(#linkDiagnostics, icons)) end
    if #linkFiles == 0 then table.insert(linkFiles, emptyNode("link collections", icons)) end

    local appDiagnostics = load(self.root .. "/hammerspoon/apps", function(content, path)
        local parsed = core.parseApps(content, path)
        local records = core.appRecords(parsed, path, icons)
        for _, record in ipairs(records) do table.insert(apps, action(record)) end
        return parsed
    end)

    table.insert(home, navigation("sheets", "Cheatsheets", "Browse command sheets",
        "Choose a cheatsheet", sheetFiles, icons.sheets))
    table.insert(home, navigation("prompts", "Prompts", "Copy a saved prompt",
        "Choose a prompt", prompts, icons.prompts))
    table.insert(home, navigation("links", "Links", "Browse saved links",
        "Choose a link collection", linkFiles, icons.links))
    if #appDiagnostics > 0 then table.insert(home, diagnosticNode(#appDiagnostics, icons)) end
    append(home, apps)
    table.insert(home, action(utility("bwhash", "BW Hash", "Utility · Copy SHA-256 hash", icons)))
    table.insert(home, action(utility("editsheets", "Edit Sheets", "Utility · Open repository", icons)))

    for _, item in ipairs(diagnostics) do
        self.adapter:log(string.format("%s:%s: %s", item.source, item.line or 1, item.message))
    end
    return { home = home, diagnostics = diagnostics }
end

function Controller:buildIndex()
    local tree = self:buildNavigation()
    local records = {}
    local function flatten(nodes)
        for _, node in ipairs(nodes) do
            if node.role == "navigation" then
                flatten(node.children or {})
            elseif node.role == "action" and node.kind ~= "diagnostic" then
                table.insert(records, node)
            end
        end
    end
    flatten(tree.home)
    if #tree.diagnostics > 0 then
        table.insert(records, 1, diagnosticNode(#tree.diagnostics, self.config.icons or {}))
    end
    return { records = records, diagnostics = tree.diagnostics }
end

function Controller:show()
    local result = self:buildIndex()
    self.adapter:showChooser(result.records, function(choice)
        if choice and self.perform then self:perform(choice, self.adapter:modifiers()) end
    end)
end

function Controller:reportFailure(action, detail)
    local message = action .. " failed"
    if detail and detail ~= "" then message = message .. ": " .. tostring(detail) end
    self.adapter:log(message)
    self.adapter:notify("Cheatsheet Error", message)
    return false
end

function Controller:perform(record, modifiers)
    -- true means the action was accepted/dispatched; asynchronous completion is reported by its callback.
    modifiers = modifiers or {}
    if not record or not record.kind then
        return self:reportFailure("Action", "invalid record")
    end

    local kind = record.kind
    if kind == "command" or kind == "prompt" then
        local ok, detail = self.adapter:setPasteboard(record.payload)
        if not ok then return self:reportFailure("Copy " .. (record.text or kind), detail) end
        self.adapter:notify("Cheatsheet", "Copied " .. (record.text or kind))
        return true
    elseif kind == "note" then
        self.adapter:notify("Cheatsheet", record.text or "Note")
        return true
    elseif kind == "link" then
        local ok, detail = self.adapter:openURL(record.payload)
        if not ok then return self:reportFailure("Open " .. (record.text or "link"), detail) end
        self.adapter:notify("Cheatsheet", "Opened " .. (record.text or "link"))
        return true
    elseif kind == "app" then
        local payload = record.payload or {}
        if modifiers.cmd or payload.mode == "focus" then
            local ok, detail = self.adapter:launchOrFocus(payload.app)
            if not ok then return self:reportFailure("Focus " .. (record.text or "app"), detail) end
            self.adapter:notify("Cheatsheet", "Focused " .. (record.text or "app"))
            return true
        elseif payload.mode == "new" then
            self.adapter:openNewWindow(
                payload.app,
                self.config.newWindow.retryInterval,
                self.config.newWindow.timeout,
                function(ok, detail)
                    if ok then
                        self.adapter:notify("Cheatsheet", "Opened new " .. (record.text or "window"))
                    else
                        self:reportFailure("Open new " .. (record.text or "window"), detail)
                    end
                end
            )
            return true
        end
        return self:reportFailure("Open " .. (record.text or "app"), "unsupported mode")
    elseif kind == "bwhash" then
        self.adapter:runHashDialog(function(ok, detail)
            if ok then
                self.adapter:notify("Cheatsheet", "Hash copied")
            else
                self:reportFailure("BW Hash", detail)
            end
        end)
        return true
    elseif kind == "editsheets" then
        self.adapter:editSheets(self.root, self.config.terminal, self.config.editor, function(ok, detail)
            if ok then
                self.adapter:notify("Cheatsheet", "Opened sheets")
            else
                self:reportFailure("Edit Sheets", detail)
            end
        end)
        return true
    elseif kind == "diagnostic" then
        self.adapter:notify("Cheatsheet", "See Hammerspoon logs for details")
        return true
    end

    return self:reportFailure("Action", "unsupported kind " .. tostring(kind))
end

local defaultController

local function default()
    if not defaultController then
        local hsApi = assert(rawget(_G, "hs"), "global hs is required")
        defaultController = M.new(M.hammerspoonAdapter(hsApi), require("config"))
    end
    return defaultController
end

function M.show()
    return default():show()
end

function M.validate()
    return default():buildIndex()
end

return M
