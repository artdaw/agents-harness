#!/usr/bin/env bash
# project-init: set up the agent harness in a project.
# Bash port of project-init.fish. Keep both in sync: bin/test-project-init.sh compares them.
# Own project:      initialize Git, add .gitignore blocks and stack sections to AGENTS.md.
# Customer project: --client creates a local ENGAGEMENT.md (excluded from Git) and adds the
#                   stack sections there. The customer's files are not changed.
# Safe to run again: existing files and sections are preserved.
# Works with bash 3.2 (macOS /bin/bash): no associative arrays, no mapfile.

shopt -s nullglob

SCRIPT_NAME=$(basename "$0")
# Order of stack sections in generated files.
ALL_STACKS=(python go java node web terraform docker sql)
# Technology skills (skills/harness-<name>), in output order. A pattern matches manifest text;
# an empty pattern means detection by files only (see below).
TECH_NAMES=(postgres temporal kafka redis kubernetes langchain datadog react typescript tailwind tanstack fastapi kotlin azure grafana)
TECH_LABELS=(PostgreSQL Temporal Kafka Redis Kubernetes LangChain Datadog React TypeScript Tailwind TanStack FastAPI Kotlin Azure Grafana)
TECH_PATTERNS=('postgres|psycopg|asyncpg|"pg"|jackc/pgx|lib/pq' 'temporalio|go\.temporal\.io|io\.temporal'
    'kafka|sarama' 'redis|valkey' '' 'langchain|langgraph' 'ddtrace|dd-trace|datadog' '"react"' '"typescript"'
    'tailwindcss' '@tanstack/' 'fastapi' 'org\.jetbrains\.kotlin|kotlin\(' 'azurerm|azuread|azure-|@azure/|com\.azure'
    'grafana|prometheus|loki|mimir')

usage() {
    printf '%s\n' \
        "Usage: $SCRIPT_NAME [stack options] [--client NAME [--provider P]] [--agents]" \
        '' \
        'Stack options:' \
        '  --py, --python  Python (uv, ruff, pytest).' \
        '  --go            Go.' \
        '  --java          Java (Maven or Gradle).' \
        '  --node          Node (pnpm).' \
        '  --web           Web (React, Astro, Tailwind). Includes --node.' \
        '  --terraform     Terraform or OpenTofu.' \
        '  --docker        Dockerfile and Compose.' \
        '  --sql           SQL and database migrations.' \
        '' \
        'Customer mode:' \
        '  --client NAME   Create ENGAGEMENT.md for a customer repository. Does not run git init' \
        '                  and does not change .gitignore or AGENTS.md.' \
        '  --provider P    Allowed model provider: anthropic, openai, or both' \
        '                  (repeat the option or use a comma list).' \
        '' \
        'Other:' \
        '  --agents, -a    Create .agents link to the harness directory.' \
        '  -h, --help      Show this help.' \
        '' \
        'Without a stack option, detect stacks in the current directory.' \
        'Technology skills (harness-postgres, harness-kafka, and others) are always detected from' \
        'the manifests in the current directory and listed in AGENTS.md or ENGAGEMENT.md.'
}

# No `set -e`: every step that can fail is checked with `|| error`, as in the fish version.
error() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

warn() {
    printf 'WARN: %s\n' "$*" >&2
}

# contains VALUE LIST...: true if VALUE is in LIST.
contains() {
    local x=$1 y
    shift
    for y in "$@"; do
        [ "$x" = "$y" ] && return 0
    done
    return 1
}

any_file() {
    local f
    for f in "$@"; do
        [ -f "$f" ] && return 0
    done
    return 1
}

any_dir() {
    local d
    for d in "$@"; do
        [ -d "$d" ] && return 0
    done
    return 1
}

# Add a line to .git/info/exclude (local only, not committed). Idempotent.
exclude_locally() {
    local file
    file=$(git rev-parse --git-path info/exclude) || error 'cannot locate .git/info/exclude'
    { mkdir -p "$(dirname "$file")" && touch "$file"; } || error "cannot write $file"
    grep -Fxq -- "$1" "$file" || printf '%s\n' "$1" >>"$file"
}

SELECTED=()
add_stack() {
    local s
    for s in "$@"; do
        contains "$s" ${SELECTED[@]+"${SELECTED[@]}"} || SELECTED+=("$s")
    done
}

