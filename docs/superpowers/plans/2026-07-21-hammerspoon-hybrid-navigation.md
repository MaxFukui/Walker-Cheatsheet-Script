# Hammerspoon Hybrid Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the overloaded all-content chooser with a compact home menu, organized content drill-down, and immediate app/utility actions.

**Architecture:** Keep `core.lua` responsible for parsing and normalized action records. Extend `cheatsheet.lua` with navigation nodes and a per-launch navigation stack; keep the Hammerspoon adapter responsible for rendering and fuzzy-filtering only the currently visible screen. Existing action routing remains unchanged.

**Tech Stack:** Lua 5.4, Hammerspoon `hs.chooser`, dependency-free Lua tests, Markdown content files.

## Global Constraints

- Keep the repository as the shared content source for macOS and Arch Linux.
- Preserve the existing sheet, prompt, link, and app Markdown formats.
- Home order is Cheatsheets, Prompts, Links, individual apps, BW Hash, Edit Sheets.
- Apps and utilities execute directly from home.
- Cheatsheets navigate file → command/note; Links navigate file → link; Prompts show prompt records directly.
- Every nested screen begins with a Back row; the global hotkey always reopens at home with an empty query.
- Search and fuzzy matching operate only on the currently visible screen.
- Preserve copy-only commands/prompts, default-browser links, targeted app windows, diagnostics, privacy-safe notifications, and portable symlink resolution.
- Use semantic, distinct macOS icons with readable labels and safe fallback.
- Add no third-party dependencies and do not change the Arch/Walker application.

## File Structure

- Modify `hammerspoon/core.lua`: expose link-file titles without changing link-entry parsing.
- Modify `hammerspoon/cheatsheet.lua`: build navigation nodes, own the navigation stack, and render screen-specific choices.
- Modify `hammerspoon/config.lua`: add semantic category, utility, and back icons.
- Modify `hammerspoon/tests/core_test.lua`: link-title behavior.
- Modify `hammerspoon/tests/controller_test.lua`: tree shape, ordering, navigation, actions, diagnostics, and reset behavior.
- Modify `hammerspoon/tests/adapter_test.lua`: screen placeholder, query reset, fuzzy isolation, icons, and selected-node callback.
- Modify `hammerspoon/README.md`: organized workflow and smoke checklist.

---

### Task 1: Build the Hybrid Navigation Tree

**Files:**
- Modify: `hammerspoon/core.lua`
- Modify: `hammerspoon/cheatsheet.lua`
- Modify: `hammerspoon/config.lua`
- Modify: `hammerspoon/tests/core_test.lua`
- Modify: `hammerspoon/tests/controller_test.lua`

**Interfaces:**
- Produces: `core.parseLinks(content, source) -> { title, entries, diagnostics }`, where `title` is the first Markdown heading or `nil`.
- Produces: `Controller:buildNavigation() -> { home = node[], diagnostics = diagnostic[] }`.
- Navigation node shape: `{ role = "navigation", kind, text, subText, searchText, image, placeholder, children }`.
- Action node shape: existing action record plus `role = "action"`.

- [ ] **Step 1: Write failing core and tree tests**

Add these behaviors to the existing test suites:

```lua
t.test("link parser exposes its collection heading", function()
    local parsed = core.parseLinks("# Quick Links\nGitHub | https://github.com\n", "links/general.md")
    t.equal(parsed.title, "Quick Links")
end)

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

t.test("cheatsheets and links drill through source files", function()
    local tree = cheatsheet.new(Fake.completeRepository(), config):buildNavigation()
    local sheets = tree.home[1]
    t.equal(sheets.children[1].role, "navigation")
    t.equal(sheets.children[1].text, "Git")
    t.equal(sheets.children[1].children[1].kind, "command")
    local links = tree.home[3]
    t.equal(links.children[1].text, "Quick Links")
    t.equal(links.children[1].children[1].kind, "link")
end)

t.test("prompts are direct child actions", function()
    local tree = cheatsheet.new(Fake.completeRepository(), config):buildNavigation()
    t.equal(tree.home[2].children[1].kind, "prompt")
    t.equal(tree.home[2].children[1].role, "action")
end)
```

Extend the fake repository fixture with at least two sheets and two link files
so ordering and file boundaries are asserted rather than incidental.

Define the fixture helpers in `controller_test.lua` before the new tests:

```lua
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

function Fake.findHome(fake, kind)
    local home = fake.screens[1].records
    for _, node in ipairs(home) do
        if node.kind == kind then return node end
    end
end
```

- [ ] **Step 2: Run tests and verify RED**

Run: `lua hammerspoon/tests/run.lua`

Expected: FAIL because `parseLinks` has no title and
`Controller:buildNavigation` is undefined.

- [ ] **Step 3: Add link collection titles**

