# Reviewer Agent Memory

## Project: Symbiotic Engineering

### Review Patterns & Lessons Learned

#### 2026-03-04: Cross-file Consistency Review (v1.3 improvements)

**Key findings from Agent Army system consistency review:**

1. **Plugin sync**: Local and plugin files must be byte-identical. Use `diff` to verify.
2. **Skill count issues**: Design doc has had recurring skill count inconsistencies. Always verify against actual directory listings.
3. **Agent count arithmetic**: When grading tables say "4-6 agents" but the enumerated list can produce 7, that's a contradiction. Always count min/max from the actual agent list.
4. **Direct communication tables**: Tech-lead.md is the authoritative source for allowed direct comms. Individual agent files may define extra paths not authorized by tech-lead -- these are contradictions.
5. **Directory tree in docs**: Must be manually updated when skills are added. Easily missed.
6. **Mermaid diagrams**: Check that they match the prose tables they illustrate. In section 10.1, skill count in Mermaid was "6 skills" while rest of doc says "10".

### Common Cross-Reference Issues
- Design doc section 2.2 local directory tree vs actual disk contents
- Design doc section 10.1 Mermaid vs actual plugin directory
- Tech-lead grading table "Agents" column vs separate Documentation Strategy table
- Failure recovery: tech-lead says "max 2 replacements" vs assemble/design-doc says "3+ retries = stop"

#### 2026-03-04: Timesheet Skill Review (v1.5)

**Key findings:**
1. **Version footer not updated**: Design doc header said 1.5.0 but footer still said v1.4.0. Always check both header and footer.
2. **Skill count in section 10.2 directory tree**: Said "11 Skills" when actual count was 12. Section 10.1 Mermaid was correct. Multiple places to update.
3. **Mermaid diagrams**: S11[timesheet] added to section 4.3 but had no relationship arrows (orphan node). Section 2.1 Command Layer did not include /timesheet at all.
4. **Dead config fields**: `workingHours` defined in config schema but never referenced in algorithm. Always check that config fields are actually consumed.
5. **Algorithm estimation concerns**: Hardcoded 30-min pre-commit padding + complexity multipliers compound errors. Configurable padding recommended.
6. **`find -newer` needs reference files**: Skill used `-newer [date-ref]` without explaining temp file creation via `touch -t`.
7. **Report filing convention**: Other skills file to `docs/reports/`, timesheet outputs to terminal only -- breaks project convention.

### Common Cross-Reference Checklist (Updated v1.5)
When a new skill is added, verify ALL these locations:
- [ ] `.claude/CLAUDE.md` skill table
- [ ] Design doc section 2.1 Mermaid (Command Layer)
- [ ] Design doc section 2.2 directory tree (local skills)
- [ ] Design doc section 4.2 skill table
- [ ] Design doc section 4.3 Mermaid (skill-agent relationships)
- [ ] Design doc section 10.1 Mermaid (plugin skill count)
- [ ] Design doc section 10.2 directory tree (plugin skills + count comment)
- [ ] Design doc version header AND footer
- [ ] `plugins/agent-army/.claude-plugin/plugin.json` version + description
- [ ] `.claude-plugin/marketplace.json` version + description
- [ ] `plugins/agent-army/README.md` skill table + architecture tree
- [ ] Local vs plugin SKILL.md byte-identical (use `diff`)

### File Locations
- Local agents: `.claude/agents/`
- Plugin agents: `plugins/agent-army/agents/`
- Local skills: `.claude/skills/` (11 skills, no setup)
- Plugin skills: `plugins/agent-army/skills/` (12 skills, includes setup)
- Design doc: `docs/AGENT-ARMY-DESIGN.md`
