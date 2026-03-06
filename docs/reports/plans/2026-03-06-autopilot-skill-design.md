# Architecture Design: Autopilot Skill

- **Date**: 2026-03-06
- **Author**: architect
- **Status**: PROPOSED
- **Approved/Rejected By**: (pending)

---

## 1. Architecture Overview

### Problem Statement

The Agent Army system currently operates in **single-shot mode**: the user invokes `/assemble` or `/sprint`, agents execute one round of work, and then stop. The user must manually review results, decide the next task, and invoke again. For large projects with 10-50 tasks, this manual loop becomes the bottleneck.

**Autopilot** solves this by wrapping the Claude CLI in a **bash outer loop** that continuously reads from a structured backlog, picks the next task, launches a Claude session to execute it, and repeats until the backlog is empty or a safety limit is reached.

### Two-Layer Architecture

```
Layer 1: SKILL.md (Claude-facing)
  - Parsed by Claude when user invokes /autopilot
  - Instructs Claude to create BACKLOG.md, configure, and launch the bash script
  - Claude NEVER runs autonomously itself — it delegates to the bash loop

Layer 2: autopilot.sh (Bash outer loop)
  - Standalone bash script executed by Claude via Bash tool
  - Creates tmux session for background execution
  - while loop: read BACKLOG.md -> pick task -> claude -p -> checkpoint -> repeat
  - Enforces safety limits, logging, graceful shutdown
  - Each iteration is a FRESH Claude session (no context accumulation)
```

### Component Diagram

```
User
  |
  v
/autopilot init "build auth module"
  |
  v
+------------------+
| SKILL.md         |  Claude reads this skill definition
| (Claude-facing)  |  and follows the instructions to:
+------------------+  1. Create BACKLOG.md with tasks
  |                    2. Create config.json with limits
  |                    3. Launch autopilot.sh via Bash
  v
+------------------+     +------------------+
| autopilot.sh     |---->| tmux session     |
| (Bash loop)      |     | autopilot-{proj} |
+------------------+     +------------------+
  |                              |
  | while loop                   | runs in background
  v                              v
+------------------+     +------------------+
| Read BACKLOG.md  |     | Logging          |
| Pick next task   |     | .claude/autopilot|
| Build prompt     |     |   /logs/         |
+------------------+     +------------------+
  |
  v
+------------------+
| claude -p        |  Fresh CLI session per iteration
|   --print        |  Non-interactive mode
|   --max-budget   |  Per-iteration cost cap
|   --model        |  Configurable model
+------------------+
  |
  v
+------------------+     +------------------+
| Inner session    |     | Git checkpoint   |
| executes task    |     | between iters    |
| (may use skills) |     +------------------+
+------------------+
  |
  v
+------------------+
| Update BACKLOG   |
| Append progress  |
| Check limits     |
+------------------+
  |
  v
[Next iteration or STOP]
```

### Data Flow (per iteration)

```
1. autopilot.sh reads BACKLOG.md
2. Finds first task with status "pending"
3. Constructs prompt with: task description + project context + progress.txt tail
4. Invokes: claude -p --max-budget-usd $PER_ITER_BUDGET --model $MODEL "$PROMPT"
5. Claude executes the task (writes code, runs tests, etc.)
6. autopilot.sh captures exit code
7. If success: marks task "done" in BACKLOG.md, git add + commit
8. If failure: marks task "failed" in BACKLOG.md, logs error, increments retry count
9. Appends iteration summary to progress.txt
10. Checks safety limits (iterations, cost, duration)
11. Sleeps for cooldown period
12. Repeats from step 1
```

---

## 2. Detailed SKILL.md Structure

The SKILL.md follows the established pattern from existing skills (frontmatter + phased instructions).

### Frontmatter

```yaml
---
name: autopilot
description: >
  Continuous autonomous iteration orchestrator. Creates a structured backlog,
  launches a tmux-based outer loop that repeatedly invokes Claude CLI to work
  through tasks. Supports init, start, stop, status, and resume commands.
  Includes safety limits (max iterations, cost, duration) and git checkpoints.
---
```

### Command Interface

```
/autopilot init [backlog-description]   -- Create BACKLOG.md from description
/autopilot start [--flags]              -- Launch tmux outer loop
/autopilot stop                         -- Graceful shutdown
/autopilot status                       -- Show progress summary
/autopilot resume                       -- Resume from last state
```

### Phase Structure in SKILL.md

