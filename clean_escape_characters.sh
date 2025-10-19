#!/bin/bash
# Script to clean escaped characters from cheatsheet markdown files
# Usage: ./clean-cheatsheet.sh <filename>

# Check if a filename was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    echo "Example: $0 conda.md"
    echo "Example: $0 ~/.config/cheatsheet/sheets/conda.md"
    exit 1
fi

# Get the file path
FILE="$1"

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found!"
    exit 1
fi

# Clean escaped characters
sed -i 's/\\</</g; s/\\>/>/g; s/\\_/_/g' "$FILE"

echo "✓ Cleaned escaped characters from: $FILE"
