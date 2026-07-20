# Cheatsheet for Hammerspoon (macOS)

This Hammerspoon configuration provides one searchable palette for the repository's
sheet commands and notes, prompts, links, apps, and utilities. Commands and prompts
are copied only; they are never typed or executed by the launcher.

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

Press `Alt+Ctrl+Shift+K` to open the palette. Search all content in the same
chooser: sheet commands and notes, prompts, links, apps, **BW Hash**, and **Edit
Sheets**.

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
- result icons

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
  the clone and the palette loads its repository content.
- [ ] Search in one palette and find a sheet command, prompt, link, and app.
- [ ] Choose a command and a prompt; confirm each copies the expected content and
  its notification does not expose that content.
- [ ] Choose a link and confirm it opens in the current default browser.
- [ ] Choose a `new` app with `Enter` and confirm a new window opens in that app.
- [ ] Choose the same app with `Cmd+Enter` and confirm it focuses without opening
  a new window.
- [ ] Select an unavailable app and confirm failure does not send `Cmd+N` to any
  other application.
- [ ] Run **BW Hash** with known exact input and compare the clipboard with
  `printf %s 'same exact input' | shasum -a 256`.
- [ ] Run **Edit Sheets** once with valid terminal/editor settings, then with an
  invalid setting; confirm success and failure notifications respectively.
- [ ] Temporarily make `sheets/` unavailable, reload, and confirm the chooser
  presents **Configuration needs attention** while logs identify `sheets/`.