```
Phase 0: Argument Parsing
  - Parse $ARGUMENTS for subcommand (init|start|stop|status|resume)
  - Route to appropriate phase

Phase 1: Init (when subcommand = "init")
  - Analyze the backlog description from $ARGUMENTS
  - Explore codebase (Read, Grep, Glob) to understand scope
  - Decompose into 5-30 atomic tasks with clear acceptance criteria
  - Write BACKLOG.md to project root
  - Write .claude/autopilot/config.json with default limits
  - Output: task count, estimated effort

Phase 2: Start (when subcommand = "start")
  - Verify BACKLOG.md exists
  - Verify .claude/autopilot/config.json exists
  - Parse --flags to override config defaults
  - Check for existing tmux session (prevent double-launch)
  - Verify autopilot.sh exists; if not, create it
  - Launch: bash .claude/autopilot/autopilot.sh start
  - Output: tmux session name, how to attach, how to stop

Phase 3: Stop (when subcommand = "stop")
  - Send graceful stop signal: touch .claude/autopilot/STOP
  - Output: confirmation message
  - Note: autopilot.sh checks for STOP file between iterations

Phase 4: Status (when subcommand = "status")
  - Read BACKLOG.md and count tasks by status
  - Read .claude/autopilot/logs/latest.log tail
  - Read progress.txt tail (last 10 entries)
  - Read .claude/autopilot/config.json for limits
  - Output: progress table, current task, limits status, log tail

Phase 5: Resume (when subcommand = "resume")
  - Verify BACKLOG.md exists with in-progress or pending tasks
  - Check for orphaned tmux sessions, clean up if needed
  - Same as Phase 2 (start) but skip creating config if exists
  - Picks up from where the loop left off (reads BACKLOG.md state)
```

---

## 3. Bash Script Design: `autopilot.sh`

### Location

```
.claude/autopilot/autopilot.sh
```

This is NOT in the skills directory (it is a runtime tool, not a skill definition). The SKILL.md instructs Claude to create or verify this file exists.

### Complete Pseudocode