Refactor the internal heading helper only enough to reuse it:

```lua
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
```

Link-file navigation falls back to the basename when `title` is absent.

- [ ] **Step 4: Implement navigation-node construction**

Add focused helpers in `cheatsheet.lua`:

```lua
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
```

`buildNavigation` must:

1. Resolve/list/read the same four source directories as the current builder.
2. Create one navigation child per valid sheet file, containing only that
   file's command/note action records.
3. Create direct prompt action children.
4. Create one navigation child per link file, containing only that file's link
   action records and using heading-or-basename labeling.
5. Put app action records directly on home.
6. Append BW Hash and Edit Sheets action records.
7. Preserve deterministic filename/title ordering.
8. Attach diagnostics/empty-state nodes to the affected category and prepend a
   home diagnostic only when root-level construction is affected.

Use these home node labels and placeholders exactly:

```lua
navigation("sheets", "Cheatsheets", "Browse command sheets", "Choose a cheatsheet", sheetFiles, icons.sheets)
navigation("prompts", "Prompts", "Copy a saved prompt", "Choose a prompt", prompts, icons.prompts)
navigation("links", "Links", "Browse saved links", "Choose a link collection", linkFiles, icons.links)
```

Keep `buildIndex()` temporarily as a compatibility wrapper returning the
flattened action records only if existing startup validation still calls it;
do not use it for chooser navigation.

- [ ] **Step 5: Configure semantic icons**

Update `config.icons` with distinct verified system names:

```lua
icons = {
    sheets = "NSListViewTemplate", sheet = "NSBookmarksTemplate",
    prompts = "NSFontPanel", prompt = "NSMultipleDocuments",
    links = "NSNetwork", link = "NSShareTemplate",
    app = "NSApplicationIcon", bwhash = "NSLockLockedTemplate",
    editsheets = "NSEditTemplate", back = "NSGoLeftTemplate",
    command = "NSActionTemplate", note = "NSInfo",
    diagnostic = "NSCaution", empty = "NSStopProgressTemplate",
}
```

If an installed Hammerspoon/AppKit source check shows a name unavailable,
replace it with a verified distinct named image before committing and record
the chosen value in the test.

- [ ] **Step 6: Run tests and commit**

Run:

```bash
lua hammerspoon/tests/run.lua
luac -p hammerspoon/*.lua hammerspoon/tests/*.lua
```

Expected: all tests pass; syntax check exits 0.

```bash
git add hammerspoon/core.lua hammerspoon/cheatsheet.lua hammerspoon/config.lua \
  hammerspoon/tests/core_test.lua hammerspoon/tests/controller_test.lua
git commit -m "feat: build organized Hammerspoon navigation tree"
```

---

### Task 2: Navigate and Render One Screen at a Time

**Files:**
- Modify: `hammerspoon/cheatsheet.lua`
- Modify: `hammerspoon/tests/controller_test.lua`
- Modify: `hammerspoon/tests/adapter_test.lua`

**Interfaces:**
- Produces: `adapter:showChooser(screen, callback)`, where `screen = { records, placeholder }`.
- Produces: `Controller:openHome()` and `Controller:select(node, modifiers)`.
- Controller state: `navigationStack`, containing previously displayed navigation nodes for Back behavior.

- [ ] **Step 1: Write failing controller navigation tests**

Add tests with a fake adapter that records every shown screen:

First update the fake adapter contract:

```lua
function Fake:showChooser(screen, callback)
    self.screens = self.screens or {}
    table.insert(self.screens, {
        records = screen.records, placeholder = screen.placeholder, callback = callback,
    })
end


function Fake:modifiers()
    return self.currentModifiers or {}
end
```

```lua
t.test("show opens home and navigation selections replace the screen", function()
    local fake = Fake.completeRepository()
    local controller = cheatsheet.new(fake, config)
    controller:show()
    t.equal(fake.screens[1].placeholder, "Cheatsheet")
    controller:select(fake.screens[1].records[1], {})
    t.equal(fake.screens[2].placeholder, "Choose a cheatsheet")
    controller:select(fake.screens[2].records[2], {}) -- first row is Back
    t.truthy(fake.screens[3].placeholder:match("Search .+ commands"))
end)

t.test("back returns one level and global show resets home", function()
    local fake = Fake.completeRepository()
    local controller = cheatsheet.new(fake, config)
    controller:show()
    controller:select(fake.screens[1].records[1], {})
    controller:select(fake.screens[2].records[2], {})
    controller:select(fake.screens[3].records[1], {}) -- Back
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
```

- [ ] **Step 2: Write failing adapter screen tests**

Verify that `showChooser`:

