# Tester Agent Memory

## Skill File Format Standards (Reviewed 2026-03-05)

### YAML Frontmatter Pattern
- Required fields: `name:` (kebab-case), `description:` (multi-line with `>`)
- Optional field: `disable-model-invocation: true` (used by orchestrator skills like assemble, sprint, quality-gate)
- No other fields observed in existing skills

### Structure Pattern
- Usage section should appear near the top (after title, before Phase 1)
- Phases use `##` headers, sub-steps use `###`
- Sub-step naming: both `Step N` and `N.N` styles are used (not yet standardized)
- Output section at end with markdown template examples
- File limit: 300 lines max per project standards

### Cross-Copy Consistency
- Plugin copies (`plugins/agent-army/skills/`) must exactly match local copies (`.claude/skills/`)
- Always verify with `diff` command

### Known Skill Inventory (14 skills)
assemble, sprint, quality-gate, integration-test, code-review, retrospective, tdd, fix, timesheet, dev-standards, setup, context-sync, onboard, changelog
- Plugin: 14 skills (all of the above)
- Local (.claude/skills/): 13 skills (all except setup)

### File Path References (correct paths)
- Reports: `docs/reports/{type}/`
- Agent memory: `.claude/agent-memory/{agent}/MEMORY.md`
- Session state: `~/.claude/projects/{project}/memory/session-state.md`
- Project memory: `~/.claude/projects/{project}/memory/MEMORY.md`
- Docs index: `docs/INDEX.md`

## Review Conventions
- Use structured table format for per-check PASS/FAIL
- Severity levels: CRITICAL > HIGH > MEDIUM > LOW
- Always check plugin/local copy sync with diff
- Always verify line count against 300-line limit

## Template & Hook Review Patterns (2026-03-05)
- Shell hook validation: `sh -n <file>` for syntax check
- JSON validation: `python3 -c "import json; json.load(open('file'))"`
- YAML validation: `python3 -c "import yaml; yaml.safe_load(open('file'))"`
- Placeholder consistency: grep for `\{[A-Z_]+\}` across templates
- Common shell bug: variables set inside piped `while read` subshells don't propagate to parent

## Metadata Consistency Review Findings (2026-03-05)

### Stale Documentation
- Design doc Section 2.2 file tree: `.claude/skills/` listing only shows 10 skills, missing context-sync, onboard, changelog (actual: 13)
- User's project MEMORY.md: says "10 agents" and "12 skills" but actual is 5 agents and 14 skills (outdated from pre-v3.0 consolidation)
- Design doc Section 2.2 file tree: `docs/reports/` shows subdirs code-review/, test/, security/, fix/, integration/ but only plans/ and quality-gate/ exist on disk
- Design doc Section 2.2 file tree: `docs/architecture/` shown but does not exist on disk

### Consistent Items
- Version numbers: plugin.json=3.0.0, marketplace.json plugin=3.0.0, metadata=2.0.0
- Agent count: 5 in both plugin and local, matches all documentation
- Skill count in Section 4.2 table: 13 (correct for local, matching disk)
- Template directories: all present and complete (memory, git-hooks, ci, keybindings, workspace)
- All SKILL.md files exist for all skills in both directories
- marketplace.json description lists all 14 skills correctly

### Review Tip
- Section 2.2 file tree is most prone to staleness -- always recount against disk
- `/batch` in usage guide appendix is NOT a skill (Claude Code built-in) -- acceptable but could confuse

## Known Template Issues
- CI quality-gate.yml: subshell variable scoping bug in commit-msg check (line 94-97)
- pre-push hook: text says "3 seconds" but sleeps 2
- commit-msg hook: `wc -c` counts bytes not chars (UTF-8 edge case)