```bash
#!/usr/bin/env bash
# autopilot.sh -- Continuous autonomous iteration loop for Claude CLI
# CONSTRAINT: macOS (darwin) compatible. Requires: tmux, jq, claude CLI.

set -euo pipefail

# ============================================================
# Constants
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"
BACKLOG_FILE="$PROJECT_ROOT/BACKLOG.md"
PROGRESS_FILE="$PROJECT_ROOT/progress.txt"
LOG_DIR="$SCRIPT_DIR/logs"
STOP_FILE="$SCRIPT_DIR/STOP"
LOCK_FILE="$SCRIPT_DIR/autopilot.lock"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
SESSION_NAME="autopilot-$PROJECT_NAME"

# ============================================================
# Configuration (read from config.json, with defaults)
# ============================================================
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "ERROR: Config file not found: $CONFIG_FILE"
        echo "Run '/autopilot init' first."
        exit 1
    fi

    MAX_ITERATIONS=$(jq -r '.maxIterations // 20' "$CONFIG_FILE")
    MAX_COST_USD=$(jq -r '.maxCostUsd // 10.0' "$CONFIG_FILE")
    MAX_DURATION_MINUTES=$(jq -r '.maxDurationMinutes // 120' "$CONFIG_FILE")
    COOLDOWN_SECONDS=$(jq -r '.cooldownSeconds // 30' "$CONFIG_FILE")
    PER_ITERATION_BUDGET=$(jq -r '.perIterationBudgetUsd // 2.0' "$CONFIG_FILE")
    MODEL=$(jq -r '.model // "sonnet"' "$CONFIG_FILE")
    GIT_CHECKPOINT=$(jq -r '.gitCheckpoint // true' "$CONFIG_FILE")
    MAX_RETRIES_PER_TASK=$(jq -r '.maxRetriesPerTask // 2' "$CONFIG_FILE")
    PERMISSION_MODE=$(jq -r '.permissionMode // "default"' "$CONFIG_FILE")
    SKIP_PERMISSIONS=$(jq -r '.dangerouslySkipPermissions // false' "$CONFIG_FILE")
    USE_SKILLS=$(jq -r '.useSkills // true' "$CONFIG_FILE")
}

# ============================================================
# Logging
# ============================================================
setup_logging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/$(date +%Y%m%d-%H%M%S).log"
    ln -sf "$LOG_FILE" "$LOG_DIR/latest.log"
}

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# ============================================================
# BACKLOG.md Parsing
# ============================================================
get_next_task() {
    # Parse BACKLOG.md for the first task with status "pending"
    # Returns: task_id, task_title, task_description
    # Format: Lines matching "- [ ] **T{id}**: {title}"
    #
    # Uses awk/grep to find first unchecked task
    # Returns empty string if no pending tasks remain
}

get_task_count() {
    # Count tasks by status:
    # pending:    lines matching "- [ ]"
    # done:       lines matching "- [x]"
    # failed:     lines matching "- [!]"
    # skipped:    lines matching "- [-]"
}

mark_task_done() {
    local task_id="$1"
    # Replace "- [ ] **T{task_id}**" with "- [x] **T{task_id}**"
    # Uses sed in-place (macOS compatible: sed -i '')
}

mark_task_failed() {
    local task_id="$1"
    local reason="$2"
    # Replace "- [ ] **T{task_id}**" with "- [!] **T{task_id}** (FAILED: {reason})"
}

increment_retry_count() {
    local task_id="$1"
    # Track retries in .claude/autopilot/retries.json
    # Returns current retry count
}

# ============================================================
# Prompt Construction
# ============================================================
build_prompt() {
    local task_id="$1"
    local task_title="$2"
    local task_description="$3"

    # Build a self-contained prompt for the inner Claude session
    # Includes:
    # 1. Role: "You are working on project {PROJECT_NAME}."
    # 2. Task: the specific task from BACKLOG.md
    # 3. Context: last 20 lines of progress.txt (cross-iteration learnings)
    # 4. Instructions:
    #    - Read CLAUDE.md for project standards
    #    - Implement the task completely
    #    - Run tests if available
    #    - Do NOT modify BACKLOG.md (the outer loop handles this)
    #    - Write a brief summary of what was done to stdout
    # 5. Constraints:
    #    - Stay within scope of this single task
    #    - Follow Clean Architecture if applicable
    #    - Commit changes with conventional commit messages
}

# ============================================================
# Git Checkpoint
# ============================================================
git_checkpoint() {
    local task_id="$1"
    local task_title="$2"

    if [[ "$GIT_CHECKPOINT" != "true" ]]; then
        return 0
    fi

    cd "$PROJECT_ROOT"

    # Check if there are changes to commit
    if ! git diff --quiet HEAD 2>/dev/null || \
       ! git diff --cached --quiet 2>/dev/null || \
       [[ -n "$(git ls-files --others --exclude-standard)" ]]; then

        git add -A
        git commit -m "autopilot: complete T${task_id} - ${task_title}" \
            --no-verify  # Skip hooks in autopilot mode for speed
    else
        log "INFO" "No changes to checkpoint for T${task_id}"
    fi
}

# ============================================================
# Safety Checks
# ============================================================
check_safety_limits() {
    local iteration="$1"
    local start_time="$2"
    local total_cost="$3"

    # Check iteration limit
    if (( iteration >= MAX_ITERATIONS )); then
        log "WARN" "Max iterations reached: $iteration >= $MAX_ITERATIONS"
        return 1
    fi

    # Check duration limit
    local elapsed=$(( ($(date +%s) - start_time) / 60 ))
    if (( elapsed >= MAX_DURATION_MINUTES )); then
        log "WARN" "Max duration reached: ${elapsed}m >= ${MAX_DURATION_MINUTES}m"
        return 1
    fi

    # Check cost limit (approximate, from log parsing)
    # Note: exact cost tracking requires parsing Claude CLI output
    # We use per-iteration budget as a proxy
    local estimated_cost
    estimated_cost=$(echo "$iteration * $PER_ITERATION_BUDGET" | bc)
    if (( $(echo "$estimated_cost >= $MAX_COST_USD" | bc -l) )); then
        log "WARN" "Estimated cost limit: \$${estimated_cost} >= \$${MAX_COST_USD}"
        return 1
    fi

    # Check for STOP file (graceful shutdown signal)
    if [[ -f "$STOP_FILE" ]]; then
        log "INFO" "STOP file detected. Graceful shutdown."
        rm -f "$STOP_FILE"
        return 1
    fi

    return 0
}

# ============================================================
# Signal Handling
# ============================================================
cleanup() {
    log "INFO" "Received shutdown signal. Cleaning up..."

    # Wait for current Claude process to finish (if any)
    if [[ -n "${CLAUDE_PID:-}" ]]; then
        log "INFO" "Waiting for current Claude session (PID: $CLAUDE_PID) to finish..."
        wait "$CLAUDE_PID" 2>/dev/null || true
    fi

    # Git checkpoint any remaining work
    git_checkpoint "interrupted" "interrupted-work"

    # Append final status to progress.txt
    echo "---" >> "$PROGRESS_FILE"
    echo "## Autopilot Stopped: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
    echo "- Reason: Signal received (SIGTERM/SIGINT)" >> "$PROGRESS_FILE"
    echo "- Iterations completed: $CURRENT_ITERATION" >> "$PROGRESS_FILE"
    echo "- $(get_task_count)" >> "$PROGRESS_FILE"

    # Remove lock file
    rm -f "$LOCK_FILE"

    log "INFO" "Cleanup complete. Exiting."
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

# ============================================================
# Main Loop
# ============================================================
main() {
    local subcommand="${1:-start}"

    case "$subcommand" in
        start)
            start_loop
            ;;
        tmux-start)
            # Internal: called from within tmux session
            run_loop
            ;;
        *)
            echo "Usage: autopilot.sh [start|tmux-start]"
            exit 1
            ;;
    esac
}

start_loop() {
    load_config
    setup_logging

    # Prevent double-launch
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "ERROR: Autopilot session '$SESSION_NAME' already running."
        echo "Use '/autopilot stop' to stop it, or '/autopilot status' to check."
        exit 1
    fi

    # Lock file check
    if [[ -f "$LOCK_FILE" ]]; then
        echo "ERROR: Lock file exists. Another instance may be running."
        echo "If this is stale, remove: $LOCK_FILE"
        exit 1
    fi

    log "INFO" "Starting autopilot in tmux session: $SESSION_NAME"
    log "INFO" "Config: max_iter=$MAX_ITERATIONS, max_cost=\$$MAX_COST_USD, max_duration=${MAX_DURATION_MINUTES}m"

    # Create tmux session and run the loop inside it
    tmux new-session -d -s "$SESSION_NAME" \
        "bash '$SCRIPT_DIR/autopilot.sh' tmux-start 2>&1 | tee -a '$LOG_DIR/latest.log'"

    echo "Autopilot started in tmux session: $SESSION_NAME"
    echo ""
    echo "Commands:"
    echo "  Attach:  tmux attach -t $SESSION_NAME"
    echo "  Status:  /autopilot status"
    echo "  Stop:    /autopilot stop"
    echo "  Logs:    tail -f $LOG_DIR/latest.log"
}

run_loop() {
    load_config
    setup_logging

    # Create lock file
    echo "$$" > "$LOCK_FILE"

    CURRENT_ITERATION=0
    START_TIME=$(date +%s)
    TOTAL_COST=0

    log "INFO" "=== Autopilot Loop Starting ==="
    log "INFO" "Project: $PROJECT_NAME"
    log "INFO" "Backlog: $BACKLOG_FILE"

    # Initialize progress.txt if not exists
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo "# Autopilot Progress Log" > "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi

    echo "---" >> "$PROGRESS_FILE"
    echo "## Autopilot Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"

    while true; do
        CURRENT_ITERATION=$((CURRENT_ITERATION + 1))

        # Safety check
        if ! check_safety_limits "$CURRENT_ITERATION" "$START_TIME" "$TOTAL_COST"; then
            log "INFO" "Safety limit reached. Stopping."
            break
        fi

        # Get next task
        local task_info
        task_info=$(get_next_task)

        if [[ -z "$task_info" ]]; then
            log "INFO" "No more pending tasks. Backlog complete!"
            break
        fi

        local task_id task_title task_description
        task_id=$(echo "$task_info" | head -1)
        task_title=$(echo "$task_info" | sed -n '2p')
        task_description=$(echo "$task_info" | tail -n +3)

        log "INFO" "=== Iteration $CURRENT_ITERATION: T${task_id} - ${task_title} ==="

        # Build prompt
        local prompt
        prompt=$(build_prompt "$task_id" "$task_title" "$task_description")

        # Build claude command
        local claude_cmd="claude -p --max-budget-usd $PER_ITERATION_BUDGET --model $MODEL"

        if [[ "$SKIP_PERMISSIONS" == "true" ]]; then
            claude_cmd="$claude_cmd --dangerously-skip-permissions"
        fi

        # Execute Claude session
        local output exit_code
        log "INFO" "Launching Claude session..."

        cd "$PROJECT_ROOT"
        output=$(eval "$claude_cmd" <<< "$prompt" 2>&1) || exit_code=$?
        exit_code=${exit_code:-0}

        # Process result
        if [[ $exit_code -eq 0 ]]; then
            log "INFO" "T${task_id} completed successfully."
            mark_task_done "$task_id"
            git_checkpoint "$task_id" "$task_title"

            # Append to progress
            echo "" >> "$PROGRESS_FILE"
            echo "### Iteration $CURRENT_ITERATION - T${task_id}: ${task_title}" >> "$PROGRESS_FILE"
            echo "- Status: DONE" >> "$PROGRESS_FILE"
            echo "- Summary: $(echo "$output" | tail -5)" >> "$PROGRESS_FILE"
        else
            log "ERROR" "T${task_id} failed with exit code $exit_code."

            local retries
            retries=$(increment_retry_count "$task_id")

            if (( retries >= MAX_RETRIES_PER_TASK )); then
                log "WARN" "T${task_id} exceeded max retries ($MAX_RETRIES_PER_TASK). Marking failed."
                mark_task_failed "$task_id" "Exceeded max retries"
            else
                log "INFO" "T${task_id} will be retried (attempt $((retries+1))/$MAX_RETRIES_PER_TASK)."
                # Task remains "pending" for retry
            fi

            # Append to progress
            echo "" >> "$PROGRESS_FILE"
            echo "### Iteration $CURRENT_ITERATION - T${task_id}: ${task_title}" >> "$PROGRESS_FILE"
            echo "- Status: FAILED (exit code: $exit_code, retry: $retries/$MAX_RETRIES_PER_TASK)" >> "$PROGRESS_FILE"
            echo "- Error: $(echo "$output" | tail -10)" >> "$PROGRESS_FILE"
        fi

        # Cooldown
        log "INFO" "Cooldown: ${COOLDOWN_SECONDS}s"
        sleep "$COOLDOWN_SECONDS"
    done

    # Final summary
    log "INFO" "=== Autopilot Loop Complete ==="
    log "INFO" "$(get_task_count)"

    echo "---" >> "$PROGRESS_FILE"
    echo "## Autopilot Finished: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
    echo "- Total iterations: $CURRENT_ITERATION" >> "$PROGRESS_FILE"
    echo "- $(get_task_count)" >> "$PROGRESS_FILE"

    # Remove lock file
    rm -f "$LOCK_FILE"

    # Context sync: save state for next session
    log "INFO" "Saving context for next session..."
    claude -p --max-budget-usd 0.5 --model "$MODEL" \
        "Run /context-sync save. The autopilot has just completed. Summary: $(get_task_count)" \
        2>/dev/null || true
}

main "$@"
```

