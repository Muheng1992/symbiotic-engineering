# Agent Army — Claude Code Plugin

> AI-powered software development team for Claude Code CLI.
> 5 specialized agents + 14 skills + 5 template categories covering the full SDLC with Clean Architecture enforcement.

## Quick Install

### Option 1: Via Marketplace (Recommended)

```bash
# Step 1: Add the marketplace
/plugin marketplace add Muheng1992/symbiotic-engineering

# Step 2: Install the plugin
/plugin install agent-army@symbiotic-engineering

# Step 3: Initialize your project
/agent-army:setup my-project
```

### Option 2: Local Testing

```bash
# Clone the repo
git clone https://github.com/Muheng1992/symbiotic-engineering.git

# Run Claude Code with the plugin
claude --plugin-dir ./symbiotic-engineering/plugins/agent-army
```

### Option 3: Project-scoped Install

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "symbiotic-engineering": {
      "source": {
        "source": "github",
        "repo": "Muheng1992/symbiotic-engineering"
      }
    }
  },
  "enabledPlugins": {
    "agent-army@symbiotic-engineering": true
  }
}
```

## What's Included

### 5 Specialized Agents

| Agent | Role | Model |
|-------|------|-------|
| `tech-lead` | Orchestration & delegation (no Write/Edit) | opus |
| `architect` | System design & API design (plan mode) | opus |
| `implementer` | Code implementation + integration | opus |
| `tester` | Testing + code review + security audit | opus |
| `documenter` | Documentation + reports + filing | sonnet |

### 14 Skills (Slash Commands)

| Skill | Command | Purpose |
|-------|---------|---------|
| **Assemble** | `/agent-army:assemble [feature]` | Launch agent army for a feature |
| **Sprint** | `/agent-army:sprint [feature]` | Sprint planning & task decomposition |
| **Quality Gate** | `/agent-army:quality-gate [scope]` | Quality checkpoint (6 gates) |
| **Integration Test** | `/agent-army:integration-test [scope]` | Integration test orchestration (5-stage) |
| **Code Review** | `/agent-army:code-review [scope]` | Code review orchestration (4-stage) |
| **Setup** | `/agent-army:setup [project-name]` | Initialize project for Agent Army |
| **TDD** | `/agent-army:tdd [feature]` | TDD Red-Green-Refactor enforcement |
| **Fix** | `/agent-army:fix [error]` | Smart problem resolution & diagnosis |
| **Timesheet** | `/agent-army:timesheet [time-range]` | Work time analysis & daily report |
| **Retrospective** | `/agent-army:retrospective` | Mission retrospective & self-improvement |
| **Context Sync** | `/agent-army:context-sync [mode]` | Cross-session context synchronization (save/load/team) |
| **Onboard** | `/agent-army:onboard [project-name]` | Project analysis & memory bootstrapping |
| **Changelog** | `/agent-army:changelog [spec]` | Auto changelog from git history & reports |
| **Dev Standards** | *(auto-loaded)* | Clean Architecture & coding standards |

### Hooks

| Event | Trigger | Action |
|-------|---------|--------|
| `PostToolUse` | After Write/Edit | Remind Clean Architecture compliance |
| `Stop` | Before session end | Check if reports are filed |

### 5 Template Categories

Installed by `/agent-army:setup`:

| Category | Files | Purpose |
|----------|-------|---------|
| **Memory** | `MEMORY.md` + 4 topic files | Structured AI memory architecture for cross-session knowledge |
| **Git Hooks** | `pre-commit`, `commit-msg`, `pre-push` | Auto-check file length, secrets, commit format |
| **CI/CD** | `quality-gate.yml` | GitHub Actions quality gate (6 checks) |
| **Keybindings** | `keybindings.json` | Keyboard shortcuts for common Agent Army commands |
| **Workspace** | `workspace.json` | Multi-project coordination settings |

## Workflow Example

```mermaid
graph LR
    A["/agent-army:setup"] --> B["/agent-army:sprint"]
    B --> C["/agent-army:assemble"]
    C --> D["/agent-army:quality-gate"]

    style A fill:#a49,stroke:#d27,color:#fff
    style B fill:#e96,stroke:#c74,color:#fff
    style C fill:#e74,stroke:#c52,color:#fff
    style D fill:#4a9,stroke:#2d7,color:#fff
```

```
# 1. Setup (first time only)
/agent-army:setup my-app

# 2. Plan a sprint
/agent-army:sprint "Add user authentication with JWT"

# 3. Deploy the agent army
/agent-army:assemble "Add user authentication with JWT"

# 4. Quality check before merge
/agent-army:quality-gate all
```

## Architecture

```
Agent Army Plugin
├── agents/           5 specialized agent definitions
├── skills/           14 skills (slash commands)
│   ├── assemble/     Full army orchestrator
│   ├── sprint/       Sprint planning
│   ├── quality-gate/ Quality checkpoints
│   ├── integration-test/ Integration test orchestration
│   ├── code-review/  Code review orchestration
│   ├── tdd/          TDD enforcement
│   ├── fix/          Smart problem resolution
│   ├── timesheet/    Work time analysis & daily report
│   ├── retrospective/ Mission retrospective
│   ├── context-sync/ Cross-session context sync
│   ├── onboard/      Project analysis & memory init
│   ├── changelog/    Auto changelog generation
│   ├── setup/        Project initialization
│   └── dev-standards/ Coding standards (auto-loaded)
├── templates/        5 template categories
│   ├── memory/       AI memory architecture templates
│   ├── git-hooks/    Pre-commit, commit-msg, pre-push
│   ├── ci/           GitHub Actions quality gate
│   ├── keybindings/  Keyboard shortcut definitions
│   └── workspace/    Multi-project coordination
└── hooks/            Clean Architecture enforcement
```

## Requirements

- Claude Code CLI (v1.0.33+)
- Agent Teams feature: set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in environment

## Key Features

- **Streamlined Team**: 5 agents based on industry best practices (3-5 recommended by Anthropic)
- **Parallel Agent Execution**: Multiple agents work simultaneously on independent tasks
- **Clean Architecture Enforcement**: Hooks + standards ensure dependency rules
- **Full Report Lifecycle**: All reviews, tests, audits filed and historically preserved
- **Cost Optimization**: Documentation agent uses Sonnet; reasoning agents use Opus
- **TDD Enforcement**: Red-Green-Refactor cycle as a blocking gate
- **Smart Fix**: Automatic diagnosis and dynamic agent selection for bug fixes
- **Role Isolation**: Tech Lead coordinates only; Architect designs only (plan mode)
- **Cross-Session Memory**: Context Sync saves/restores work state across sessions
- **One-Click Onboard**: Scans project, generates structured memory for instant context
- **Auto Changelog**: Generates Keep a Changelog format from git history & reports
- **Project Templates**: 5 template categories (memory, git-hooks, CI, keybindings, workspace)

## Version

**Current**: v3.0.0

See the main repository [CHANGELOG.md](../../CHANGELOG.md) for version history.

## License

MIT
