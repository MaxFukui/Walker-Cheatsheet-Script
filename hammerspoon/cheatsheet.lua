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

local function typeRanks(config)
    local ranks = {}
    for key, value in pairs(config.typeOrder or {}) do
        if type(key) == "number" then
            ranks[value] = key
        else
            ranks[key] = value
        end
    end
    return ranks
end

local function utility(kind, text, subText, icons)
    return {
        kind = kind, text = text, subText = subText, source = "",
        searchText = ("utility " .. text):lower(), image = icons.utility,
    }
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

function Controller:buildIndex()
    local records, diagnostics = {}, {}
    local icons = self.config.icons or {}
    local sources = {
        {
            directory = self.root .. "/sheets",
            parse = function(content, source) return core.parseSheet(content, source) end,
            records = core.sheetRecords,
        },
        {
            directory = self.root .. "/prompts",
            parse = function(content, source, path) return core.parsePrompt(content, basename(path), source) end,
            records = function(parsed, source, configuredIcons)
                return { core.promptRecord(parsed, source, configuredIcons) }
            end,
        },
        {
            directory = self.root .. "/links",
            parse = function(content, source) return core.parseLinks(content, source) end,
            records = core.linkRecords,
        },
        {
            directory = self.root .. "/hammerspoon/apps",
            parse = function(content, source) return core.parseApps(content, source) end,
            records = core.appRecords,
        },
    }

    for _, sourceType in ipairs(sources) do
        local files, listError = self.adapter:listRegularFiles(sourceType.directory)
        if not files then
            table.insert(diagnostics, {
                source = sourceType.directory, line = 1,
                message = "required directory unavailable" .. (listError and ": " .. listError or ""),
            })
        else
            for _, path in ipairs(files) do
                local content, readError = self.adapter:readFile(path)
                if content == nil then
                    table.insert(diagnostics, {
                        source = path, line = 1,
                        message = "file is unreadable" .. (readError and ": " .. readError or ""),
                    })
                else
                    local parsed = sourceType.parse(content, path, path)
                    append(diagnostics, parsed.diagnostics)
                    append(records, sourceType.records(parsed, path, icons))
                end
            end
        end
    end

    table.insert(records, utility("bwhash", "BW Hash", "Utility · Copy SHA-256 hash", icons))
    table.insert(records, utility("editsheets", "Edit Sheets", "Utility · Open repository", icons))

    local ranks = typeRanks(self.config)
    table.sort(records, function(left, right)
        local leftRank = ranks[left.kind] or ranks.utility or math.huge
        local rightRank = ranks[right.kind] or ranks.utility or math.huge
        if leftRank ~= rightRank then return leftRank < rightRank end
        if (left.source or "") ~= (right.source or "") then
            return (left.source or "") < (right.source or "")
        end
        return (left.text or "") < (right.text or "")
    end)

    if #diagnostics > 0 then
        for _, item in ipairs(diagnostics) do
            self.adapter:log(string.format("%s:%s: %s", item.source, item.line or 1, item.message))
        end
        table.insert(records, 1, {
            kind = "diagnostic",
            text = "Configuration needs attention",
            subText = string.format("%d diagnostic%s · See Hammerspoon logs", #diagnostics,
                #diagnostics == 1 and "" or "s"),
            source = "", searchText = "diagnostic configuration attention",
            image = icons.diagnostic,
        })
    end

    return { records = records, diagnostics = diagnostics }
end

function Controller:show()
    local result = self:buildIndex()
    self.adapter:showChooser(result.records, function(choice)
        if choice and self.perform then self:perform(choice, self.adapter:modifiers()) end
    end)
end

return M
