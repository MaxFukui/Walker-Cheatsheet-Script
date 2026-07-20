# Hammerspoon Unified Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two-level Hammerspoon prototype with a portable, tested, unified native chooser for shared sheets, prompts, links, apps, and utilities.

**Architecture:** Pure parsing and record normalization live in `core.lua`; macOS configuration lives in `config.lua`; filesystem discovery, chooser presentation, and platform actions live in `cheatsheet.lua`. The controller accepts an adapter so normal Lua tests can verify behavior without launching Hammerspoon.

**Tech Stack:** Lua 5.4, Hammerspoon APIs, dependency-free Lua assertions, Markdown data files.

## Global Constraints

- Keep the repository as the single source of truth for macOS and Arch Linux.
- Preserve the shared sheet, prompt, and link formats consumed by `cheatsheet.sh`.
- Derive the repository root from the resolved `hammerspoon/` configuration directory; do not add a separate content-root override.
- Commands and prompts are copy-only and never paste automatically.
- Links open in the current macOS default browser.
- App `Enter` behavior uses the configured mode, defaulting to `new`; `Cmd+Enter` always uses launch-or-focus.
- Never send an untargeted delayed `Cmd+N`.
- Notifications must not reveal copied command, prompt, passphrase, or hash content.
- Do not add third-party Lua dependencies.

## File Structure

- Create `hammerspoon/core.lua`: pure parsers, validation, and unified record construction.
- Create `hammerspoon/config.lua`: hotkey, chooser, icons, editor, and app-launch defaults.
- Create `hammerspoon/tests/test_helper.lua`: tiny assertion and test runner utilities.
- Create `hammerspoon/tests/core_test.lua`: parser and normalized-record tests.
- Create `hammerspoon/tests/controller_test.lua`: fake-adapter tests for indexing and action routing.
- Create `hammerspoon/tests/run.lua`: test entry point.
- Rewrite `hammerspoon/cheatsheet.lua`: repository resolution, discovery, chooser, diagnostics, and actions.
- Modify `hammerspoon/init.lua`: config-driven hotkey and quiet startup validation.
- Modify `hammerspoon/apps/general.md`: retain explicit exceptions while relying on `new` as the default.
- Modify `hammerspoon/README.md`: portable symlink setup, behavior, configuration, tests, and smoke checklist.

---

### Task 1: Pure Markdown parsers

**Files:**
- Create: `hammerspoon/core.lua`
- Create: `hammerspoon/tests/test_helper.lua`
- Create: `hammerspoon/tests/core_test.lua`
- Create: `hammerspoon/tests/run.lua`

**Interfaces:**
- Produces: `core.parseSheet(content, source) -> { title, entries, diagnostics }`
- Produces: `core.parsePrompt(content, filename, source) -> { title, content, diagnostics }`
- Produces: `core.parseLinks(content, source) -> { entries, diagnostics }`
- Produces: `core.parseApps(content, source) -> { entries, diagnostics }`
- Diagnostic shape: `{ source = string, line = integer, message = string }`

- [ ] **Step 1: Add the dependency-free test harness**

```lua
-- hammerspoon/tests/test_helper.lua
local M = { tests = {} }

function M.test(name, fn)
    table.insert(M.tests, { name = name, fn = fn })
end

function M.equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") ..
            string.format("\nexpected: %s\nactual: %s", tostring(expected), tostring(actual)), 2)
    end
end

function M.truthy(value, message)
    if not value then error(message or "expected truthy value", 2) end
end

function M.run()
    local failed = 0
    for _, item in ipairs(M.tests) do
        local ok, err = pcall(item.fn)
        if ok then
            print("PASS " .. item.name)
        else
            failed = failed + 1
            io.stderr:write("FAIL " .. item.name .. "\n" .. err .. "\n")
        end
    end
    if failed > 0 then os.exit(1) end
end

return M
```

```lua
-- hammerspoon/tests/run.lua
package.path = "hammerspoon/?.lua;hammerspoon/tests/?.lua;" .. package.path
local t = require("test_helper")
require("core_test")
t.run()
```

- [ ] **Step 2: Write failing parser tests**

```lua
-- hammerspoon/tests/core_test.lua
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
```

- [ ] **Step 3: Run the tests and confirm the missing-module failure**

Run: `lua hammerspoon/tests/run.lua`

Expected: FAIL containing `module 'core' not found`.

- [ ] **Step 4: Implement the minimal pure parsers**

Implement `core.lua` with:

