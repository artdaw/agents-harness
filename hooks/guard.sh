#!/bin/sh
# guard.sh: block tool calls that the harness rules forbid. Runs before each edit or shell command.
# Input (stdin): JSON {"tool_name": "...", "tool_input": {...}}, the Claude Code PreToolUse format.
#   Edit tools: Edit, Write, MultiEdit, NotebookEdit with tool_input.file_path or notebook_path.
#   Shell: Bash with tool_input.command.
# The OpenCode plugin (config/opencode/harness-guard.js) converts its tool calls to the same format.
# Exit 0: allow. Exit 2: block; stderr is the reason, and the agent reads it.
# Project directory: $CLAUDE_PROJECT_DIR, else the current directory.
set -u

block() {
    printf 'harness-guard blocked this call: %s\n' "$1" >&2
    printf 'If the task needs it, stop and ask the user. Do not look for a bypass.\n' >&2
    exit 2
}

# ponytail: without jq the guard cannot read its input and allows the call; install.sh warns when jq is missing.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0
project=${CLAUDE_PROJECT_DIR:-$(pwd)}
project=${project%/}

check_path() {
    path=$1
    name=${path##*/}
    case $name in
    .env.example | .env.sample | .env.template | .env.dist) ;;
    .env | .env.*) block "$path holds secrets. Agents do not edit .env files." ;;
    pnpm-lock.yaml | package-lock.json | yarn.lock | bun.lock | bun.lockb | uv.lock | poetry.lock | \
        Pipfile.lock | go.sum | Cargo.lock | Gemfile.lock | composer.lock | .terraform.lock.hcl)
        block "$path is a lockfile. Change it with the package manager command, not by hand." ;;
    *.tfstate | *.tfstate.backup) block "$path is Terraform state. Agents never edit state." ;;
    esac
    # Fix mode: the failing test is the proof of the bug, so the fix must not change it.
    if [ -f "$project/.agent/STATE.md" ] && grep -qE '^Mode:[[:space:]]*fix[[:space:]]*$' "$project/.agent/STATE.md"; then
        # Match inside the project only: a parent folder named tests/ must not make every file a test.
        rel=${path#"$project"/}
        case $rel in
        */test/* | */tests/* | */__tests__/* | */spec/* | test/* | tests/* | __tests__/* | spec/* | \
            *_test.* | *.test.* | *.spec.* | test_*.py | */test_*.py | *Test.java | *Tests.java | *_spec.rb)
            block "$path is a test file, and .agent/STATE.md says Mode: fix. Change the code, not the test.
When the fix passes, remove the Mode: fix line from .agent/STATE.md." ;;
        esac
    fi
}

check_commit() {
    cmd=$1
    # ponytail: matches "git commit" and "git -C dir commit" in a command line; misses aliases and scripts.
    printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_.-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' || return 0
    if printf '%s' "$cmd" | grep -qE '[[:space:]](-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
        range=HEAD
    else
        range=--cached
    fi
    # Read only added lines, as "file<TAB>line". Report the file and the kind of secret, never the value.
    added=$(git -C "$project" diff "$range" --unified=0 --no-color 2>/dev/null |
        awk '/^\+\+\+ / { file = substr($0, 7); next } /^\+/ { print file "\t" substr($0, 2) }')
    found=$(
        for rule in \
            'AWS access key|AKIA[0-9A-Z]{16}' \
            'private key|-----BEGIN [A-Z ]*PRIVATE KEY-----' \
            'GitHub token|gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}' \
            'Slack token|xox[baprs]-[A-Za-z0-9-]{10,}' \
            'API key (sk-)|(^|[^A-Za-z0-9])sk-(ant-|proj-)?[A-Za-z0-9_-]{32,}' \
            'Google API key|AIza[0-9A-Za-z_-]{35}'; do
            label=${rule%%|*}
            printf '%s\n' "$added" | grep -E -- "${rule#*|}" | cut -f1 | sed "s/\$/: $label/"
        done | sort -u
    )
    [ -z "$found" ] || block "the commit adds a secret. Remove it and use the project secret store.
$found"
}

case $tool in
Edit | Write | MultiEdit | NotebookEdit)
    path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
    [ -z "$path" ] || check_path "$path"
    ;;
Bash)
    check_commit "$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
    ;;
esac
exit 0
