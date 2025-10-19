#!/bin/bash
# Universal Cheatsheet System
# A two-level menu system for organizing and accessing cheatsheets

CHEATSHEET_DIR="$HOME/.config/cheatsheet/sheets"

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
    list_categories | awk -F'|' '{print $1}'
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
            printf "%-40s → %s\n", description, command;
        }
    }'
}

# Function to display the cheatsheet content
display_cheatsheet() {
    local selected_file="$1"
    
    # Parse and format the cheatsheet, then show in walker
    selected_entry=$(cat "$selected_file" | parse_cheatsheet | walker --dmenu -p 'Cheatsheet' -w 1000 -h "$menu_height")
    
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
category_selection=$(display_categories | walker --dmenu -p 'Select Cheatsheet' -w 1000 -h "$menu_height")

# If a category was selected, show its cheatsheet
if [ -n "$category_selection" ]; then
    # Find the file that matches this header
    selected_file=$(list_categories | grep "^$category_selection|" | awk -F'|' '{print $2}')
    
    # Display the cheatsheet entries
    if [ -n "$selected_file" ]; then
        display_cheatsheet "$selected_file"
    fi
fi