```lua
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
        local title = line:match("^#+%s+(.+)$")
        if title then return trim(title) end
    end
end

function M.parseSheet(content, source)
    local result = { title = firstHeader(content), entries = {}, diagnostics = {} }
    local section
    for number, line in ipairs(lines(content)) do
        local hashes, heading = line:match("^(#+)%s+(.+)$")
        if hashes then
            if #hashes >= 2 then section = trim(heading) end
        elseif trim(line) ~= "" then
            local note = line:match("^~%s*(.*)$")
            local separator = line:find("|", 1, true)
            if note then
                note = trim(note)
                if note ~= "" then
                    table.insert(result.entries, { kind = "note", text = note, section = section })
                end
            elseif separator then
                local description = trim(line:sub(1, separator - 1))
                local value = trim(line:sub(separator + 1))
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
        if trim(line) ~= "" and not line:match("^#") then
            local parts = splitPipe(line)
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
    return parseDelimited(content, source, function(parts)
        if #parts ~= 2 or parts[1] == "" or parts[2] == "" then
            return nil, "link record requires name and URL"
        end
        return { kind = "link", name = parts[1], url = parts[2] }
    end)
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

return M
```

- [ ] **Step 5: Run tests and commit**

Run: `lua hammerspoon/tests/run.lua`

Expected: all five tests print `PASS`; exit 0.

```bash
git add hammerspoon/core.lua hammerspoon/tests
git commit -m "test: add pure Hammerspoon content parsers"
```

---

### Task 2: Unified chooser records

**Files:**
- Modify: `hammerspoon/core.lua`
- Modify: `hammerspoon/tests/core_test.lua`

**Interfaces:**
- Consumes: parser result shapes from Task 1.
- Produces: `core.sheetRecords(parsed, source, icons) -> record[]`
- Produces: `core.promptRecord(parsed, source, icons) -> record`
- Produces: `core.linkRecords(parsed, source, icons) -> record[]`
- Produces: `core.appRecords(parsed, source, icons) -> record[]`
- Record shape: `{ text, subText, kind, searchText, payload, source, image? }`

- [ ] **Step 1: Add failing normalization tests**

```lua
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
```

- [ ] **Step 2: Verify failure**

Run: `lua hammerspoon/tests/run.lua`

Expected: FAIL containing `attempt to call a nil value (field 'sheetRecords')`.

- [ ] **Step 3: Implement normalization**

Add these functions to `core.lua`:

```lua
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
```

- [ ] **Step 4: Run tests and commit**

Run: `lua hammerspoon/tests/run.lua`

Expected: all tests print `PASS`; exit 0.

```bash
git add hammerspoon/core.lua hammerspoon/tests/core_test.lua
git commit -m "feat: normalize unified chooser records"
```

---

### Task 3: Portable discovery and diagnostics

**Files:**
- Create: `hammerspoon/config.lua`
- Rewrite: `hammerspoon/cheatsheet.lua`
- Create: `hammerspoon/tests/controller_test.lua`
- Modify: `hammerspoon/tests/run.lua`

**Interfaces:**
- Produces: `cheatsheet.new(adapter, config) -> controller`
- Produces: `controller:buildIndex() -> { records, diagnostics }`
- Produces: `controller:show()`
- Adapter methods: `realpath`, `parent`, `listRegularFiles`, `readFile`, `log`, `notify`, `showChooser`, `setPasteboard`, `openURL`, `launchOrFocus`, `openNewWindow`, `runHashDialog`, `editSheets`, `modifiers`.

- [ ] **Step 1: Add fake-adapter discovery tests**

Create a fake adapter with an in-memory file map and record calls. Test that:

```lua
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
    t.equal(#result.records, 6) -- four content records plus two utilities
    t.equal(fake.requestedRoot, "/repo")
end)

t.test("missing required directory becomes a diagnostic record", function()
    local fake = Fake.new({ configDir = "/repo/hammerspoon", missing = { ["/repo/sheets"] = true } })
    local result = cheatsheet.new(fake, config):buildIndex()
    t.truthy(#result.diagnostics > 0)
    t.equal(result.records[1].kind, "diagnostic")
end)
```

Update `run.lua` with `require("controller_test")`.

- [ ] **Step 2: Verify failure**

Run: `lua hammerspoon/tests/run.lua`

Expected: FAIL because `cheatsheet.new` and `config` do not exist.

- [ ] **Step 3: Add configuration defaults**