### CLI Flags Summary

| Flag | Default | Description |
|------|---------|-------------|
| `--max-iterations` | 20 | Maximum number of loop iterations |
| `--max-cost` | 10.0 | Total cost limit in USD |
| `--max-duration` | 120 | Maximum runtime in minutes |
| `--cooldown` | 30 | Seconds between iterations |
| `--per-iteration-budget` | 2.0 | Per-iteration cost cap (passed to `claude --max-budget-usd`) |
| `--model` | sonnet | Model to use for inner sessions |
| `--no-git-checkpoint` | false | Disable git commit between iterations |
| `--max-retries` | 2 | Max retries per failed task |
| `--dangerously-skip-permissions` | false | Skip permission checks (requires explicit opt-in) |

---

## 4. BACKLOG.md Format Specification

### Location

```
{project-root}/BACKLOG.md
```

### Format

```markdown
# Autopilot Backlog

> Generated: YYYY-MM-DD HH:MM
> Source: [original description or issue URL]
> Total tasks: N

## Context
[Brief project context that each iteration can reference]

## Tasks

### Phase 1: Foundation
- [ ] **T01**: [Task title]
  - Description: [What to do, specific enough for a fresh Claude session]
  - Files: [files to create or modify]
  - Acceptance: [how to verify this is done]
  - Dependencies: none

- [ ] **T02**: [Task title]
  - Description: [details]
  - Files: [file list]
  - Acceptance: [criteria]
  - Dependencies: T01

### Phase 2: Core Implementation
- [ ] **T03**: [Task title]
  - Description: [details]
  - Files: [file list]
  - Acceptance: [criteria]
  - Dependencies: T01

- [ ] **T04**: [Task title]
  - Description: [details]
  - Files: [file list]
  - Acceptance: [criteria]
  - Dependencies: T02, T03

### Phase 3: Testing & Documentation
- [ ] **T05**: [Task title]
  - Description: [details]
  - Files: [file list]
  - Acceptance: [criteria]
  - Dependencies: T04

## Status Legend
- `[ ]` — Pending
- `[x]` — Done
- `[!]` — Failed (will not retry)
- `[-]` — Skipped
```