FOUND_TECHS=()
add_tech() {
    contains "$1" ${FOUND_TECHS[@]+"${FOUND_TECHS[@]}"} || FOUND_TECHS+=("$1")
}

# The first line of each block is its marker, used to detect existing blocks.
# Stacks without ignore rules (docker, sql) print nothing.
gitignore_block() {
    case $1 in
    base)
        printf '%s\n' \
            '# ---- macOS ----' '.DS_Store' '.AppleDouble' '.LSOverride' '._*' '.Spotlight-V100' '.Trashes' \
            '' '# ---- Editors / IDE ----' '.idea/' '*.iml' '.vscode/*' '!.vscode/settings.json' \
            '!.vscode/extensions.json' '!.vscode/launch.json' '*.swp' '*.swo' '*~' \
            '' '# ---- Secrets and local env ----' '.env' '.env.*' '!.env.example' '*.pem' '*.key' '*.p12' \
            'secrets/' '*.local' \
            '' '# ---- Logs and temp ----' '*.log' 'logs/' 'tmp/' '.tmp/' '.cache/'
        ;;
    python)
        printf '%s\n' \
            '# ---- Python (uv, ruff, pytest) ----' '__pycache__/' '*.py[cod]' '.venv/' 'venv/' \
            '.pytest_cache/' '.ruff_cache/' '.mypy_cache/' '.pyright/' '.coverage' '.coverage.*' \
            'coverage.xml' 'htmlcov/' '*.egg-info/' '.eggs/' 'build/' 'dist/' \
            '# Commit uv.lock. Do not ignore it.'
        ;;
    go)
        printf '%s\n' \
            '# ---- Go ----' '/bin/' '*.exe' '*.test' '*.out' 'coverage.out' 'coverage.html' 'go.work.sum' \
            '# Commit go.sum. Do not ignore it.'
        ;;
    java)
        printf '%s\n' \
            '# ---- Java (Maven, Gradle) ----' 'target/' 'build/' '.gradle/' 'out/' '*.class' \
            'hs_err_pid*' 'replay_pid*' \
            '# Commit the Maven and Gradle wrappers (mvnw, gradlew, gradle/wrapper/). Do not ignore them.'
        ;;
    node)
        printf '%s\n' \
            '# ---- Node / pnpm ----' 'node_modules/' '.pnpm-store/' '.pnpm-debug.log*' 'npm-debug.log*' \
            'yarn-debug.log*' 'yarn-error.log*' '*.tsbuildinfo' '.eslintcache' '.npm/' 'dist/' 'coverage/' \
            '# Commit pnpm-lock.yaml. Do not ignore it.'
        ;;
    web)
        printf '%s\n' \
            '# ---- Web (React, Vite, Astro, Tailwind) ----' '.astro/' '.vite/' '.turbo/' '.output/' \
            'storybook-static/' 'playwright-report/' 'test-results/'
        ;;
    terraform)
        printf '%s\n' \
            '# ---- Terraform / OpenTofu ----' '.terraform/' '*.tfstate' '*.tfstate.*' '*.tfplan' \
            'crash.log' 'crash.*.log' '*.tfvars' '*.tfvars.json' 'override.tf' 'override.tf.json' \
            '*_override.tf' '*_override.tf.json' '.terraformrc' 'terraform.rc' \
            '# Commit .terraform.lock.hcl. Do not ignore it.' \
            '# *.tfvars can hold secrets. Add a non-secret one with: git add -f <file>'
        ;;
    esac
}

engagement_template() {
    printf '%s\n' \
        '# ENGAGEMENT.md' \
        '<!-- Local file. Excluded from Git in .git/info/exclude. Do not commit or share it. -->' \
        'Customer mode is active. The rules are in the "Customer mode" section of the harness AGENTS.md.' \
        '' \
        '## Client' \
        "- Client: $1" \
        '- Goal: <deliverable and acceptance criteria>' \
        '' \
        '## Models' \
        "- Allowed providers: $2" \
        '- Model notes: <contract terms, hosting (direct API, Bedrock, Vertex, Azure), region, retention, or "none">' \
        '' \
        '## Data' \
        '- Customer data in this repository: <none, test data, or production data>' \
        '- Do not send code or data to: <services, or "none">' \
        '' \
        '## Environments' \
        '- Allowed to change: <for example local, dev>' \
        '- Read-only: <for example staging, prod>' \
        '- Never touch: <systems or paths, or "none">' \
        '' \
        '## Conventions' \
        '- Package manager: <tool>' \
        '- Commit format: <format, or "follow git log">' \
        '- Branch flow: <flow>' \
        '- Full check: <command, or "none">' \
        '' \
        '## Decisions' \
        '<!-- One line each: YYYY-MM-DD: decision. Reason. -->'
}

