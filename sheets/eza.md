# eza - Modern ls Alternative

~ eza is a colorized, feature-rich replacement for ls written in Rust
~ --icons requires a Nerd Font in your terminal

## Basic Listing
List current directory | eza
List with icons | eza --icons
List one item per line | eza -1
List all including hidden | eza -a
List all including . and .. | eza -aa
List with header row | eza -lh

## Long View
Long list (permissions, size, date) | eza -l
Long list with icons | eza -l --icons
Long list all files | eza -la
Long list with git status | eza -l --git
Long list with human sizes | eza -lh
Long list with file group | eza -lg
Long list with inode number | eza -li

## Tree View
Tree view | eza -T
Tree view with icons | eza -T --icons
Tree view N levels deep | eza -T -L <N>
Long tree view | eza -lT
Long tree view N levels | eza -lT -L <N>

## Sorting
Sort by size (largest last) | eza -l -s size
Sort by size (largest first) | eza -l -s size -r
Sort by modification time | eza -l -s modified
Sort by extension | eza -l -s extension
Sort by name (default) | eza -l -s name
Reverse sort order | eza -l -r

## Filtering
Show only directories | eza -D
Show only files (no dirs) | eza -f
Filter by glob pattern | eza <*.md>
Recurse into subdirectories | eza -R
Recurse with depth limit | eza -R -L <N>

## Git Integration
~ Requires being inside a git repository
Show git status per file | eza -l --git
Show git status + repo summary | eza -l --git --git-repos

## Output Tweaks
No file permissions | eza -l --no-permissions
No file sizes | eza -l --no-filesize
No owner column | eza -l --no-user
No timestamps | eza -l --no-time
Show timestamps as relative | eza -l --time-style=relative
Show created time | eza -l --time=created
Show accessed time | eza -l --time=accessed

## Common Aliases
~ Add to your shell config for convenience
Alias ls to eza | alias ls='eza --icons'
Alias ll to long list | alias ll='eza -lh --icons --git'
Alias la to show hidden | alias la='eza -lah --icons --git'
Alias lt to tree view | alias lt='eza -T --icons -L 2'
