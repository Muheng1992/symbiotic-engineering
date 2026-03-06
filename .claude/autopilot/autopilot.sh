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
RETRIES_FILE="$SCRIPT_DIR/retries.json"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
SESSION_NAME="autopilot-$PROJECT_NAME"

CURRENT_ITERATION=0
CLAUDE_PID=""

# ============================================================
# Dependency Checks
# ============================================================
check_dependencies() {
    local missing=0

    if ! command -v tmux >/dev/null 2>&1; then
        echo "ERROR: tmux is required but not installed."
        echo "Install with: brew install tmux"
        missing=1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "ERROR: jq is required but not installed."
        echo "Install with: brew install jq"
        missing=1
    fi

    if ! command -v claude >/dev/null 2>&1; then
        echo "ERROR: claude CLI is required but not installed."
        echo "See: https://docs.anthropic.com/en/docs/claude-cli"
        missing=1
    fi

    if [[ $missing -eq 1 ]]; then
        exit 1
    fi
}

# ============================================================
# Configuration
# ============================================================
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "ERROR: Config file not found: $CONFIG_FILE"
        echo "Run '/autopilot init' first."
        exit 1
    fi

    MAX_ITERATIONS=$(jq -r '.maxIterations // 50' "$CONFIG_FILE")
    MAX_COST_USD=$(jq -r '.maxCostUsd // 25.0' "$CONFIG_FILE")
    MAX_DURATION_MINUTES=$(jq -r '.maxDurationMinutes // 240' "$CONFIG_FILE")
    COOLDOWN_SECONDS=$(jq -r '.cooldownSeconds // 30' "$CONFIG_FILE")
    PER_ITERATION_BUDGET=$(jq -r '.perIterationBudgetUsd // 5.0' "$CONFIG_FILE")
    MODEL=$(jq -r '.model // "sonnet"' "$CONFIG_FILE")
    GIT_CHECKPOINT=$(jq -r '.gitCheckpoint // true' "$CONFIG_FILE")
    MAX_RETRIES_PER_TASK=$(jq -r '.maxRetriesPerTask // 2' "$CONFIG_FILE")
    SKIP_PERMISSIONS=$(jq -r '.dangerouslySkipPermissions // false' "$CONFIG_FILE")
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
    # WHY: We need dependency-aware task selection. A task is eligible only
    # when all its dependencies are marked [x] (done).
    if [[ ! -f "$BACKLOG_FILE" ]]; then
        return
    fi

    local task_id task_title task_block deps_line
    local all_done_ids

    # Collect all done task IDs
    all_done_ids=$(grep -E '^\- \[x\] \*\*T[0-9]+\*\*' "$BACKLOG_FILE" \
        | sed -E 's/^- \[x\] \*\*T([0-9]+)\*\*.*/T\1/' || true)

    # Find each pending task and check its dependencies
    local in_task=0
    local current_id="" current_title="" current_desc=""

    while IFS= read -r line; do
        # Match a pending task line: - [ ] **T01**: Title
        if echo "$line" | grep -qE '^\- \[ \] \*\*T[0-9]+\*\*'; then
            current_id=$(echo "$line" | sed -E 's/^- \[ \] \*\*T([0-9]+)\*\*.*/\1/')
            current_title=$(echo "$line" | sed -E 's/^- \[ \] \*\*T[0-9]+\*\*: (.*)/\1/')
            current_desc=""
            in_task=1
            continue
        fi

        # If we are inside a task block, collect description lines
        if [[ $in_task -eq 1 ]]; then
            # Check if we hit the next task or a non-indented line
            if echo "$line" | grep -qE '^\- \[.\] \*\*T[0-9]+\*\*' || echo "$line" | grep -qE '^### '; then
                # Process the task we just finished collecting
                if _check_deps "$current_id" "$all_done_ids" "$current_desc"; then
                    echo "$current_id"
                    echo "$current_title"
                    echo "$current_desc"
                    return
                fi
                # Check if this new line is also a pending task
                if echo "$line" | grep -qE '^\- \[ \] \*\*T[0-9]+\*\*'; then
                    current_id=$(echo "$line" | sed -E 's/^- \[ \] \*\*T([0-9]+)\*\*.*/\1/')
                    current_title=$(echo "$line" | sed -E 's/^- \[ \] \*\*T[0-9]+\*\*: (.*)/\1/')
                    current_desc=""
                    continue
                else
                    in_task=0
                    current_id=""
                fi
            else
                current_desc="${current_desc}${line}
