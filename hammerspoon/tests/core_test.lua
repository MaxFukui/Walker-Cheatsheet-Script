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