### Task ID Rules

- IDs are sequential: T01, T02, ..., T99
- Zero-padded for consistent sorting
- IDs are stable once assigned (never renumbered)

### Dependency Handling

The outer loop picks the first task whose dependencies are ALL marked `[x]`. If a dependency is marked `[!]` (failed), downstream tasks are automatically marked `[-]` (skipped) unless they have no real dependency on the failed output.

**Important design note**: Dependencies are resolved by the bash script via simple text matching. The script scans each task's `Dependencies:` line, checks if all referenced task IDs are `[x]`, and only then considers the task eligible for execution.

### Task Granularity Guidelines

When creating BACKLOG.md (in the `init` phase), tasks should be:

| Property | Guideline |
|----------|-----------|
| **Scope** | 1-5 files per task |
| **Duration** | Each task completable within a single Claude session |
| **Self-containment** | Task description includes enough context for a fresh session |
| **Verifiability** | Acceptance criteria are concrete and testable |
| **Independence** | Minimize cross-task dependencies when possible |

---

## 5. State Management Design

### State Files Overview

```
{project-root}/
  BACKLOG.md                    # Task list with status (the primary state)
  progress.txt                  # Append-only learnings log

{project-root}/.claude/autopilot/
  config.json                   # Runtime configuration
  autopilot.sh                  # The outer loop script
  autopilot.lock                # PID lock file (exists only while running)
  STOP                          # Sentinel file for graceful stop
  retries.json                  # Retry count per task
  logs/
    20260306-143022.log         # Timestamped log files
    latest.log -> 20260306-...  # Symlink to current log
```

### config.json Schema

```json
{
  "maxIterations": 20,
  "maxCostUsd": 10.0,
  "maxDurationMinutes": 120,
  "cooldownSeconds": 30,
  "perIterationBudgetUsd": 2.0,
  "model": "sonnet",
  "gitCheckpoint": true,
  "maxRetriesPerTask": 2,
  "permissionMode": "default",
  "dangerouslySkipPermissions": false,
  "useSkills": true,
  "createdAt": "2026-03-06T14:30:22Z",
  "lastModified": "2026-03-06T14:30:22Z"
}
```

### retries.json Schema

```json
{
  "T01": 0,
  "T03": 1,
  "T07": 2
}
```

### progress.txt Format

This is an append-only file that accumulates learnings across iterations. It serves as a **cross-iteration memory** -- since each Claude session is fresh, the outer loop injects the tail of this file into the prompt so that later iterations benefit from earlier learnings.