# Parse all options first, like fish argparse: an invalid option fails before --help.
FLAG_HELP=
FLAG_AGENTS=
FLAG_CLIENT=
CLIENT_NAME=
PROVIDER_ARGS=()
POSITIONAL=()
STACK_FLAGS=()
while [ $# -gt 0 ]; do
    case $1 in
    -h | --help) FLAG_HELP=1 ;;
    -a | --agents) FLAG_AGENTS=1 ;;
    --py | --python) STACK_FLAGS+=(python) ;;
    --go | --java | --node | --terraform | --docker | --sql) STACK_FLAGS+=("${1#--}") ;;
    --web) STACK_FLAGS+=(node web) ;;
    --client=*) FLAG_CLIENT=1 CLIENT_NAME=${1#*=} ;;
    --client)
        [ $# -ge 2 ] || error 'invalid option (use --help)'
        FLAG_CLIENT=1 CLIENT_NAME=$2
        shift
        ;;
    --provider=*) PROVIDER_ARGS+=("${1#*=}") ;;
    --provider)
        [ $# -ge 2 ] || error 'invalid option (use --help)'
        PROVIDER_ARGS+=("$2")
        shift
        ;;
    --)
        shift
        POSITIONAL+=("$@")
        break
        ;;
    -?*)
        printf '%s: %s: unknown option\n' "$SCRIPT_NAME" "$1" >&2
        error 'invalid option (use --help)'
        ;;
    *) POSITIONAL+=("$1") ;;
    esac
    shift
done

if [ -n "$FLAG_HELP" ]; then
    usage
    exit 0
