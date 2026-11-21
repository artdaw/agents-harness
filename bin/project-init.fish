#!/usr/bin/env fish
# project-init: set up the agent harness in a project.
# Own project:      initialize Git, add .gitignore blocks and stack sections to AGENTS.md.
# Customer project: --client creates a local ENGAGEMENT.md (excluded from Git) and adds the
#                   stack sections there. The customer's files are not changed.
# Safe to run again: existing files and sections are preserved.
# Requires fish >= 3.5 (for the `path` builtin).

set -g SCRIPT_NAME (path basename (status filename))
# Order of stack sections in generated files.
set -g ALL_STACKS python go java node web terraform docker sql
# Technology skills (skills/harness-<name>), in output order. A pattern matches manifest text;
# an empty pattern means detection by files only (see below).
set -g TECH_NAMES postgres temporal kafka redis kubernetes langchain datadog react typescript tailwind tanstack
set -g TECH_LABELS PostgreSQL Temporal Kafka Redis Kubernetes LangChain Datadog React TypeScript Tailwind TanStack
set -g TECH_PATTERNS 'postgres|psycopg|asyncpg|"pg"|jackc/pgx|lib/pq' 'temporalio|go\.temporal\.io|io\.temporal' \
    'kafka|sarama' 'redis|valkey' '' 'langchain|langgraph' 'ddtrace|dd-trace|datadog' '"react"' '"typescript"' \
    'tailwindcss' '@tanstack/'

function usage
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
end

# fish has no `set -e`: every step that can fail is checked with `or error`.
function error
    printf 'ERROR: %s\n' "$argv" >&2
    exit 1
end

function warn
    printf 'WARN: %s\n' "$argv" >&2
end

# Add a line to .git/info/exclude (local only, not committed). Idempotent.
function exclude_locally
    set -l file (git rev-parse --git-path info/exclude); or error 'cannot locate .git/info/exclude'
    mkdir -p (path dirname $file); and touch $file; or error "cannot write $file"
    grep -Fxq -- $argv[1] $file; or printf '%s\n' $argv[1] >>$file
end

function add_stack
    for s in $argv
        contains -- $s $SELECTED; or set -ga SELECTED $s
    end
end

function add_tech
    contains -- $argv[1] $FOUND_TECHS; or set -ga FOUND_TECHS $argv[1]
end

# The first line of each block is its marker, used to detect existing blocks.
# Stacks without ignore rules (docker, sql) print nothing.
function gitignore_block
    switch $argv[1]
        case base
            printf '%s\n' \
                '# ---- macOS ----' '.DS_Store' '.AppleDouble' '.LSOverride' '._*' '.Spotlight-V100' '.Trashes' \
                '' '# ---- Editors / IDE ----' '.idea/' '*.iml' '.vscode/*' '!.vscode/settings.json' \
                '!.vscode/extensions.json' '!.vscode/launch.json' '*.swp' '*.swo' '*~' \
                '' '# ---- Secrets and local env ----' '.env' '.env.*' '!.env.example' '*.pem' '*.key' '*.p12' \
                'secrets/' '*.local' \
                '' '# ---- Logs and temp ----' '*.log' 'logs/' 'tmp/' '.tmp/' '.cache/'
        case python
            printf '%s\n' \
                '# ---- Python (uv, ruff, pytest) ----' '__pycache__/' '*.py[cod]' '.venv/' 'venv/' \
                '.pytest_cache/' '.ruff_cache/' '.mypy_cache/' '.pyright/' '.coverage' '.coverage.*' \
                'coverage.xml' 'htmlcov/' '*.egg-info/' '.eggs/' 'build/' 'dist/' \
                '# Commit uv.lock. Do not ignore it.'
        case go
            printf '%s\n' \
                '# ---- Go ----' '/bin/' '*.exe' '*.test' '*.out' 'coverage.out' 'coverage.html' 'go.work.sum' \
                '# Commit go.sum. Do not ignore it.'
        case java
            printf '%s\n' \
                '# ---- Java (Maven, Gradle) ----' 'target/' 'build/' '.gradle/' 'out/' '*.class' \
                'hs_err_pid*' 'replay_pid*' \
                '# Commit the Maven and Gradle wrappers (mvnw, gradlew, gradle/wrapper/). Do not ignore them.'
        case node
            printf '%s\n' \
                '# ---- Node / pnpm ----' 'node_modules/' '.pnpm-store/' '.pnpm-debug.log*' 'npm-debug.log*' \
                'yarn-debug.log*' 'yarn-error.log*' '*.tsbuildinfo' '.eslintcache' '.npm/' 'dist/' 'coverage/' \
                '# Commit pnpm-lock.yaml. Do not ignore it.'
        case web
            printf '%s\n' \
                '# ---- Web (React, Vite, Astro, Tailwind) ----' '.astro/' '.vite/' '.turbo/' '.output/' \
                'storybook-static/' 'playwright-report/' 'test-results/'
        case terraform
            printf '%s\n' \
                '# ---- Terraform / OpenTofu ----' '.terraform/' '*.tfstate' '*.tfstate.*' '*.tfplan' \
                'crash.log' 'crash.*.log' '*.tfvars' '*.tfvars.json' 'override.tf' 'override.tf.json' \
                '*_override.tf' '*_override.tf.json' '.terraformrc' 'terraform.rc' \
                '# Commit .terraform.lock.hcl. Do not ignore it.' \
                '# *.tfvars can hold secrets. Add a non-secret one with: git add -f <file>'
    end
