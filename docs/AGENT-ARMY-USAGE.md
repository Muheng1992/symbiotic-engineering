# Agent Army 使用指南

> **版本**: 1.1.0 | **最後更新**: 2026-03-04
> 從零開始設定和使用 Agent Army 系統的完整教學

---

## 目錄

1. [快速開始](#1-快速開始)
2. [前置條件](#2-前置條件)
3. [安裝與設定](#3-安裝與設定)
4. [基本使用](#4-基本使用)
5. [進階使用](#5-進階使用)
6. [Skill 詳細說明](#6-skill-詳細說明)
7. [Agent 角色說明](#7-agent-角色說明)
8. [工作流程範例](#8-工作流程範例)
9. [報告與文件管理](#9-報告與文件管理)
10. [Plan 追蹤與可追溯性](#10-plan-追蹤與可追溯性)
11. [自訂與擴展](#11-自訂與擴展)
12. [分發與安裝到其他專案](#12-分發與安裝到其他專案)
13. [疑難排解](#13-疑難排解)

---

## 1. 快速開始

### 30 秒版本（Plugin 安裝）

```bash
# 1. 在 Claude Code 中加入 marketplace
/plugin marketplace add Muheng1992/symbiotic-engineering

# 2. 安裝 Agent Army plugin
/plugin install agent-army@symbiotic-engineering

# 3. 初始化你的專案
/agent-army:setup my-project

# 4. 初始化 Context
/agent-army:context-sync init

# 5. 開始使用！
/agent-army:assemble implement user authentication with JWT
```

### 傳統手動安裝（進階用戶）

```bash
# 1. Clone repo 並複製 .claude/ 目錄到你的專案
git clone https://github.com/Muheng1992/symbiotic-engineering.git
cp -r symbiotic-engineering/.claude/ /your/project/.claude/

# 2. 建立 docs/ 目錄結構
mkdir -p /your/project/docs/{reports/{code-review,test,security,fix,integration,quality-gate,plans},architecture,archive,guides}

# 3. 啟動 Claude Code
cd /your/project && claude

# 4. 初始化 Context
/context-sync init

# 5. 開始使用！
/assemble implement user authentication with JWT
```

---

## 2. 前置條件

| 條件 | 最低版本 | 確認指令 |
|------|---------|---------|
| Claude Code CLI | v2.1.0+ | `claude --version` |
| Git | 2.x | `git --version` |
| Node.js (如果是 JS 專案) | 18+ | `node --version` |

### 驗證 Claude Code 設定

```bash
# 確認可用的 agents
claude agents

# 確認 Agent Teams 已啟用
claude --print-settings | grep AGENT_TEAMS
```

---

## 3. 安裝與設定

### 方式 A: Plugin 安裝（推薦 — 最簡單）

只需在 Claude Code 中執行三個指令：

```bash
# Step 1: 加入 marketplace
/plugin marketplace add Muheng1992/symbiotic-engineering

# Step 2: 安裝 plugin
/plugin install agent-army@symbiotic-engineering

# Step 3: 初始化專案
/agent-army:setup my-project
```

`/agent-army:setup` 會自動：
- 建立 `docs/` 目錄結構（含所有報告分類）
- 建立或更新 `.claude/CLAUDE.md`（含 Clean Architecture 標準）
- 配置 `.claude/settings.json`（啟用 Agent Teams）
- 建立 `docs/INDEX.md` 和 `docs/archive/ARCHIVE-INDEX.md`

### 方式 B: 本機測試安裝

```bash
# Clone repository
git clone https://github.com/Muheng1992/symbiotic-engineering.git

# 用 plugin-dir 啟動 Claude Code
claude --plugin-dir ./symbiotic-engineering/plugins/agent-army
```

### 方式 C: 團隊自動安裝

在你的專案 `.claude/settings.json` 中加入：

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

團隊成員 clone 專案後，Claude Code 會自動提示安裝 Agent Army plugin。

### 方式 D: 傳統手動安裝

```bash
cd /your/project

# 複製 Agent Army 系統
cp -r /path/to/symbiotic-engineering/.claude/ .claude/

# 建立文件目錄
mkdir -p docs/{reports/{code-review,test,security,fix,integration,quality-gate,plans},architecture,archive,guides}

# 調整 .claude/CLAUDE.md 的專案描述
# 調整 .claude/settings.json 的權限設定
```

### 驗證安裝

```bash
# 查看所有可用的 agents
claude agents

# Plugin 安裝的 agents 會有 namespace 前綴：
# - agent-army:tech-lead
# - agent-army:architect
# - agent-army:implementer
# - agent-army:tester
# - agent-army:reviewer
# - agent-army:documenter
# - agent-army:security-auditor
# - agent-army:integrator
# - agent-army:doc-manager
# - agent-army:reporter

# 手動安裝的 agents 沒有前綴：
# - tech-lead
# - architect
# - ...
```

---

## 4. 基本使用

### 4.1 集結 Agent 大軍（最常用）

```
/assemble [功能描述]
```

範例：
```
/assemble implement a REST API for user management with CRUD operations
/assemble add JWT authentication to the existing Express server
/assemble refactor the payment module to follow Clean Architecture
```

執行流程：
1. Claude 分析你的專案結構
2. 根據任務複雜度決定團隊規模（3-10 agents）
3. 自動分解任務、設定依賴
4. 並行啟動 agents
5. 監控執行、處理問題
6. 產生報告、歸檔文件
7. 回報結果

### 4.2 Sprint 規劃

```
/sprint [功能描述或 issue URL]
```

範例：
```
/sprint implement dashboard with charts, filters, and export functionality
/sprint https://github.com/org/repo/issues/42
```

### 4.3 品質檢查

```
/quality-gate [範圍]
```

範例：
```
/quality-gate src/auth/           # 檢查特定目錄
/quality-gate user-management     # 檢查特定功能
/quality-gate all                 # 檢查整個專案
```

### 4.4 Context 管理

```
/context-sync init              # 初始化 context 基礎設施
/context-sync refresh           # 更新 context 檔案
/context-sync status            # 查看 context 健康狀態
/context-sync export            # 匯出可攜 context 包
```

---

## 5. 進階使用

### 5.1 指定團隊組成

你可以在 `/assemble` 中指定需要的 agents：

```
/assemble implement payment gateway. Use architect for design, 3 implementers
for parallel coding, and security-auditor for payment security review.
```

### 5.2 使用 Agent Teams（實驗性）

對於需要 agents 之間互相溝通的複雜任務：

```
Create an agent team to refactor the authentication system. Spawn:
- An architect teammate to redesign the module
- Two implementer teammates for frontend and backend
- A tester teammate to write comprehensive tests
Have them coordinate and challenge each other's approaches.
```

### 5.3 使用 /batch 進行大規模變更

```
/batch migrate all React class components to functional components with hooks
/batch update all API endpoints to v2 schema
/batch add error handling to all database query functions
```

### 5.4 指定 Plan Approval

要求 agent 在實作前先提交計畫：

```
/assemble implement feature X. All agents must submit plans for approval
before making any code changes.
```

### 5.5 直接使用特定 Agent

你也可以直接讓 Claude 使用特定 agent：

```
Use the reviewer agent to review my recent changes
Use the security-auditor agent to scan src/auth/
Use the tester agent to write tests for the user module
```

---

## 6. Skill 詳細說明

### `/assemble` — Agent 大軍集結器

**用途**: 自動分析專案、分解任務、啟動 agent 大軍

**語法**: `/assemble [功能描述]`

**行為**:
1. 讀取專案結構和 CLAUDE.md
2. 分解任務為 5-15 個獨立工作單元
3. 決定團隊規模（小/中/大/完整）
4. 啟動 agents 並行工作
5. 監控進度、處理問題
6. 產生報告並歸檔

**參考檔案**:
- `references/role-catalog.md` — 角色完整定義
- `references/workflow-patterns.md` — 工作流程模式

---

### `/sprint` — Sprint 規劃器

**用途**: 將功能分解為結構化的任務板

**語法**: `/sprint [功能描述 | issue URL]`

**輸出**: Sprint 計劃文件，包含任務板、依賴圖、風險評估

---

### `/quality-gate` — 品質閘門

**用途**: 在 merge 前執行全面品質檢查

**語法**: `/quality-gate [scope]`

**檢查項目**:
1. Build 驗證
2. 測試通過 + 覆蓋率
3. Code Review
4. 安全掃描
5. Clean Architecture 合規
6. 文件完整性

---

### `/context-sync` — Context 同步

**用途**: 管理跨 agent 的共享 context

**語法**: `/context-sync [init | refresh | status | export]`

---

### `dev-standards` — 開發標準（自動載入）

**用途**: Claude 自動載入的開發規範

**不需要手動觸發** — 當 Claude 寫程式碼時自動參考

**包含**:
- Clean Architecture 原則
- 程式碼命名規範
- 註解策略（WHY-not-WHAT）
- 錯誤處理標準
- 測試標準

---

## 7. Agent 角色說明

### 決策流程圖

```
需要什麼？
├── 設計/架構 → architect
├── 寫程式碼 → implementer (可多個)
├── 寫/跑測試 → tester
├── 審查程式碼 → reviewer
├── 安全分析 → security-auditor
├── 合併整合 → integrator
├── 寫文件 → documenter
├── 產生報告 → reporter
├── 管理文件 → doc-manager
└── 複雜協調 → tech-lead
```

### 角色快速參考

| 角色 | 何時使用 | 輸出 |
|------|---------|------|
| **tech-lead** | 複雜任務需要多 agent 協調 | 任務分解 + 協調 |
| **architect** | 新功能、重構、技術決策 | 設計文件 + 介面定義 |
| **implementer** | 寫/改程式碼 | 程式碼檔案 |
| **tester** | 實作後寫測試 | 測試檔案 + 測試報告 |
| **reviewer** | 程式碼變更後審查 | Review 報告 |
| **security-auditor** | 安全敏感的變更 | 安全報告 |
| **integrator** | 多 agent 工作完成後合併 | 整合報告 |
| **documenter** | 功能完成後更新文件 | 文件檔案 |
| **doc-manager** | 管理報告歸檔和文件索引 | INDEX.md + 歸檔 |
| **reporter** | 任何開發活動後產生報告 | 結構化報告 |

---

## 8. 工作流程範例

### 範例 1: 小功能（新增一個 API endpoint）

```
/assemble add a GET /api/users/:id endpoint that returns user profile data
```

系統自動：
1. 分析現有 API 結構
2. 啟動 implementer + tester + reviewer（3 agents）
3. Implementer 寫 controller + use case
4. Tester 寫測試
5. Reviewer 審查
6. 回報結果

### 範例 2: 中型功能（用戶認證系統）

```
/assemble implement JWT-based authentication with login, register, and
token refresh endpoints. Include middleware for route protection.
```

系統自動：
1. Architect 設計認證架構（Clean Architecture）
2. 3 個 Implementer 並行：auth middleware / user endpoints / token service
3. Tester 寫全面測試
4. Reviewer + Security Auditor 並行審查
5. Integrator 合併並驗證
6. Documenter 更新 API 文件
7. Reporter 產生所有報告
8. Doc Manager 歸檔

### 範例 3: 大規模重構

```
/batch migrate all Express route handlers from callbacks to async/await
```

系統自動：
1. 分析所有路由檔案
2. 分解為 5-30 個獨立工作單元
3. 展示計劃供你確認
4. 每個工作單元在獨立 git worktree 中執行
5. 每個完成後開 PR
6. 所有 PR 可以個別審查和合併

### 範例 4: Sprint 規劃 + 執行

```
# 先規劃
/sprint implement a dashboard with:
- Real-time data charts (Chart.js)
- Date range filter
- Export to CSV/PDF
- Mobile responsive layout

# 審查計劃後執行
/assemble execute the sprint plan above
```

---

## 9. 報告與文件管理

### 9.1 報告自動產生

每次 agent 活動後，reporter 會自動產生結構化報告。

報告位置：
```
docs/reports/
├── code-review/YYYY-MM-DD-[subject]-review-report.md
├── test/YYYY-MM-DD-[subject]-test-report.md
├── security/YYYY-MM-DD-[subject]-security-report.md
├── fix/YYYY-MM-DD-[subject]-fix-report.md
├── integration/YYYY-MM-DD-[subject]-integration-report.md
├── quality-gate/YYYY-MM-DD-[subject]-quality-gate.md
└── plans/YYYY-MM-DD-[subject]-plan.md
```

### 9.2 查看報告索引

所有報告都索引在 `docs/INDEX.md`。

### 9.3 歸檔策略

- 報告**永不刪除**
- 過時文件移到 `docs/archive/YYYY-MM/`
- 歸檔文件列在 `docs/archive/ARCHIVE-INDEX.md`
- 歸檔時加上元資料（日期、原因、取代文件）

---

## 10. Plan 追蹤與可追溯性

### 10.1 Plan 文件化

每當 Agent 進入 Plan 模式或產生設計方案時，Plan 都會被記錄：

**儲存位置**: `docs/reports/plans/YYYY-MM-DD-[subject]-plan.md`

**Plan 文件格式**:
```markdown
# Plan: [Feature Name]

## Metadata
- **Date**: YYYY-MM-DD HH:MM
- **Author**: [agent-name]
- **Status**: PROPOSED | APPROVED | REJECTED | EXECUTED | PARTIALLY_EXECUTED
- **Approved By**: [agent-name or human]
- **Rejected By**: [agent-name, if rejected]
- **Rejection Reason**: [reason, if rejected]

## Plan Content
[Detailed plan...]

## Execution Tracking
| Step | Status | Executor | Completed At | Notes |
|------|--------|----------|-------------|-------|
| 1    | Done   | implementer | HH:MM     |       |
| 2    | Done   | implementer | HH:MM     |       |
| 3    | Skipped | —       | —           | [reason] |

## Deviations
[Any deviations from the original plan and why]

## Final Status
- **Fully Executed**: YES / NO
- **Completion Rate**: N/M steps (XX%)
- **Deviations**: N deviations documented
```

### 10.2 Plan 審核流程

```
Agent proposes plan
       ↓
Tech Lead reviews
       ↓
    ┌── APPROVED → Execute → Track completion → File report
    └── REJECTED → Document reason → Revise → Re-submit
                         ↓
              Rejection recorded in plan file
              with agent name and reason
```

### 10.3 查看 Plan 歷史

```bash
# 列出所有 plans
ls docs/reports/plans/

# 搜尋被拒絕的 plans
grep -l "REJECTED" docs/reports/plans/*.md

# 搜尋未完全執行的 plans
grep -l "Fully Executed: NO" docs/reports/plans/*.md
```

---

## 11. 自訂與擴展

### 11.1 新增自訂 Agent

在 `.claude/agents/` 新增 `.md` 檔案：

```markdown
---
name: my-custom-agent
description: >
  Description of when to use this agent...
tools: Read, Write, Edit, Bash
model: inherit
memory: project
skills:
  - dev-standards
---

You are a [role description]. When invoked:

1. [Step 1]
2. [Step 2]
...
```

### 11.2 新增自訂 Skill

在 `.claude/skills/` 新增目錄：

```bash
mkdir -p .claude/skills/my-skill
```

建立 `SKILL.md`：

```markdown
---
name: my-skill
description: What this skill does and when to use it
---

Instructions for Claude when this skill is invoked...
```

### 11.3 修改 Quality Gate

編輯 `.claude/skills/quality-gate/SKILL.md` 來新增或修改品質檢查項目。

### 11.4 新增 Hooks

編輯 `.claude/settings.json` 的 `hooks` 區段。

---

## 12. 分發與安裝到其他專案

### 方法 1: Plugin Marketplace（推薦 — 最簡單）

任何人只需要知道你的 GitHub repo URL 就可以安裝：

```bash
# 使用者在 Claude Code 中執行：
/plugin marketplace add Muheng1992/symbiotic-engineering
/plugin install agent-army@symbiotic-engineering
/agent-army:setup my-project
```

**優點**: 一鍵安裝、自動更新、版本管理
**前置條件**: GitHub repo 需要是 public（或使用者有 access）

### 方法 2: 團隊自動安裝

在團隊專案的 `.claude/settings.json` 中設定，新成員 clone 後自動提示安裝：

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

### 方法 3: 本機測試 / CI 環境

```bash
git clone https://github.com/Muheng1992/symbiotic-engineering.git
claude --plugin-dir ./symbiotic-engineering/plugins/agent-army
```

### 方法 4: 傳統直接複製

```bash
# 複製核心設定
cp -r .claude/agents/ /new-project/.claude/agents/
cp -r .claude/skills/ /new-project/.claude/skills/
cp .claude/settings.json /new-project/.claude/settings.json
cp .claude/CLAUDE.md /new-project/.claude/CLAUDE.md

# 建立文件結構
mkdir -p /new-project/docs/{reports/{code-review,test,security,fix,integration,quality-gate,plans},architecture,archive,guides}
```

### 發布你自己的 Marketplace

如果你 fork 了本 repo 並做了修改，可以作為獨立 marketplace 發布：

1. **Fork** 到你的 GitHub org
2. 修改 `.claude-plugin/marketplace.json` 中的 `name` 和 `owner`
3. 修改 `plugins/agent-army/.claude-plugin/plugin.json` 的 `repository`
4. Push 到 GitHub
5. 分享你的安裝指令：`/plugin marketplace add YOUR_ORG/YOUR_REPO`

### Plugin 更新

```bash
# 使用者更新到最新版本
/plugin marketplace update symbiotic-engineering
/plugin update agent-army@symbiotic-engineering
```

**注意**: 每次更新 plugin 內容後，記得在 `plugin.json` 中更新 `version`，否則使用者的 cache 不會更新。

---

## 13. 疑難排解

### Agent 沒有出現

```bash
# 確認 agent 檔案存在
ls .claude/agents/

# 確認 YAML frontmatter 格式正確
head -5 .claude/agents/tech-lead.md

# 重新載入
# 在 Claude Code 中執行 /agents 查看
```

### Skill 沒有觸發

```bash
# 確認 skill 檔案存在
ls .claude/skills/

# 確認 SKILL.md 有 frontmatter
head -5 .claude/skills/assemble/SKILL.md

# 手動觸發測試
/assemble test
```

### Agent Teams 不工作

```bash
# 確認啟用了實驗功能
grep AGENT_TEAMS .claude/settings.json

# 應該看到：
# "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
```

### Context 超載

```bash
# 在 Claude Code 中檢查
/context

# 如果有 skill 被排除，考慮：
# 1. 精簡 CLAUDE.md（目標 ≤ 150 行）
# 2. 將較少用的 skill 設為 disable-model-invocation: true
# 3. 設定環境變數增加 budget：
# export SLASH_COMMAND_TOOL_CHAR_BUDGET=32000
```

### 報告沒有被歸檔

確認 `doc-manager` agent 在 `/assemble` 的執行流程中被啟動。

手動歸檔：
```
Use the doc-manager agent to file all pending reports and update the index
```

### Hook 沒有觸發

```bash
# 確認 settings.json 中的 hooks 格式正確
cat .claude/settings.json | python3 -m json.tool

# 測試 hook 腳本可執行
chmod +x .claude/hooks/scripts/*.sh
```

---

## 附錄：指令速查表

### Plugin 安裝版（有 namespace 前綴）

| 指令 | 用途 | 範例 |
|------|------|------|
| `/agent-army:setup [name]` | 初始化專案 | `/agent-army:setup my-app` |
| `/agent-army:assemble [desc]` | 集結 Agent 大軍 | `/agent-army:assemble add user auth` |
| `/agent-army:sprint [desc]` | Sprint 規劃 | `/agent-army:sprint dashboard feature` |
| `/agent-army:quality-gate [scope]` | 品質檢查 | `/agent-army:quality-gate src/` |
| `/agent-army:context-sync [action]` | Context 管理 | `/agent-army:context-sync init` |
| `/batch [instruction]` | 大規模並行變更 | `/batch migrate to React hooks` |

### 手動安裝版（無前綴）

| 指令 | 用途 | 範例 |
|------|------|------|
| `/assemble [desc]` | 集結 Agent 大軍 | `/assemble add user auth` |
| `/sprint [desc]` | Sprint 規劃 | `/sprint dashboard feature` |
| `/quality-gate [scope]` | 品質檢查 | `/quality-gate src/` |
| `/context-sync [action]` | Context 管理 | `/context-sync init` |
| `/batch [instruction]` | 大規模並行變更 | `/batch migrate to React hooks` |

---

*Agent Army Usage Guide v1.1.0 | Symbiotic Engineering | 2026-03-04*
