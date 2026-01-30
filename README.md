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

```bash
git clone <repo-url> && cd log-test
./install.sh
```

The install script:

- Copies `session-end.sh` to `~/.claude/hooks/`
- Merges the hook config into `~/.claude/settings.json` (preserving existing settings)
- Creates `~/.claude/logs/` for transcripts and log output
- Works on macOS, Linux, WSL, and Windows (Git Bash/MSYS2)

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
