#!/bin/sh
# install.sh: link agents-harness into Claude Code and OpenCode.
# Safe to run again. Run it again after `git pull` to link new skills.
# Never replaces a real file or directory. It replaces only symlinks.
set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
# AGENTS.md and the skills refer to this fixed path.
HARNESS="$HOME/.config/agents-harness"

warn() { printf 'WARN: %s\n' "$*" >&2; }

# link SOURCE DEST: create or update a symlink. Skip a real file or directory.
link() {
    if [ -e "$2" ] && [ ! -L "$2" ]; then
        warn "$2 exists and is not a symlink. Skipped. Merge or move it, then run again."
        return 0
    fi
    ln -sfn "$1" "$2"
    printf 'linked %s\n' "$2"
}

[ -f "$REPO/AGENTS.md" ] && [ -d "$REPO/skills" ] || { echo "ERROR: $REPO is not an agents-harness checkout" >&2; exit 1; }

mkdir -p "$HOME/.config" "$HOME/.claude/skills" "$HOME/.config/opencode/skills" "$HOME/.local/bin"

# 1. Fixed path to this checkout.
if [ "$REPO" != "$(cd "$HARNESS" 2>/dev/null && pwd -P)" ]; then
    link "$REPO" "$HARNESS"
fi

# 2. Core rules.
import='@~/.config/agents-harness/AGENTS.md'
if grep -qxF "$import" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
    echo "present ~/.claude/CLAUDE.md import"
else
    printf '%s\n' "$import" >>"$HOME/.claude/CLAUDE.md"
    echo "added   ~/.claude/CLAUDE.md import"
fi
link "$HARNESS/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

# 3. Skills. Remove harness links whose skill no longer exists.
for dir in "$HOME/.claude/skills" "$HOME/.config/opencode/skills"; do
    for old in "$dir"/harness-*; do
        if [ -L "$old" ] && [ ! -e "$old" ]; then
            rm "$old"
            printf 'removed %s (skill no longer exists)\n' "$old"
        fi
    done
    for skill in "$REPO"/skills/*/; do
        name=$(basename "$skill")
        link "$HARNESS/skills/$name" "$dir/$name"
    done
done

# 4. Project setup command: the fish version if fish is installed, else the bash version.
if command -v fish >/dev/null 2>&1; then
    link "$HARNESS/bin/project-init.fish" "$HOME/.local/bin/project-init"
else
    link "$HARNESS/bin/project-init.bash" "$HOME/.local/bin/project-init"
fi
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) warn "$HOME/.local/bin is not in PATH. Add it to use project-init." ;;
esac

echo 'Done. Start a new Claude Code or OpenCode session. Then, in a project: project-init'
