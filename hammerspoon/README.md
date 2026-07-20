# Cheatsheet for Hammerspoon (macOS)

A port of `cheatsheet.sh` (Hyprland + Walker) to Hammerspoon. Reuses the same
`sheets/`, `prompts/` and `links/` content from the repo root, and adds an
`apps/` menu for launching apps with non-Spotlight behavior (e.g. forcing a
new window instead of just focusing the existing one).

## Setup

1. Install Hammerspoon (already done via `brew install --cask hammerspoon`).
2. Symlink this folder as your Hammerspoon config:
   ```bash
   ln -s ~/Development/Walker-Cheatsheet-Script/hammerspoon ~/.hammerspoon
   ```
3. Launch Hammerspoon.app and grant it Accessibility permission when prompted
   (System Settings -> Privacy & Security -> Accessibility). This is required
   for the global hotkey and for the "new window" `Cmd+N` simulation.
4. Menu bar icon -> "Reload Config" (or `hs -c "hs.reload()"` from a shell)
   after any edit to files in this folder.

## Usage

Default hotkey: `Alt + Ctrl + Shift + K`. Change it in `init.lua`:
```lua
hs.hotkey.bind({ "alt", "ctrl", "shift" }, "K", function()
```
A lighter-weight alternative worth considering: `Cmd + Alt + C` (mirrors the
original `Super + C` bind, single modifier pair, nothing on macOS claims it
by default).

Top-level menu items:
- **Prompts** — files in `../prompts/`, copies full file content to clipboard
- **Links** — entries from `../links/*.md`, opens URL in Firefox
- **Apps** — entries from `apps/*.md`, launches/focuses an app
- **BW Hash** — masked passphrase prompt, copies its SHA-256 hex digest
- **Edit Sheets** — opens Ghostty + nvim in the repo root
- **Sheet categories** — all `.md` files from `../sheets/`, same format as
  the Linux version (`description | value`, `~ note` for info-only lines)

## Apps format

`hammerspoon/apps/*.md`, one entry per line:
```
Name | AppName | mode
```
- `AppName` is what `hs.application.launchOrFocus` expects (the app's name).
- `mode` is `new` (launch/focus, then send `Cmd+N` to force a new window) or
  `focus` (default Spotlight-like behavior). Omit `mode` to default to `focus`.

## Dependencies
- `hs` CLI (bundled with Hammerspoon, already on `PATH` via Homebrew)
- `shasum` (built into macOS) — used for BW Hash
- Ghostty + `nvim` — used for Edit Sheets
- Firefox — used for opening Links