```lua
return {
    hotkey = { modifiers = { "alt", "ctrl", "shift" }, key = "K" },
    chooser = { width = 55, rows = 14 },
    terminal = "Ghostty",
    editor = "nvim",
    newWindow = { retryInterval = 0.1, timeout = 3.0 },
    icons = {
        command = "command", note = "info", prompt = "text", link = "link",
        app = "application", utility = "settings", diagnostic = "caution",
    },
}
```

- [ ] **Step 4: Implement controller construction and index discovery**

Rewrite `cheatsheet.lua` as a module that does not touch `hs` at require time.
`new(adapter, config)` resolves `adapter.configDir`, obtains its real path,
uses `parent` as the repository root, enumerates only regular files, parses
them through `core`, collects diagnostics, appends BW Hash/Edit Sheets utility
records, and sorts by configured type order then source/text.

When diagnostics exist, prepend one non-destructive diagnostic record whose
text is `"Configuration needs attention"` and whose subtext contains the
diagnostic count. Log every detailed diagnostic with source and line.

- [ ] **Step 5: Run tests and commit**

Run: `lua hammerspoon/tests/run.lua`

Expected: all tests print `PASS`; exit 0.

```bash
git add hammerspoon/config.lua hammerspoon/cheatsheet.lua hammerspoon/tests
git commit -m "feat: add portable unified content discovery"
```

---

### Task 4: Safe action routing

**Files:**
- Modify: `hammerspoon/cheatsheet.lua`
- Modify: `hammerspoon/tests/controller_test.lua`

**Interfaces:**
- Produces: `controller:perform(record, modifiers) -> boolean`
- `openNewWindow(appName, retryInterval, timeout, callback)` must target the returned application object.

- [ ] **Step 1: Add failing routing tests**

Add tests proving:

```lua
t.test("commands and prompts copy without exposing content", function()
    local fake = Fake.new({})
    local controller = cheatsheet.new(fake, config)
    controller:perform({ kind = "command", text = "Status", payload = "git status" }, {})
    t.equal(fake.clipboard, "git status")
    t.equal(fake.notifications[1].text, "Copied Status")
    t.equal(fake.notifications[1].text:find("git status", 1, true), nil)
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
    controller:perform(app, { cmd = true })
    t.equal(fake.focusTarget, "Firefox")
    t.equal(fake.untargetedKeystrokes, 0)
end)

t.test("failed actions report failure rather than success", function()
    local fake = Fake.new({ failures = { openURL = true } })
    cheatsheet.new(fake, config):perform(
        { kind = "link", text = "Bad", payload = "bad://url" }, {}
    )
    t.equal(fake.notifications[1].title, "Cheatsheet Error")
end)
```

- [ ] **Step 2: Verify failure**

Run: `lua hammerspoon/tests/run.lua`

Expected: FAIL because `controller:perform` is undefined.

- [ ] **Step 3: Implement one action router**

Implement explicit branches for `command`, `prompt`, `note`, `link`, `app`,
`bwhash`, `editsheets`, and `diagnostic`. Every adapter operation returns
success/failure or uses a callback. Notify success only on confirmed success;
log and notify failures through one `reportFailure(action, detail)` helper.

For app records, `modifiers.cmd` forces `launchOrFocus`. Otherwise honor
`payload.mode`; `new` calls only the targeted `openNewWindow` adapter method.

- [ ] **Step 4: Run tests and commit**

Run: `lua hammerspoon/tests/run.lua`

Expected: all tests print `PASS`; exit 0.

```bash
git add hammerspoon/cheatsheet.lua hammerspoon/tests/controller_test.lua
git commit -m "fix: route launcher actions safely"
```

---

### Task 5: Hammerspoon adapter and unified chooser

**Files:**
- Modify: `hammerspoon/cheatsheet.lua`
- Modify: `hammerspoon/init.lua`
- Modify: `hammerspoon/apps/general.md`

**Interfaces:**
- Produces: `cheatsheet.hammerspoonAdapter(hs) -> adapter`
- Produces: module-level `cheatsheet.show()` for `init.lua`.

- [ ] **Step 1: Add a smoke-loading test with a stubbed `hs`**

Add a test that supplies minimal fakes for chooser, filesystem, pasteboard,
notifications, applications, timers, eventtap, tasks, images, logger, and
osascript; construct `hammerspoonAdapter(fakeHs)` and assert every adapter
method required by Task 3 is a function.

- [ ] **Step 2: Verify failure**

Run: `lua hammerspoon/tests/run.lua`

