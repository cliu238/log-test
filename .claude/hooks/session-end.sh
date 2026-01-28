#!/bin/bash
# SessionEnd hook - saves session conversation

# Read JSON input from stdin
input=$(cat)

# Extract fields using jq
session_id=$(echo "$input" | jq -r '.session_id')
reason=$(echo "$input" | jq -r '.reason')
cwd=$(echo "$input" | jq -r '.cwd')
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
file_timestamp=$(date '+%Y%m%d_%H%M%S')

# Output directory for saved conversations
OUTPUT_DIR="/Users/eric/projects6/log-test/saved-sessions"
mkdir -p "$OUTPUT_DIR"

# Construct the transcript source path
# Claude stores transcripts at ~/.claude/projects/-[PATH]/[SESSION_ID].jsonl
# The path uses dashes instead of slashes
project_path=$(echo "$cwd" | sed 's|/|-|g')
transcript_src="$HOME/.claude/projects/$project_path/$session_id.jsonl"

# Copy the transcript if it exists
if [ -f "$transcript_src" ]; then
    cp "$transcript_src" "$OUTPUT_DIR/session_${file_timestamp}_${session_id}.jsonl"
    echo "[$timestamp] Session saved: $OUTPUT_DIR/session_${file_timestamp}_${session_id}.jsonl" >> /Users/eric/projects6/log-test/session-end.log
else
    echo "[$timestamp] Session ended but transcript not found: $transcript_src" >> /Users/eric/projects6/log-test/session-end.log
fi

echo "[$timestamp] Session ended: id=$session_id reason=$reason" >> /Users/eric/projects6/log-test/session-end.log

exit 0
