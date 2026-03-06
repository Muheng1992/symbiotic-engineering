# Autopilot Backlog

> Generated: 2026-03-06 17:45
> Source: 針對專案深入研究提升開發效率的好工具與好設計，寫文件、評估價值、寫程式
> Total tasks: 18

## Context

Symbiotic Engineering 是一個基於 Claude Code CLI 的多代理開發框架（v3.1.0），包含 5 個 agent、15 個 skill、plugin 分發系統。目前缺少：代碼腳手架工具、成本追蹤、DAG 任務排程、批量操作、agent 健康監控。本次迭代的目標是研究最佳工具與設計模式，撰寫分析文件，評估優先順序，然後實作最有價值的改進。

## Tasks

### Phase 1: Research & Documentation

- [x] **T01**: Research developer productivity tools and patterns
  - Description: 研究 2025-2026 年開發效率工具生態系。涵蓋：(1) Code scaffolding/template engines (Plop, Hygen, Yeoman alternatives) (2) DAG-based task schedulers (Dagger, Turborepo patterns) (3) Agent cost tracking solutions (Langfuse, Helicone, custom hooks) (4) Batch operation patterns for AI agents (5) Agent health monitoring patterns (heartbeat, watchdog). 將研究結果寫入 `docs/guides/dev-efficiency-tools-research.md`，格式參考現有 guides（繁體中文，30-50KB）。
  - Files: docs/guides/dev-efficiency-tools-research.md
  - Acceptance: 文件存在且包含至少 5 個工具類別的深度分析，每個類別至少 3 個候選方案
  - Dependencies: none

- [x] **T02**: Research multi-agent coordination design patterns
  - Description: 研究多代理協調設計模式。涵蓋：(1) DAG vs linear task scheduling (2) Agent state machines (idle/running/blocked/failed) (3) Event-driven agent communication (4) Feedback loop optimization (tester↔implementer) (5) Resource contention strategies (file locks, worktree). 寫入 `docs/guides/multi-agent-coordination-patterns.md`。
  - Files: docs/guides/multi-agent-coordination-patterns.md
  - Acceptance: 文件存在且包含架構圖（Mermaid）、對比表、與 Symbiotic Engineering 的整合建議
  - Dependencies: none

- [x] **T03**: Research security hardening for AI agent systems
  - Description: 研究 AI agent 系統安全強化。涵蓋：(1) OWASP Top 10 for Agentic Applications (2) Permission sandboxing (devcontainer, --dangerously-skip-permissions 風險) (3) Secret management for multi-agent (4) Audit trail hooks (ConfigChange, HTTP hooks) (5) Supply chain security (dependency scanning). 寫入 `docs/guides/agent-security-hardening-guide.md`。
  - Files: docs/guides/agent-security-hardening-guide.md
  - Acceptance: 文件存在且包含具體的安全清單、hook 範例、threat model
  - Dependencies: none

### Phase 2: Evaluation & Prioritization

- [ ] **T04**: Write value evaluation report with priority matrix
  - Description: 讀取 T01-T03 產出的三份研究文件，建立價值評估矩陣。評估每個工具/設計的：(1) 對開發效率的影響（High/Medium/Low）(2) 實作複雜度（High/Medium/Low）(3) 與現有系統的相容性 (4) 預估 ROI。產出一份排序後的優先順序報告 `docs/reports/plans/2026-03-06-efficiency-improvement-plan.md`。必須包含前 5 名推薦實作項目，並說明理由。
  - Files: docs/reports/plans/2026-03-06-efficiency-improvement-plan.md
  - Acceptance: 報告包含優先矩陣表格、前 5 名推薦、每項的實作估算
  - Dependencies: T01, T02, T03

### Phase 3: Implement High-Value Items