end

function engagement_template
    printf '%s\n' \
        '# ENGAGEMENT.md' \
        '<!-- Local file. Excluded from Git in .git/info/exclude. Do not commit or share it. -->' \
        'Customer mode is active. The rules are in the "Customer mode" section of the harness AGENTS.md.' \
        '' \
        '## Client' \
        "- Client: $argv[1]" \
        '- Goal: <deliverable and acceptance criteria>' \
        '' \
        '## Models' \
        "- Allowed providers: $argv[2]" \
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
end

argparse h/help a/agents py python go java node web terraform docker sql 'client=' 'provider=+' -- $argv
or error 'invalid option (use --help)'

if set -q _flag_help
    usage
    exit 0
end
set -q argv[1]; and error "unexpected argument: $argv[1] (use --help)"

if set -q _flag_client
    set -g TARGET ENGAGEMENT.md
    test -n "$_flag_client"; or error '--client needs a name'
else
    set -g TARGET AGENTS.md
    set -q _flag_provider; and error '--provider needs --client'
end

set -g PROVIDERS
for item in $_flag_provider
    for p in (string split , -- $item | string trim)
        contains -- $p anthropic openai; or error "unknown provider: $p (use anthropic or openai)"
        contains -- $p $PROVIDERS; or set -ga PROVIDERS $p
    end
end

if test -n "$AGENTS_SRC"
    set -g SRC $AGENTS_SRC
else
    # The script is in bin/. The harness root is one level up.
    set -g SRC (path dirname (path dirname (path resolve (status filename))))
end
test -d "$SRC"; or error "source directory does not exist: $SRC"
set SRC (path resolve $SRC)
set -g PROJECT_DIR (pwd -P)

set -g SELECTED
if set -q _flag_py; or set -q _flag_python
    add_stack python
end
set -q _flag_go; and add_stack go
set -q _flag_java; and add_stack java
set -q _flag_node; and add_stack node
set -q _flag_web; and add_stack node web
set -q _flag_terraform; and add_stack terraform
set -q _flag_docker; and add_stack docker
set -q _flag_sql; and add_stack sql

# Detect from lockfiles and manifests. A new project has a manifest before it has a lockfile.
if not set -q SELECTED[1]
    # A glob without matches expands to nothing inside `set` (no error).
    test (count (path filter -f uv.lock pyproject.toml)) -gt 0; and add_stack python
    test -f go.mod; and add_stack go
    test (count (path filter -f pom.xml build.gradle build.gradle.kts settings.gradle settings.gradle.kts)) -gt 0; and add_stack java
    test (count (path filter -f pnpm-lock.yaml package.json)) -gt 0; and add_stack node
    set -l web_configs astro.config.* vite.config.*
    set -q web_configs[1]; and add_stack node web
    set -l tf_files *.tf
    set -q tf_files[1]; and add_stack terraform
    set -l docker_files Dockerfile *.Dockerfile compose.yaml compose.yml docker-compose.yaml docker-compose.yml
    test (count (path filter -f $docker_files)) -gt 0; and add_stack docker
    if test (count (path filter -f .sqlfluff flyway.toml flyway.conf liquibase.properties alembic.ini schema.prisma)) -gt 0; or test -d migrations; or test -d prisma
        add_stack sql
    end

    if set -q SELECTED[1]
        echo "Detected stacks: $SELECTED"
    else
        echo 'No stack detected. Use a stack option (see --help) to select one.'
    end
end

# Normalize stack order so output and generated files are deterministic.
set -g STACKS
for c in $ALL_STACKS
    contains -- $c $SELECTED; and set -ga STACKS $c
