#!/bin/bash
# Universal Cheatsheet System
# A two-level menu system for organizing and accessing cheatsheets

CHEATSHEET_DIR="$HOME/.config/cheatsheet/sheets"
PROMPTS_DIR="$HOME/.config/cheatsheet/prompts"
LINKS_DIR="$HOME/.config/cheatsheet/links"

# Links menu: this file's entries show inline at the top level, every other
# links/*.md becomes a browsable collection prefixed with LINK_GROUP_PREFIX
LINKS_ROOT_FILE="general.md"
LINK_GROUP_PREFIX="▸ "

# Ensure the cheatsheet directory exists
if [ ! -d "$CHEATSHEET_DIR" ]; then
    notify-send "Cheatsheet" "Directory not found: $CHEATSHEET_DIR"
    exit 1
fi

# Get monitor height for consistent sizing with other Omarchy menus
monitor_height=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .height')
menu_height=$((monitor_height * 40 / 100))

# Function to extract the first markdown header (# Title) from a file
get_header() {
    local file="$1"
    # Get the first line that starts with #
    grep -m 1 "^#" "$file" | sed 's/^#* *//'
}

# Function to list all cheatsheet files and their headers
list_categories() {
    for file in "$CHEATSHEET_DIR"/*.md; do
        if [ -f "$file" ]; then
            header=$(get_header "$file")
            if [ -n "$header" ]; then
                # Output: "Header|filepath"
                echo "$header|$file"
            fi
        fi
    done
}

# Function to display only headers for the first menu
display_categories() {
    echo "Prompts"
    echo "Links"
    echo "BW Hash"
    echo "Edit Sheets"
    list_categories | awk -F'|' '{print $1}'
}
# Clipboard helper: copies stdin using available tool
copy_to_clipboard() {
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        xsel -b
    else
        cat >/dev/null
        notify-send "Cheatsheet" "No clipboard tool found (wl-copy/xclip/xsel)"
        return 1
    fi
}

# List prompts as "Header|filepath"; fallback to filename when no markdown header
list_prompts() {
    for file in "$PROMPTS_DIR"/*; do
        [ -f "$file" ] || continue
        header=$(get_header "$file")
        if [ -z "$header" ]; then
            header=$(basename "$file")
        fi
        echo "$header|$file"
    done
}

# Function to parse and format cheatsheet entries (inspired by parse_bindings)
parse_cheatsheet() {
    awk '
    # Skip empty lines and markdown headers
    /^[[:space:]]*$/ { next }
    /^#/ { next }

    # Handle informational lines (starting with ~)
    /^~/ {
        note = $0;
        gsub(/^~[ \t]*/, "", note);
        gsub(/[ \t]+$/, "", note);
        if (note != "") {
            printf "ℹ %s\n", note;
        }
        next
    }

    {
        # Split only on the first | so commands containing pipes are preserved
        idx = index($0, "|");
        if (idx == 0) { next }
        description = substr($0, 1, idx - 1);
        command = substr($0, idx + 1);

        # Trim whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", description);
        gsub(/^[ \t]+|[ \t]+$/, "", command);

        # Only print if both parts exist
        if (description != "" && command != "") {
            printf "%-30s → %s\n", description, command;
        }
    }'
}
# Prompts flow: select a prompt then copy its content
handle_prompts() {
    # Ensure prompts directory exists
    if [ ! -d "$PROMPTS_DIR" ]; then
        notify-send "Prompts" "Directory not found: $PROMPTS_DIR"
        return
    fi
    # Show list of prompts
    prompt_sel=$(list_prompts | awk -F'|' '{print $1}' | walker --dmenu -p 'Prompts' --width 1000 --height "$menu_height")
    [ -z "$prompt_sel" ] && return
    file=$(list_prompts | awk -F'|' -v sel="$prompt_sel" '$1==sel{print $2; exit}')
    [ -z "$file" ] && return
    content=$(cat "$file")
    if [ -n "$content" ]; then
        printf "%s" "$content" | copy_to_clipboard && notify-send "Prompts" "Copied: $prompt_sel"
    fi
}

# List links as "Name|URL" from a single markdown file
list_links_in_file() {
    local file="$1"
    [ -f "$file" ] || return 0
    # Parse each line for "Name | URL" format
    awk -F'|' '
    /^[[:space:]]*$/ { next }
    /^#/ { next }
    {
        name = $1;
        url = $2;
        gsub(/^[ \t]+|[ \t]+$/, "", name);
        gsub(/^[ \t]+|[ \t]+$/, "", url);
        if (name != "" && url != "") {
            print name "|" url;
        }
    }' "$file"
}

