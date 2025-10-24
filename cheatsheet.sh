#!/bin/bash
# Universal Cheatsheet System
# A two-level menu system for organizing and accessing cheatsheets

CHEATSHEET_DIR="$HOME/.config/cheatsheet/sheets"
PROMPTS_DIR="$HOME/.config/cheatsheet/prompts"

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
    awk -F'|' '
    # Skip empty lines and markdown headers
    /^[[:space:]]*$/ { next }
    /^#/ { next }
    
    {
        # Extract description (left side) and command (right side)
        description = $1;
        command = $2;
        
        # Trim whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", description);
        gsub(/^[ \t]+|[ \t]+$/, "", command);
        
        # Only print if both parts exist
        if (description != "" && command != "") {
            # Format with nice alignment (50 chars for description column)
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

# Function to display the cheatsheet content
display_cheatsheet() {
    local selected_file="$1"
    
    # Parse and format the cheatsheet, then show in walker
    selected_entry=$(cat "$selected_file" | parse_cheatsheet | walker --dmenu -p 'Cheatsheet' --width 1000 --height "$menu_height")
    
    # If an entry was selected, handle it
    if [ -n "$selected_entry" ]; then
        # Extract the command (everything after →)
        command=$(echo "$selected_entry" | awk -F'→' '{print $2}' | sed 's/^ *//')
        
        # For now, just show it in a notification
        # This is where you can extend functionality later:
        # - Copy to clipboard: echo -n "$command" | wl-copy
        # - Execute command: eval "$command"
        # - Insert at cursor: wtype "$command"
        
        notify-send "Cheatsheet" "$command"
        
        # Uncomment this line if you want to copy to clipboard:
        # echo -n "$command" | wl-copy
    fi
}

# Main logic: First menu (category selection)
category_selection=$(display_categories | walker --dmenu -p 'Select' --width 1000 --height "$menu_height")

# If a category was selected, route accordingly
if [ -n "$category_selection" ]; then
    if [ "$category_selection" = "Prompts" ]; then
        handle_prompts
    else
        # Find the file that matches this header
        selected_file=$(list_categories | grep "^$category_selection|" | awk -F'|' '{print $2}')
        # Display the cheatsheet entries
        if [ -n "$selected_file" ]; then
            display_cheatsheet "$selected_file"
        fi
    fi
fi