```markdown
# Autopilot Progress Log

---
## Autopilot Started: 2026-03-06 14:30:22

### Iteration 1 - T01: Define TypeScript interfaces
- Status: DONE
- Summary: Created src/domain/entities/user.ts and src/application/ports/user-port.ts

### Iteration 2 - T02: Implement user repository
- Status: DONE
- Summary: Implemented PostgreSQL adapter in src/adapters/outbound/persistence/user-repository.ts

### Iteration 3 - T03: Add authentication middleware
- Status: FAILED (exit code: 1, retry: 1/2)
- Error: Missing dependency @types/jsonwebtoken. Need to npm install first.

### Iteration 4 - T03: Add authentication middleware (retry)
- Status: DONE
- Summary: Installed jsonwebtoken, implemented auth middleware in src/adapters/inbound/http/auth-middleware.ts

---
## Autopilot Finished: 2026-03-06 16:45:10
- Total iterations: 4
- Done: 3, Failed: 0, Pending: 0, Skipped: 0
```

### State Lifecycle

```
                    /autopilot init
                          |
                          v
              +-----------------------+
              | BACKLOG.md created    |
              | config.json created   |
              | progress.txt created  |
              +-----------------------+
                          |
                    /autopilot start
                          |
                          v
              +-----------------------+
              | autopilot.lock exists |
              | tmux session running  |
              | logs accumulating     |
              +-----------------------+
                    |           |
            (each iteration)   |
                    |           |
                    v           |
              +-----------+    |
              | BACKLOG   |    |
              | updated   |    |
              | progress  |    |
              | appended  |    |
              +-----------+    |
                    |          |
            (limits reached    |
             or backlog empty) |
                    |          |
                    v          v
              +-----------------------+
              | autopilot.lock gone   |
              | tmux session ended    |
              | BACKLOG reflects      |
              | final state           |
              | progress.txt complete |
              +-----------------------+
                          |
                    /autopilot resume
                    (if tasks remain)
```

---

## 6. Safety Mechanisms

### Triple Safety Limit

The autopilot enforces three independent limits. **Any single limit** being reached causes a graceful stop.

| Limit | Default | Purpose | Override Flag |
|-------|---------|---------|---------------|
| **Max Iterations** | 20 | Prevent infinite loops | `--max-iterations N` |
| **Max Cost** | $10.00 | Prevent runaway spending | `--max-cost N.NN` |
| **Max Duration** | 120 min | Prevent indefinite runtime | `--max-duration N` |

### Per-Iteration Budget

Each `claude -p` call uses `--max-budget-usd` to cap individual iteration cost. Default: $2.00. This prevents a single runaway iteration from consuming the entire budget.

### Graceful Shutdown

```
Method 1: /autopilot stop
  -> Creates STOP sentinel file
  -> Loop checks between iterations
  -> Current iteration completes normally
  -> Git checkpoint, state save, clean exit

Method 2: SIGTERM / SIGINT / SIGHUP
  -> Signal trapped by bash script
  -> Waits for current Claude process to finish
  -> Git checkpoint any changes
  -> Appends shutdown note to progress.txt
  -> Removes lock file
  -> Exits cleanly

Method 3: tmux kill
  -> tmux kill-session -t autopilot-{project}
  -> Less graceful, but lock file can be manually cleaned
  -> BACKLOG.md state is still valid (updated after each iteration)
```

### Lock File Protection

- `autopilot.lock` prevents double-launch
- Contains the PID of the running process
- Removed on clean exit
- Can be manually removed if stale (script checks PID validity)

### Permission Safety

```
CRITICAL RULE:
  --dangerously-skip-permissions is NEVER set by default.
  It must be explicitly requested by the user via:
    /autopilot start --dangerously-skip-permissions

  The SKILL.md instructs Claude to WARN the user:
    "WARNING: --dangerously-skip-permissions bypasses all safety checks.
     Only use this in sandboxed environments with no internet access.
     Are you sure? (yes/no)"
```

### Retry Logic

- Failed tasks are retried up to `maxRetriesPerTask` times (default: 2)
- After max retries, the task is marked `[!]` (permanently failed)
- Downstream dependent tasks are automatically skipped
- Each retry attempt includes the error message from the previous attempt in the prompt

### Cost Estimation

Since the Claude CLI does not output exact cost per invocation, the script uses a conservative estimate:
```
estimated_cost = iteration_count * per_iteration_budget
```
This is an upper bound (actual cost may be lower if the session exits early). Users should set `maxCostUsd` based on their actual budget, knowing the estimate is conservative.

---

## 7. Integration Points with Existing Skills

### Integration with `/assemble`

The inner Claude session (each iteration) CAN invoke `/assemble` if the task is complex enough. However, this is **not the default behavior**. The default prompt instructs Claude to implement the task directly.

For complex backlogs, the user can configure the SKILL.md to build prompts that say:
```
"Use /assemble to implement this task if it involves 5+ files.
 Otherwise, implement directly."
```

**Design decision**: The default autopilot does NOT use `/assemble` per iteration because:
1. Each autopilot task should already be atomic (1-5 files)
2. Spawning sub-agents inside a `claude -p` session adds complexity
3. The cost multiplier is significant (each `/assemble` spawns multiple agents)

If users want agent-army-powered iterations, they can set this in config:
```json
{
  "useSkills": true,
  "iterationPromptSuffix": "Use /assemble if this task involves more than 5 files."
}
```