fi
[ ${#POSITIONAL[@]} -gt 0 ] && error "unexpected argument: ${POSITIONAL[0]} (use --help)"

if [ -n "$FLAG_CLIENT" ]; then
    TARGET=ENGAGEMENT.md
    [ -n "$CLIENT_NAME" ] || error '--client needs a name'
else
    TARGET=AGENTS.md
    [ ${#PROVIDER_ARGS[@]} -gt 0 ] && error '--provider needs --client'
fi

PROVIDERS=()
for item in ${PROVIDER_ARGS[@]+"${PROVIDER_ARGS[@]}"}; do
    # Split on commas and keep empty fields, so "anthropic," fails like in fish.
    rest="$item,"
    while [ -n "$rest" ]; do
        p=${rest%%,*}
        rest=${rest#*,}
        p=${p#"${p%%[![:space:]]*}"}
        p=${p%"${p##*[![:space:]]}"}
        contains "$p" anthropic openai || error "unknown provider: $p (use anthropic or openai)"
        contains "$p" ${PROVIDERS[@]+"${PROVIDERS[@]}"} || PROVIDERS+=("$p")
    done
done

if [ -n "${AGENTS_SRC:-}" ]; then
    SRC=$AGENTS_SRC
else
    # The script is in bin/. The harness root is one level up. Follow symlinks (no readlink -f on old macOS).
    script=$0
    while [ -L "$script" ]; do
        dir=$(cd -P "$(dirname "$script")" && pwd)
        script=$(readlink "$script")
        case $script in
        /*) ;;
        *) script=$dir/$script ;;
        esac
    done
    SRC=$(cd -P "$(dirname "$script")/.." && pwd)
fi
[ -d "$SRC" ] || error "source directory does not exist: $SRC"
SRC=$(cd -P "$SRC" && pwd)
PROJECT_DIR=$(pwd -P)

[ ${#STACK_FLAGS[@]} -gt 0 ] && add_stack "${STACK_FLAGS[@]}"

# Detect from lockfiles and manifests. A new project has a manifest before it has a lockfile.
if [ ${#SELECTED[@]} -eq 0 ]; then
    any_file uv.lock pyproject.toml && add_stack python
    [ -f go.mod ] && add_stack go
    any_file pom.xml build.gradle build.gradle.kts settings.gradle settings.gradle.kts && add_stack java
    any_file pnpm-lock.yaml package.json && add_stack node
    web_configs=(astro.config.* vite.config.*)
    [ ${#web_configs[@]} -gt 0 ] && add_stack node web
    tf_files=(*.tf)
    [ ${#tf_files[@]} -gt 0 ] && add_stack terraform
    any_file Dockerfile ./*.Dockerfile compose.yaml compose.yml docker-compose.yaml docker-compose.yml && add_stack docker
    if any_file .sqlfluff flyway.toml flyway.conf liquibase.properties alembic.ini schema.prisma || any_dir migrations prisma; then
        add_stack sql
    fi

    if [ ${#SELECTED[@]} -gt 0 ]; then
        echo "Detected stacks: ${SELECTED[*]}"
    else
        echo 'No stack detected. Use a stack option (see --help) to select one.'
    fi
fi

# Normalize stack order so output and generated files are deterministic.
STACKS=()
for c in "${ALL_STACKS[@]}"; do
    contains "$c" ${SELECTED[@]+"${SELECTED[@]}"} && STACKS+=("$c")
done

# Detect technology skills from manifests. Lockfiles are not read: they list transitive dependencies.
# shortcut: only the current directory is scanned, like stack detection; run again in each subproject of a monorepo.
manifests=()
# Terraform files count too: providers and resource types name the technology (azurerm_redis_cache).
for f in package.json pyproject.toml requirements*.txt go.mod pom.xml build.gradle build.gradle.kts \
    compose.yaml compose.yml docker-compose.yaml docker-compose.yml *.tf; do
    [ -f "$f" ] && manifests+=("$f")
done
if [ ${#manifests[@]} -gt 0 ]; then
    # Indirect Go dependencies are not used by the project code.
    # Full-line comments (#, //) are not dependencies, for example in Terraform and requirements files.
    deps=$(cat "${manifests[@]}" | grep -vF '// indirect' | grep -vE '^[[:space:]]*(#|//)')
    for i in "${!TECH_NAMES[@]}"; do
        [ -n "${TECH_PATTERNS[$i]}" ] || continue
        printf '%s\n' "$deps" | grep -qiE -- "${TECH_PATTERNS[$i]}" && add_tech "${TECH_NAMES[$i]}"
    done
fi
# Prisma: read only the datasource provider line. Model names and comments are not dependencies.
for f in schema.prisma prisma/schema.prisma prisma/schema/*.prisma; do
    [ -f "$f" ] && grep -qE '^[[:space:]]*provider[[:space:]]*=[[:space:]]*"postgres(ql)?"' "$f" && add_tech postgres
done
[ -f tsconfig.json ] && add_tech typescript
if any_file Chart.yaml kustomization.yaml kustomization.yml skaffold.yaml || any_dir k8s kubernetes helm charts; then
    add_tech kubernetes
fi
alloy_files=(*.alloy)
if [ ${#alloy_files[@]} -gt 0 ] || any_file prometheus.yml prometheus.yaml; then
    add_tech grafana
fi
TECHS=()
for t in "${TECH_NAMES[@]}"; do
    contains "$t" ${FOUND_TECHS[@]+"${FOUND_TECHS[@]}"} && TECHS+=("$t")
done
[ ${#TECHS[@]} -gt 0 ] && echo "Detected technology skills: ${TECHS[*]}"

# Validate every source and destination before making changes.
command -v git >/dev/null 2>&1 || error 'git is required but was not found in PATH'

for stack in ${STACKS[@]+"${STACKS[@]}"}; do
    stack_file=$SRC/stacks/$stack.md
    [ -f "$stack_file" ] && [ -s "$stack_file" ] || error "missing or empty stack file: $stack_file"
    case $(head -n 1 "$stack_file") in
    '## Stack:'*) ;;
    *) error "$stack_file must start with '## Stack:'" ;;
    esac
done
for t in ${TECHS[@]+"${TECHS[@]}"}; do
    [ -f "$SRC/skills/harness-$t/SKILL.md" ] || error "missing skill file: $SRC/skills/harness-$t/SKILL.md"
done

if [ -n "$FLAG_AGENTS" ]; then
    [ -f "$SRC/AGENTS.md" ] || error "missing source file: $SRC/AGENTS.md"
    [ "$SRC" != "$PROJECT_DIR" ] || error '--agents cannot link .agents to the project directory itself'
fi

if [ -n "$FLAG_CLIENT" ]; then
    # Without Git, the local exclude cannot keep ENGAGEMENT.md out of commits.
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || error '--client must run inside the customer Git repository'
    [ -L ENGAGEMENT.md ] && error 'ENGAGEMENT.md is a symlink; refusing to modify its target'
    if [ -e ENGAGEMENT.md ] && [ ! -f ENGAGEMENT.md ]; then
        error 'ENGAGEMENT.md exists but is not a regular file'
    fi
else
    [ -L .gitignore ] && error '.gitignore is a symlink; refusing to modify its target'
    if [ -e .gitignore ] && [ ! -f .gitignore ]; then
        error '.gitignore exists but is not a regular file'
    fi
    if [ -L AGENTS.md ]; then
        if [ ${#STACKS[@]} -gt 0 ] || [ ${#TECHS[@]} -gt 0 ]; then
            warn 'AGENTS.md is a symlink; stack sections and skill lines will not be written to the shared file'
        fi
    elif [ -e AGENTS.md ] && [ ! -f AGENTS.md ]; then
        error 'AGENTS.md exists but is not a regular file'
    fi
fi

if [ -n "$FLAG_CLIENT" ]; then
    if [ -e ENGAGEMENT.md ]; then
        echo 'ENGAGEMENT.md: present, skip'
    else
        providers='<anthropic, openai, or both>'
        if [ ${#PROVIDERS[@]} -gt 0 ]; then
            providers=$(printf '%s, ' "${PROVIDERS[@]}")
            providers=${providers%, }
        fi
        engagement_template "$CLIENT_NAME" "$providers" >ENGAGEMENT.md || error 'cannot create ENGAGEMENT.md'
        echo 'ENGAGEMENT.md: created'
    fi
    exclude_locally ENGAGEMENT.md
    if git ls-files --error-unmatch ENGAGEMENT.md >/dev/null 2>&1; then
        warn 'ENGAGEMENT.md is tracked by Git, so the exclude does not hide it. Run: git rm --cached ENGAGEMENT.md'
    fi
else
    # Initialize Git only when the current directory is not already in a worktree.
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        toplevel=$(git rev-parse --show-toplevel)
        if [ "$toplevel" != "$PROJECT_DIR" ]; then
            warn "directory is inside another repository ($toplevel); git init skipped"
        else
            echo 'git: worktree exists, skip init'
        fi
    else
        git init || error 'git init failed'
    fi

    # Add the base block even when .gitignore already contains user rules.
    # Existing content is never replaced. Marker checks make repeated runs idempotent.
    [ -e .gitignore ] || touch .gitignore || error 'cannot create .gitignore'
    for stack in base ${STACKS[@]+"${STACKS[@]}"}; do
        block=$(gitignore_block "$stack")
        [ -n "$block" ] || continue
        if grep -qxF -- "${block%%$'\n'*}" .gitignore; then
            printf '.gitignore: %s present, skip\n' "$stack"
        else
            if [ -s .gitignore ]; then
                printf '\n' >>.gitignore
            fi
            printf '%s\n' "$block" >>.gitignore || error 'cannot write .gitignore'
            printf '.gitignore: added %s\n' "$stack"
        fi
    done

    if { [ ${#STACKS[@]} -gt 0 ] || [ ${#TECHS[@]} -gt 0 ]; } && [ ! -e AGENTS.md ]; then
        printf '%s\n' \
            '# AGENTS.md' \
            '' \
            '## Project' \
            '- Purpose: <one line>' \
            '- Layout: <directory = stack, for example api/ = Go, web/ = Astro, tools/ = Python>' \
            '- Do not touch: <generated or vendored paths>' \
            '- Full check: <command, for example make check>' \
            '' \
            'Run each stack command in the directory of that stack.' \
            'Run checks only for the stacks that you changed.' >AGENTS.md || error 'cannot create AGENTS.md'
        echo 'AGENTS.md: created'
    fi
fi

# Add stack instructions without replacing existing content.
if [ ${#STACKS[@]} -gt 0 ] && [ ! -L "$TARGET" ]; then
    for stack in "${STACKS[@]}"; do
        marker="<!-- stack:$stack -->"
        heading=$(head -n 1 "$SRC/stacks/$stack.md")
        if grep -qxF -- "$marker" "$TARGET" || grep -qxF -- "$heading" "$TARGET"; then
            printf '%s: %s present, skip\n' "$TARGET" "$stack"
        else
            {
                printf '\n%s\n' "$marker"
                awk 1 "$SRC/stacks/$stack.md"
            } >>"$TARGET" || error "cannot write $TARGET"
            if [ -n "$FLAG_CLIENT" ]; then
                printf '%s: added %s\n' "$TARGET" "$stack"
            else
                printf '%s: added %s. Update the Layout line.\n' "$TARGET" "$stack"
            fi
        fi
    done
fi

# List the technology skills, one self-contained line each, so the agent loads them.
# A rerun appends only missing lines, and each line stays correct wherever it lands.
if [ ${#TECHS[@]} -gt 0 ] && [ -f "$TARGET" ] && [ ! -L "$TARGET" ]; then
    marker='<!-- harness-skills -->'
    if ! grep -qxF -- "$marker" "$TARGET"; then
        printf '\n%s\n%s\n' "$marker" '## Technology skills' >>"$TARGET" || error "cannot write $TARGET"
    fi
    for i in "${!TECH_NAMES[@]}"; do
        contains "${TECH_NAMES[$i]}" "${TECHS[@]}" || continue
        skill=harness-${TECH_NAMES[$i]}
        if grep -qF -- "\`$skill\`" "$TARGET"; then
            printf '%s: %s present, skip\n' "$TARGET" "$skill"
        else
            # shellcheck disable=SC2016 # the backticks are Markdown, not a command
            printf -- '- This project uses %s. Load `%s` before you change code that uses it.\n' \
                "${TECH_LABELS[$i]}" "$skill" >>"$TARGET" || error "cannot write $TARGET"
            printf '%s: added %s\n' "$TARGET" "$skill"
        fi
    done
fi

# Create the optional local link. Do not hide an unrelated existing .agents path.
if [ -n "$FLAG_AGENTS" ]; then
    if [ -L .agents ]; then
        if [ "$(cd -P .agents 2>/dev/null && pwd)" = "$SRC" ]; then
            echo 'link: .agents already points to the source directory'
            exclude_locally .agents
        else
            warn '.agents already exists as a different symlink; leaving it unchanged and not changing Git excludes'
        fi
    elif [ -e .agents ]; then
        warn '.agents already exists and is not a symlink; leaving it unchanged and not changing Git excludes'
    else
        ln -s "$SRC" .agents || error 'cannot create .agents link'
        echo "link: .agents -> $SRC"
        exclude_locally .agents
    fi
fi

# Report the template placeholders that are still unfilled.
if [ -n "$FLAG_CLIENT" ]; then
    placeholder_re='^- [^:]+: <'
else
    placeholder_re='^- (Purpose|Layout|Do not touch|Full check): <'
fi
if [ -f "$TARGET" ] && [ ! -L "$TARGET" ] && grep -qE "$placeholder_re" "$TARGET"; then
    echo ---
    if [ -n "$FLAG_CLIENT" ]; then
        echo 'TODO: fill in ENGAGEMENT.md. The agent stops while "Allowed providers" is a placeholder.'
    else
        printf '%s\n' \
            'TODO: fill in the placeholders in AGENTS.md (section "## Project"):' \
            '  Purpose:       one sentence about the project' \
            '  Layout:        directory = stack. Example: root = Go (go.mod); web/ = Astro (pnpm)' \
            '  Do not touch:  generated or vendored paths, or "none"' \
            '  Full check:    one command, for example "make check", or "none"' \
            'Do not keep "<...>" as project values.'
    fi
    echo 'Lines to fix:'
    grep -nE "$placeholder_re" "$TARGET"
fi

echo ---
git status --short