- [ ] **T05**: Create `/scaffold` skill for code generation templates
  - Description: 建立 `/scaffold` skill，支援從模板快速產生程式碼。功能：(1) 支援多種模板類型（component, service, domain-entity, use-case, adapter, test） (2) 自動套用 Clean Architecture 層級命名 (3) 內建常用 patterns（Repository, Factory, Strategy, Observer） (4) 產生對應的 test stub。Skill 定義在 `.claude/skills/scaffold/SKILL.md`。
  - Files: .claude/skills/scaffold/SKILL.md, .claude/skills/scaffold/references/templates.md
  - Acceptance: Skill 檔案存在、語法正確、包含至少 4 種模板類型
  - Dependencies: T04

- [ ] **T06**: Create scaffold skill for plugin distribution
  - Description: 將 T05 建立的 scaffold skill 複製到 plugin 目錄 `plugins/agent-army/skills/scaffold/`，調整命名空間為 `/agent-army:scaffold`。確保與 plugin.json 相容。
  - Files: plugins/agent-army/skills/scaffold/SKILL.md, plugins/agent-army/skills/scaffold/references/templates.md
  - Acceptance: Plugin 目錄下的 scaffold skill 存在且路徑正確
  - Dependencies: T05

- [ ] **T07**: Implement agent cost tracker hook system
  - Description: 在 `.claude/hooks/` 下建立成本追蹤機制。(1) 建立 `cost-tracker.sh` 腳本，在每次 tool call 後記錄使用量到 `.claude/autopilot/logs/cost-log.jsonl` (2) 追蹤欄位：timestamp, agent_name, tool_name, model, estimated_tokens (3) 在 settings.json 的 PostToolUse hooks 中加入成本追蹤 hook (4) 建立 `/cost-report` 的簡單讀取邏輯。
  - Files: .claude/hooks/cost-tracker.sh, .claude/skills/cost-report/SKILL.md
  - Acceptance: Hook 腳本可執行、skill 定義正確、成本日誌格式為 JSONL
  - Dependencies: T04

- [ ] **T08**: Implement DAG-based task scheduler for autopilot
  - Description: 改進 autopilot.sh 的任務排程，從線性掃描改為 DAG 拓撲排序。(1) 新增 `task-scheduler.sh` 作為獨立模組 (2) 解析 BACKLOG.md 的依賴關係建立 DAG (3) 使用 Kahn's algorithm 進行拓撲排序 (4) 支援並行任務識別（無依賴衝突的任務可同時執行） (5) 更新 autopilot.sh 使用新排程器。
  - Files: .claude/autopilot/task-scheduler.sh, .claude/autopilot/autopilot.sh
  - Acceptance: 排程器可正確處理依賴、拓撲排序、並行識別
  - Dependencies: T04

### Phase 4: Implement Medium-Value Items

- [ ] **T09**: Create `/batch` skill for parallel file transformations
  - Description: 建立 `/batch` skill，支援對多檔案進行批量轉換。(1) 接受 glob pattern + transformation description (2) 對每個匹配檔案平行執行轉換 (3) 支援 dry-run 模式（預覽變更） (4) 自動 git checkpoint before/after (5) 彙總報告。Skill 在 `.claude/skills/batch/SKILL.md`。
  - Files: .claude/skills/batch/SKILL.md
  - Acceptance: Skill 定義正確、包含 dry-run 支援、使用範例
  - Dependencies: T04

- [ ] **T10**: Create batch skill for plugin distribution
  - Description: 將 T09 的 batch skill 複製到 plugin 目錄 `plugins/agent-army/skills/batch/`。
  - Files: plugins/agent-army/skills/batch/SKILL.md
  - Acceptance: Plugin 目錄下的 batch skill 存在
  - Dependencies: T09