### Integration with `/sprint`

`/sprint` and `/autopilot init` have overlapping responsibilities (task decomposition). The relationship is:

```
/sprint                        /autopilot init
  |                               |
  v                               v
Sprint Plan                    BACKLOG.md
(for human review)             (for machine consumption)
```

A user can use `/sprint` first to plan, then feed the sprint plan to `/autopilot init` to convert it into a BACKLOG.md. The SKILL.md includes this workflow:

```
/sprint [feature]                 # Human reviews and approves the plan
/autopilot init "from sprint"     # Reads the sprint plan and creates BACKLOG.md
/autopilot start                  # Launch autonomous execution
```

### Integration with `/context-sync`

Context sync is integrated at two points:

1. **End of autopilot run**: After the loop completes, the script invokes:
   ```bash
   claude -p "Run /context-sync save. Autopilot completed. Summary: ..."
   ```
   This saves the final state for the next human session.

2. **Between iterations (optional)**: For long-running autopilots, the script can optionally invoke context-sync every N iterations to save intermediate state. This is configurable:
   ```json
   {
     "contextSyncEveryN": 10
   }
   ```

### Integration with Quality Gate (Stop Hook)

The existing `PostToolUse` hook for `Write|Edit` still fires inside each inner Claude session. This means Clean Architecture compliance reminders still appear.

Additionally, the SKILL.md instructs the `init` phase to add a quality gate task at the end of the backlog:
```markdown
### Phase N: Quality Assurance
- [ ] **T{last}**: Run quality gate on all changes
  - Description: Run /quality-gate on the entire project to verify all changes pass quality standards
  - Acceptance: All quality checks pass
  - Dependencies: all previous tasks
```

### Integration with Git Workflow

The autopilot creates commits with the prefix `autopilot:` following Conventional Commits:
```
autopilot: complete T01 - Define TypeScript interfaces
autopilot: complete T02 - Implement user repository
autopilot: complete T03 - Add authentication middleware
```

This makes it easy to identify autopilot-generated commits and squash them if desired before merging:
```bash
git log --oneline | grep "^autopilot:"
```

---

## 8. File List (What to Create, What to Modify)

### Files to CREATE