end

# Detect technology skills from manifests. Lockfiles are not read: they list transitive dependencies.
# shortcut: only the current directory is scanned, like stack detection; run again in each subproject of a monorepo.
set -g FOUND_TECHS
set -l manifests package.json pyproject.toml requirements*.txt go.mod pom.xml build.gradle build.gradle.kts \
    compose.yaml compose.yml docker-compose.yaml docker-compose.yml
set manifests (path filter -f $manifests)
if set -q manifests[1]
    # Indirect Go dependencies are not used by the project code.
    set -l deps (cat $manifests | string match -v -- '*// indirect*')
    for i in (seq (count $TECH_NAMES))
        test -n "$TECH_PATTERNS[$i]"; or continue
        printf '%s\n' $deps | grep -qiE -- $TECH_PATTERNS[$i]; and add_tech $TECH_NAMES[$i]
    end
end
# Prisma: read only the datasource provider line. Model names and comments are not dependencies.
set -l prisma_files schema.prisma prisma/schema.prisma prisma/schema/*.prisma
for f in (path filter -f $prisma_files)
    grep -qE '^[[:space:]]*provider[[:space:]]*=[[:space:]]*"postgres(ql)?"' $f; and add_tech postgres
end
test -f tsconfig.json; and add_tech typescript
if test (count (path filter -f Chart.yaml kustomization.yaml kustomization.yml skaffold.yaml)) -gt 0
    or test (count (path filter -d k8s kubernetes helm charts)) -gt 0
    add_tech kubernetes
end
set -g TECHS
for t in $TECH_NAMES
    contains -- $t $FOUND_TECHS; and set -ga TECHS $t
end
set -q TECHS[1]; and echo "Detected technology skills: $TECHS"

# Validate every source and destination before making changes.
command -q git; or error 'git is required but was not found in PATH'

for stack in $STACKS
    set -l stack_file $SRC/stacks/$stack.md
    test -f $stack_file -a -s $stack_file; or error "missing or empty stack file: $stack_file"
    string match -q -- '## Stack:*' (head -n 1 $stack_file); or error "$stack_file must start with '## Stack:'"
end
for t in $TECHS
    test -f $SRC/skills/harness-$t/SKILL.md; or error "missing skill file: $SRC/skills/harness-$t/SKILL.md"
end

if set -q _flag_agents
    test -f $SRC/AGENTS.md; or error "missing source file: $SRC/AGENTS.md"
    test "$SRC" != "$PROJECT_DIR"; or error '--agents cannot link .agents to the project directory itself'
end

if set -q _flag_client
    # Without Git, the local exclude cannot keep ENGAGEMENT.md out of commits.
    git rev-parse --is-inside-work-tree >/dev/null 2>&1; or error '--client must run inside the customer Git repository'
    test -L ENGAGEMENT.md; and error 'ENGAGEMENT.md is a symlink; refusing to modify its target'
    if test -e ENGAGEMENT.md -a ! -f ENGAGEMENT.md
        error 'ENGAGEMENT.md exists but is not a regular file'
    end
else
    test -L .gitignore; and error '.gitignore is a symlink; refusing to modify its target'
    if test -e .gitignore -a ! -f .gitignore
        error '.gitignore exists but is not a regular file'
    end
    if test -L AGENTS.md
        if set -q STACKS[1]; or set -q TECHS[1]
            warn 'AGENTS.md is a symlink; stack sections and skill lines will not be written to the shared file'
        end
    else if test -e AGENTS.md -a ! -f AGENTS.md
        error 'AGENTS.md exists but is not a regular file'
    end
end

if set -q _flag_client
    if test -e ENGAGEMENT.md
        echo 'ENGAGEMENT.md: present, skip'
    else
        set -l providers '<anthropic, openai, or both>'
        set -q PROVIDERS[1]; and set providers (string join ', ' $PROVIDERS)
        engagement_template $_flag_client $providers >ENGAGEMENT.md; or error 'cannot create ENGAGEMENT.md'
        echo 'ENGAGEMENT.md: created'
    end
    exclude_locally ENGAGEMENT.md
    if git ls-files --error-unmatch ENGAGEMENT.md >/dev/null 2>&1
        warn 'ENGAGEMENT.md is tracked by Git, so the exclude does not hide it. Run: git rm --cached ENGAGEMENT.md'
    end
else
    # Initialize Git only when the current directory is not already in a worktree.
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l toplevel (git rev-parse --show-toplevel)
        if test "$toplevel" != "$PROJECT_DIR"
            warn "directory is inside another repository ($toplevel); git init skipped"
        else
            echo 'git: worktree exists, skip init'
        end
    else
        git init; or error 'git init failed'
    end

    # Add the base block even when .gitignore already contains user rules.
    # Existing content is never replaced. Marker checks make repeated runs idempotent.
    test -e .gitignore; or touch .gitignore; or error 'cannot create .gitignore'
    for stack in base $STACKS
        set -l block (gitignore_block $stack)
        set -q block[1]; or continue
        if grep -qxF -- $block[1] .gitignore
            printf '.gitignore: %s present, skip\n' $stack
        else
            if test -s .gitignore
                printf '\n' >>.gitignore
            end
            printf '%s\n' $block >>.gitignore; or error 'cannot write .gitignore'
            printf '.gitignore: added %s\n' $stack
        end
    end

    if set -q STACKS[1]; or set -q TECHS[1]; and not test -e AGENTS.md
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
            'Run checks only for the stacks that you changed.' >AGENTS.md; or error 'cannot create AGENTS.md'
        echo 'AGENTS.md: created'
    end
end

# Add stack instructions without replacing existing content.
if set -q STACKS[1]; and not test -L $TARGET
    for stack in $STACKS
        set -l marker "<!-- stack:$stack -->"
        set -l heading (head -n 1 $SRC/stacks/$stack.md)
        if grep -qxF -- $marker $TARGET; or grep -qxF -- $heading $TARGET
            printf '%s: %s present, skip\n' $TARGET $stack
        else
            begin
                printf '\n%s\n' $marker
                awk 1 $SRC/stacks/$stack.md
            end >>$TARGET; or error "cannot write $TARGET"
            if set -q _flag_client
                printf '%s: added %s\n' $TARGET $stack
            else
                printf '%s: added %s. Update the Layout line.\n' $TARGET $stack
            end
        end
    end
end

# List the technology skills, one self-contained line each, so the agent loads them.
# A rerun appends only missing lines, and each line stays correct wherever it lands.
if set -q TECHS[1]; and test -f $TARGET -a ! -L $TARGET
    set -l marker '<!-- harness-skills -->'
    if not grep -qxF -- $marker $TARGET
        printf '\n%s\n%s\n' $marker '## Technology skills' >>$TARGET; or error "cannot write $TARGET"
    end
    for i in (seq (count $TECH_NAMES))
        contains -- $TECH_NAMES[$i] $TECHS; or continue
        set -l skill harness-$TECH_NAMES[$i]
        if grep -qF -- "`$skill`" $TARGET
            printf '%s: %s present, skip\n' $TARGET $skill
        else
            printf '- This project uses %s. Load `%s` before you change code that uses it.\n' \
                $TECH_LABELS[$i] $skill >>$TARGET; or error "cannot write $TARGET"
            printf '%s: added %s\n' $TARGET $skill
        end
    end
end

# Create the optional local link. Do not hide an unrelated existing .agents path.
if set -q _flag_agents
    if test -L .agents
        if test (path resolve .agents) = "$SRC"
            echo 'link: .agents already points to the source directory'
            exclude_locally .agents
        else
            warn '.agents already exists as a different symlink; leaving it unchanged and not changing Git excludes'
        end
    else if test -e .agents
        warn '.agents already exists and is not a symlink; leaving it unchanged and not changing Git excludes'
    else
        ln -s $SRC .agents; or error 'cannot create .agents link'
        echo "link: .agents -> $SRC"
        exclude_locally .agents
    end
end

# Report the template placeholders that are still unfilled.
if set -q _flag_client
    set -g placeholder_re '^- [^:]+: <'
else
    set -g placeholder_re '^- (Purpose|Layout|Do not touch|Full check): <'
end
if test -f $TARGET -a ! -L $TARGET; and grep -qE $placeholder_re $TARGET
    echo ---
    if set -q _flag_client
        echo 'TODO: fill in ENGAGEMENT.md. The agent stops while "Allowed providers" is a placeholder.'
    else
        printf '%s\n' \
            'TODO: fill in the placeholders in AGENTS.md (section "## Project"):' \
            '  Purpose:       one sentence about the project' \
            '  Layout:        directory = stack. Example: root = Go (go.mod); web/ = Astro (pnpm)' \
            '  Do not touch:  generated or vendored paths, or "none"' \
            '  Full check:    one command, for example "make check", or "none"' \
            'Do not keep "<...>" as project values.'
    end
    echo 'Lines to fix:'
    grep -nE $placeholder_re $TARGET
end

echo ---
git status --short
