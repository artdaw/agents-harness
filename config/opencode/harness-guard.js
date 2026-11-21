// harness-guard: OpenCode 1.x plugin. Runs hooks/guard.sh before edit and shell tool calls.
// install.sh links this file to ~/.config/opencode/plugins/. OpenCode 2.x uses another plugin API and does not load it.
// The plugin converts OpenCode tool calls to the Claude Code PreToolUse input, so both runtimes share one guard.
import { spawnSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const GUARD = join(homedir(), ".config", "agents-harness", "hooks", "guard.sh");

// apply_patch names each file in its patch text.
function patchPaths(text) {
  const paths = [];
  for (const line of String(text ?? "").split("\n")) {
    const m = line.match(/^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$/);
    if (m) paths.push(m[1].trim());
  }
  return paths;
}

// Returns the guard calls for one OpenCode tool call, in the Claude Code input format.
function toGuardInputs(tool, args) {
  args = args ?? {};
  if (tool === "bash") return [{ tool_name: "Bash", tool_input: { command: String(args.command ?? "") } }];
  if (tool === "edit" || tool === "write") return [{ tool_name: "Edit", tool_input: { file_path: String(args.filePath ?? "") } }];
  if (tool === "apply_patch") return patchPaths(args.patchText).map((p) => ({ tool_name: "Edit", tool_input: { file_path: p } }));
  return [];
}

function runGuard(directory, inputs, guard = GUARD) {
  for (const input of inputs) {
    const r = spawnSync(guard, [], {
      input: JSON.stringify(input),
      cwd: directory,
      env: { ...process.env, CLAUDE_PROJECT_DIR: directory },
      encoding: "utf8",
    });
    // Same rule as Claude Code: only exit 2 blocks. A missing or broken guard allows the call.
    if (r.status === 2) throw new Error(r.stderr.trim());
  }
}

// Only the default export: the loader reads { id, server }. "helpers" is for bin/test-hooks.sh.
export default {
  id: "harness-guard",
  helpers: { toGuardInputs, runGuard },
  server: async ({ directory }) => ({
    "tool.execute.before": async (input, output) => {
      runGuard(directory, toGuardInputs(input.tool, output.args));
    },
  }),
};
