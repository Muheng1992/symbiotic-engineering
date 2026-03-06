# Implementer Agent Memory

## Project: Symbiotic Engineering

### Codebase Patterns

#### Skill File Structure
- Location: `plugins/agent-army/skills/{skill-name}/SKILL.md`
- YAML frontmatter with `name` and `description` fields
- `description` uses YAML block scalar `>` for multi-line
- Title format: `# Skill Name -- Chinese Subtitle` (using em dash or double hyphen)
- Structured with numbered Phases, each with numbered Steps
- Usage section with code blocks showing invocation examples
- Output section describing what each mode displays
- Edge Cases section at the end
- 300 line soft limit; larger skills (assemble: 316, setup: 436) are acceptable for comprehensive guides

#### Existing Skills (15 total: 14 local + setup plugin-only)
assemble, autopilot, code-review, context-sync, dev-standards, fix,
integration-test, onboard, quality-gate, retrospective, setup (plugin-only),
sprint, tdd, timesheet, changelog

#### Autopilot System
- Two-layer: SKILL.md (Claude-facing) + autopilot.sh (bash outer loop)
- Script at `.claude/autopilot/autopilot.sh` (runtime tool, not in skills/)
- Runtime files: config.json, BACKLOG.md (project root), progress.txt (project root)
- tmux is HARD dependency (no fallback)
- Commit prefix: `autopilot:` (not conventional commits)
- macOS sed: always use `sed -i ''` (not `sed -i`)
- Relaxed defaults: 50 iter / $25 cost / 240 min / $5 per-iter / 30s cooldown
- Bash scripts: validate with `bash -n` before committing

#### Git Hook Templates
- Location: `plugins/agent-army/templates/git-hooks/`
- 3 hooks: `pre-commit`, `commit-msg`, `pre-push`
- Must use `#!/bin/sh` (POSIX) for portability, not `#!/bin/bash`
- Must be `chmod +x` after creation
- Validate syntax with `sh -n` before committing
- Setup skill copies these into `.git/hooks/` in the target project

#### Keybindings Template
- Location: `plugins/agent-army/templates/keybindings/keybindings.json`
- 7 bindings: Ctrl+Shift+{A,Q,R,T,F,S,C} for assemble, quality-gate, code-review, tdd, fix, sprint, context-sync
- Merge with existing `~/.claude/keybindings.json`, do not overwrite

#### Workspace Template
- Location: `plugins/agent-army/templates/workspace/workspace.json`
- Supports multi-project coordination and cross-project timesheet
- Placeholders: `{WORKSPACE_NAME}`, `{PROJECT_N_NAME}`, `{PROJECT_N_PATH}`, `{PROJECT_N_DESCRIPTION}`

#### Memory Templates (5 files)
- Location: `plugins/agent-army/templates/memory/`
- MEMORY.md (60 lines), architecture.md (61), debugging.md (45), patterns.md (56), conventions.md (49)
- Use `{PLACEHOLDER}` syntax for values that setup skill replaces
- Placeholders: `{PROJECT_NAME}`, `{PROJECT_TYPE}`, `{PROJECT_PATH}`, `{ARCHITECTURE_PATTERN}`,
  `{LANGUAGE}`, `{FRAMEWORK}`, `{BUILD_TOOL}`, `{TEST_FRAMEWORK}`,
  `{BUILD_COMMAND}`, `{TEST_COMMAND}`, `{START_COMMAND}`, `{LINT_COMMAND}`, `{PROJECT_ROOT}`
- Use `<!-- comment -->` for inline agent instructions

### Conventions
- Local skills at `.claude/skills/` (14 skills, no setup)
- Plugin skills at `plugins/agent-army/skills/` (12+ skills)
- Plugin skills are namespaced: `/agent-army:{skill-name}`
- Template files live in `plugins/agent-army/templates/` (plugin-only, not mirrored locally)
- Reports go to `docs/reports/` with timestamps
- User prefers Traditional Chinese (繁體中文) in responses and some doc titles
