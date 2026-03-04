# Agent Army Role Catalog

## Complete Role Registry

| Role | Agent File | Primary Skill | Model | Memory | Key Tools |
|------|-----------|---------------|-------|--------|-----------|
| Tech Lead | `tech-lead.md` | Orchestration | inherit | project | All + Agent |
| Architect | `architect.md` | System Design | inherit | project | Read, Grep, Write |
| Implementer | `implementer.md` | Coding | inherit | project | Read, Write, Edit, Bash |
| Tester | `tester.md` | Testing | inherit | project | Read, Write, Bash |
| Reviewer | `reviewer.md` | Code Review | inherit | project | Read, Grep, Glob |
| Documenter | `documenter.md` | Documentation | sonnet | project | Read, Write, Edit |
| Security Auditor | `security-auditor.md` | Security | inherit | project | Read, Grep, Bash |
| Integrator | `integrator.md` | Integration | inherit | project | All |
| Doc Manager | `doc-manager.md` | Doc Lifecycle | sonnet | project | Read, Write, Grep |
| Reporter | `reporter.md` | Report Generation | sonnet | project | Read, Write |

## Role Interaction Matrix

```
                Architect  Implementer  Tester  Reviewer  Documenter  Security  Integrator  DocMgr  Reporter
Architect         —        provides     —       —         provides    consults    —          —       —
Implementer    receives      —         —       receives  provides    receives  provides    —       provides
Tester            —        receives     —       —         —           —        provides    —       provides
Reviewer          —        reviews      —        —        —           —        provides    —       provides
Documenter     receives    receives   receives   —         —          receives    —         provides provides
Security          —        reviews      —       shares     —           —        provides    —       provides
Integrator     receives    receives   receives receives    —          receives    —          —       provides
DocMgr            —          —          —        —        manages      —          —          —       receives
Reporter          —          —          —        —          —           —          —         provides   —
```

## Role Assignment Decision Tree

```
Is the task about design/architecture?
  YES → architect
  NO ↓
Is it about writing/modifying code?
  YES → implementer (spawn multiple if independent files)
  NO ↓
Is it about writing/running tests?
  YES → tester
  NO ↓
Is it about reviewing code quality?
  YES → reviewer
  NO ↓
Is it about security analysis?
  YES → security-auditor
  NO ↓
Is it about combining multiple agents' work?
  YES → integrator
  NO ↓
Is it about writing documentation?
  YES → documenter
  NO ↓
Is it about managing/filing reports?
  YES → doc-manager + reporter
  NO ↓
Is it a complex multi-step task?
  YES → tech-lead (orchestrates sub-agents)
  NO → implementer (default)
```

## Scaling Patterns

### Horizontal Scaling (Multiple Instances)
These roles support multiple parallel instances:
- **implementer** (x1-5): Each works on different files/components
- **tester** (x1-2): Unit tester + integration tester
- **reviewer** (x1-3): Security focus + performance focus + quality focus

### Roles That Should Be Singleton
- **architect**: One source of truth for design
- **integrator**: One merge coordinator
- **doc-manager**: One librarian
- **tech-lead**: One orchestrator

## Cost Optimization

| Agent | Recommended Model | Rationale |
|-------|------------------|-----------|
| Explore (built-in) | haiku | Fast, read-only, low cost |
| documenter | sonnet | Good writing, lower cost than opus |
| reporter | sonnet | Template-based, doesn't need opus |
| doc-manager | sonnet | Organizational, not creative |
| reviewer | inherit (opus) | Needs deep reasoning for review |
| architect | inherit (opus) | Needs creative design thinking |
| implementer | inherit (opus) | Needs full coding capability |
| security-auditor | inherit (opus) | Needs deep security knowledge |
