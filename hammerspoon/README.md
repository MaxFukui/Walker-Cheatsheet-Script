# Cheatsheet for Hammerspoon (macOS)

The home menu keeps apps and utilities immediately available while grouping
repository content under Cheatsheets, Prompts, and Links. Search applies only
to the menu currently on screen. Commands and prompts are copied only; they are
never typed or executed by the launcher.

## Install

1. Install [Hammerspoon](https://www.hammerspoon.org/).
2. Clone this repository anywhere on your Mac.
3. If `~/.hammerspoon` already exists, back it up or merge the configuration you
   need before replacing it. The following command expects that path not to exist.
4. Symlink this repository's `hammerspoon/` directory to `~/.hammerspoon`, using
   its absolute path:

   ```bash
   ln -s "/absolute/path/to/Walker-Cheatsheet-Script/hammerspoon" ~/.hammerspoon
   ```

   For example, from the repository root:

   ```bash
   ln -s "$(pwd)/hammerspoon" ~/.hammerspoon
   ```

5. Launch Hammerspoon and grant it permission in **System Settings → Privacy &
   Security → Accessibility**. Accessibility is required for the global hotkey
   and for sending `Cmd+N` to the intended application.
6. Choose **Reload Config** from Hammerspoon's menu-bar menu.

The `hs` command-line tool is optional. Hammerspoon must install or enable it
separately before terminal commands such as `hs -c 'hs.reload()'` will work.

## Use

Press `Alt+Ctrl+Shift+K` to open the home menu. The home rows are **Cheatsheets**,
**Prompts**, **Links**, configured apps, **BW Hash**, and **Edit Sheets**, in that
order. Pressing the hotkey again always resets the chooser to this home menu,
even if a nested menu was open.

- **Cheatsheets** → choose a sheet → choose a command or note.
- **Prompts** → choose a prompt to copy it directly.
- **Links** → choose a link file → choose a link.
- Every nested menu starts with **← Back**, which returns to the previous menu.
- Search fuzzy-matches all query tokens within only the rows on the current
  screen; it does not search across other categories or nested menus.
- Apps, **BW Hash**, and **Edit Sheets** are selected directly from home and run
  immediately rather than opening another menu.

- Choosing a command copies only its command value. Choosing a prompt copies the
  full prompt file. Success notifications identify the item but do not reveal
  copied content.
- Choosing a link opens it in the current macOS default browser.
- Choosing an app with `Enter` follows its configured mode. The default `new`
  mode launches or focuses that app, waits for it to become available, and sends
  `Cmd+N` specifically to it. A `focus` record only launches or focuses it.
- Choosing any app with `Cmd+Enter` launches or focuses it without opening a new
  window, overriding `new` mode.
- **BW Hash** asks for hidden input, copies the SHA-256 digest of the exact input,
  and does not append a newline.
- **Edit Sheets** opens the repository root in the configured terminal and editor.

Failures are logged and shown as **Cheatsheet Error** notifications. If a required
content directory such as `sheets/` is unavailable, the chooser starts with a
**Configuration needs attention** diagnostic and the details appear in the
Hammerspoon logs.

## App records

Add app records to Markdown files under `hammerspoon/apps/`, one per line:

```text
Display Name | Application Name | mode
```

`Application Name` is the name accepted by Hammerspoon's
`hs.application.launchOrFocus`. `mode` may be `new` or `focus`; when it is omitted,
it defaults to `new`.

```text
Firefox | Firefox
Mail | Mail | focus
```

## Configure

Edit `hammerspoon/config.lua` and reload Hammerspoon. It contains:

- `hotkey.modifiers` and `hotkey.key` (the default is `Alt+Ctrl+Shift+K`)
- chooser width and row count
- terminal and editor names used by **Edit Sheets**
- new-window retry interval and timeout
- result type ordering
- semantic category and action icons, specified as AppKit system image names;
  unavailable images use the configured safe fallback

Repository content remains in `sheets/`, `prompts/`, `links/`, and
`hammerspoon/apps/`. Because the configuration resolves paths from the symlink's
real target, the repository can be cloned anywhere.

## Automated verification

From the repository root, run:

```bash
lua hammerspoon/tests/run.lua
luac -p hammerspoon/*.lua hammerspoon/tests/*.lua
```

## Manual smoke checklist

- [ ] From a clone outside `~/Development`, confirm `~/.hammerspoon` resolves to
  the clone, reload Hammerspoon, and confirm the home menu loads its repository
  content.
- [ ] Confirm compact home ordering: **Cheatsheets**, **Prompts**, **Links**, apps,
  **BW Hash**, then **Edit Sheets**.
- [ ] Select an app, **BW Hash**, and **Edit Sheets** from home; confirm each acts
  immediately without opening a submenu.
- [ ] Follow **Cheatsheets** → sheet → command and note. Confirm the command copies
  its exact value, the note displays, and notifications do not expose copied
  content.
- [ ] Follow **Links** → link file → link and confirm it opens in the current
  default browser.
- [ ] Follow **Prompts** → prompt and confirm the full prompt is copied while its
  notification does not expose the content.
- [ ] At every nested category, sheet, and link-file level, confirm **← Back** is
  first and returns exactly one level.
- [ ] Navigate into a nested menu, press `Alt+Ctrl+Shift+K`, and confirm the chooser
  resets to home.
- [ ] On each screen, confirm search excludes rows from other screens and
  case-insensitively fuzzy-matches every query token as a subsequence.
- [ ] Confirm categories, Back, commands, notes, prompts, links, apps, utilities,
  diagnostics, and empty states use their semantic icons; temporarily configure
  an unavailable system image name and confirm the safe fallback appears.
- [ ] Choose a `new` app with `Enter` and confirm a new window opens in that app;
  choose it with `Cmd+Enter` and confirm it only focuses. Confirm a `focus` app
  only focuses, and an unavailable app never sends `Cmd+N` to another app.
- [ ] Run **BW Hash** with known exact input and compare the clipboard with
  `printf %s 'same exact input' | shasum -a 256`.
- [ ] Run **Edit Sheets** once with valid terminal/editor settings, then with an
  invalid setting; confirm the editor launch and the respective success/failure
  notifications.
- [ ] Temporarily make `sheets/` unavailable, reload, and confirm the relevant
  menu presents **Configuration needs attention** while Hammerspoon logs identify
  `sheets/`.
