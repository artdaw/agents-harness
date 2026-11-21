#!/usr/bin/env bash
# test-hooks.sh: check hooks/guard.sh and the OpenCode plugin against expected allow or block results.
# Usage: bin/test-hooks.sh. Needs git and jq. The plugin cases need bun (as OpenCode uses) or node.
set -u

ROOT=$(cd -P "$(dirname "$0")/.." && pwd)
GUARD=$ROOT/hooks/guard.sh
command -v jq >/dev/null 2>&1 || { echo 'FAIL: jq is not installed' >&2; exit 1; }

T=$(mktemp -d "${TMPDIR:-/tmp}/test-hooks.XXXXXX")
trap 'rm -rf "$T"' EXIT
P=$T/project
mkdir -p "$P/src" "$P/tests"
git -C "$P" init -q
git -C "$P" config user.email test@example.com
git -C "$P" config user.name test

fail=0
# expect NAME WANT(0|2) JSON
expect() {
    local got
    printf '%s' "$3" | CLAUDE_PROJECT_DIR=$P "$GUARD" 2>"$T/err"
    got=$?
    if [ "$got" = "$2" ]; then echo "ok   $1"; else echo "FAIL $1: exit $got, want $2"; cat "$T/err"; fail=1; fi
}
edit() { printf '{"tool_name":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2"; }
bash_cmd() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }

expect 'edit source file' 0 "$(edit Edit "$P/src/app.ts")"
expect 'edit .env' 2 "$(edit Edit "$P/.env")"
expect 'write .env.local' 2 "$(edit Write "$P/.env.local")"
expect 'edit .env.example' 0 "$(edit Edit "$P/.env.example")"
expect 'edit pnpm-lock.yaml' 2 "$(edit Edit "$P/pnpm-lock.yaml")"
expect 'edit go.sum (relative path)' 2 "$(edit Edit go.sum)"
expect 'edit terraform state' 2 "$(edit Write "$P/infra/prod.tfstate")"
expect 'edit test file, no fix mode' 0 "$(edit Edit "$P/tests/test_cart.py")"
mkdir -p "$P/.agent"
printf 'Current step: 3\nMode: fix\n' >"$P/.agent/STATE.md"
expect 'edit test file in fix mode' 2 "$(edit Edit "$P/tests/test_cart.py")"
expect 'edit cart.test.ts in fix mode' 2 "$(edit MultiEdit "$P/src/cart.test.ts")"
expect 'edit source file in fix mode' 0 "$(edit Edit "$P/src/cart.ts")"
# A project inside a folder named tests/: only files inside the project count as tests.
Q=$T/tests/app
mkdir -p "$Q/.agent" "$Q/src"
printf 'Mode: fix\n' >"$Q/.agent/STATE.md"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/src/main.go"}}' "$Q" | CLAUDE_PROJECT_DIR=$Q "$GUARD" 2>"$T/err"
if [ $? = 0 ]; then echo 'ok   fix mode, project under a tests/ folder, source file'; else echo 'FAIL fix mode, project under a tests/ folder, source file'; cat "$T/err"; fail=1; fi
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/src/main_test.go"}}' "$Q" | CLAUDE_PROJECT_DIR=$Q "$GUARD" 2>"$T/err"
if [ $? = 2 ]; then echo 'ok   fix mode, project under a tests/ folder, test file'; else echo 'FAIL fix mode, project under a tests/ folder, test file'; fail=1; fi
printf 'Current step: 4\n' >"$P/.agent/STATE.md"
expect 'edit test file after fix mode' 0 "$(edit Edit "$P/tests/test_cart.py")"
expect 'unknown tool' 0 '{"tool_name":"Read","tool_input":{"file_path":".env"}}'
expect 'bad input' 0 'not json'