"
            fi
        fi
    done < "$BACKLOG_FILE"

    # Process the last task if we were still collecting
    if [[ $in_task -eq 1 && -n "$current_id" ]]; then
        if _check_deps "$current_id" "$all_done_ids" "$current_desc"; then
            echo "$current_id"
            echo "$current_title"
            echo "$current_desc"
            return
        fi
    fi
}

_check_deps() {
    # WHY: A task is eligible only when all its listed dependencies are done.
    # If a dependency is failed [!], the task should not be picked (the main
    # loop will skip it and it gets marked [-] by _skip_orphaned_tasks).
    local task_id="$1"
    local done_ids="$2"
    local desc_block="$3"

    # Extract dependencies line from the description block
    local deps_line
    deps_line=$(echo "$desc_block" | grep -i '^\s*- Dependencies:' | head -1 || true)

    # No dependencies line or "none" means no dependencies
    if [[ -z "$deps_line" ]] || echo "$deps_line" | grep -qi 'none'; then
        return 0
    fi

    # Extract task IDs from dependencies (T01, T02, etc.)
    local dep_ids
    dep_ids=$(echo "$deps_line" | grep -oE 'T[0-9]+' || true)

    if [[ -z "$dep_ids" ]]; then
        return 0
    fi

    # Check each dependency is in the done list
    local dep
    for dep in $dep_ids; do
        if ! echo "$done_ids" | grep -q "^${dep}$"; then
            # Check if dependency is failed -- if so, this task cannot proceed
            if grep -qE "^\- \[!\] \*\*${dep}\*\*" "$BACKLOG_FILE"; then
                return 1
            fi
            # Dependency not yet done
            return 1
        fi
    done

    return 0
}

get_task_count() {
    if [[ ! -f "$BACKLOG_FILE" ]]; then
        echo "No BACKLOG.md found"
        return
    fi

    local pending done failed skipped
    pending=$(grep -cE '^\- \[ \] \*\*T[0-9]+\*\*' "$BACKLOG_FILE" || echo 0)
    done=$(grep -cE '^\- \[x\] \*\*T[0-9]+\*\*' "$BACKLOG_FILE" || echo 0)
    failed=$(grep -cE '^\- \[!\] \*\*T[0-9]+\*\*' "$BACKLOG_FILE" || echo 0)
    skipped=$(grep -cE '^\- \[-\] \*\*T[0-9]+\*\*' "$BACKLOG_FILE" || echo 0)

    echo "Done: $done, Pending: $pending, Failed: $failed, Skipped: $skipped"
}

mark_task_done() {
    local task_id="$1"
    # CONSTRAINT: macOS sed requires -i '' for in-place editing
    sed -i '' "s/^- \[ \] \*\*T${task_id}\*\*/- [x] **T${task_id}**/" "$BACKLOG_FILE"
}

mark_task_failed() {
    local task_id="$1"
    local reason="$2"
    sed -i '' "s/^- \[ \] \*\*T${task_id}\*\*\(.*\)/- [!] **T${task_id}**\1 (FAILED: ${reason})/" "$BACKLOG_FILE"
}

mark_task_skipped() {
    local task_id="$1"
    sed -i '' "s/^- \[ \] \*\*T${task_id}\*\*/- [-] **T${task_id}**/" "$BACKLOG_FILE"
}

