# Hammerspoon Hybrid Navigation Design

## Goal

Replace the overloaded all-content chooser with an organized hierarchy while
keeping apps and frequent utilities immediately available from the home menu.

## Scope

This change affects Hammerspoon navigation, chooser presentation, navigation
tests, and macOS documentation. It retains the current parsers, repository
layout, path resolution, action routing, clipboard privacy, default-browser
behavior, targeted app-window handling, diagnostics, and shared Markdown
formats.

## Home Menu

Opening the global launcher always shows a compact home menu containing, in
this order:

1. Cheatsheets
2. Prompts
3. Links
4. Individual app shortcuts
5. BW Hash
6. Edit Sheets

Apps and utilities are action records, not categories. Selecting them runs the
existing action immediately. `Enter` uses an app's configured mode, defaulting
to a new window; `Cmd+Enter` uses launch-or-focus.

Search on the home menu filters only these home records. It does not search
inside cheatsheet commands, prompts, or links.

## Category Flows

### Cheatsheets

`Cheatsheets` opens a list containing one row per valid sheet file. The row's
primary label is the sheet's Markdown title, with the filename as secondary
context. Selecting a sheet opens only that sheet's commands and notes.

The sheet screen uses a context-specific placeholder such as `Search Git
commands`. Existing section metadata remains visible and searchable within the
selected sheet.

### Prompts

`Prompts` opens the prompt records directly. Selecting a prompt copies its
complete file content. There is no intermediate prompt-file category screen
because each prompt already corresponds to one file.

### Links

`Links` opens a list containing one row per link Markdown file. The row label
uses the file's first Markdown heading and falls back to its filename if no
heading exists. Selecting a link file opens only the links parsed from that
file.

## Back and Reset Behavior

Every nested screen begins with a `← Back` navigation row. Selecting it returns
to the immediately preceding screen:

- Sheet entries → sheet list → home
- Link entries → link-file list → home
- Prompt list → home

The global launcher hotkey always resets navigation and search state to the
home menu, even if the chooser was previously closed from a nested screen.

Search filters only the currently visible screen. It keeps the existing
case-insensitive token-wise fuzzy subsequence behavior and never mixes records
from other screens.

## Navigation Model

The controller builds a navigation tree rather than one flattened array.
Normalized nodes have one of two roles:

- Navigation node: opens a child screen and carries its label, subtitle, icon,
  placeholder, and child nodes.
- Action node: wraps an existing normalized action record and routes through
  `Controller:perform` unchanged.

The controller owns the current navigation stack. The Hammerspoon adapter
continues to own chooser rendering and current-screen fuzzy filtering. Showing
a screen replaces the chooser's rows and placeholder, clears the query, and
does not recreate the chooser.

Content is rebuilt when the global launcher opens so repository updates appear
without reloading Hammerspoon. Navigation within that invocation uses the
already-built tree for consistent back behavior.

## Icons

Rows use distinct, verified macOS system image names with safe fallback:

- Cheatsheets: book or list
- Prompts: document/text
- Links: link/share
- Apps: application
- BW Hash: lock/security
- Edit Sheets: edit/pencil
- Back: back/left arrow
- Commands: terminal/action
- Notes: information
- Diagnostics: warning

Labels and subtitles remain sufficient when a named image is unavailable.
Icons are presentation metadata and do not affect routing.

## Diagnostics

Malformed records remain logged with file and line context.

- A diagnostic that prevents the navigation tree from being built appears on
  the home menu.
- A problem confined to sheets, prompts, links, or apps appears when the user
  enters the affected category or alongside affected home app records as
  appropriate.
- Legitimately empty categories show a non-actionable empty-state row instead
  of a blank chooser.

Failure notifications and logs retain the existing privacy rules and do not
display copied commands, prompt content, passphrases, or hashes.

## Testing

Pure/controller tests cover:

- Home ordering and contents
- Apps and utilities executing directly from home
- Cheatsheets → sheet → command/note navigation
- Links → link file → link navigation
- Prompts opening directly to prompt records
- Back behavior at every nested level
- Global reopen resetting to home with an empty query
- Search isolation and fuzzy matching on each screen
- Empty-state and category-specific diagnostic placement
- Preservation of current copy, browser, app, hash, editor, and notification
  behavior

Adapter tests cover replacing chooser rows and placeholders without recreating
the chooser, clearing stale query state, semantic icon lookup, and returning
the selected navigation/action record to the controller.

Manual smoke testing covers visual hierarchy, icon rendering, keyboard flow,
modifier timing, app-targeted `Cmd+N`, default-browser links, external tasks,
and recovery from missing content directories.

## Out of Scope

- Returning to a single flattened all-content index
- A second global hotkey
- User-configurable pins or favorites
- Usage-based ranking or persisted navigation state
- A custom webview interface
- Changes to the Arch/Walker application
- Changes to shared Markdown formats
