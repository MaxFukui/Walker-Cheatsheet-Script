-- Universal Cheatsheet System (Hammerspoon port of cheatsheet.sh)
-- Two-level hs.chooser menu for sheets, prompts, links, apps and a BW hash helper.

local M = {}

local repoRoot = os.getenv("HOME") .. "/Development/Walker-Cheatsheet-Script"
local SHEETS_DIR = repoRoot .. "/sheets"
local PROMPTS_DIR = repoRoot .. "/prompts"
local LINKS_DIR = repoRoot .. "/links"
local APPS_DIR = repoRoot .. "/hammerspoon/apps"

-- hs.chooser only accepts its completion callback at construction time, so we
-- keep one chooser instance and redirect through this upvalue per menu shown.
local currentHandler = nil
local chooser = hs.chooser.new(function(choice)
    if choice and currentHandler then currentHandler(choice) end
end)
chooser:width(30)
chooser:rows(9)

local function notify(title, text)
    hs.notify.new({ title = title, informativeText = text }):send()
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Reads every regular file in dir matching an optional suffix ("*.md" -> ".md", nil -> any file)
local function filesIn(dir, suffix)
    local files = {}
    local ok, iter, dirObj = pcall(hs.fs.dir, dir)
    if not ok then return files end
    for name in iter, dirObj do
        if name ~= "." and name ~= ".." then
            if not suffix or name:sub(-#suffix) == suffix then
                table.insert(files, dir .. "/" .. name)
            end
        end
    end
    table.sort(files)
    return files
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

-- First markdown header ("# Title") in a file, header text only.
local function getHeader(path)
    local content = readFile(path)
    if not content then return nil end
    for line in content:gmatch("[^\r\n]+") do
        local header = line:match("^#+%s*(.+)$")
        if header then return trim(header) end
    end
    return nil
end

local function basename(path)
    return path:match("([^/]+)$")
end

local function show(choices, placeholder, callback)
    currentHandler = callback
    chooser:choices(choices)
    chooser:placeholderText(placeholder)
    chooser:show()
end

-- ===== Sheets =====

local function listSheetCategories()
    local rows = {}
    for _, file in ipairs(filesIn(SHEETS_DIR, ".md")) do
        local header = getHeader(file)
        if header then
            table.insert(rows, { text = header, file = file })
        end
    end
    return rows
end

-- Parses a sheet body into chooser rows (mirrors parse_cheatsheet() in cheatsheet.sh)
local function parseSheet(path)
    local content = readFile(path)
    if not content then return {} end
    local rows = {}
    for line in content:gmatch("[^\r\n]+") do
        if trim(line) == "" or line:match("^#") then
            -- skip blank lines and headers
        elseif line:match("^~") then
            local note = trim(line:gsub("^~%s*", ""))
            if note ~= "" then
                table.insert(rows, { text = "\xE2\x84\xB9 " .. note, info = true })
            end
        else
            local idx = line:find("|", 1, true)
            if idx then
                local description = trim(line:sub(1, idx - 1))
                local command = trim(line:sub(idx + 1))
                if description ~= "" and command ~= "" then
                    table.insert(rows, {
                        text = string.format("%-30s \xE2\x86\x92 %s", description, command),
                        value = command,
                    })
                end
            end
        end
    end
    return rows
end

local function showSheet(path)
    show(parseSheet(path), "Cheatsheet", function(choice)
        if choice.info then
            notify("Cheatsheet", choice.text:gsub("^\xE2\x84\xB9 ", ""))
        elseif choice.value then
            hs.pasteboard.setContents(choice.value)
            notify("Cheatsheet", "Copied: " .. choice.value)
        end
    end)
end

-- ===== Prompts =====

local function listPrompts()
    local rows = {}
    for _, file in ipairs(filesIn(PROMPTS_DIR)) do
        local header = getHeader(file) or basename(file)
        table.insert(rows, { text = header, file = file })
    end
    return rows
end

local function showPrompts()
    show(listPrompts(), "Prompts", function(choice)
        local content = readFile(choice.file)
        if content and content ~= "" then
            hs.pasteboard.setContents(content)
            notify("Prompts", "Copied: " .. choice.text)
        end
    end)
end

-- ===== Links =====

-- Parses "Name | URL" lines from every links/*.md file
local function listLinks()
    local rows = {}
    for _, file in ipairs(filesIn(LINKS_DIR, ".md")) do
        local content = readFile(file)
        if content then
            for line in content:gmatch("[^\r\n]+") do
                if trim(line) ~= "" and not line:match("^#") then
                    local idx = line:find("|", 1, true)
                    if idx then
                        local name = trim(line:sub(1, idx - 1))
                        local url = trim(line:sub(idx + 1))
                        if name ~= "" and url ~= "" then
                            table.insert(rows, { text = name, url = url })
                        end
                    end
                end
            end
        end
    end
    return rows
end

local function showLinks()
    show(listLinks(), "Links", function(choice)
        hs.task.new("/usr/bin/open", nil, { "-a", "Firefox", choice.url }):start()
        notify("Links", "Opening: " .. choice.text)
    end)
end

-- ===== Apps =====

-- Parses "Name | AppName | mode" lines from every apps/*.md file. mode: "new" or "focus" (default).
local function listApps()
    local rows = {}
    for _, file in ipairs(filesIn(APPS_DIR, ".md")) do
        local content = readFile(file)
        if content then
            for line in content:gmatch("[^\r\n]+") do
                if trim(line) ~= "" and not line:match("^#") then
                    local parts = {}
                    for part in line:gmatch("[^|]+") do
                        table.insert(parts, trim(part))
                    end
                    if parts[1] and parts[2] then
                        table.insert(rows, { text = parts[1], app = parts[2], mode = parts[3] or "focus" })
                    end
                end
            end
        end
    end
    return rows
end

local function showApps()
    show(listApps(), "Apps", function(choice)
        hs.application.launchOrFocus(choice.app)
        if choice.mode == "new" then
            -- Give the app a moment to become frontmost before sending Cmd+N,
            -- which is how most Mac apps open a genuinely new window.
            hs.timer.doAfter(0.4, function()
                hs.eventtap.keyStroke({ "cmd" }, "n")
            end)
        end
        notify("Apps", "Opening: " .. choice.text)
    end)
end

-- ===== BW Hash =====

local function handleBwHash()
    -- hs.osascript.applescript doesn't expose "display dialog"'s result record as a
    -- plain enumerable Lua table, so pull the field out in AppleScript itself and
    -- return it directly as a string.
    local ok, passphrase = hs.osascript.applescript(
        'display dialog "Enter your Bitwarden passphrase:" default answer "" ' ..
        'with hidden answer with title "Bitwarden"\n' ..
        'text returned of result'
    )
    if not ok or not passphrase or passphrase == "" then return end

    local task = hs.task.new("/usr/bin/shasum", function(exitCode, stdOut, _)
        local hash = stdOut and stdOut:match("^(%x+)")
        if exitCode == 0 and hash then
            hs.pasteboard.setContents(hash)
            notify("Bitwarden", "Hash copied to clipboard!")
        else
            notify("Bitwarden", "Failed to generate hash")
        end
    end, { "-a", "256" })
    task:setInput(passphrase)
    task:start()
end

-- ===== Edit Sheets =====

local function handleEditSheets()
    hs.task.new("/usr/bin/open", nil, {
        "-na", "Ghostty",
        "--args", "--working-directory=" .. repoRoot, "-e", "nvim", ".",
    }):start()
end

-- ===== Top-level menu =====

local function topChoices()
    local rows = {
        { text = "Prompts", action = "prompts" },
        { text = "Links", action = "links" },
        { text = "Apps", action = "apps" },
        { text = "BW Hash", action = "bwhash" },
        { text = "Edit Sheets", action = "editsheets" },
    }
    for _, row in ipairs(listSheetCategories()) do
        row.action = "sheet"
        table.insert(rows, row)
    end
    return rows
end

function M.show()
    show(topChoices(), "Select", function(choice)
        if choice.action == "prompts" then
            showPrompts()
        elseif choice.action == "links" then
            showLinks()
        elseif choice.action == "apps" then
            showApps()
        elseif choice.action == "bwhash" then
            handleBwHash()
        elseif choice.action == "editsheets" then
            handleEditSheets()
        elseif choice.action == "sheet" then
            showSheet(choice.file)
        end
    end)
end

return M
