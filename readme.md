# Universal Cheatsheet System

A two-level fuzzy-searchable cheatsheet system for Hyprland using Walker.

## Installation

1. Create the cheatsheet directory structure:
```bash
mkdir -p ~/.config/cheatsheet/sheets ~/.config/cheatsheet/prompts ~/.config/cheatsheet/links
```

2. Copy the main script:
```bash
cp cheatsheet.sh ~/.config/cheatsheet/cheatsheet.sh
chmod +x ~/.config/cheatsheet/cheatsheet.sh
```

3. Add keybinding to your Hyprland config (`~/.config/hypr/hyprland.conf`):
```
bind = SUPER, C, exec, ~/.config/cheatsheet/cheatsheet.sh
```

4. Reload Hyprland config:
```bash
hyprctl reload
```

## Usage

1. Press `Super + C` (or your configured keybinding)
2. First menu appears with top-level items:
   - **Prompts** — list files from `prompts/`, selecting copies entire file content to clipboard
   - **Links** — list entries from `links/*.md`, selecting opens URL in Firefox
   - **BW Hash** — prompt for a passphrase, generates SHA256 hash and copies to clipboard
   - **Edit Sheets** — opens Ghostty + Neovim in the cheatsheet directory
   - **Sheet categories** — all `.md` files from `sheets/`
3. When a sheet is selected, a second menu shows all its entries
4. Selecting an entry copies the value to clipboard (Ctrl+V to paste)
5. Informational entries (marked with `ℹ`) show a notification instead of copying

## Creating New Cheatsheets

Create a new markdown file in `~/.config/cheatsheet/sheets/`:

```markdown
# Category Name - Description

## Section Header (for readability in the file, not shown in menu)

Human description | value_to_copy
Another description | another_value

~ Informational note (shown in menu as ℹ, selecting shows notification)
~ Another note or reminder
```

**Format rules:**
- First line MUST be a markdown header (`# Title`)
- `## Section` lines are filtered — use them to organize the file, they won't appear in the menu
- Each entry: `description | value_to_copy`
  - Left side: short human description (what it is)
  - Right side: the value that gets copied to clipboard on selection
- `~ note text` — informational line; shown in menu with `ℹ` prefix, selecting shows a notification (nothing copied)
- Empty lines are ignored

**Example** (`~/.config/cheatsheet/sheets/docker.md`):
```markdown
# Docker - Container Management

## Containers
List all containers | docker ps -a
Start container | docker start <container>
Stop container | docker stop <container>
Remove container | docker rm <container>

## Images
List images | docker images
Pull image | docker pull <image>
Build image | docker build -t <name> .

~ Use <name> placeholders for values you fill in at runtime
```

## Adding Prompts

Place any text file in `~/.config/cheatsheet/prompts/`. Selecting it from the Prompts menu copies its entire content to clipboard. Useful for LLM prompts, boilerplate snippets, etc.

## Adding Links

Create a markdown file in `~/.config/cheatsheet/links/` with `Name | URL` entries:

```markdown
# My Links

GitHub | https://github.com
Arch Wiki | https://wiki.archlinux.org
```

## Customization

### Change keybinding
Edit `~/.config/hypr/hyprland.conf`:
```
bind = SUPER, C, exec, ~/.config/cheatsheet/cheatsheet.sh
```

### Adjust menu width/height
Edit the script and change these values:
```bash
--width 1000       # Width in pixels
--height "$menu_height"    # Height (auto-calculated as 40% of monitor height)
```

### Change description column width
In the `parse_cheatsheet()` function, adjust the number:
```bash
printf "%-30s → %s\n", description, command;
#        ^^ change this number
```

## Directory Structure
```
~/.config/cheatsheet/
├── cheatsheet.sh          # Main script
├── sheets/                # Cheatsheet files
│   ├── git.md
│   ├── docker.md
│   ├── tmux.md
│   └── <your-custom>.md
├── prompts/               # Full-file prompts (copied to clipboard)
│   └── my-prompt.md
└── links/                 # URL collections (opened in Firefox)
    └── general.md
```

## Dependencies
- `walker` - Menu system (already installed on Omarchy)
- `hyprctl` - Hyprland control (comes with Hyprland)
- `jq` - JSON parsing (for monitor detection)
- `wl-clipboard` - Clipboard copy (`wl-copy`)
- `zenity` - Password dialog (for BW Hash)
- `ghostty` + `nvim` - For Edit Sheets

Install dependencies:
```bash
sudo pacman -S wl-clipboard zenity
```

## Tips
- Keep descriptions short and clear (under ~30 characters for clean alignment)
- The right side of `|` is always what gets copied — put the "pasteable" value there
- Use `~ note` lines for reminders or context that helps with lookup but isn't something to paste
- Use `##` section headers to group related entries in the file without cluttering the menu
- The fuzzy finder works great with abbreviations (e.g., "gco" finds "git checkout")
