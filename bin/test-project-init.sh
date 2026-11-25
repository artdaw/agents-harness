#!/usr/bin/env bash
# shellcheck disable=SC2329 # fixture functions are called by name through check
# test-project-init.sh: run project-init.fish and project-init.bash on the same sample projects
# and compare output, exit code, and written files. Run after any change to either script.
# Usage: bin/test-project-init.sh [path to bash]   (default: bash in PATH; try /bin/bash for 3.2)
set -u

BIN=$(cd -P "$(dirname "$0")" && pwd)
BASH_CMD=${1:-bash}
command -v fish >/dev/null 2>&1 || { echo 'SKIP: fish is not installed, nothing to compare' >&2; exit 0; }

T=$(mktemp -d "${TMPDIR:-/tmp}/project-init-test.XXXXXX")
trap 'rm -rf "$T"' EXIT
W=$T/work
# Symlinks named project-init, as installed, so the usage text matches.
mkdir -p "$T/fish" "$T/bash"
ln -s "$BIN/project-init.fish" "$T/fish/project-init"
ln -s "$BIN/project-init.bash" "$T/bash/project-init"
# No AGENTS_SRC: both scripts must find the harness root through the symlink.
unset AGENTS_SRC

# Fixtures: each function fills the empty directory $W.
fx_empty() { :; }
fx_node() {
    echo '{"dependencies":{"react":"19","@tanstack/react-query":"5","pg":"8"},"devDependencies":{"typescript":"5","tailwindcss":"4"}}' >package.json
    printf 'services:\n  cache:\n    image: redis:7\n' >compose.yaml
    touch Chart.yaml vite.config.ts
}
fx_go() { printf 'module x\nrequire (\n\tgithub.com/redis/go-redis/v9 v9.0.0 // indirect\n\tgo.temporal.io/sdk v1.30.0\n)\n' >go.mod; }
fx_mixed() {
    touch main.tf pyproject.toml Dockerfile alembic.ini tsconfig.json
    mkdir migrations k8s
    echo 'langchain>=1' >requirements.txt
}
fx_prisma() {
    echo '{"devDependencies":{"prisma":"6"}}' >package.json
    mkdir prisma
    printf 'datasource db {\n  provider = "postgresql"\n  url      = env("DATABASE_URL")\n}\n' >prisma/schema.prisma
}
fx_prisma_mysql() {
    mkdir prisma
    printf '// Moved from Postgres in 2024\ndatasource db {\n  provider = "mysql"\n  url      = env("POSTGRES_URL")\n}\nmodel KafkaOffset {\n  redisKey String @id\n}\n' >prisma/schema.prisma
}
fx_platform() {
    printf '[project]\ndependencies = ["fastapi>=0.115", "prometheus-client"]\n' >pyproject.toml
    printf 'plugins {\n    kotlin("jvm") version "2.0.0"\n}\n' >build.gradle.kts
    printf 'resource "azurerm_redis_cache" "c" {}\nresource "azurerm_postgresql_flexible_server" "db" {}\n' >main.tf
    touch config.alloy
}
fx_tf_comments() {
    printf '# we moved off azure-hosted redis and postgres; see grafana docs\nprovider "aws" {}\n' >main.tf
}
fx_client() { git init -q; echo '{"dependencies":{"kafkajs":"2"}}' >package.json; }
fx_symlink() { echo '{"dependencies":{"react":"19"}}' >package.json; echo shared >"$T/shared.md"; ln -s "$T/shared.md" AGENTS.md; }
fx_existing() { git init -q; printf '# Mine\n' >AGENTS.md; printf 'node_modules/\n' >.gitignore; echo '{}' >package.json; }

# case NAME FIXTURE ARGS...: the run is repeated once to check idempotence.
run_impl() {
    local impl=$1 fixture=$2
    shift 2
    rm -rf "$W"
    mkdir -p "$W"
    (
        cd "$W" || exit 1
        $fixture
        for run in 1 2; do
            echo "== run $run"
            if [ "$impl" = fish ]; then
                fish "$T/fish/project-init" "$@" 2>&1
            else
                "$BASH_CMD" "$T/bash/project-init" "$@" 2>&1
            fi
            echo "exit: $?"
        done
        for f in AGENTS.md ENGAGEMENT.md .gitignore .git/info/exclude; do
            [ -f "$f" ] && { echo "== $f"; cat "$f"; }
        done
        [ -L .agents ] && echo "== .agents -> $(readlink .agents)"
        true
    )
}

fail=0
check() {
    local name=$1
    shift
    # The unknown-option line comes from fish argparse and has a different prefix in bash.
    run_impl fish "$@" 2>&1 | grep -v ': unknown option$' >"$T/out.fish"
    run_impl bash "$@" 2>&1 | grep -v ': unknown option$' >"$T/out.bash"
    if diff -u "$T/out.fish" "$T/out.bash" >"$T/diff"; then
        echo "ok   $name"
    else
        echo "FAIL $name"
        cat "$T/diff"
        fail=1
    fi
}

check 'no stack' fx_empty
check 'detect node, web, docker, tech skills' fx_node
check 'go with indirect dependency' fx_go
check 'detect python, terraform, docker, sql' fx_mixed
check 'detect prisma: sql stack and postgres' fx_prisma
check 'prisma mysql: no postgres, kafka, or redis from names and comments' fx_prisma_mysql
check 'detect platform stack: fastapi, kotlin, azure, grafana' fx_platform
check 'terraform comments select no technology' fx_tf_comments
check 'explicit stacks' fx_empty --go --web --sql
check 'customer mode' fx_client --client Acme --provider 'anthropic, openai'
check 'customer mode, provider placeholder' fx_client --client=Acme
check 'existing AGENTS.md and .gitignore' fx_existing --agents
check 'AGENTS.md is a symlink' fx_symlink
check 'help' fx_empty --help
check 'error: invalid option' fx_empty --bogus
check 'error: positional argument' fx_empty extra
check 'error: provider without client' fx_empty --provider openai
check 'error: unknown provider' fx_client --client Acme --provider anthropic,
check 'error: empty client name' fx_client --client ''
check 'error: client outside Git' fx_empty --client Acme

exit $fail
