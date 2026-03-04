# Symbiotic Engineering 深度研究系列 — 任務規劃

> 最後更新：2026-03-04
> 狀態追蹤：每篇完成後更新下方狀態欄

---

## 已完成

| # | 文件 | 狀態 |
|---|------|------|
| 0 | `ai-era-code-best-practices.md` — AI 時代程式碼最佳實踐 | ✅ 已完成 |
| 1 | `claude-code-skills-guide.md` — Claude Code Skills 完全指南 | ✅ 已完成 |
| 3 | `context-engineering-memory-architecture.md` — Context Engineering 記憶架構 | ✅ 已完成 |

---

## 待撰寫（按優先級排序）

### 第 2 篇【極高優先】Agent Teams + Git Worktree：多代理平行開發

- **檔名**: `agent-teams-parallel-development.md`
- **核心主題**: 多個 Claude 實例如何在共享 codebase 上平行工作、自動分工、互相審查
- **為什麼重要**: 2026 最具革命性功能，中文深度分析幾乎為零

#### 研究大綱

1. **Agent Teams 是什麼**
   - 與 Subagents 的本質差異（平等協作 vs 主從委派）
   - 啟用方式（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`）
   - 架構：Coordinator → Teammates → 共享 codebase

2. **Git Worktree 原生支援**
   - worktree 基礎概念
   - `isolation: worktree` 在 agent/subagent frontmatter 中的配置
   - 平行開發不互相干擾的機制

3. **實戰案例：Anthropic 用 Agent Teams 建 C 編譯器**
   - 10 萬行程式碼、~2,000 sessions
   - 任務分配策略
   - 品質保證方法

4. **使用模式與最佳實踐**
   - 適合場景：research & review、新模組開發、competing hypotheses debugging、跨層協調
   - 不適合場景
   - 團隊大小建議
   - Coordinator 提示詞設計

5. **`/batch` 大規模平行重構**
   - 與 Agent Teams 的關係
   - 工作分解策略（5-30 獨立單元）
   - 實戰範例：框架遷移、API 版本升級、大規模重命名

6. **限制與風險**
   - 合併衝突處理
   - Token 成本分析
   - 實驗性功能的穩定性

#### 關鍵參考來源
- https://code.claude.com/docs/en/agent-teams
- https://www.anthropic.com/engineering/building-c-compiler
- https://www.anthropic.com/news/enabling-claude-code-to-work-more-autonomously
- https://claudefa.st/blog/guide/agents/agent-teams
- https://supergok.com/claude-code-git-worktree-support/
- https://www.sitepoint.com/anthropic-claude-code-agent-teams/
- Boris Cherny Threads: git worktree 公告
- https://darasoba.medium.com/how-to-set-up-and-use-claude-code-agent-teams

---

### 第 3 篇【極高優先】Context Engineering：AI 輔助開發的記憶架構

- **檔名**: `context-engineering-memory-architecture.md`
- **核心主題**: CLAUDE.md + Auto Memory + Skills 三層記憶架構的最佳配置策略
- **為什麼重要**: 跨 session 記憶是 AI 輔助開發的根本性改變，與前兩篇形成完整系列

#### 研究大綱

1. **Context Engineering 的定義與演進**
   - 從 Prompt Engineering → Context Engineering 的典範轉移
   - 為什麼 context 比 prompt 重要
   - Andrej Karpathy 等人的論述

2. **Claude Code 三層記憶架構**
   - **Layer 1: CLAUDE.md** — 人類撰寫的持久指令（永遠載入）
   - **Layer 2: Auto Memory (MEMORY.md)** — Claude 自己寫的筆記（前 200 行自動載入）
   - **Layer 3: Skills** — 按需載入的模組化知識
   - 三者如何協同、何時用哪個

3. **Auto Memory 深度解析**
   - 運作機制：何時觸發儲存、儲存什麼
   - 目錄結構：`~/.claude/projects/<project>/memory/`
   - MEMORY.md + topic files 的組織策略
   - 200 行限制的應對：主題檔案拆分

4. **CLAUDE.md 撰寫最佳實踐**
   - 150 行建議上限
   - 結構化模板
   - 層級系統（Enterprise > User > Project > Directory）
   - 與 .cursorrules、AGENTS.md 的對比

5. **Subagent 持久記憶**
   - `memory: user|project|local` frontmatter
   - agent-memory 目錄結構
   - 跨 session 知識累積

6. **Context Window 管理策略**
   - 1M context window 的正確使用方式
   - `/compact` 壓縮策略
   - `/context` 監控
   - Tool results 超過 50K 自動持久化到磁碟
   - `CLAUDE_CODE_DISABLE_1M_CONTEXT` 的使用時機

7. **實戰：設計你的專案記憶架構**
   - 小型專案 vs 大型 Monorepo 的配置差異
   - 團隊協作的記憶分層策略
   - 從零開始的設定 checklist

#### 關鍵參考來源
- https://code.claude.com/docs/en/memory
- https://claudefa.st/blog/guide/mechanics/auto-memory
- https://medium.com/@joe.njenga/anthropic-just-added-auto-memory-to-claude-code-memory-md-i-tested-it
- https://the-decoder.com/claude-code-now-remembers-your-fixes-your-preferences-and-your-project-quirks-on-its-own/
- https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/deep-dive/
- https://agentnativedev.medium.com/persistent-memory-for-claude-code-never-lose-context-setup-guide
- https://www.humanlayer.dev/blog/writing-a-good-claude-md
- https://dometrain.com/blog/creating-the-perfect-claudemd-for-claude-code/
- https://claudefa.st/blog/guide/mechanics/context-buffer-management

---

### 第 4 篇【高優先】Plugins 生態系：從開發到分發

- **檔名**: `plugins-ecosystem-guide.md`
- **核心主題**: Plugin 開發、分發、企業 Private Marketplace、生態系分析
- **為什麼重要**: 9,000+ plugins 的生態系已成形，是 Claude Code 商業化的重要環節

#### 研究大綱

1. **Plugin 架構**
   - Plugin = Skills + Hooks + Commands + MCP Servers 的打包
   - `.claude-plugin/plugin.json` manifest 結構
   - 與 Skills 的差異：分發性、組合性

2. **Plugin 開發實戰**
   - 從 Skill 到 Plugin 的升級路徑
   - 目錄結構規範
   - 測試與驗證
   - `/plugin create` 工作流程

3. **Marketplace 生態**
   - Anthropic 官方 Marketplace
   - 社群第三方 Marketplace（ClaudePluginHub、Claude-Plugins.dev 等）
   - 熱門 Plugin 分類分析
   - 安全審查機制

4. **企業 Private Marketplace**
   - 設定與管理
   - Per-user provisioning 和 auto-install
   - 部門級 Plugin 策略
   - 合規與安全考量

5. **LSP 整合與 Code Intelligence**
   - Language Server Protocol 在 Plugin 中的角色
   - Jump to definition、find references、type errors

6. **MCP Connectors 生態**
   - 12 個新 MCP connectors（Google Suite、DocuSign 等）
   - 自建 MCP server 的方法

#### 關鍵參考來源
- https://www.anthropic.com/news/claude-code-plugins
- https://claude.com/plugins
- https://code.claude.com/docs/en/discover-plugins
- https://github.com/anthropics/claude-plugins-official
- https://www.ghacks.net/2026/02/25/anthropic-expands-claude-with-enterprise-plugins-and-marketplace/
- https://claudecodemarketplace.com/
- https://www.firecrawl.dev/blog/best-claude-code-plugins
- https://repomix.com/guide/claude-code-plugins

---

### 第 5 篇【高優先】Hooks 進階：事件驅動的 AI 工作流自動化

- **檔名**: `hooks-advanced-automation.md`
- **核心主題**: Hooks 四種類型（command/http/prompt/agent）的深度解析與自動化實戰
- **為什麼重要**: Hooks 是讓 AI 工作流程「可靠且確定性」的關鍵，HTTP 和 Agent 類型是 2026 新增

#### 研究大綱

1. **Hooks 基礎回顧**
   - 17 個 Hook 事件完整列表
   - command hook 的基礎用法

2. **HTTP Hooks（2026 新增）**
   - POST JSON → 接收 JSON 回應
   - 與外部 CI/CD、Slack、監控系統整合
   - 實戰範例

3. **Agent Hooks（2026 新增）**
   - 多輪驗證機制
   - 工具存取能力（Read, Grep, Glob）
   - 與 prompt hook 的差異

4. **Prompt Hooks**
   - Haiku 模型單輪判斷
   - 成本效益分析

5. **Hooks in Skills & Subagents Frontmatter**
   - 生命周期範圍限定
   - 組合模式

6. **安全考量**
   - CVE-2025-59536, CVE-2026-21852 案例分析
   - 安全最佳實踐

7. **實戰食譜**
   - 自動 lint/format
   - 部署前安全門禁
   - 測試覆蓋率驗證
   - Slack 通知整合

#### 關鍵參考來源
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/hooks-guide
- https://github.com/disler/claude-code-hooks-mastery
- https://docs.gitbutler.com/features/ai-integration/claude-code-hooks
- https://www.eesel.ai/blog/hooks-in-claude-code
- https://research.checkpoint.com/2026/rce-and-api-token-exfiltration-through-claude-code-project-files-cve-2025-59536/

---

### 第 6 篇【中優先】Agent Skills 開放標準：跨工具 AI 指令的統一格式

- **檔名**: `agent-skills-open-standard.md`
- **核心主題**: Agent Skills 開放標準的規範、跨工具實測、生態系分析
- **為什麼重要**: 這是 AI 工具生態的「HTML」時刻——統一格式可能改變整個行業

#### 研究大綱

1. **為什麼需要開放標準**
   - 各工具指令系統的碎片化（.cursorrules, .windsurfrules, CLAUDE.md, .github/copilot/）
   - 標準化的商業和技術價值

2. **Agent Skills 規範深度解析**
   - SKILL.md 格式完整規範
   - Frontmatter 必要 vs 可選欄位
   - 各工具的擴展欄位對比

3. **25+ 工具採用情況實測**
   - Claude Code 原生支援
   - GitHub Copilot 支援狀況
   - Cursor 相容性
   - Gemini CLI、Codex 等

4. **跨平台 Skill 撰寫技巧**
   - 寫一次、到處用的策略
   - 平台特定 vs 通用 frontmatter
   - 降級策略

5. **生態系展望**
   - Skill Marketplace 的未來
   - 企業 Skill 管理
   - 開源 Skill 社群

#### 關鍵參考來源
- https://agentskills.io/specification
- https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- https://thenewstack.io/agent-skills-anthropics-next-bid-to-define-ai-standards/
- https://aibusiness.com/foundation-models/anthropic-launches-skills-open-standard-claude
- https://newsletter.victordibia.com/p/implementing-claude-code-skills-from
- https://claude.com/blog/improving-skill-creator-test-measure-and-refine-agent-skills

---

## 撰寫指南（每篇通用）

### 格式要求
- 繁體中文撰寫
- 善用 Mermaid 圖表（避免 quadrantChart 和中文標籤問題）
- 實際程式碼範例（多語言：TypeScript, Python, Go, Kotlin, Swift）
- 傳統方法 vs AI 時代方法的比較
- 附上完整 Reference 列表

### 研究方法
- 先用 3 個平行 research agent 蒐集資料
- 交叉比對官方文件、技術分析、社群經驗
- 引用具體數據和案例

### 品質標準
- 每篇 800-1200 行
- Mermaid 圖表 5+ 個
- 參考文獻 15+ 篇
- 實戰範例 5+ 個

---

## 進度追蹤

| # | 文件 | 優先級 | 狀態 | 預計字數 |
|---|------|--------|------|---------|
| 0 | AI 時代程式碼最佳實踐 | — | ✅ 完成 | ~1000 行 |
| 1 | Claude Code Skills 完全指南 | — | ✅ 完成 | ~1088 行 |
| 2 | Agent Teams + Git Worktree | 極高 | ✅ 完成 | ~883 行 |
| 3 | Context Engineering 記憶架構 | 極高 | ✅ 完成 | ~1167 行 |
| 4 | Plugins 生態系 | 高 | ⬜ 待開始 | ~900 行 |
| 5 | Hooks 進階自動化 | 高 | ⬜ 待開始 | ~800 行 |
| 6 | Agent Skills 開放標準 | 中 | ⬜ 待開始 | ~800 行 |

---

*此計劃檔案應在每篇完成後更新狀態。新 session 開始時請先讀取此檔案以了解進度。*
