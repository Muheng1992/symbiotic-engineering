---
name: setup
description: >
  Initialize the Agent Army in your project. Creates the docs/ directory structure,
  report directories, document index, CLAUDE.md template with Clean Architecture
  standards, and configures environment settings for multi-agent development.
  Run this once when setting up Agent Army in a new project.
disable-model-invocation: true
---

# Agent Army Setup

Initialize your project for Agent Army multi-agent development.

## Usage

```
/agent-army:setup [project-name]
```

## What This Does

This setup creates all the infrastructure needed for the Agent Army system to operate in your project.

## Step 1: Create Documentation Structure

Create the following directory tree in the project root:

```
docs/
├── INDEX.md                          # Master document index
├── architecture/                     # Architecture Decision Records
├── reports/                          # All reports (historically preserved)
│   ├── code-review/
│   ├── test/
│   ├── security/
│   ├── fix/
│   ├── integration/
│   ├── quality-gate/
│   └── plans/
├── guides/
├── api/
└── archive/
    └── ARCHIVE-INDEX.md
```

Use `mkdir -p` to create all directories. Then create the following files:

### docs/INDEX.md

```markdown
# Documentation Index

> **Last updated**: [today's date]
> **Total documents**: 0 | Active: 0 | Archived: 0

---

## System Documentation

| Document | Last Updated | Status | Description |
|----------|-------------|--------|-------------|
| (none yet) | — | — | — |

## Architecture Decision Records

| Document | Last Updated | Status |
|----------|-------------|--------|
| (none yet) | — | — |

## Reports

### Plans
| Date | Subject | Status | Author | Link |
|------|---------|--------|--------|------|

### Code Reviews
| Date | Feature | Verdict | Link |
|------|---------|---------|------|

### Test Reports
| Date | Feature | Pass Rate | Coverage | Link |
|------|---------|-----------|----------|------|

### Security Audits
| Date | Scope | Result | Link |
|------|-------|--------|------|

### Fix Reports
| Date | Issue | Root Cause | Link |
|------|-------|-----------|------|

### Integration Reports
| Date | Feature | Status | Link |
|------|---------|--------|------|

### Quality Gate Reports
| Date | Scope | Result | Link |
|------|-------|--------|------|

## Guides
| Document | Last Updated | Status |
|----------|-------------|--------|

## Archived
| Document | Archived Date | Reason | Link |
|----------|--------------|--------|------|

---

*This index is maintained by the `doc-manager` agent. Update after filing any new report.*
```

### docs/archive/ARCHIVE-INDEX.md

```markdown
# Archive Index

> Documents that have been superseded or are no longer active.
> These are preserved for historical reference — NEVER delete archived documents.

| Document | Archived Date | Reason | Original Location | Link |
|----------|--------------|--------|-------------------|------|
```

## Step 2: Create/Update CLAUDE.md

If `.claude/CLAUDE.md` does NOT exist, create it. If it exists, append the Agent Army section.

### Template for new projects:

```markdown
# [Project Name] — Project Standards

> Human-AI Collaborative Development | Clean Architecture | Agent Army

## Architecture Standards: Clean Architecture (Mandatory)

All code MUST follow Clean Architecture principles:

### Dependency Rule
Dependencies point INWARD only. Inner layers never import from outer layers.

```
Domain (innermost) → Application → Adapters → Infrastructure (outermost)
```

### Layer Rules
- **Domain**: Pure business logic. NO framework imports. NO external dependencies.
- **Application**: Use cases and port interfaces. Depends only on Domain.
- **Adapters**: Controllers, repository implementations. Implements ports from Application.
- **Infrastructure**: Framework setup, DI container, config. Wires everything together.

### File Structure
```
src/
├── domain/          # Entities, Value Objects, Domain Events
├── application/     # Use Cases, Ports (interfaces), DTOs
├── adapters/        # Controllers, Repository Implementations
└── infrastructure/  # Config, DI, Server Setup
```

## Coding Standards

### File Limits
- Max file length: 300 lines
- Max function length: 50 lines
- Max parameters: 4 (use object parameter for more)
- Max nesting: 3 levels

### Naming
- Files: `kebab-case.ts`
- Types/Classes: `PascalCase`
- Functions: `camelCase` (verb+noun: `createUser`)
- Constants: `UPPER_SNAKE_CASE`
- Booleans: `is/has/should/can` prefix

### Comments (Human-AI Collaboration)
- `// WHY:` — Non-obvious business reason
- `// CONTEXT:` — Domain knowledge for AI
- `// CONSTRAINT:` — External limitation
- `// AI-BOUNDARY:` — Integration point marker
- `// AI-INVARIANT:` — Must-hold condition
- `// AI-CAUTION:` — Modification impact warning

### Error Handling
- Validate at system boundaries only
- Use typed errors (DomainError, ApplicationError, InfrastructureError)
- Never swallow errors silently

## Agent Army

This project uses the Agent Army plugin for multi-agent development.
See the plugin documentation for available agents and skills.

### Report Management
All reports are filed in `docs/reports/` with timestamps.
Reports are NEVER deleted — only archived to `docs/archive/`.

## Git Workflow
- Branch naming: `feature/[name]`, `fix/[name]`, `refactor/[name]`
- Commit messages: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`)
- Run `/agent-army:quality-gate` before merge
```

## Step 3: Configure Environment

Check if `.claude/settings.json` exists. If not, create it. If it exists, merge the following settings:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(npm test *)",
      "Bash(npm run *)",
      "Bash(npx *)",
      "Bash(python -m pytest *)",
      "Bash(go test *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git branch *)",
      "Bash(gh pr *)",
      "Bash(gh issue *)"
    ]
  }
}
```

**Important**: Merge carefully — do NOT overwrite existing settings. Add to existing arrays.

## Step 4: Verification

After setup, verify:

1. ✅ `docs/` directory structure exists
2. ✅ `docs/INDEX.md` created
3. ✅ `docs/archive/ARCHIVE-INDEX.md` created
4. ✅ `.claude/CLAUDE.md` contains Clean Architecture standards
5. ✅ `.claude/settings.json` has Agent Teams enabled

## Output

```markdown
## Agent Army Setup Complete ✅

### Created
- docs/ directory structure with all report categories
- docs/INDEX.md — Master document index
- docs/archive/ARCHIVE-INDEX.md — Archive index
- .claude/CLAUDE.md — Project standards [created | updated]
- .claude/settings.json — Environment settings [created | merged]

### Next Steps
1. Run `/agent-army:context-sync init` to initialize context management
2. Run `/agent-army:assemble [feature]` to launch your first agent army
3. Run `/agent-army:sprint [feature]` for sprint planning

### Available Commands
| Command | Purpose |
|---------|---------|
| `/agent-army:assemble [feature]` | Launch full agent army |
| `/agent-army:sprint [feature]` | Sprint planning & execution |
| `/agent-army:quality-gate [scope]` | Quality checkpoint |
| `/agent-army:context-sync [action]` | Context management |
| `/agent-army:setup` | This setup (re-run safe) |
```