skip_orphaned_tasks() {
    # WHY: If a task has failed, all downstream dependents should be skipped
    # to avoid wasting iterations on tasks that cannot succeed.
    if [[ ! -f "$BACKLOG_FILE" ]]; then
        return
    fi

    local failed_ids
    failed_ids=$(grep -E '^\- \[!\] \*\*T[0-9]+\*\*' "$BACKLOG_FILE" \
        | sed -E 's/^- \[!\] \*\*T([0-9]+)\*\*.*/T\1/' || true)

    if [[ -z "$failed_ids" ]]; then
        return
    fi

    # For each pending task, check if any dependency is in the failed list
    local pending_ids
    pending_ids=$(grep -E '^\- \[ \] \*\*T[0-9]+\*\*' "$BACKLOG_FILE" \
        | sed -E 's/^- \[ \] \*\*T([0-9]+)\*\*.*/\1/' || true)

    for pid in $pending_ids; do
        # Read the task block to find its dependencies
        local in_block=0
        local deps_line=""
        while IFS= read -r line; do
            if echo "$line" | grep -qE "^\- \[ \] \*\*T${pid}\*\*"; then
                in_block=1
                continue
            fi
            if [[ $in_block -eq 1 ]]; then
                if echo "$line" | grep -qi '^\s*- Dependencies:'; then
                    deps_line="$line"
                    break
                fi
                if echo "$line" | grep -qE '^\- \[.\] \*\*T[0-9]+\*\*' || echo "$line" | grep -qE '^### '; then
                    break
                fi
            fi
        done < "$BACKLOG_FILE"

        if [[ -n "$deps_line" ]]; then
            local dep_refs
            dep_refs=$(echo "$deps_line" | grep -oE 'T[0-9]+' || true)
            for dep in $dep_refs; do
                if echo "$failed_ids" | grep -q "^${dep}$"; then
                    log "WARN" "Skipping T${pid}: dependency ${dep} has failed"
                    mark_task_skipped "$pid"
                    break
                fi
            done
        fi
    done
}

# ============================================================
# Retry Tracking
# ============================================================
increment_retry_count() {
    local task_id="$1"
    local key="T${task_id}"

    if [[ ! -f "$RETRIES_FILE" ]]; then
        echo '{}' > "$RETRIES_FILE"
    fi

    local current
    current=$(jq -r --arg k "$key" '.[$k] // 0' "$RETRIES_FILE")
    current=$((current + 1))
    jq --arg k "$key" --argjson v "$current" '.[$k] = $v' "$RETRIES_FILE" > "${RETRIES_FILE}.tmp"
    mv "${RETRIES_FILE}.tmp" "$RETRIES_FILE"
    echo "$current"
}

get_retry_count() {
    local task_id="$1"
    local key="T${task_id}"

    if [[ ! -f "$RETRIES_FILE" ]]; then
        echo "0"
        return
    fi

    jq -r --arg k "$key" '.[$k] // 0' "$RETRIES_FILE"
}