```lua
t.test("adapter renders only the current screen and its placeholder", function()
    local adapter, hs = makeAdapter()
    adapter:showChooser({
        placeholder = "Choose a cheatsheet",
        records = {
            { text = "Back", searchText = "back", image = "NSGoLeftTemplate" },
            { text = "Git", searchText = "git", image = "NSBookmarksTemplate" },
        },
    }, function() end)
    t.equal(hs.chooserInstance.placeholder, "Choose a cheatsheet")
    t.equal(#hs.chooserInstance.currentChoices, 2)
    hs.chooserInstance.queryCallback("docker")
    t.equal(#hs.chooserInstance.currentChoices, 0)
end)
```

Also assert query reset on every screen, fuzzy matching within the provided
records, no access to records from a previous screen, and semantic icon lookup.

- [ ] **Step 3: Run tests and verify RED**

Run: `lua hammerspoon/tests/run.lua`

Expected: FAIL because the controller has no navigation stack/select API and
the adapter still accepts a flat record array without a placeholder.

- [ ] **Step 4: Implement screen rendering and navigation**

Change the adapter signature to:

```lua
function adapter:showChooser(screen, callback)
    local records = screen.records or {}
    chooserCallback = callback
    chooser:placeholderText(screen.placeholder or "Cheatsheet")
    chooser:query("")
    chooser:choices(rowsFor(records, ""))
    chooser:show()
end
```

Keep `rowsFor(records, query)` and the existing token-wise fuzzy subsequence
matcher so it cannot see records outside the supplied screen.

Add controller helpers:

```lua
function Controller:display(node, includeBack)
    local records = {}
    if includeBack then
        table.insert(records, {
            role = "navigation", kind = "back", text = "← Back",
            subText = "Return to the previous menu", searchText = "back return previous",
            image = self.config.icons.back,
        })
    end
    append(records, node.children or {})
    self.adapter:showChooser({ records = records, placeholder = node.placeholder }, function(choice)
        self:select(choice, self.adapter:modifiers())
    end)
end

function Controller:select(node, modifiers)
    if node.kind == "back" then
        table.remove(self.navigationStack)
        local parent = self.navigationStack[#self.navigationStack]
        return parent and self:display(parent, true) or self:openHome()
    elseif node.role == "navigation" then
        table.insert(self.navigationStack, node)
        return self:display(node, true)
    end
    return self:perform(node, modifiers)
end
```

`openHome()` builds a fresh tree, clears `navigationStack`, and renders home
without Back. `show()` delegates to `openHome()`.

- [ ] **Step 5: Run focused and full tests**

Run:

```bash
lua hammerspoon/tests/run.lua
luac -p hammerspoon/*.lua hammerspoon/tests/*.lua
git diff --check
```

Expected: navigation, adapter, action-regression, syntax, and whitespace checks
all pass.

- [ ] **Step 6: Commit**

```bash
git add hammerspoon/cheatsheet.lua hammerspoon/tests/controller_test.lua \
  hammerspoon/tests/adapter_test.lua
git commit -m "feat: add hierarchical Hammerspoon chooser navigation"
```

---

### Task 3: Documentation and End-to-End Verification

**Files:**
- Modify: `hammerspoon/README.md`

**Interfaces:**
- Consumes: final home/category/app/utility behavior from Tasks 1–2.
- Produces: accurate usage and smoke-test documentation.

- [ ] **Step 1: Update usage documentation**

Replace the one-palette description with:

```text
The home menu keeps apps and utilities immediately available while grouping
repository content under Cheatsheets, Prompts, and Links. Search applies only
to the menu currently on screen.
```

Document the exact flows, Back row, home reset on hotkey, direct apps/BW Hash/
Edit Sheets, existing app modifier behavior, and semantic icon configuration.

- [ ] **Step 2: Update the manual smoke checklist**

Require live checks for:

1. Compact home ordering.
2. Immediate app and utility actions.
3. Cheatsheets → sheet → command/note.
4. Links → link file → link.
5. Prompts → prompt copy.
6. Back at every nested level.
7. Hotkey reset to home.
8. Search isolation and fuzzy matching per screen.
9. Semantic category/action icons and fallbacks.
10. Existing clipboard, browser, app targeting, hash, editor, and diagnostic behavior.

- [ ] **Step 3: Run final verification**

Run:

```bash
lua hammerspoon/tests/run.lua
luac -p hammerspoon/*.lua hammerspoon/tests/*.lua
git diff --check
git status --short
```

Expected: all tests pass; syntax/whitespace checks exit 0; status contains only
the intended README change before commit.

- [ ] **Step 4: Perform available live smoke tests**

Reload Hammerspoon and execute the documented checklist. If IPC or GUI access
is unavailable, record the exact failure and list the automated tests covering
each unavailable behavior; do not report unexecuted checks as passing.

- [ ] **Step 5: Commit**

```bash
git add hammerspoon/README.md
git commit -m "docs: explain organized Hammerspoon navigation"
```
