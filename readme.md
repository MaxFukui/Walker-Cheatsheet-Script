# Universal Cheatsheet System

A two-level fuzzy-searchable cheatsheet system for Hyprland using Walker.

## Installation

1. Create the cheatsheet directory structure:
```bash
mkdir -p ~/.config/cheatsheet/sheets
```

2. Copy the main script:
```bash
cp cheatsheet.sh ~/.config/cheatsheet/cheatsheet.sh
chmod +x ~/.config/cheatsheet/cheatsheet.sh
```

3. Copy the example cheatsheets:
```bash
cp git.md vim.md hyprland.md system.md ~/.config/cheatsheet/sheets/
```

4. Add keybinding to your Hyprland config (`~/.config/hypr/hyprland.conf`):
```
bind = SUPER, C, exec, ~/.config/cheatsheet/cheatsheet.sh
```

5. Reload Hyprland config:
```bash
hyprctl reload
```

## Usage

1. Press `Super + C` (or your configured keybinding)
2. First menu appears showing all available cheatsheet categories
3. Select a category (e.g., "Git - Version Control")
4. Second menu appears with all commands in that category
5. Select a command to see it in a notification

## Creating New Cheatsheets

Create a new markdown file in `~/.config/cheatsheet/sheets/`:

```markdown
# Category Name - Description

Command description | actual command
Another command | command here
Third command | yet another command
```

**Format rules:**
- First line MUST be a markdown header (`# Title`)
- Each command line: `description | command`
- Empty lines are ignored
- Comments (lines starting with `#` after the first) are ignored

**Example** (`~/.config/cheatsheet/sheets/docker.md`):
```markdown
# Docker - Container Management

List containers | docker ps -a
Start container | docker start <container>
Stop container | docker stop <container>
Remove container | docker rm <container>
List images | docker images
Pull image | docker pull <image>
Build image | docker build -t <name> .
```

## Customization

### Change keybinding
Edit `~/.config/hypr/hyprland.conf`:
```
bind = SUPER, C, exec, ~/.config/cheatsheet/cheatsheet.sh
```

### Enable clipboard copy
Edit `~/.config/cheatsheet/cheatsheet.sh`, find this line:
```bash
# Uncomment this line if you want to copy to clipboard:
# echo -n "$command" | wl-copy
```

Remove the `#` to enable:
```bash
echo -n "$command" | wl-copy
```

### Adjust menu width/height
Edit the script and change these values:
```bash
-w 800    # Width in pixels
-h "$menu_height"    # Height (auto-calculated)
```

### Change column width
In the `parse_cheatsheet()` function, adjust the number:
```bash
printf "%-50s → %s\n", description, command;
#        ^^ change this number
```

## Future Extensions

The code is structured to easily add:
- **Copy to clipboard**: Uncomment the `wl-copy` line
- **Execute commands**: Add `eval "$command"`
- **Insert at cursor**: Add `wtype "$command"`
- **Multi-action menu**: Add a third walker menu to choose action

## Directory Structure
```
~/.config/cheatsheet/
├── cheatsheet.sh          # Main script
└── sheets/                # Cheatsheet files
    ├── git.md
    ├── vim.md
    ├── hyprland.md
    ├── system.md
    └── <your-custom>.md
```

## Dependencies
- `walker` - Menu system (already installed on Omarchy)
- `hyprctl` - Hyprland control (comes with Hyprland)
- `jq` - JSON parsing (for monitor detection)
- `wl-clipboard` - For clipboard copy (optional)

Install optional dependencies:
```bash
sudo pacman -S wl-clipboard
```

## Tips
- Keep command descriptions short and clear
- Use consistent naming for categories
- Group related commands together
- The fuzzy finder works great with abbreviations (e.g., "gco" finds "git checkout")