# ============================================================
# Prompt Construction
# ============================================================
build_prompt() {
    local task_id="$1"
    local task_title="$2"
    local task_description="$3"

    local progress_context=""
    if [[ -f "$PROGRESS_FILE" ]]; then
        progress_context=$(tail -20 "$PROGRESS_FILE")
    fi

    local retry_count
    retry_count=$(get_retry_count "$task_id")

    local retry_hint=""
    if [[ "$retry_count" -gt 0 ]]; then
        retry_hint="
NOTE: This is retry attempt $((retry_count + 1)). Previous attempts failed.
Check progress log above for error details from prior attempts.
Fix the root cause before proceeding."
    fi

    cat <<PROMPT
You are working on project "${PROJECT_NAME}".

## Task: T${task_id} -- ${task_title}

${task_description}
${retry_hint}

## Instructions

1. Read CLAUDE.md for project standards and conventions.
2. Implement this task completely. Write production-quality code.
3. Run tests if a test framework is available.
4. Do NOT modify BACKLOG.md or progress.txt (the outer loop handles these).
5. Stay within the scope of this single task.
6. Follow Clean Architecture if applicable.
7. Write a brief summary of what you did to stdout when finished.

## Recent Progress (cross-iteration context)

${progress_context:-No previous progress recorded.}
PROMPT
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

    # Check if there are any changes to commit
    if ! git diff --quiet HEAD 2>/dev/null || \
       ! git diff --cached --quiet 2>/dev/null || \
       [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then

        git add -A
        # CONSTRAINT: Commit prefix is "autopilot:" per user requirement
        git commit -m "autopilot: complete T${task_id} - ${task_title}" \
            --no-verify 2>/dev/null || true
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

    # Check iteration limit
    if (( iteration > MAX_ITERATIONS )); then
        log "WARN" "Max iterations reached: $iteration > $MAX_ITERATIONS"
        return 1
    fi

    # Check duration limit
    local now elapsed
    now=$(date +%s)
    elapsed=$(( (now - start_time) / 60 ))
    if (( elapsed >= MAX_DURATION_MINUTES )); then
        log "WARN" "Max duration reached: ${elapsed}m >= ${MAX_DURATION_MINUTES}m"
        return 1
    fi

    # Check cost limit (conservative upper-bound estimate)
    local estimated_cost
    estimated_cost=$(echo "$iteration * $PER_ITERATION_BUDGET" | bc 2>/dev/null || echo "0")
    # WHY: bc -l returns a decimal; we compare with awk for portability
    if awk "BEGIN { exit !($estimated_cost >= $MAX_COST_USD) }" 2>/dev/null; then
        log "WARN" "Estimated cost limit: \$${estimated_cost} >= \$${MAX_COST_USD}"
        return 1
    fi

    # Check for STOP sentinel file
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

    # Wait for current Claude process to finish
    if [[ -n "${CLAUDE_PID:-}" ]] && kill -0 "$CLAUDE_PID" 2>/dev/null; then
        log "INFO" "Waiting for current Claude session (PID: $CLAUDE_PID)..."
        wait "$CLAUDE_PID" 2>/dev/null || true
    fi

    # Git checkpoint any remaining work
    git_checkpoint "interrupted" "interrupted-work" 2>/dev/null || true

    # Append final status to progress.txt
    {
        echo "---"
        echo "## Autopilot Stopped: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "- Reason: Signal received (SIGTERM/SIGINT)"
        echo "- Iterations completed: $CURRENT_ITERATION"
        echo "- $(get_task_count)"
    } >> "$PROGRESS_FILE"

    rm -f "$LOCK_FILE"
    log "INFO" "Cleanup complete. Exiting."
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

# ============================================================
# Main Loop
# ============================================================
start_loop() {
    check_dependencies
    load_config
    setup_logging

    # Verify BACKLOG.md exists
    if [[ ! -f "$BACKLOG_FILE" ]]; then
        echo "ERROR: BACKLOG.md not found at $BACKLOG_FILE"
        echo "Run '/autopilot init' first."
        exit 1
    fi

    # Prevent double-launch
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "ERROR: Autopilot session '$SESSION_NAME' already running."
        echo "Use '/autopilot stop' to stop it, or '/autopilot status' to check."
        exit 1
    fi

    # Lock file check
    if [[ -f "$LOCK_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            echo "ERROR: Another autopilot instance is running (PID: $old_pid)."
            exit 1
        else
            log "INFO" "Removing stale lock file (PID $old_pid no longer running)."
            rm -f "$LOCK_FILE"
        fi
    fi

    log "INFO" "Starting autopilot in tmux session: $SESSION_NAME"
    log "INFO" "Config: max_iter=$MAX_ITERATIONS, max_cost=\$$MAX_COST_USD, max_duration=${MAX_DURATION_MINUTES}m"

    # Launch in tmux
    tmux new-session -d -s "$SESSION_NAME" \
        "bash '${SCRIPT_DIR}/autopilot.sh' tmux-start 2>&1 | tee -a '${LOG_DIR}/latest.log'"

    echo ""
    echo "Autopilot started in tmux session: $SESSION_NAME"
    echo ""
    echo "Commands:"
    echo "  Attach:  tmux attach -t $SESSION_NAME"
    echo "  Status:  /autopilot status"
    echo "  Stop:    /autopilot stop"
    echo "  Logs:    tail -f $LOG_DIR/latest.log"
}

run_loop() {
    check_dependencies
    load_config
    setup_logging

    # Create lock file with current PID
    echo "$$" > "$LOCK_FILE"

    CURRENT_ITERATION=0
    local start_time
    start_time=$(date +%s)

    log "INFO" "=== Autopilot Loop Starting ==="
    log "INFO" "Project: $PROJECT_NAME"
    log "INFO" "Backlog: $BACKLOG_FILE"

    # Initialize progress.txt if needed
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo "# Autopilot Progress Log" > "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi

    {
        echo "---"
        echo "## Autopilot Started: $(date '+%Y-%m-%d %H:%M:%S')"
    } >> "$PROGRESS_FILE"

    while true; do
        CURRENT_ITERATION=$((CURRENT_ITERATION + 1))

        # Safety check (uses iteration-1 for cost since this iteration hasn't run yet)
        if ! check_safety_limits "$CURRENT_ITERATION" "$start_time"; then
            log "INFO" "Safety limit reached. Stopping."
            break
        fi

        # Skip tasks whose dependencies have failed
        skip_orphaned_tasks

        # Get next eligible task
        local task_info
        task_info=$(get_next_task)

        if [[ -z "$task_info" ]]; then
            log "INFO" "No more eligible tasks. Backlog complete!"
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
        local claude_args=("-p" "--output-format" "text" "--max-turns" "50")
        claude_args+=("--max-budget-usd" "$PER_ITERATION_BUDGET")
        claude_args+=("--model" "$MODEL")

        if [[ "$SKIP_PERMISSIONS" == "true" ]]; then
            claude_args+=("--dangerously-skip-permissions")
        fi

        # Execute Claude session
        local output exit_code
        log "INFO" "Launching Claude session..."
        cd "$PROJECT_ROOT"

        set +e
        output=$(echo "$prompt" | claude "${claude_args[@]}" 2>&1)
        exit_code=$?
        set -e

        # Process result
        if [[ $exit_code -eq 0 ]]; then
            log "INFO" "T${task_id} completed successfully."
            mark_task_done "$task_id"
            git_checkpoint "$task_id" "$task_title"

            {
                echo ""
                echo "### Iteration $CURRENT_ITERATION - T${task_id}: ${task_title}"
                echo "- Status: DONE"
                echo "- Summary: $(echo "$output" | tail -5)"
            } >> "$PROGRESS_FILE"
        else
            log "ERROR" "T${task_id} failed with exit code $exit_code."

            local retries
            retries=$(increment_retry_count "$task_id")

            if (( retries >= MAX_RETRIES_PER_TASK )); then
                log "WARN" "T${task_id} exceeded max retries ($MAX_RETRIES_PER_TASK). Marking failed."
                mark_task_failed "$task_id" "Exceeded max retries"
            else
                log "INFO" "T${task_id} will be retried (attempt $((retries + 1))/$MAX_RETRIES_PER_TASK)."
            fi

            {
                echo ""
                echo "### Iteration $CURRENT_ITERATION - T${task_id}: ${task_title}"
                echo "- Status: FAILED (exit code: $exit_code, retry: $retries/$MAX_RETRIES_PER_TASK)"
                echo "- Error: $(echo "$output" | tail -10)"
            } >> "$PROGRESS_FILE"
        fi

        # Cooldown
        log "INFO" "Cooldown: ${COOLDOWN_SECONDS}s"
        sleep "$COOLDOWN_SECONDS"
    done

    # Final summary
    log "INFO" "=== Autopilot Loop Complete ==="
    log "INFO" "$(get_task_count)"

    {
        echo "---"
        echo "## Autopilot Finished: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "- Total iterations: $CURRENT_ITERATION"
        echo "- $(get_task_count)"
    } >> "$PROGRESS_FILE"

    rm -f "$LOCK_FILE"

    # Context sync: save state for next session
    log "INFO" "Saving context for next session..."
    claude -p --max-budget-usd 0.5 --model "$MODEL" \
        "Run /context-sync save. The autopilot has just completed. Summary: $(get_task_count)" \
        2>/dev/null || true
}

main() {
    local subcommand="${1:-start}"

    case "$subcommand" in
        start)
            start_loop
            ;;
        tmux-start)
            run_loop
            ;;
        *)
            echo "Usage: autopilot.sh [start|tmux-start]"
            echo ""
            echo "  start       Launch the autopilot loop in a tmux session"
            echo "  tmux-start  (internal) Run the loop directly (called from within tmux)"
            exit 1
            ;;
    esac
}

main "$@"