- [ ] **T11**: Implement agent health monitor for autopilot
  - Description: 在 autopilot 系統中加入 agent 健康監控。(1) 新增 `health-monitor.sh` 模組 (2) 監控：iteration timeout（超過 10 分鐘警告）、連續失敗次數、cost burn rate (3) 寫入 health log `.claude/autopilot/logs/health.jsonl` (4) 在 autopilot.sh 主迴圈中整合健康檢查 (5) 超過閾值時自動觸發 graceful stop。
  - Files: .claude/autopilot/health-monitor.sh, .claude/autopilot/autopilot.sh
  - Acceptance: 健康監控腳本可執行、整合到主迴圈、有 timeout 和 failure rate 檢測
  - Dependencies: T08

- [ ] **T12**: Create enhanced GitHub Actions CI template
  - Description: 增強 `plugins/agent-army/templates/ci/quality-gate.yml`。(1) 加入 dependency scanning (npm audit / pip-audit) (2) 加入 SAST 掃描 (semgrep) (3) 加入 test coverage reporting (4) 加入 architecture compliance check via grep patterns (5) 加入 cost budget check for AI agents in CI。
  - Files: plugins/agent-army/templates/ci/quality-gate.yml, plugins/agent-army/templates/ci/security-scan.yml
  - Acceptance: YAML 語法正確、包含至少 4 個 job steps、可在 GitHub Actions 運行
  - Dependencies: T04

### Phase 5: Integration & Documentation

- [ ] **T13**: Update plugin.json with new skills
  - Description: 更新 `plugins/agent-army/.claude-plugin/plugin.json`，加入新的 skills（scaffold, batch, cost-report）。更新版本號到 3.2.0。確保 skills 計數和 keywords 正確。
  - Files: plugins/agent-army/.claude-plugin/plugin.json
  - Acceptance: plugin.json 語法正確、版本 3.2.0、新 skills 列入
  - Dependencies: T06, T10

- [ ] **T14**: Update settings.json with new hooks
  - Description: 更新 `.claude/settings.json`，加入成本追蹤 hook 和任何新的 permission patterns。確保不破壞現有 hooks。
  - Files: .claude/settings.json
  - Acceptance: JSON 語法正確、新 hook 已加入、現有 hooks 未被破壞
  - Dependencies: T07

- [ ] **T15**: Update CLAUDE.md with new skills documentation
  - Description: 更新 `.claude/CLAUDE.md` 的 Available Skills 表格，加入 scaffold、batch、cost-report skills。
  - Files: .claude/CLAUDE.md
  - Acceptance: Skills 表格包含新的 3 個 skills、格式一致
  - Dependencies: T05, T09, T07

- [ ] **T16**: Update docs/INDEX.md with new documents
  - Description: 更新 `docs/INDEX.md`，加入 T01-T04 產出的新文件索引。
  - Files: docs/INDEX.md
  - Acceptance: INDEX.md 包含所有新文件的連結、格式一致
  - Dependencies: T01, T02, T03, T04

- [ ] **T17**: Generate CHANGELOG entry for v3.2.0
  - Description: 使用 conventional commits 格式，在 CHANGELOG.md 中新增 v3.2.0 條目。涵蓋所有本次新增的 skills、hooks、CI templates、研究文件。
  - Files: CHANGELOG.md
  - Acceptance: CHANGELOG 包含 v3.2.0 條目、格式與現有條目一致
  - Dependencies: T13, T14, T15, T16

### Phase 6: Quality Assurance

- [ ] **T18**: Run quality gate on all changes
  - Description: 對所有本次變更執行品質檢查：(1) 驗證所有新 skill 的 SKILL.md 語法 (2) 驗證 JSON 檔案語法正確 (3) 驗證 YAML 檔案語法正確 (4) 驗證 shell scripts 可執行且通過 shellcheck (5) 驗證所有文件連結有效 (6) 驗證 plugin 結構完整
  - Files: all changed files
  - Acceptance: 所有品質檢查通過
  - Dependencies: T17

## Status Legend
- `[ ]` -- Pending
- `[x]` -- Done
- `[!]` -- Failed (will not retry)
- `[-]` -- Skipped
