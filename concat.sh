#!/usr/bin/env bash

# Name of the output directory
OUTPUT_DIR="concatenated_lua"

# Create the output directory (if not already existing)
mkdir -p "$OUTPUT_DIR"

# Find all *.lua files recursively in the current directory
find . -type f -name "*.lua" | while read -r file; do
    # Extract the directory name
    dir=$(dirname "$file")
    
    # If the directory is ".", we'll call our output file "root.lua"
    if [ "$dir" = "." ]; then
        output_file="root.lua"
    else
        # Remove leading "./" if present
        dir="${dir#./}"
        # Replace any slash (/) with underscore (_) to form a valid filename
        dir="${dir//\//_}"
        # Add .lua extension
        output_file="${dir}.txt"
    fi
    
    # Build the full path to the output file in the new directory
    output_path="$OUTPUT_DIR/$output_file"

    # Append a separator and the file path
    echo "----------" >> "$output_path"
    echo "$file"      >> "$output_path"
    echo "----------" >> "$output_path"
    
    # Append the content of the lua file
    cat "$file"       >> "$output_path"
    
    # Add a blank line after the file content for readability
    echo "" >> "$output_path"
done

echo "All Lua files have been concatenated into the '$OUTPUT_DIR' directory."
