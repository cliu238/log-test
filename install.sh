#!/bin/bash
# install.sh — Install Claude Code session-end hook at user level
set -euo pipefail

# --- Prerequisites ---
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed."
    echo "  macOS:   brew install jq"
    echo "  Ubuntu:  sudo apt install jq"
    echo "  Windows: choco install jq"
    exit 1
fi

# --- Detect platform and resolve Claude config directory ---
detect_claude_dir() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            # Windows via Git Bash / MSYS2
            if [ -n "${APPDATA:-}" ]; then
                echo "$APPDATA/.claude"
            else
                echo "$HOME/.claude"
            fi
            ;;
        *)
            # macOS, Linux, WSL
            echo "$HOME/.claude"
            ;;
    esac
}

CLAUDE_DIR="$(detect_claude_dir)"
HOOKS_DIR="$CLAUDE_DIR/hooks"
LOGS_DIR="$CLAUDE_DIR/logs"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_HOOK="$SCRIPT_DIR/hooks/session-end.sh"

echo "Installing Claude session-end hook..."
echo "  Claude dir: $CLAUDE_DIR"

# --- Verify source hook exists ---
if [ ! -f "$SOURCE_HOOK" ]; then
    echo "Error: Source hook not found at $SOURCE_HOOK"
    exit 1
fi

# --- Create directories ---
mkdir -p "$HOOKS_DIR" "$LOGS_DIR"

# --- Copy hook script ---
cp "$SOURCE_HOOK" "$HOOKS_DIR/session-end.sh"
chmod +x "$HOOKS_DIR/session-end.sh"

# --- Patch paths in copied script ---
INSTALLED_HOOK="$HOOKS_DIR/session-end.sh"
SAVED_SESSIONS_DIR="$LOGS_DIR/saved-sessions"
LOG_FILE="$LOGS_DIR/session-end.log"

# Replace OUTPUT_DIR line
sed -i.bak "s|^OUTPUT_DIR=.*|OUTPUT_DIR=\"$SAVED_SESSIONS_DIR\"|" "$INSTALLED_HOOK"

# Replace log file paths (all occurrences)
sed -i.bak "s|>> .*session-end\.log|>> \"$LOG_FILE\"|g" "$INSTALLED_HOOK"

# Clean up sed backup files
rm -f "$INSTALLED_HOOK.bak"

# --- Merge hook config into settings.json ---
HOOK_COMMAND="$HOOKS_DIR/session-end.sh"

HOOK_CONFIG=$(cat <<EOF
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOOK_COMMAND"
          }
        ]
      }
    ]
  }
}
EOF
)

if [ -f "$SETTINGS_FILE" ]; then
    # Merge with existing settings, preserving everything
    MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$HOOK_CONFIG"))
    echo "$MERGED" > "$SETTINGS_FILE"
else
    echo "$HOOK_CONFIG" | jq '.' > "$SETTINGS_FILE"
fi

# --- Done ---
echo ""
echo "Installation complete!"
echo "  Hook:     $INSTALLED_HOOK"
echo "  Settings: $SETTINGS_FILE"
echo "  Logs:     $LOGS_DIR/"
echo "  Sessions: $SAVED_SESSIONS_DIR/"
