local M = {}

local function trim(value)
    return (value or ""):match("^%s*(.-)%s*$")
end

local function lines(content)
    local result = {}
    content = (content or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in (content .. "\n"):gmatch("(.-)\n") do
        table.insert(result, line)
    end
    return result
end

local function diagnostic(target, source, line, message)
    table.insert(target, { source = source, line = line, message = message })
end

local function firstHeader(content)
    for _, line in ipairs(lines(content)) do
        local title = trim(line):match("^#+%s+(.+)$")
        if title then return trim(title) end
    end
end

function M.parseSheet(content, source)
    local result = { title = firstHeader(content), entries = {}, diagnostics = {} }
    local section
    for number, line in ipairs(lines(content)) do
        local trimmed = trim(line)
        local hashes, heading = trimmed:match("^(#+)%s+(.+)$")
        if hashes then
            if #hashes >= 2 then section = trim(heading) end
        elseif trimmed ~= "" then
            local note = trimmed:match("^~%s*(.*)$")
            local separator = trimmed:find("|", 1, true)
            if note then
                note = trim(note)
                if note ~= "" then
                    table.insert(result.entries, { kind = "note", text = note, section = section })
                else
                    diagnostic(result.diagnostics, source, number, "note requires text")
                end
            elseif separator then
                local description = trim(trimmed:sub(1, separator - 1))
                local value = trim(trimmed:sub(separator + 1))
                if description ~= "" and value ~= "" then
                    table.insert(result.entries, {
                        kind = "command", description = description, value = value, section = section,
                    })
                else
                    diagnostic(result.diagnostics, source, number, "sheet record requires description and value")
                end
            else
                diagnostic(result.diagnostics, source, number, "unrecognized sheet record")
            end
        end
    end
    if not result.title then diagnostic(result.diagnostics, source, 1, "sheet requires a heading") end
    return result
end

function M.parsePrompt(content, filename, source)
    return { title = firstHeader(content) or filename, content = content, diagnostics = {} }
end

local function splitPipe(line)
    local parts, start = {}, 1
    while true do
        local separator = line:find("|", start, true)
        if not separator then
            table.insert(parts, trim(line:sub(start)))
            return parts
        end
        table.insert(parts, trim(line:sub(start, separator - 1)))
        start = separator + 1
    end
end

local function parseDelimited(content, source, consume)
    local result = { entries = {}, diagnostics = {} }
    for number, line in ipairs(lines(content)) do
        local trimmed = trim(line)
        if trimmed ~= "" and not trimmed:match("^#") then
            local parts = splitPipe(trimmed)
            local entry, message = consume(parts)
            if entry then
                table.insert(result.entries, entry)
            else
                diagnostic(result.diagnostics, source, number, message)
            end
        end
    end
    return result
end

function M.parseLinks(content, source)
    local result = parseDelimited(content, source, function(parts)
        if #parts ~= 2 or parts[1] == "" or parts[2] == "" then
            return nil, "link record requires name and URL"
        end
        return { kind = "link", name = parts[1], url = parts[2] }
    end)
    result.title = firstHeader(content)
    return result
end

function M.parseApps(content, source)
    return parseDelimited(content, source, function(parts)
        local mode = parts[3] and parts[3] ~= "" and parts[3] or "new"
        if (#parts ~= 2 and #parts ~= 3) or parts[1] == "" or parts[2] == "" then
            return nil, "app record requires name and application"
        end
        if mode ~= "new" and mode ~= "focus" then
            return nil, "app mode must be new or focus"
        end
        return { kind = "app", name = parts[1], app = parts[2], mode = mode }
    end)
end

local function joined(...)
    local values = {}
    for _, value in ipairs({ ... }) do
        if value and value ~= "" then table.insert(values, value:lower()) end
    end
    return table.concat(values, " ")
end

local function record(kind, text, subText, payload, source, searchText, icons)
    return {
        kind = kind, text = text, subText = subText, payload = payload,
        source = source, searchText = searchText, image = icons[kind],
    }
end

function M.sheetRecords(parsed, source, icons)
    local records = {}
    if not parsed.title or parsed.title == "" then return records end
    for _, entry in ipairs(parsed.entries) do
        local location = parsed.title .. (entry.section and " › " .. entry.section or "")
        if entry.kind == "command" then
            table.insert(records, record("command", entry.description,
                location .. " · Copy command", entry.value, source,
                joined(parsed.title, entry.section, entry.description, entry.value, "command"), icons))
        else
            table.insert(records, record("note", entry.text,
                location .. " · Show note", entry.text, source,
                joined(parsed.title, entry.section, entry.text, "note"), icons))
        end
    end
    return records
end

function M.promptRecord(parsed, source, icons)
    return record("prompt", parsed.title, "Prompt · Copy full content",
        parsed.content, source, joined("prompt", parsed.title, source), icons)
end

function M.linkRecords(parsed, source, icons)
    local records = {}
    for _, entry in ipairs(parsed.entries) do
        table.insert(records, record("link", entry.name, "Link · Open in default browser",
            entry.url, source, joined("link", entry.name, entry.url), icons))
    end
    return records
end

function M.appRecords(parsed, source, icons)
    local records = {}
    for _, entry in ipairs(parsed.entries) do
        local action = entry.mode == "new" and "Open new window · ⌘↵ Focus" or "Focus"
        table.insert(records, record("app", entry.name, "App · " .. action,
            entry, source, joined("app", entry.name, entry.app, entry.mode), icons))
    end
    return records
end

return M
