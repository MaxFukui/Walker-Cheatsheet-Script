# Hammerspoon Unified Launcher Design

## Goal

Turn the macOS Hammerspoon prototype into a fast, native, unified command
palette while preserving the repository as the single shared source of
cheatsheets, prompts, and links for both macOS and Arch Linux.

## Scope

This work covers the Hammerspoon application under `hammerspoon/`, its setup
documentation, automated Lua tests, and macOS-specific app definitions. It
must not change the shared Markdown formats in ways that break
`cheatsheet.sh`.

## Interaction Model

Opening the launcher displays one native `hs.chooser` containing searchable
results from all supported sources:

- Sheet commands and informational notes
- Prompts
- Links
- Applications
- Utilities, initially BW Hash and Edit Sheets

Each result has:

- Primary text describing the item or action
- Secondary text containing its type, source/category, and outcome
- An icon that identifies its type
- Search metadata that includes the visible text, type, category, section,
  and relevant aliases

Examples of useful searches include `git branch`, `app firefox`, and
`prompt developer`. The initial list remains useful without a query and uses
a stable, predictable ordering by type and source.

The chooser uses more screen width and rows than the prototype so primary and
secondary text remain readable. It relies on native chooser behavior rather
than introducing a custom webview.

## Actions

- Selecting a sheet command copies its value to the clipboard.
- Selecting a prompt copies its complete file content.
- Selecting a link opens it in the current macOS default browser.
- Selecting an informational note shows the note.
- Selecting BW Hash opens the existing masked passphrase flow and copies the
  SHA-256 digest.
- Selecting Edit Sheets opens the configured terminal and editor at the
  repository root.
- Selecting an app with `Enter` uses its configured mode, which defaults to
  opening a new window.
- Selecting an app with `Cmd+Enter` performs normal launch-or-focus behavior.

Copy actions never paste automatically. Success notifications are concise and
do not include copied command, prompt, passphrase, or hash content.

## Shared Repository and Path Resolution

The repository remains the source of truth on every operating system:

```text
<repository>/
├── hammerspoon/
├── sheets/
├── prompts/
└── links/
```

On macOS, the documented setup symlinks `~/.hammerspoon` to the repository's
`hammerspoon/` directory. The application resolves the real target of its
configuration/module directory and uses the parent directory as the repository
root. This removes the current dependency on
`~/Development/Walker-Cheatsheet-Script` while keeping the symlink-based
workflow.

No shared content is copied into a machine-specific directory. A separate
content-root override is out of scope.

## Components

### `hammerspoon/core.lua`

A pure Lua module responsible for:

- Trimming and line handling
- Reading Markdown semantics from supplied strings
- Parsing sheets, prompts, links, and app definitions
- Validating records and app modes
- Preserving sheet section names as searchable metadata
- Producing normalized unified result records

It has no dependency on the global `hs` object or filesystem operations.

### `hammerspoon/cheatsheet.lua`

The Hammerspoon controller and adapter responsible for:

- Resolving and validating repository paths
- Reading regular files
- Building and presenting the chooser
- Detecting the selection modifier
- Routing normalized records to platform actions
- Clipboard, notification, browser, application, task, and logging APIs
- Refreshing the index each time the launcher opens so Git-updated content
  appears without a Hammerspoon reload

### `hammerspoon/config.lua`

Holds macOS-specific defaults:

- Global launcher hotkey
- Chooser width and row count
- Terminal and editor commands
- Type icons and display ordering
- App activation/new-window timing limits

The repository root is derived, not configured as an absolute path.

## File and Format Behavior

Only regular files are indexed. Directory entries are never shown as prompts
or parsed as Markdown files.

Sheet parsing continues to split on the first `|`, preserving later pipe
characters in commands. Markdown headings are not selectable results:

- The first level-one heading supplies the sheet title.
- Level-two and deeper headings supply section metadata for following entries.

Prompt titles use the first Markdown heading when present and otherwise use
the filename. Links continue to use `Name | URL`. Apps continue to use
`Name | AppName | mode`, where mode must be `new` or `focus`; an omitted mode
defaults to `new` to match the approved interaction. An explicit `focus` mode
supports applications that do not have a meaningful `Cmd+N` action.

Malformed non-empty records generate diagnostics with source file and line
number rather than disappearing silently.

## App Launching

Normal focus mode uses Hammerspoon's launch-or-focus API and checks its return
value.

New-window mode:

1. Launches or activates the requested application.
2. Waits up to a configured limit for the intended application object to
   become available.
3. Sends `Cmd+N` specifically to that application object.
4. Reports success only after dispatching to the intended application.

It must never send an untargeted delayed `Cmd+N` to whichever application is
frontmost. A missing application, activation failure, or timeout produces a
clear failure notification and log entry.

## Diagnostics and Feedback

Startup and index construction validate required directories and readable
files. Missing directories, unreadable files, invalid app modes, malformed
rows, and failed external actions are logged with actionable context.

The unified chooser shows a diagnostic result when required content cannot be
loaded, distinguishing a broken configuration from a legitimate empty search.
The unconditional reload alert is removed; startup feedback appears only when
attention is needed.

Browser and editor tasks use completion callbacks and do not announce success
after a failed start or nonzero exit. Successful clipboard operations report
only the item label and action, never the copied value.

## Testing

Add a dependency-free Lua test runner under `hammerspoon/tests/`. Pure tests
cover:

- First-pipe preservation
- LF and CRLF input
- Leading/trailing whitespace
- Markdown headings and section metadata
- Informational notes
- Empty and malformed rows
- Prompt title fallback
- Link parsing
- App default mode and invalid modes
- Unified result text, subtext, type, source, and search metadata

A fake Hammerspoon adapter covers:

- Copy-only routing for commands and prompts
- Default-browser link routing
- `Enter` new-window versus `Cmd+Enter` focus routing
- Missing directory and unreadable-file diagnostics
- Failed application and task feedback
- Prevention of untargeted new-window keystrokes

Verification also includes `luac -p` for all Lua files and a documented manual
smoke test for chooser layout, fuzzy search, clipboard behavior, default
browser opening, both app actions, BW Hash, Edit Sheets, and configuration
failure display.

## Out of Scope

- A custom `hs.webview` interface
- Automatic pasting into the previously focused application
- Usage history, ranking, favorites, or persistence
- Changes to the Arch/Walker UI
- Moving shared content outside the repository
- Installing applications or command-line dependencies automatically
