local t = require("test_helper")
local core = require("core")

t.test("sheet preserves pipes and section metadata", function()
    local parsed = core.parseSheet(
        "# Git\r\n## Branches\r\nFilter log | git log | grep fix\r\n~ Be careful\r\n",
        "sheets/git.md"
    )
    t.equal(parsed.title, "Git")
    t.equal(parsed.entries[1].description, "Filter log")
    t.equal(parsed.entries[1].value, "git log | grep fix")
    t.equal(parsed.entries[1].section, "Branches")
    t.equal(parsed.entries[2].kind, "note")
end)

t.test("malformed sheet row reports its source line", function()
    local parsed = core.parseSheet("# Git\nnot a record\n", "sheets/git.md")
    t.equal(#parsed.diagnostics, 1)
    t.equal(parsed.diagnostics[1].line, 2)
end)

t.test("prompt title falls back to filename", function()
    local parsed = core.parsePrompt("plain text", "plain.txt", "prompts/plain.txt")
    t.equal(parsed.title, "plain.txt")
    t.equal(parsed.content, "plain text")
end)

t.test("links reject malformed records", function()
    local parsed = core.parseLinks("# Links\nGitHub | https://github.com\nbroken\n", "links/general.md")
    t.equal(parsed.entries[1].name, "GitHub")
    t.equal(parsed.entries[1].url, "https://github.com")
    t.equal(parsed.diagnostics[1].line, 3)
end)

t.test("apps default to new and reject unknown modes", function()
    local parsed = core.parseApps(
        "# Apps\nFirefox | Firefox\nMail | Mail | focus\nBad | Bad | other\n",
        "hammerspoon/apps/general.md"
    )
    t.equal(parsed.entries[1].mode, "new")
    t.equal(parsed.entries[2].mode, "focus")
    t.equal(#parsed.entries, 2)
    t.equal(parsed.diagnostics[1].line, 4)
end)

t.test("indented headings and comments are recognized by every parser", function()
    local sheet = core.parseSheet("  # Git\n  ## Branches\n  Status | git status\n", "sheet")
    t.equal(sheet.title, "Git")
    t.equal(sheet.entries[1].section, "Branches")
    local prompt = core.parsePrompt("  # Developer\nBody", "dev.md", "prompt")
    t.equal(prompt.title, "Developer")
    local links = core.parseLinks("  # Links\n  GitHub | https://github.com\n", "links")
    t.equal(#links.entries, 1)
    local apps = core.parseApps("  # Apps\n  Firefox | Firefox\n", "apps")
    t.equal(#apps.entries, 1)
end)

t.test("empty note marker produces a diagnostic", function()
    local parsed = core.parseSheet("# Git\n~\n", "sheet")
    t.equal(#parsed.diagnostics, 1)
    t.equal(parsed.diagnostics[1].line, 2)
end)

t.test("sheet record exposes readable and searchable metadata", function()
    local parsed = core.parseSheet("# Git\n## Branches\nCreate | git switch -c x\n", "sheets/git.md")
    local record = core.sheetRecords(parsed, "sheets/git.md", {})[1]
    t.equal(record.text, "Create")
    t.equal(record.subText, "Git › Branches · Copy command")
    t.truthy(record.searchText:find("git branches create", 1, true))
    t.equal(record.payload, "git switch -c x")
end)

t.test("all source types normalize to explicit actions", function()
    local prompt = core.promptRecord(
        core.parsePrompt("# Developer\nBody", "dev.md", "prompts/dev.md"),
        "prompts/dev.md", {}
    )
    local link = core.linkRecords(
        core.parseLinks("GitHub | https://github.com", "links/general.md"),
        "links/general.md", {}
    )[1]
    local app = core.appRecords(
        core.parseApps("Firefox | Firefox", "hammerspoon/apps/general.md"),
        "hammerspoon/apps/general.md", {}
    )[1]
    t.equal(prompt.kind, "prompt")
    t.equal(link.subText, "Link · Open in default browser")
    t.equal(app.subText, "App · Open new window · ⌘↵ Focus")
end)
