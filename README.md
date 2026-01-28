# Claude Code Session Logger

A Claude Code hook that automatically saves session transcripts and logs session metadata (user, project, timestamp) when a session ends.

## What it does

When a Claude Code session ends, the `session-end.sh` hook:

- Copies the full session transcript (`.jsonl`) to a `saved-sessions/` directory
- Logs session metadata to `session-end.log` including:
  - Timestamp
  - Session ID and end reason
  - Username (`whoami`)
  - Project name (from git remote, git root, or directory name)

## Prerequisites

- `jq` must be installed (`brew install jq` on macOS)
- `git` (optional, used to resolve project name from repo)

## Installation

### Option 1: User-level (Recommended)

This applies the hook to **all** your Claude Code sessions across every project.

1. Copy the hook script:

```bash
mkdir -p ~/.claude/hooks
cp .claude/hooks/session-end.sh ~/.claude/hooks/session-end.sh
chmod +x ~/.claude/hooks/session-end.sh
```

2. Edit (or create) `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
```

3. Update the `OUTPUT_DIR` inside the script to your preferred location, e.g.:

```bash
OUTPUT_DIR="$HOME/claude-session-logs/saved-sessions"
```

### Option 2: Project-level

This applies the hook only when working inside a specific project.

1. Copy the `.claude/` directory into your project:

```bash
cp -r .claude/ /path/to/your-project/.claude/
chmod +x /path/to/your-project/.claude/hooks/session-end.sh
```

2. Update the `OUTPUT_DIR` inside the script to your preferred location.

3. The settings file at `.claude/settings.json` is already configured and uses `$CLAUDE_PROJECT_DIR` to resolve the hook path.

## Output

### Saved transcripts

```
saved-sessions/session_20250128_143022_abc123.jsonl
```

### Log entries

```
[2025-01-28 14:30:22] Session saved: .../session_20250128_143022_abc123.jsonl (user=eric project=my-repo)
[2025-01-28 14:30:22] Session ended: id=abc123 reason=user_exit user=eric project=my-repo
```

## Customization

- **`OUTPUT_DIR`** -- where transcripts are saved
- **Log file path** -- hardcoded at the bottom of `session-end.sh`, change to your preference
