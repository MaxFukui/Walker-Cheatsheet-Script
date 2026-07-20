# Final review fixes report

## Finding map

1. Unified chooser metadata: `hammerspoon/cheatsheet.lua` now installs a
   `queryChangedCallback` and performs case-insensitive AND-token filtering over
   `record.searchText`, while chooser rows retain only readable `text` and
   `subText`. `adapter_test.lua` covers `git branch` and `app firefox` and checks
   the displayed strings.
2. Title-less sheets: `core.sheetRecords` deliberately skips records whose
   parser result has no title. The existing parser diagnostic is retained and
   logged/indexed by the controller. `controller_test.lua` proves index building
   does not throw and produces a diagnostic row.
3. Indented Markdown: all heading/comment decisions and delimited parsing now
   operate on trimmed lines. `core_test.lua` covers sheets (title and section),
   prompts, links, and apps.
4. Icons: generic strings were replaced with distinct AppKit `NSImage` names
   from `hs.image.systemImageNames`; lookup retains the safe `NSAdvanced`
   fallback. `adapter_test.lua` checks distinct configured names, each lookup,
   and fallback. `README.md` adds the required live icon smoke check.
5. Empty stderr: hash/editor failures now use fallback detail for nil or empty
   stderr. Covered in `adapter_test.lua`.
6. Empty note: a non-empty `~` record now emits `note requires text`, with line
   number. Covered in `core_test.lua`.
7. Async return semantics: `Controller:perform` documents that true means
   accepted/dispatched, not completed.
8. Task retention: the adapter retains active `hs.task` objects until completion
   and releases them in callbacks (or immediately after failed start). Covered
   in `adapter_test.lua`.

## RED / GREEN

RED command: `lua hammerspoon/tests/run.lua`

Expected failures observed:

- indented headings: expected `Git`, actual nil;
- empty note: expected one diagnostic, actual zero;
- title-less sheet: controller index build threw;
- metadata filtering: chooser had no query callback;
- icons: configured `note` icon was not an AppKit `NS*` name.

GREEN focused/full command: `lua hammerspoon/tests/run.lua`

Result: 28 PASS, 0 FAIL, including metadata filtering, title-less sheet,
trimmed source parsing, icon/fallback behavior, stderr fallback, and task
retention regressions.

Additional GREEN checks:

- `luac -p hammerspoon/*.lua hammerspoon/tests/*.lua`: exit 0.
- `git diff --check`: exit 0.

## Hammerspoon API/source evidence

- Installed `/Applications/Hammerspoon.app/Contents/Resources/docs.json`
  documents `hs.chooser:queryChangedCallback` and explicitly says callers may
  filter on each query change. Upstream `HSChooser.m` confirms that when this
  callback is installed, responsibility for displaying/filtering results moves
  to Lua; native text/subtext filtering is in the callback-absent branch.
- Installed docs state `imageFromName` accepts names exposed through
  `hs.image.systemImageNames`, populated from `NSImage.h`, and returns nil when
  unavailable. The adapter therefore uses documented names and a nil-safe
  named-image fallback.
- Installed `hs.task.new` docs describe construction, callbacks, and start, but
  do not guarantee that started task userdata self-retains. Because retention
  is undocumented, the adapter conservatively owns active tasks through their
  completion callbacks.

## Files changed

- `hammerspoon/cheatsheet.lua`
- `hammerspoon/config.lua`
- `hammerspoon/core.lua`
- `hammerspoon/README.md`
- `hammerspoon/tests/adapter_test.lua`
- `hammerspoon/tests/controller_test.lua`
- `hammerspoon/tests/core_test.lua`

## Self-review and runtime-only concerns

The diff is scoped to final-review findings. Search ordering remains stable
because filtering preserves input order. Parser diagnostics are preserved.
Clipboard and asynchronous success semantics are unchanged.

Runtime-only checks remain the documented live Hammerspoon smoke tests:
appearance/availability of AppKit named icons on the target macOS release,
chooser layout and query interaction, targeted app window creation, browser and
editor launch, and BW Hash execution. Automated stubs cannot render AppKit
images or exercise macOS application focus/accessibility behavior.

## Re-review: fuzzy metadata and chooser reset

The metadata matcher now treats each whitespace-separated query token as a
case-insensitive subsequence of `record.searchText`; every token must match.
This restores abbreviated/fuzzy queries without changing stable record order
or the readable chooser row fields. Adapter regressions cover exact queries,
`G brnch`, abbreviated command query `g swtc`, multi-token AND behavior, and a
zero-result nonmatch.

Every `showChooser` call now uses the documented `chooser:query("")` API before
restoring the complete choice list. Installed `docs.json` documents explicit
empty string as clearing the query. Installed/upstream `libchooser.m` shows the
setter only assigns `queryField.stringValue`; `HSChooser.m` shows query callbacks
are invoked by `controlTextDidChange`, so this reset does not recursively invoke
the Lua callback. Stub coverage opens the chooser twice and verifies both stale
queries are cleared and all choices restored.

RED: `lua hammerspoon/tests/run.lua` produced exactly two failures: fuzzy query
expected one result but got zero; reset expected an empty query but retained
`stale query`.

GREEN: `lua hammerspoon/tests/run.lua` passed 30 tests with 0 failures.
`luac -p hammerspoon/*.lua hammerspoon/tests/*.lua` and `git diff --check` both
exited 0.
