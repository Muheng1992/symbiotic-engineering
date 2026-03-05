# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-03-05

### Added
- **context-sync** skill: Cross-session context synchronization (save/load/team)
- **onboard** skill: Project analysis and memory bootstrapping for new projects
- **changelog** skill: Auto changelog generation from git history and development reports
- **Templates system**: 5 template categories for project initialization
  - Memory templates (MEMORY.md + 4 topic files)
  - Git Hooks templates (pre-commit, commit-msg, pre-push)
  - CI/CD template (quality-gate.yml for GitHub Actions)
  - Keybindings template (keyboard shortcuts for Agent Army commands)
  - Workspace template (multi-project coordination settings)
- Setup skill now installs templates, detects MCP servers, and configures keybindings
- Comprehensive documentation (design doc, usage guide, INDEX.md)

### Changed
- Skill count increased from 11 to 14
- Plugin manifest updated to reflect templates and new skills
- Marketplace description updated with full feature list

## [2.0.0] - 2026-03-04

### Changed
- **Agent consolidation**: Reduced from 10 agents to 5 specialized agents
  - `implementer` now absorbs `integrator` responsibilities
  - `tester` now absorbs `reviewer` and `security-auditor` responsibilities
  - `documenter` now absorbs `reporter` and `doc-manager` responsibilities
- Removed: `integrator`, `reviewer`, `security-auditor`, `reporter`, `doc-manager` agents
- Reduced coordination overhead, improved parallel execution efficiency
- New Grading Card system for mandatory scope analysis before spawning agents

### Added
- **integration-test** skill: 5-stage integration test orchestration
- **code-review** skill: 4-stage structured code review
- **fix** skill: Smart problem resolution with automatic agent selection
- **tdd** skill: TDD Red-Green-Refactor enforcement with phase gates
- **timesheet** skill: Work time analysis and daily report generation
- **retrospective** skill: Mission retrospective and self-improvement
- Plugin distribution via GitHub Marketplace
- Setup skill for one-command project initialization
- Complexity Grading Card (S/A/B/C) with hard agent limits
- Sub-coordinator pattern for C-grade tasks

## [1.0.0] - 2026-03-01

### Added
- Initial release with 10 agents
- Core skills: assemble, sprint, quality-gate, dev-standards
- Clean Architecture enforcement via hooks
- Report management system (docs/reports/)
- Archive system (docs/archive/)
- CLAUDE.md project standards template
