# Implementer Agent Memory

## Project: Symbiotic Engineering

### Key Patterns
- Agent definitions exist in TWO locations that must stay in sync:
  - `.claude/agents/` (local project use)
  - `plugins/agent-army/agents/` (plugin distribution)
- Skill definitions also exist in TWO mirrored locations:
  - `.claude/skills/[skill-name]/SKILL.md` (local project use)
  - `plugins/agent-army/skills/[skill-name]/SKILL.md` (plugin distribution)
  - Exception: `setup` skill exists only in `plugins/agent-army/skills/`
- Always verify both copies are identical after modification using `diff`

### Conventions
- Agent `.md` files use YAML frontmatter (name, description, tools, model, memory)
- Skill SKILL.md files use YAML frontmatter (name, description)
- Last line of agent files is typically an "Update your agent memory..." instruction
- New sections should be inserted before that final line
- Section hierarchy: `##` for major sections, `###` for subsections within

### Completed Tasks
- 2026-03-04: Added Adversarial Review Protocol to `reviewer.md` (both locations)
  - Inserted before "## Review Principles" section
  - Includes: Challenge Architect, Challenge Implementer, Cross-Verification with Security Auditor, Adversarial Output table format
- 2026-03-04: Added Adversarial Review Protocol to `security-auditor.md` (both locations)
  - Inserted before final "Update your agent memory..." line
  - Includes: Challenge Architect's Design, Challenge Implementer's Code, Cross-Verification with Reviewer, Adversarial Output table format
- 2026-03-04: Created `/retrospective` skill (both locations)
  - Files: `.claude/skills/retrospective/SKILL.md` and `plugins/agent-army/skills/retrospective/SKILL.md`
  - 5-phase structured retrospective: Data Collection, Analysis, Pattern Recognition, Actionable Improvements, Memory Update
  - Reports filed to `docs/reports/retrospective/`
- 2026-03-04: Added plan mode to `architect.md` (both locations)
  - Frontmatter: added `permissionMode: plan`, removed `Write, Edit` from tools
  - Added `## Plan Mode` section after `## Design Principles` and before `## Output Format`
  - Includes: Design-Only Workflow (5 steps), Why Plan Mode (4 reasons)
  - Agent can only read/analyze, not write/edit — enforces design-before-implementation
- 2026-03-04: Created `/tdd` skill (both locations)
  - Files: `.claude/skills/tdd/SKILL.md` and `plugins/agent-army/skills/tdd/SKILL.md`
  - Red-Green-Refactor cycle enforcement with strict phase gates
  - Includes: 3-phase process, gate checks, anti-pattern table, report format
  - Updated `tester.md` (both locations) to add `- tdd` to skills list
