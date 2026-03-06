# Documenter Agent Memory

## Project Knowledge

### Documentation Structure
- **Location**: `/Users/muhengli/HephAIProject/symbiotic-engineering/docs/`
- **Master Index**: `docs/INDEX.md` (must update after filing any document)
- **Language**: 繁體中文 for user-facing docs, English for code/commits

### Document Categories

#### Research Articles (`docs/guides/`)
- 7-part Claude Code research series (completed)
- Remote development guides (iPhone, dual Mac)
- Technical deep-dives (MCP, observability, enterprise deployment)
- **Latest**: Continuous iteration research (Ralph Loop, Stop Hook, tmux orchestrator)

#### Plugin Documentation (`docs/plugin/`)
- Agent Army design and usage guides
- Plugin installation README

#### Reports (`docs/reports/`)
- Never delete — archive to `docs/archive/` instead
- Categories: plans, code-review, test, security, fix, integration, quality-gate
- Always include timestamps in filenames

#### Templates (`plugins/agent-army/templates/`)
- 6 categories: memory, git-hooks, ci, keybindings, workspace, **autopilot**
- Use `{{PLACEHOLDER}}` syntax for variables

### Filing Protocol

1. Write document to appropriate directory
2. Update `docs/INDEX.md` (increment document count, add entry)
3. Update last modified date in INDEX.md
4. Cross-reference related documents

### Documentation Standards

#### Research Article Style
- Use Mermaid diagrams extensively
- 繁體中文 body, English for technical terms
- 500-800 lines optimal length
- Include: 摘要, 目錄, numbered sections, 參考資源, 結論與建議
- Use tables and comparison matrices
- Add mindmaps for concept overviews

#### Template Style
- Clear placeholder descriptions
- Include usage examples
- Add metadata header (Generated date, source, etc.)
- Provide status legends and documentation

## Recent Work

### 2026-03-06: Continuous Iteration Research
- Created comprehensive research doc on Ralph Loop, Stop Hook, tmux orchestrator
- Added BACKLOG.template.md for autopilot mode
- Documented integration with Agent Army (/assemble, /sprint, /context-sync)
- Filed to `docs/guides/continuous-iteration-research.md`
- Updated INDEX.md (18 active documents)

## Patterns to Remember

### Mermaid Usage
- Use `graph TD` for workflows
- Use `sequenceDiagram` for interactions
- Use `mindmap` for concept overviews
- Use `timeline` for evolution/history

### Comparison Tables
Always include when comparing approaches:
- 方案比較 (feature comparison)
- 優缺點分析 (pros/cons)
- 使用場景推薦 (use case recommendations)

### Cross-References
Link to related docs:
- Internal: `[Title](relative-path.md)`
- Always use relative paths within docs/

## Anti-Patterns

- ❌ Don't use emojis unless explicitly requested
- ❌ Don't delete reports — archive them
- ❌ Don't modify filed reports — create addendums
- ❌ Don't skip INDEX.md updates
- ❌ Don't write documentation without user request