# List link collections (every links/*.md except general.md) as "Label|filepath"
list_link_groups() {
    for file in "$LINKS_DIR"/*.md; do
        [ -f "$file" ] || continue
        [ "$(basename "$file")" = "$LINKS_ROOT_FILE" ] && continue
        label=$(get_header "$file")
        if [ -z "$label" ]; then
            label=$(basename "$file" .md)
        fi
        echo "$label|$file"
    done
}

# Top-level Links menu: general.md links inline + one entry per collection
display_links_root() {
    list_links_in_file "$LINKS_DIR/$LINKS_ROOT_FILE" | awk -F'|' '{print $1}'
    list_link_groups | awk -F'|' -v p="$LINK_GROUP_PREFIX" '{print p $1}'
}

# Open a URL in Firefox
open_link() {
    local name="$1" url="$2"
    [ -z "$url" ] && return
    firefox "$url" &
    notify-send "Links" "Opening: $name"
}

# Show the links of a single collection file
handle_link_group() {
    local file="$1" label="$2"
    link_sel=$(list_links_in_file "$file" | awk -F'|' '{print $1}' | walker --dmenu -p "$label" --width 1000 --height "$menu_height")
    [ -z "$link_sel" ] && return
    url=$(list_links_in_file "$file" | awk -F'|' -v sel="$link_sel" '$1==sel{print $2; exit}')
    open_link "$link_sel" "$url"
}

# Links flow: general links open directly, collections open a submenu
handle_links() {
    # Ensure links directory exists
    if [ ! -d "$LINKS_DIR" ]; then
        notify-send "Links" "Directory not found: $LINKS_DIR"
        return
    fi
    # Show general links plus collection entries
    link_sel=$(display_links_root | walker --dmenu -p 'Links' --width 1000 --height "$menu_height")
    [ -z "$link_sel" ] && return

    # A collection was picked — descend into it
    if [[ "$link_sel" == "$LINK_GROUP_PREFIX"* ]]; then
        label="${link_sel#"$LINK_GROUP_PREFIX"}"
        file=$(list_link_groups | awk -F'|' -v sel="$label" '$1==sel{print $2; exit}')
        [ -z "$file" ] && return
        handle_link_group "$file" "$label"
        return
    fi

    # A general link was picked — open it directly
    url=$(list_links_in_file "$LINKS_DIR/$LINKS_ROOT_FILE" | awk -F'|' -v sel="$link_sel" '$1==sel{print $2; exit}')
    open_link "$link_sel" "$url"
}

# BW Hash flow: prompt for passphrase, generate SHA256 hash, copy to clipboard
handle_bwhash() {
    # Prompt for passphrase using zenity password dialog
    passphrase=$(zenity --password --title="Bitwarden" --text="Enter your Bitwarden passphrase:")
    [ -z "$passphrase" ] && return
    # Generate SHA256 hash and copy to clipboard
    hash=$(echo -n "$passphrase" | sha256sum | cut -d" " -f1)
    if [ -n "$hash" ]; then
        echo -n "$hash" | copy_to_clipboard && notify-send "Bitwarden" "Hash copied to clipboard!"
    else
        notify-send "Bitwarden" "Failed to generate hash"
    fi
}

# Edit Sheets flow: open ghostty terminal with neovim in cheatsheet directory
handle_edit_sheets() {
    ghostty -e bash -c "cd $HOME/.config/cheatsheet && nvim ." &
}

# Function to display the cheatsheet content
display_cheatsheet() {
    local selected_file="$1"

    # Parse and format the cheatsheet, then show in walker
    selected_entry=$(cat "$selected_file" | parse_cheatsheet | walker --dmenu -p 'Cheatsheet' --width 1000 --height "$menu_height")

    # If an entry was selected, handle it
    if [ -n "$selected_entry" ]; then
        # Informational entries (~ lines displayed as ℹ) — show notification only
        if [[ "$selected_entry" == "ℹ"* ]]; then
            note="${selected_entry#ℹ }"
            notify-send "Cheatsheet" "$note"
            return
        fi

        # Regular entries — extract value (everything after →) and copy to clipboard
        value=$(echo "$selected_entry" | awk -F'→' '{print $2}' | sed 's/^ *//')
        if [ -n "$value" ]; then
            echo -n "$value" | copy_to_clipboard && notify-send "Cheatsheet" "Copied: $value"
        fi
    fi
}

# Main logic: First menu (category selection)
category_selection=$(display_categories | walker --dmenu -p 'Select' --width 1000 --height "$menu_height")

# If a category was selected, route accordingly
if [ -n "$category_selection" ]; then
    if [ "$category_selection" = "Prompts" ]; then
        handle_prompts
    elif [ "$category_selection" = "Links" ]; then
        handle_links
    elif [ "$category_selection" = "BW Hash" ]; then
        handle_bwhash
    elif [ "$category_selection" = "Edit Sheets" ]; then
        handle_edit_sheets
    else
        # Find the file that matches this header
        selected_file=$(list_categories | grep "^$category_selection|" | awk -F'|' '{print $2}')
        # Display the cheatsheet entries
        if [ -n "$selected_file" ]; then
            display_cheatsheet "$selected_file"
        fi
    fi
fi