Expected: FAIL because `cheatsheet.hammerspoonAdapter` is undefined.

- [ ] **Step 3: Implement the real adapter**

Use Hammerspoon APIs as follows:

- Resolve the symlinked config path with `hs.fs.pathToAbsolute(hs.configdir)`.
- Filter `hs.fs.dir` entries using `hs.fs.attributes(path, "mode") == "file"`.
- Open links with `hs.urlevent.openURL(url)` so macOS chooses the browser.
- Poll `hs.application.get(appName)` with `hs.timer.waitUntil`; when available,
  call `hs.eventtap.keyStroke({ "cmd" }, "n", 0, appObject)`.
- Read selection modifiers with `hs.eventtap.checkKeyboardModifiers()`.
- Create chooser rows with `text`, `subText`, and cached `hs.image` icons.
- Configure `chooser:width(config.chooser.width)` and
  `chooser:rows(config.chooser.rows)`.
- Rebuild choices immediately before every `chooser:show()`.
- Preserve the exact-input `shasum -a 256` task and masked AppleScript dialog.
- Run editor launch through `/usr/bin/open` and report its completion status.

- [ ] **Step 4: Update initialization and app data**

`init.lua` must load IPC, config, and cheatsheet; bind
`config.hotkey.modifiers/config.hotkey.key` to `cheatsheet.show`; remove the
unconditional startup alert; run validation once and notify only when errors
exist.

In `apps/general.md`, omit `| new` where `new` is the default; retain
`Mail | Mail | focus` as the explicit focus-only exception.

- [ ] **Step 5: Run automated and syntax checks**

Run:

```bash
lua hammerspoon/tests/run.lua
luac -p hammerspoon/*.lua hammerspoon/tests/*.lua
```

Expected: all tests print `PASS`; `luac` exits 0 with no output.

- [ ] **Step 6: Commit**

```bash
git add hammerspoon/cheatsheet.lua hammerspoon/init.lua hammerspoon/apps/general.md
git commit -m "feat: add native unified Hammerspoon chooser"
```

---

### Task 6: Documentation and end-to-end verification

**Files:**
- Modify: `hammerspoon/README.md`

**Interfaces:**
- Consumes: final setup, configuration, commands, and tests from Tasks 1–5.
- Produces: reproducible installation and manual verification instructions.

- [ ] **Step 1: Rewrite setup and usage documentation**

Document:

- Clone the repository anywhere.
- Back up or merge an existing `~/.hammerspoon` configuration.
- Symlink the repository's `hammerspoon/` directory using an absolute path.
- Grant Accessibility permission.
- Use the existing `Alt+Ctrl+Shift+K` default and explain how to change it in
  `config.lua`.
- Search all content in one palette.
- `Enter`/`Cmd+Enter` app semantics.
- Copy-only behavior and default-browser links.
- App record format and default `new` mode.
- Configurable values in `config.lua`.
- `lua hammerspoon/tests/run.lua` and `luac -p` verification commands.
- The `hs` CLI is optional for terminal reloads and must be installed/enabled
  separately if desired.

- [ ] **Step 2: Add the manual smoke checklist**

Include checkboxes for:

1. Symlink resolution from a clone path other than `~/Development`.
2. Unified search across a command, prompt, link, and app.
3. Command/prompt clipboard copy with privacy-safe notification.
4. Link opening in the current default browser.
5. App `Enter` opening a new window in the intended app.
6. App `Cmd+Enter` focusing without opening a window.
7. Missing-app failure without sending `Cmd+N` elsewhere.
8. BW Hash exact-input digest.
9. Edit Sheets success/failure.
10. Missing `sheets/` diagnostic presentation.

- [ ] **Step 3: Run final verification**

Run:

```bash
lua hammerspoon/tests/run.lua
luac -p hammerspoon/*.lua hammerspoon/tests/*.lua
git diff --check
git status --short
```

Expected: automated tests pass; syntax and whitespace checks exit 0; status
contains only the intended implementation/documentation changes and any
pre-existing `.superpowers/` brainstorming artifacts.

- [ ] **Step 4: Perform the manual Hammerspoon smoke checklist**

Reload Hammerspoon from its menu and execute every documented smoke item.
Record any environment-dependent item that cannot be run, including the exact
reason and the automated coverage that substitutes for it.

- [ ] **Step 5: Commit**

```bash
git add hammerspoon/README.md
git commit -m "docs: document unified Hammerspoon launcher"
```
