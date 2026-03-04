# Symbiotic Engineering — Project Standards

> Human-AI 協作開發規範 | Clean Architecture | Agent Army 開發框架

## Project Overview

This project implements the **Symbiotic Engineering** methodology — a framework for maximizing single-developer productivity through AI agent armies. It contains research articles, practical skill definitions, agent configurations, and tooling for orchestrating multi-agent software development.

## Language

- Documentation and comments: 繁體中文 or English (follow existing file convention)
- Code: English (variables, functions, types)
- Git commits: English

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
Use these prefixes for comments:
- `// WHY:` — Non-obvious business reason
- `// CONTEXT:` — Domain knowledge for AI
- `// CONSTRAINT:` — External limitation
- `// AI-BOUNDARY:` — Integration point marker
- `// AI-INVARIANT:` — Must-hold condition
- `// AI-CAUTION:` — Modification impact warning

Do NOT comment obvious code. Let types and naming be self-documenting.

### Error Handling
- Validate at system boundaries only
- Use typed errors (DomainError, ApplicationError, InfrastructureError)
- Never swallow errors silently

## Agent Army System

This project includes a multi-agent development system in `.claude/`:

### Available Agents (`.claude/agents/`)
| Agent | Role | When to Use |
|-------|------|-------------|
| `tech-lead` | Orchestration | Coordination & delegation (no direct coding) |
| `architect` | System Design | Design & planning (plan mode, read-only) |
| `implementer` | Coding | Writing and modifying code |
| `tester` | Testing | Writing and running tests |
| `reviewer` | Code Review | Post-implementation quality review |
| `documenter` | Documentation | Writing and updating docs |
| `security-auditor` | Security | Security scanning and audit |
| `integrator` | Integration | Merging multi-agent work |
| `doc-manager` | Doc Lifecycle | Filing reports, maintaining doc index |
| `reporter` | Report Generation | Creating structured reports |

### Available Skills (`.claude/skills/`)
| Skill | Purpose | Invocation |
|-------|---------|------------|
| `/assemble` | Launch full agent army | `/assemble [feature description]` |
| `/sprint` | Sprint planning & execution | `/sprint [feature or issue]` |
| `/quality-gate` | Quality checkpoint | `/quality-gate [scope]` |
| `/context-sync` | Context management | `/context-sync [action]` |
| `/integration-test` | Integration test orchestration | `/integration-test [scope]` |
| `/code-review` | Code review orchestration | `/code-review [scope]` |
| `/retrospective` | Mission retrospective | `/retrospective` |
| `/tdd` | TDD enforcement | `/tdd [feature description]` |
| `/fix` | Smart problem resolution | `/fix [error or bug description]` |
| `dev-standards` | Coding standards (auto-loaded) | Automatic |

### Report Management
All development reports are filed in `docs/reports/` with timestamps:
- Code reviews → `docs/reports/code-review/`
- Test results → `docs/reports/test/`
- Security audits → `docs/reports/security/`
- Fix reports → `docs/reports/fix/`
- Integration reports → `docs/reports/integration/`

Reports are NEVER deleted — only archived to `docs/archive/`.

## Git Workflow

- Branch naming: `feature/[name]`, `fix/[name]`, `refactor/[name]`
- Commit messages: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`)
- Always run `/quality-gate` before merge

## Testing Standards

- Test files co-located with source OR in parallel `tests/` directory
- Naming: `[module].test.ts` or `test_[module].py`
- Coverage target: ≥ 80% for new code
- Test by layer: Unit (domain) → Integration (adapters) → E2E (infrastructure)
