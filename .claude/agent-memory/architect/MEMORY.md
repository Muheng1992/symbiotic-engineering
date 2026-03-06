# Architect Agent Memory

## Project: Symbiotic Engineering

### Codebase Patterns Observed

- **Skill structure**: YAML frontmatter (name, description, disable-model-invocation) + phased markdown instructions
- **Agent structure**: YAML frontmatter (name, description, tools, model, memory, permissionMode) + role definition markdown
- **Plugin mirroring**: Skills exist both in `.claude/skills/` (local) and `plugins/agent-army/skills/` (plugin distribution)
- **State management**: Markdown files for human-readable state (BACKLOG.md pattern), JSON for machine config
- **Report filing**: All reports go to `docs/reports/{category}/YYYY-MM-DD-{slug}.md`
- **Safety patterns**: PostToolUse hooks for compliance reminders, PreToolUse hooks for pre-push checks

### Key Architecture Decisions Made

- **2026-03-06 Autopilot Skill**: Two-layer design (SKILL.md for Claude, autopilot.sh for bash outer loop). Fresh `claude -p` session per iteration to avoid context overflow. BACKLOG.md at project root for visibility. Triple safety limit (iterations + cost + duration). See `docs/reports/plans/2026-03-06-autopilot-skill-design.md`.

### Claude CLI Key Flags
- `--print` / `-p`: Non-interactive mode (essential for automation)
- `--max-budget-usd`: Per-session cost cap
- `--model`: Model selection (sonnet, opus, etc.)
- `--dangerously-skip-permissions`: Bypasses all permission checks (sandbox only)
- `--agent`: Specify agent for session
- `--resume` / `--continue`: Session persistence

### Integration Patterns
- Skills can invoke other skills by instructing Claude in their prompt
- `/context-sync save` is the standard way to persist state between sessions
- Git checkpoints use `--no-verify` for speed in automated contexts
- Existing hooks (PostToolUse Write|Edit) fire inside inner Claude sessions
