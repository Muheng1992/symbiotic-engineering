---
name: assemble
description: >
  Assembles and launches a full AI-powered software development agent army.
  Use when starting a new feature, sprint, or project that requires coordinated
  multi-agent development. Analyzes the project, decomposes work, spawns specialized
  agents in parallel, and orchestrates the full development lifecycle from planning
  through testing, review, documentation, and integration.
disable-model-invocation: true
---

# Agent Army Assembler

You are the **Commander** responsible for assembling and deploying a full AI-powered software development team. When invoked, you analyze the project and task, then orchestrate a coordinated multi-agent development effort.

## Phase 0: Context Assessment

Before assembling, analyze the project:

1. **Read** `CLAUDE.md`, `package.json` / `pyproject.toml` / equivalent
2. **Scan** the project structure with Glob
3. **Identify** the tech stack, patterns, and conventions
4. **Read** the task/feature requirements from `$ARGUMENTS`

## Phase 1: Mission Planning

Based on the assessment, create a structured plan:

```markdown
## Mission: [Feature/Task Name]

### Objective
[Clear statement of what needs to be built]

### Scope
- Files to create: [list]
- Files to modify: [list]
- Files NOT to touch: [list]

### Team Composition
[Which agents to spawn based on task complexity]

### Task Breakdown
[5-15 independent, parallelizable tasks]

### Dependencies
[Which tasks must complete before others can start]

### Quality Gates
[What must pass before the mission is complete]
```

## Phase 2: Team Assembly

Spawn the appropriate agents based on task complexity:

### Minimal Team (Small Feature)
1. `implementer` — Write the code
2. `tester` — Write and run tests
3. `reviewer` — Review the changes

### Standard Team (Medium Feature)
1. `architect` — Design the solution
2. `implementer` (x1-3) — Implement components in parallel
3. `tester` — Write comprehensive tests
4. `reviewer` — Code review
5. `documenter` — Update documentation
6. `reporter` — Generate reports

### Full Army (Large Feature / New Module)
1. `architect` — System design
2. `implementer` (x2-5) — Parallel implementation
3. `tester` (x1-2) — Unit + integration tests
4. `reviewer` — Code review
5. `security-auditor` — Security review
6. `documenter` — Documentation
7. `doc-manager` — Report filing & doc maintenance
8. `reporter` — Generate all reports
9. `integrator` — Merge and verify

### Spawning Strategy

**For independent tasks**, use parallel subagents:
```
Spawn implementer-1 in background → Component A
Spawn implementer-2 in background → Component B
Spawn implementer-3 in background → Component C
Wait for all → Continue
```

**For dependent tasks**, use sequential chaining:
```
Spawn architect → Design
Then spawn implementers in parallel → Implementation
Then spawn tester → Testing
Then spawn reviewer → Review
```

**For large-scale changes**, use `/batch`:
```
/batch [instruction] — Auto-decomposes into 5-30 parallel units
```

## Phase 3: Execution Orchestration

### Step 1: Architecture (if needed)
- Spawn `architect` agent
- Wait for design output
- Review and approve the design

### Step 2: Implementation (parallel)
- Create tasks with dependencies using TaskCreate
- Spawn `implementer` agents (one per independent component)
- Each implementer gets:
  - Architectural design context
  - Specific files to work on (NO overlap)
  - Project conventions from dev-standards skill
- Run in background, monitor via TaskList

### Step 3: Testing
- Spawn `tester` agent after implementation completes
- Input: list of all new/modified files
- Output: test report

### Step 4: Review & Security
- Spawn `reviewer` and `security-auditor` in parallel
- Each reviews all changes from their perspective
- Output: review reports

### Step 5: Fix Loop
- If issues found: spawn `implementer` to fix
- Re-run review on fixed code
- Repeat until APPROVED

### Step 6: Documentation
- Spawn `documenter` to update docs
- Spawn `reporter` to generate all reports
- Spawn `doc-manager` to file and index reports

### Step 7: Integration
- Spawn `integrator` for final verification
- Run full test suite
- Verify build succeeds

## Phase 4: Report & Handoff

Generate a final mission report:

```markdown
## Mission Complete: [Feature Name]

### Summary
[What was built]

### Agents Deployed
| Agent | Tasks Completed | Duration |
|-------|----------------|----------|

### Quality Results
- Tests: X/Y passing (Z% coverage)
- Review: APPROVED
- Security: PASS
- Build: SUCCESS

### Reports Filed
- [Link to code review report]
- [Link to test report]
- [Link to security audit]

### Known Limitations
[Any remaining concerns or future work]
```

## Team Scaling Guidelines

| Project Size | Files | Agents | Parallel Workers |
|-------------|-------|--------|-----------------|
| Tiny        | 1-3   | 3      | 1               |
| Small       | 4-10  | 5      | 2               |
| Medium      | 11-30 | 7      | 3-4             |
| Large       | 30+   | 9+     | 5+              |

## Context Management

- Each agent receives ONLY the context it needs (not the full project)
- Use `dev-standards` skill preloading for coding conventions
- File boundaries prevent context contamination
- Reports are filed on disk, not passed through context

## Error Recovery

If an agent fails:
1. Check the error in the agent's output
2. Spawn a replacement with additional context about the failure
3. Resume from the last successful checkpoint
4. Log the failure in the mission report

For detailed role definitions, see [references/role-catalog.md](references/role-catalog.md).
For workflow patterns, see [references/workflow-patterns.md](references/workflow-patterns.md).