| # | Path | Description | Size Est. |
|---|------|-------------|-----------|
| 1 | `.claude/skills/autopilot/SKILL.md` | Skill definition (local project) | ~250 lines |
| 2 | `.claude/autopilot/autopilot.sh` | Bash outer loop script | ~280 lines |
| 3 | `plugins/agent-army/skills/autopilot/SKILL.md` | Plugin skill definition (same as #1) | ~250 lines |

### Files to MODIFY

| # | Path | Change | Reason |
|---|------|--------|--------|
| 4 | `.claude/CLAUDE.md` | Add `/autopilot` to the Available Skills table | Register the skill |
| 5 | `plugins/agent-army/.claude-plugin/plugin.json` | Add "autopilot" to keywords | Plugin metadata |
| 6 | `docs/INDEX.md` | Add this design plan to the Plans table | Document index |

### Files CREATED AT RUNTIME (by the skill, not by implementation)

These files are created when the user runs `/autopilot init`:

| Path | Created By | Description |
|------|-----------|-------------|
| `BACKLOG.md` | `/autopilot init` (Claude) | Task backlog |
| `progress.txt` | `/autopilot init` (Claude) | Progress log |
| `.claude/autopilot/config.json` | `/autopilot init` (Claude) | Configuration |
| `.claude/autopilot/retries.json` | `autopilot.sh` (at runtime) | Retry tracking |
| `.claude/autopilot/logs/*.log` | `autopilot.sh` (at runtime) | Iteration logs |
| `.claude/autopilot/autopilot.lock` | `autopilot.sh` (at runtime) | PID lock |
| `.claude/autopilot/STOP` | `/autopilot stop` (Claude) | Stop sentinel |

### .gitignore Additions

The following should be added to `.gitignore` (or `.claude/autopilot/.gitignore`):

```gitignore
# Autopilot runtime files
.claude/autopilot/logs/
.claude/autopilot/autopilot.lock
.claude/autopilot/STOP
.claude/autopilot/retries.json
```

`BACKLOG.md`, `progress.txt`, `config.json`, and `autopilot.sh` should be tracked in git.

---

## 9. Design Decisions & Tradeoffs

### Decision 1: Fresh session per iteration (chosen) vs. single long-running session

**Chosen**: Each iteration spawns a new `claude -p` process.

**Rationale**:
- Avoids context window overflow (each iteration starts clean)
- Prevents error accumulation (hallucinations do not carry over)
- Enables clean cost tracking per iteration
- Allows different models per task if needed
- progress.txt provides selective cross-iteration memory

**Tradeoff**: Loses intra-session context. Mitigated by injecting progress.txt tail into prompts.

### Decision 2: BACKLOG.md in project root (chosen) vs. inside .claude/autopilot/

**Chosen**: `BACKLOG.md` lives at project root.

**Rationale**:
- Visible to the user (they need to review and approve the backlog)
- Easy to edit manually before starting
- Git-tracked alongside the project
- Follows the pattern of other project-root artifacts (README.md, etc.)

### Decision 3: tmux-based background (chosen) vs. nohup/screen/launchd

**Chosen**: tmux.

**Rationale**:
- Available on macOS by default (or easily installable)
- User can attach/detach to watch progress
- Named sessions make management easy
- Better than nohup (interactive monitoring) or launchd (overkill for dev tool)

### Decision 4: Markdown-based state (chosen) vs. JSON/SQLite

**Chosen**: BACKLOG.md in markdown, progress.txt in plain text.

**Rationale**:
- Human-readable and editable (users can modify the backlog manually)
- Git-friendly diffs
- Claude naturally reads and writes markdown
- Simple grep/sed parsing in bash (no jq needed for state, only for config)
- Consistent with the project's existing state management patterns

**Tradeoff**: Slightly more fragile parsing than structured formats. Mitigated by strict format conventions.

### Decision 5: Autopilot script inside .claude/ (chosen) vs. standalone bin/

**Chosen**: `.claude/autopilot/autopilot.sh`

**Rationale**:
- Keeps all Claude-related tooling under `.claude/`
- Not a user-facing binary (it is infrastructure)
- Can be gitignored for sensitive projects
- Consistent with `.claude/skills/` and `.claude/agents/` locations

### Decision 6: Conservative cost estimation (chosen) vs. exact cost tracking

**Chosen**: `estimated_cost = iterations * per_iteration_budget` (upper bound).

**Rationale**:
- Claude CLI does not expose exact cost in its output
- Upper-bound estimation is safer (stops early rather than late)
- Users can set `perIterationBudgetUsd` to match their expected per-task cost
- Exact tracking would require parsing API responses, which is fragile

---

## 10. Security Considerations

### Permission Escalation Risk

The most dangerous aspect of autopilot is that it runs `claude -p` in a loop, potentially with `--dangerously-skip-permissions`. Mitigations:

1. **Default is safe**: `dangerouslySkipPermissions` defaults to `false` in config.json
2. **Explicit opt-in**: User must pass `--dangerously-skip-permissions` flag to `/autopilot start`
3. **SKILL.md warning**: The skill instructs Claude to display a clear warning before enabling
4. **Per-iteration budget**: Even with skip-permissions, cost is capped per iteration

### Prompt Injection via BACKLOG.md

Since the backlog is user-editable markdown, a malicious or careless task description could contain instructions that make Claude do unintended things. Mitigations:

1. BACKLOG.md is created by the `/autopilot init` skill (Claude-generated, not arbitrary user input)
2. Users who edit BACKLOG.md manually are trusted (they have project access)
3. Per-iteration budget limits blast radius
4. Git checkpoint enables rollback

### Runaway Process

The triple safety limit (iterations + cost + duration) plus the STOP sentinel file ensure the process cannot run indefinitely. The lock file prevents accidental double-launch.

---

## 11. Future Extensions (Out of Scope)

These are NOT designed now but should be considered for future versions:

1. **Parallel task execution**: Run multiple non-dependent tasks in parallel tmux panes
2. **Web dashboard**: A simple HTML status page served from the log directory
3. **Slack/webhook notifications**: Send alerts on completion, failure, or budget warnings
4. **Adaptive model selection**: Use cheaper models for simple tasks, expensive models for complex ones
5. **Backlog from GitHub Issues**: `/autopilot init --from-issues` to pull tasks from GitHub
6. **Cross-project autopilot**: Run autopilot across a workspace of related projects

---

## Appendix: SKILL.md Content Outline (Abridged)

Below is the structural outline of what the SKILL.md should contain (the full file would be ~250 lines following existing skill patterns):

```
---
name: autopilot
description: ...
---

# Autopilot -- Continuous Autonomous Iteration

## Usage
  /autopilot init [description]
  /autopilot start [--flags]
  /autopilot stop
  /autopilot status
  /autopilot resume

## Phase 0: Argument Parsing
  Parse $ARGUMENTS for subcommand

## Phase 1: Init
  Step 1: Analyze scope (Read, Grep, Glob)
  Step 2: Decompose into tasks
  Step 3: Write BACKLOG.md
  Step 4: Write config.json
  Step 5: Create autopilot.sh if not exists
  Output: summary

## Phase 2: Start
  Step 1: Verify prerequisites
  Step 2: Parse flags / override config
  Step 3: Check for existing session
  Step 4: Launch tmux
  Output: session info

## Phase 3: Stop
  Step 1: Touch STOP sentinel
  Output: confirmation

## Phase 4: Status
  Step 1: Read BACKLOG.md counts
  Step 2: Read latest.log tail
  Step 3: Read progress.txt tail
  Output: progress dashboard

## Phase 5: Resume
  Step 1: Verify BACKLOG.md has pending tasks
  Step 2: Clean up stale sessions
  Step 3: Relaunch (same as Phase 2)

## Safety Warnings
  - Default limits
  - Permission escalation warning
  - How to monitor
  - How to emergency stop
```