# Secrets are built at run time, so the test file itself holds no secret-shaped value.
fake_aws="AKIA$(printf 'Q%.0s' $(seq 16))"
echo 'export const ok = 1' >"$P/src/ok.ts"
git -C "$P" add src/ok.ts
expect 'commit clean change' 0 "$(bash_cmd 'git commit -m add')"
expect 'non-commit command' 0 "$(bash_cmd 'git status')"
git -C "$P" commit -q -m init
printf 'const key = "%s"\n' "$fake_aws" >>"$P/src/ok.ts"
expect 'commit -a with unstaged secret in a tracked file' 2 "$(bash_cmd 'git commit -am add')"
expect 'commit without -a, secret not staged' 0 "$(bash_cmd 'git commit -m add')"
git -C "$P" checkout -q -- src/ok.ts
printf 'const key = "%s"\n' "$fake_aws" >"$P/src/key.ts"
git -C "$P" add src/key.ts
expect 'commit staged secret' 2 "$(bash_cmd 'git commit -m add')"
expect 'commit staged secret with -C' 2 "$(bash_cmd "cd $P && git -C . commit -m add")"
if grep -q "$fake_aws" "$T/err"; then echo 'FAIL block message shows the secret value'; fail=1; else echo 'ok   block message hides the secret value'; fi
printf 'const t = "task-%s"\n' "$(printf 'a%.0s' $(seq 40))" >"$P/src/key.ts"
git -C "$P" add src/key.ts
expect 'commit word with sk- inside' 0 "$(bash_cmd 'git commit -m add')"

# OpenCode plugin: same cases through the plugin, as OpenCode 1.x calls it.
if command -v bun >/dev/null 2>&1; then runner=bun; elif command -v node >/dev/null 2>&1; then runner=node; else runner=; fi
if [ -z "$runner" ]; then
    echo 'SKIP plugin: bun and node are not installed'
else
    cp "$ROOT/config/opencode/harness-guard.js" "$T/plugin.mjs"
    printf 'Mode: fix\n' >"$P/.agent/STATE.md"
    cat >"$T/plugin-test.mjs" <<'EOF'
const [plugin, project, guard] = [(await import(process.argv[2])).default, process.argv[3], process.argv[4]];
const { toGuardInputs, runGuard } = plugin.helpers;
let fail = 0;
async function expect(name, want, tool, args) {
  let got = "allow";
  try { runGuard(project, toGuardInputs(tool, args), guard); } catch (e) { got = "block"; }
  console.log(`${got === want ? "ok  " : "FAIL"} plugin: ${name}${got === want ? "" : `: ${got}, want ${want}`}`);
  if (got !== want) fail = 1;
}
await expect("edit .env", "block", "edit", { filePath: `${project}/.env` });
await expect("write source", "allow", "write", { filePath: `${project}/src/a.ts`, content: "x" });
await expect("apply_patch on a test file in fix mode", "block", "apply_patch",
  { patchText: "*** Begin Patch\n*** Update File: tests/test_cart.py\n@@\n-a\n+b\n*** End Patch" });
await expect("apply_patch on source", "allow", "apply_patch",
  { patchText: "*** Begin Patch\n*** Add File: src/b.ts\n+x\n*** End Patch" });
await expect("bash commit with staged secret", "block", "bash", { command: "git commit -m x" });
await expect("read tool", "allow", "read", { filePath: `${project}/.env` });
const hooks = await plugin.server({ directory: project });
try { await hooks["tool.execute.before"]({ tool: "edit", sessionID: "s", callID: "c" }, { args: { filePath: ".env" } }); console.log("FAIL plugin: server hook allowed .env"); fail = 1; }
catch { console.log("ok   plugin: server hook blocks .env"); }
process.exit(fail);
EOF
    # The plugin calls the guard from the checkout, not from ~/.config.
    printf 'const key = "%s"\n' "$fake_aws" >"$P/src/key.ts"
    git -C "$P" add src/key.ts
    sed "s|join(homedir(), \".config\", \"agents-harness\", \"hooks\", \"guard.sh\")|\"$GUARD\"|" "$T/plugin.mjs" >"$T/plugin2.mjs"
    "$runner" "$T/plugin-test.mjs" "$T/plugin2.mjs" "$P" "$GUARD" || fail=1
fi

exit $fail
