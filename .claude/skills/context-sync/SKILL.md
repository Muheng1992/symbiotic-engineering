---
name: context-sync
description: >
  Context management and synchronization for multi-agent development. Use when
  agents need shared context, when the project context needs refreshing, or when
  setting up a new session. Manages the project knowledge base, decision log,
  and ensures agents have the context they need without context overflow.
disable-model-invocation: true
---

# Context Synchronization Manager

Manages shared context across agent sessions and development activities.

## Usage

```
/context-sync [action: init | refresh | status | sync-agents | export]
```

## Action: init

Initialize the context management infrastructure for the project.

1. Create the context directory structure:
```
.claude/
├── context/
│   ├── PROJECT-CONTEXT.md      # Project overview for agent onboarding
│   ├── DECISION-LOG.md         # Architectural and design decisions
│   ├── TECH-STACK.md           # Technology stack reference
│   └── ACTIVE-WORK.md          # Current sprint/feature state
```

2. Auto-populate by scanning:
   - `package.json` / `pyproject.toml` / `go.mod` → tech stack
   - Directory structure → architecture overview
   - Existing README → project purpose
   - Git log → recent activity
   - `.claude/CLAUDE.md` → project conventions

3. Generate `PROJECT-CONTEXT.md`:
```markdown
# Project Context

## Purpose
[Auto-detected from README]

## Tech Stack
[Auto-detected from package manager files]

## Architecture
[Auto-detected from directory structure]

## Key Patterns
[Auto-detected from code analysis]

## Active Conventions
[From CLAUDE.md]
```

## Action: refresh

Update existing context files with current state:

1. Scan for new files, changed patterns, new dependencies
2. Update TECH-STACK.md if dependencies changed
3. Update ACTIVE-WORK.md with current task status
4. Identify and flag stale context

## Action: status

Show current context health:

```markdown
## Context Status

### Files
| Context File | Last Updated | Status |
|-------------|-------------|--------|
| PROJECT-CONTEXT.md | YYYY-MM-DD | ✅ Current |
| DECISION-LOG.md | YYYY-MM-DD | ⚠️ 3 undocumented decisions |
| TECH-STACK.md | YYYY-MM-DD | ✅ Current |
| ACTIVE-WORK.md | YYYY-MM-DD | 🔄 Needs refresh |

### Agent Memory Status
| Agent | Memory Size | Last Updated |
|-------|------------|-------------|
| architect | 2.3 KB | YYYY-MM-DD |
| implementer | 1.8 KB | YYYY-MM-DD |

### Context Budget
- CLAUDE.md: XXX chars / recommended 5000 max
- Skills loaded: N skills, XXX chars total
- Estimated context usage: XX% of budget
```

## Action: sync-agents

Prepare context packages for agent spawning:

For each agent role, generate a focused context summary:
- **architect**: Project architecture, design decisions, tech stack
- **implementer**: Coding conventions, patterns, active files
- **tester**: Test infrastructure, coverage status, test patterns
- **reviewer**: Quality standards, common issues, review history
- **security-auditor**: Security requirements, past findings

This reduces spawn prompt size while maximizing relevance.

## Action: export

Export the current project context as a portable package:

1. Collect all `.claude/` configuration
2. Collect context files
3. Generate a setup guide for replication
4. Output as a zip or directory that can be copied to another project

## Decision Log Format

```markdown
# Decision Log

## DEC-001: [Title]
- **Date**: YYYY-MM-DD
- **Decision**: [What was decided]
- **Context**: [Why this decision was needed]
- **Alternatives Considered**: [What else was considered]
- **Consequences**: [Tradeoffs accepted]
- **Decided By**: [human / architect-agent / team consensus]

## DEC-002: ...
```

## Context Budget Guidelines

To prevent context overflow:

| Component | Budget | Purpose |
|-----------|--------|---------|
| CLAUDE.md | ≤ 150 lines | Core project instructions |
| Skill descriptions | ≤ 16KB total | Available skill catalog |
| Skill content | On-demand | Loaded when invoked |
| Agent memory | ≤ 200 lines MEMORY.md | Cross-session learnings |
| Spawn prompts | ≤ 2000 tokens each | Task-specific context |

## Agent Onboarding Protocol

When spawning a new agent, provide:

1. **Role**: Which agent definition (from .claude/agents/)
2. **Task**: Specific work to accomplish
3. **Files**: Which files to read/modify
4. **Context**: Key decisions and constraints from DECISION-LOG.md
5. **Standards**: Preload dev-standards skill
6. **Boundaries**: What NOT to touch

This ensures agents start productive immediately without exploring.
