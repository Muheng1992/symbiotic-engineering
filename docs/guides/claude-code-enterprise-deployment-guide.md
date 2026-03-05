# Claude Code CLI 企業部署完全指南

> **「From team productivity to enterprise transformation.」**
> 當 Claude Code 從個人工具變成企業基礎設施，部署策略、預算管理和合規要求會完全不同。
> 本指南提供從 5 人小團隊到 500+ 人組織的完整部署方案。

```mermaid
timeline
    title Claude Code Enterprise Adoption Journey
    2024 Q2 : Claude Code CLI 發布
             : 開發者自助試用
             : 個人訂閱制
    2024 Q4 : Claude for Teams 推出
             : 5-100 人團隊方案
             : 訂閱制 + Extra Usage
    2025 Q2 : 企業功能上線
             : SSO / SCIM / Domain Capture
             : Compliance API / Audit Log
    2025 Q4 : AWS Bedrock 整合
             : 雲端平台計費
             : Corporate Proxy 支援
    2026 Q1 : 統計數據
             : 195M lines of code processed weekly
             : 115,000+ developers using Claude Code
             : 1 in 7 PRs have AI participation (14.9%)
```

---

## 目錄

1. [為什麼企業需要 Claude Code CLI](#1-為什麼企業需要-claude-code-cli)
2. [方案比較 — 訂閱制 vs API 制 vs 雲端平台](#2-方案比較--訂閱制-vs-api-制-vs-雲端平台)
3. [API 定價完整分析](#3-api-定價完整分析)
4. [預算規劃與成本估算](#4-預算規劃與成本估算)
5. [用量追蹤與監控體系](#5-用量追蹤與監控體系)
6. [偵測專案外使用](#6-偵測專案外使用)
7. [預算控管機制](#7-預算控管機制)
8. [企業安全與合規](#8-企業安全與合規)
9. [案例研究](#9-案例研究)
10. [部署最佳實踐](#10-部署最佳實踐)
11. [決策流程圖](#11-決策流程圖)
12. [參考資源](#12-參考資源)

---

## 1. 為什麼企業需要 Claude Code CLI

### 1.1 開發加速與 ROI

**2026 年初市場數據**：
- 📊 **195 million lines of code** processed weekly (Anthropic, 2026-01)
- 👨‍💻 **115,000+ developers** actively using Claude Code
- 🔀 **14.9%** of all Pull Requests have AI agent participation (1 in 7 PRs)
- 📈 **335,000+ AI-authored PRs** in 2025 alone
- ⚡ **30% PR turnaround improvement** (pilot programs average)

**成本效益分析**：
- 平均每位開發者每天 **$6 USD**
- 90% 用戶低於 **$12/天**
- 月均費用 **~$100-200/developer** (Sonnet 4.6)

**Faros AI 測量的 ROI**：
- **4:1 ROI** (每投入 $1 節省 $4)
- 每個增量 PR 成本 **$37.50** vs 開發者時間 **$150**
- 工具接受率計算：`accepted / (accepted + rejected)`

### 1.2 統一開發體驗的商業價值

```mermaid
graph TD
    subgraph "傳統工具鏈分散"
        A1[GitHub Copilot] --> B1[IDE 內補全]
        A2[ChatGPT] --> B2[瀏覽器問答]
        A3[Terminal Scripts] --> B3[手動執行]
        A4[Code Review] --> B4[人工檢查]

        style B1 fill:#FFD93D
        style B2 fill:#FFD93D
        style B3 fill:#FFD93D
        style B4 fill:#FFD93D
    end

    subgraph "Claude Code 統一體驗"
        C1[Claude Code CLI] --> D1[編寫程式碼]
        C1 --> D2[執行測試]
        C1 --> D3[Code Review]
        C1 --> D4[部署到雲端]

        style C1 fill:#90EE90
    end
```

**統一工具帶來的好處**：
1. **學習成本降低**：只需學會一個工具
2. **Context 連續性**：不需要在多個工具間複製貼上
3. **自動化加速**：Agent Teams 協同作業
4. **監控集中化**：統一追蹤所有 AI 活動

### 1.3 2-10x 開發速度提升案例

| 場景 | 傳統時間 | Claude Code | 加速比 |
|------|---------|------------|--------|
| JavaScript 編輯器重寫 | 2 hours | 10 minutes | 12x |
| Build 優化 | 數天 | $8 (幾小時) | 18% improvement |
| Feedback Loop | 90 seconds | <10 seconds | 9x |
| MCP Server 開發 | 2-3 週 | 1 天 | 14-21x |
| 自主程式碼重構 | 數週 | 7 小時 | 20-40x |

**來源**：incident.io, Treasure Data, Rakuten (2025-2026 案例)

---

## 2. 方案比較 — 訂閱制 vs API 制 vs 雲端平台

### 2.1 Claude for Teams（訂閱制）

**定價結構**：
- **Standard Seat**: $25/月（年付）/ $30/月（月付）
- **Premium Seat**: $150/月（含 Claude Code）
- **年付 Premium**: ~$100-125/月（折扣後）
- **最低人數**: 5 人起

**包含內容**：
- ✅ Claude web interface (claude.ai)
- ✅ Claude Code CLI
- ✅ 基礎用量包 (Base Usage)
- ✅ 自助式管理 (Self-Service Admin)
- ✅ Extra Usage（超過基礎用量時按 API 費率計費）

**適用場景**：
- 5-50 人的新創團隊
- 需要快速開始，不想管理基礎設施
- 預算可預測（訂閱費 + Extra Usage）

### 2.2 Claude for Enterprise（訂閱制）

**定價結構**：
- **客製定價**，需聯繫銷售團隊
- **Usage-based Enterprise**: 無每座位限制，按用量計費

**企業功能**：
- ✅ **SSO** (SAML 2.0 + OIDC) — 單一登入
- ✅ **SCIM** — 自動化用戶管理
- ✅ **Domain Capture** — 自動化 workspace 註冊
- ✅ **Role-Based Access Control** — 角色權限管理
- ✅ **Compliance API** — 程式化存取使用資料和客戶內容
- ✅ **Audit Log** — 系統活動追蹤
- ✅ **Managed Policy Settings** — 集中管理設定（透過 MDM 分發）
- ✅ **HIPAA-ready 環境**（不含 Claude Code）

**適用場景**：
- 50+ 人的企業組織
- 需要合規和安全控制
- 已有 Okta / Azure AD / Google Workspace SSO

### 2.3 Anthropic API 直接使用（PAYG）

**計費方式**：
- **Pay-As-You-Go** (按用量付費)
- **API Key**: `sk-ant-api...`
- **Admin Key**: `sk-ant-admin...` (用於 Usage API / Cost API)

**Usage Tiers**：

| Tier | Deposit | Monthly Spend Limit |
|------|---------|---------------------|
| Free | $0 | $10 |
| Tier 1 | $5 | $100 |
| Tier 2 | $40 | $500 |
| Tier 3 | $200 | $1,000 |
| Tier 4 | $400 | $5,000 |

**環境變數設定**：
```bash
export ANTHROPIC_API_KEY="sk-ant-api..."
claude-code
```

**適用場景**：
- 自建系統整合
- 需要完全的 API 控制
- 中小型團隊，預算彈性

### 2.4 AWS Bedrock

**計費方式**：
- **透過 AWS 帳號計費** (PAYG through AWS)
- 整合 AWS Cost Explorer 追蹤
- Regional endpoints 有 **10% premium**

**整合 AWS 服務**：
- ✅ **IAM** — 權限管理
- ✅ **CloudTrail** — API 調用日誌
- ✅ **VPC** — 網路隔離
- ✅ **Corporate Proxy** 支援
- ✅ **LLM Gateway** 集中管理

**環境變數設定**：
```bash
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION="us-west-2"
export AWS_PROFILE="your-profile"
claude-code
```

**適用場景**：
- 已使用 AWS 生態系
- 需要 VPC 隔離
- 企業級審計需求

### 2.5 Google Vertex AI / Microsoft Foundry

**Vertex AI (Google Cloud Platform)**：
```bash
export CLAUDE_CODE_USE_VERTEX=1
export VERTEX_PROJECT_ID="your-project-id"
export VERTEX_REGION="us-central1"
claude-code
```

**Microsoft Foundry (Azure)**：
```bash
export CLAUDE_CODE_USE_FOUNDRY=1
export AZURE_SUBSCRIPTION_ID="..."
export AZURE_RESOURCE_GROUP="..."
claude-code
```

**共同特性**：
- ✅ 各自透過 GCP/Azure 帳號計費
- ✅ 支援 Entra ID 認證 (Foundry)
- ✅ Corporate Proxy 和 LLM Gateway 支援
- ✅ 整合各自的監控工具（Cloud Monitoring / Azure Monitor）

**適用場景**：
- 已使用 GCP/Azure 生態系
- 多雲策略
- 需要特定區域部署（如歐洲 GDPR）

---

### 2.6 方案總比較

| 維度 | Claude for Teams | Claude for Enterprise | Anthropic API | AWS Bedrock | Vertex/Foundry |
|------|-----------------|----------------------|---------------|-------------|----------------|
| **最適合** | 5-50 人團隊 | 50+ 人企業 | 自建系統 | AWS 生態系 | GCP/Azure 生態系 |
| **計費方式** | 訂閱 + Extra Usage | 客製 / Usage-based | PAYG | AWS 計費 | GCP/Azure 計費 |
| **認證方式** | Email / Google / SSO | SSO (SAML/OIDC) | API Key | IAM / API Key | IAM / Entra ID |
| **成本追蹤** | Console | Console + Compliance API | Admin API | AWS Cost Explorer | Cloud Billing / Azure Cost Mgmt |
| **含 Claude Web** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **企業功能** | 基礎 | 完整 | 無 | AWS 整合 | GCP/Azure 整合 |
| **Prompt Caching** | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 3. API 定價完整分析

### 3.1 模型定價表（per Million Tokens）

**2026 Q1 最新定價**：

| Model | Base Input | Output | 5m Cache Write | 1h Cache Write | Cache Hit |
|-------|-----------|--------|----------------|----------------|-----------|
| **Opus 4.6** | $5 | $25 | $6.25 | $10 | $0.50 |
| **Sonnet 4.5/4.6** | $3 | $15 | $3.75 | $6 | $0.30 |
| **Haiku 4.5** | $1 | $5 | $1.25 | $2 | $0.10 |

**Prompt Caching 說明**：
- **5m Cache Write**: 快取保留 5 分鐘，寫入時多收 25%
- **1h Cache Write**: 快取保留 1 小時，寫入時多收 100%
- **Cache Hit**: 命中快取時只收 10% 費用

**範例計算**（Sonnet 4.5）：
```
第一次調用（無快取）:
- Input: 10K tokens × $3/1M = $0.03
- Output: 5K tokens × $15/1M = $0.075
- Total: $0.105

第二次調用（5 分鐘內，快取命中）:
- Input (cached): 10K tokens × $0.30/1M = $0.003  (90% 折扣！)
- Output: 5K tokens × $15/1M = $0.075
- Total: $0.078
- 節省: $0.027 (25.7%)
```

### 3.2 Batch API（50% 折扣）

**適用場景**：非即時任務（資料分析、批次測試、文件生成）

| Model | Input | Output | 折扣 |
|-------|-------|--------|------|
| **Opus 4.6** | $2.50 | $12.50 | 50% off |
| **Sonnet 4.5/4.6** | $1.50 | $7.50 | 50% off |
| **Haiku 4.5** | $0.50 | $2.50 | 50% off |

**使用方式**：
```bash
# 批次處理模式（非阻塞）
curl https://api.anthropic.com/v1/batches \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2024-01-01" \
  -d '{
    "requests": [
      {"custom_id": "task-1", "params": {...}},
      {"custom_id": "task-2", "params": {...}}
    ]
  }'
```

### 3.3 長上下文定價（>200K tokens）

**當 input tokens 超過 200K 時，啟動長上下文定價**：

| Model | Input | Output |
|-------|-------|--------|
| **Opus 4.6** | $10 | $37.50 |
| **Sonnet 4.5/4.6** | $6 | $22.50 |

**說明**：
- 前 200K tokens 用標準定價
- 超過 200K 的部分用長上下文定價
- 適合處理大型 codebase 或長文件

### 3.4 Fast Mode（Opus 4.6 Research Preview）

**特性**：
- 更快的回應速度（約 2-3x）
- 適合即時協作場景

**定價**（6x standard）：
- Input: **$30** per 1M tokens
- Output: **$150** per 1M tokens

**使用方式**：
```python
response = client.messages.create(
    model="claude-opus-4-6",
    max_tokens=1024,
    messages=[...],
    metadata={
        "mode": "fast"  # 啟用 Fast Mode
    }
)
```

### 3.5 附加功能定價

| 功能 | 定價 | 說明 |
|------|------|------|
| **Web Search** | $10 per 1,000 searches | Claude 自動搜尋網路資訊 |
| **Code Execution** | $0.05/hr/container | 每月 1,550 免費小時 |
| **Web Fetch** | 免費（僅 token 費用） | 抓取網頁內容 |
| **Data Residency (US-only)** | 1.1x 加成 | 資料僅存美國境內 |

**Code Execution 範例**：
```
每月免費額度: 1,550 小時 (約 64 天)
超過後: $0.05/小時
平均單次執行: 5-30 秒
```

---

## 4. 預算規劃與成本估算

### 4.1 團隊成本試算

#### 情境 A：5 人小團隊（Team Premium）

**方案選擇**: Claude for Teams — Premium Seat

```
訂閱費用:
- 5 人 × $150/月 = $750/月
- 年付折扣: ~$100-125/月 → $500-625/月

基礎用量包含:
- 每人 ~50K tokens/day 的 Sonnet 用量

Extra Usage 估算:
- 假設每人每天多用 20K tokens (Sonnet)
- 20K × 30 天 × 5 人 = 3M tokens/月
- 3M × $3/1M = $9/月

總成本: $500-625 + $9 = $509-634/月
平均每人: $102-127/月
```

#### 情境 B：20 人中型團隊（API 方案）

**方案選擇**: Anthropic API + 自建監控

```
估算每人用量:
- 平均每天 $6-8 (市場數據)
- 月均: $100-200/developer

團隊總成本:
- 20 人 × $150/月 = $3,000/月（保守估算）
- 範圍: $2,000-4,000/月

需要自行建設:
- 用量追蹤系統（使用 Admin API）
- 成本儀表板
- 告警機制
```

#### 情境 C：50 人大型團隊（Enterprise）

**方案選擇**: Claude for Enterprise + Usage-based

```
客製定價考量因素:
- 總人數: 50 人
- 預期用量: 每人 $100-150/月
- 企業功能需求: SSO, SCIM, Audit Log

估算範圍:
- 基礎費用: $5,000-10,000/月（一次性設定費）
- 用量費用: 50 × $100-150 = $5,000-7,500/月
- 總計: $10,000-17,500/月
- 平均每人: $200-350/月

建議策略:
1. 先 pilot 小組（5-10 人）建立使用模式
2. 收集 3 個月數據
3. 與 Anthropic 談客製定價
```

#### 情境 D：100+ 人組織（雲端平台）

**方案選擇**: AWS Bedrock / Vertex AI + LLM Gateway

```
架構設計:
- LLM Gateway (LiteLLM / Kong / Apigee)
- 集中計費和監控
- Per-team / Per-project 追蹤

成本結構:
- LLM 費用: 100 × $100-150 = $10,000-15,000/月
- Gateway 基礎設施: $500-1,000/月
- 監控工具（Datadog / Grafana）: $500-1,000/月
- 總計: $11,000-17,000/月
- 平均每人: $110-170/月

優勢:
- 整合現有雲端計費
- 統一監控和告警
- 多雲策略彈性
```

---

### 4.2 Rate Limit 建議表

**根據團隊規模配置 Rate Limit**：

| Team Size | TPM per User | RPM per User | 建議配置原因 |
|-----------|-------------|--------------|------------|
| **1-5 users** | 200k-300k | 5-7 | 小團隊可允許爆發性使用 |
| **5-20 users** | 100k-150k | 2.5-3.5 | 平衡個人彈性與總量控制 |
| **20-50 users** | 50k-75k | 1.25-1.75 | 避免單一用戶影響全體 |
| **50-100 users** | 25k-35k | 0.62-0.87 | 需要更嚴格的配額管理 |
| **100-500 users** | 15k-20k | 0.37-0.47 | 企業級控制，預防濫用 |
| **500+ users** | 10k-15k | 0.25-0.35 | 大型組織需最嚴格限制 |

**TPM**: Tokens Per Minute
**RPM**: Requests Per Minute

**設定範例**（API Gateway 層級）：
```yaml
rate_limits:
  tier_1:  # 5 人團隊
    tpm: 250000
    rpm: 6
  tier_2:  # 20 人團隊
    tpm: 125000
    rpm: 3
  tier_3:  # 50 人團隊
    tpm: 62500
    rpm: 1.5
```

---

## 5. 用量追蹤與監控體系

### 5.1 Admin API — Usage & Cost API

**Endpoint**: `/v1/organizations/usage_report/messages`

**需要 Admin API Key**：
```bash
# Admin Key 格式
sk-ant-admin-xxxxx...
```

**核心功能**：
- ✅ 按模型分組追蹤（group_by: model）
- ✅ 按 workspace 分組（group_by: workspace）
- ✅ 按 API Key 分組（group_by: api_key）
- ✅ 按服務層級分組（group_by: service_tier）
- ✅ 時間粒度：1m (60 buckets) / 1h (168) / 1d (31)
- ✅ 資料延遲約 **5 分鐘**

#### 範例 1：查詢日用量（按模型分組）

```bash
curl https://api.anthropic.com/v1/organizations/usage_report/messages \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -H "anthropic-version: 2024-01-01" \
  -d '{
    "start_time": "2026-03-01T00:00:00Z",
    "end_time": "2026-03-02T00:00:00Z",
    "granularity": "1d",
    "group_by": ["model"]
  }'
```

**Response**：
```json
{
  "data": [
    {
      "model": "claude-opus-4-6",
      "input_tokens": 5000000,
      "output_tokens": 2500000,
      "requests": 1250,
      "estimated_cost": {
        "currency": "USD",
        "amount": 87500
      }
    },
    {
      "model": "claude-sonnet-4-5",
      "input_tokens": 10000000,
      "output_tokens": 5000000,
      "requests": 3200,
      "estimated_cost": {
        "currency": "USD",
        "amount": 105000
      }
    }
  ]
}
```

#### 範例 2：查詢小時級用量（過濾特定 workspace）

```bash
curl https://api.anthropic.com/v1/organizations/usage_report/messages \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -H "anthropic-version: 2024-01-01" \
  -d '{
    "start_time": "2026-03-05T00:00:00Z",
    "end_time": "2026-03-05T23:59:59Z",
    "granularity": "1h",
    "group_by": ["workspace"],
    "filter": {
      "workspace_id": "ws_engineering_team"
    }
  }'
```

#### 範例 3：查詢成本（Cost API）

**Endpoint**: `/v1/organizations/cost_report`

**注意**：僅支援 `1d` 粒度

```bash
curl https://api.anthropic.com/v1/organizations/cost_report \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -H "anthropic-version: 2024-01-01" \
  -d '{
    "start_time": "2026-03-01T00:00:00Z",
    "end_time": "2026-03-05T23:59:59Z",
    "granularity": "1d",
    "group_by": ["api_key"]
  }'
```

**Response**：
```json
{
  "data": [
    {
      "date": "2026-03-01T00:00:00Z",
      "api_key_name": "prod-backend-key",
      "cost": {
        "currency": "USD",
        "amount": 125000
      }
    },
    {
      "date": "2026-03-01T00:00:00Z",
      "api_key_name": "dev-frontend-key",
      "cost": {
        "currency": "USD",
        "amount": 45000
      }
    }
  ]
}
```

---

### 5.2 Claude Code Analytics API（重要！）

**這是追蹤 Claude Code 使用的專用 API**

**Endpoint**: `/v1/organizations/usage_report/claude_code`

**核心特性**：
- ✅ **Per-user 追蹤**：每筆記錄包含 actor email 或 API key name
- ✅ **核心指標**：sessions, LOC (lines of code), commits, PRs
- ✅ **工具使用**：edit_tool, write_tool, notebook_edit_tool 的 accepted/rejected 數
- ✅ **模型分解**：每個模型的 tokens (input/output/cache) 和 estimated_cost
- ✅ **維度**：date, actor, organization_id, customer_type, terminal_type
- ✅ 支援 **cursor-based pagination**
- ✅ 資料延遲約 **1 小時**

#### 完整範例（JSON Response）

```bash
curl https://api.anthropic.com/v1/organizations/usage_report/claude_code \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -H "anthropic-version: 2024-01-01" \
  -d '{
    "start_time": "2026-03-01T00:00:00Z",
    "end_time": "2026-03-02T00:00:00Z"
  }'
```

**Response**：
```json
{
  "data": [
    {
      "date": "2026-03-01T00:00:00Z",
      "actor": {
        "type": "user_actor",
        "email_address": "developer@company.com"
      },
      "organization_id": "org-dc9f6c26-xxxx",
      "customer_type": "api",
      "terminal_type": "vscode",
      "core_metrics": {
        "num_sessions": 5,
        "lines_of_code": {
          "added": 1543,
          "removed": 892
        },
        "commits_by_claude_code": 12,
        "pull_requests_by_claude_code": 2
      },
      "tool_actions": {
        "edit_tool": {
          "accepted": 45,
          "rejected": 5
        },
        "write_tool": {
          "accepted": 8,
          "rejected": 1
        },
        "notebook_edit_tool": {
          "accepted": 0,
          "rejected": 0
        }
      },
      "model_breakdown": [
        {
          "model": "claude-opus-4-6",
          "tokens": {
            "input": 100000,
            "output": 35000,
            "cache_read": 10000,
            "cache_creation": 5000
          },
          "estimated_cost": {
            "currency": "USD",
            "amount": 1025
          }
        },
        {
          "model": "claude-sonnet-4-5",
          "tokens": {
            "input": 250000,
            "output": 80000,
            "cache_read": 25000,
            "cache_creation": 10000
          },
          "estimated_cost": {
            "currency": "USD",
            "amount": 1950
          }
        }
      ]
    }
  ],
  "has_more": false,
  "next_cursor": null
}
```

**重要指標解讀**：

| 欄位 | 說明 | 用途 |
|------|------|------|
| `actor.email_address` | 用戶 email（可追蹤個人使用） | 成本歸因、用量分析 |
| `terminal_type` | IDE 類型 (vscode, cursor, etc) | 識別非工作場景使用 |
| `core_metrics.num_sessions` | 會話數 | 活躍度指標 |
| `lines_of_code.added` | 新增程式碼行數 | 產出指標 |
| `commits_by_claude_code` | AI 產生的 commits | 貢獻度指標 |
| `tool_actions.*.accepted` | 工具接受率 | 品質指標 |
| `model_breakdown` | 模型用量和成本 | 成本優化依據 |

---

### 5.3 OpenTelemetry 監控

**啟用方式**：
```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
claude-code
```

**支援的 Exporters**：
- **OTLP** (gRPC/HTTP) — 標準 OpenTelemetry
- **Prometheus** — 指標導出
- **Console** — 開發除錯

**管理員集中配置**（透過 MDM 分發）：

**Managed Settings JSON**：
```json
{
  "telemetry": {
    "enabled": true,
    "exporter": "otlp",
    "endpoint": "https://otel.company.com:4317",
    "headers": {
      "x-api-key": "company-otel-key"
    },
    "sample_rate": 0.1,
    "log_user_prompts": false,
    "log_tool_details": false
  }
}
```

**核心指標**：

| 指標名稱 | 類型 | 說明 |
|---------|------|------|
| `session.count` | Counter | 會話數 |
| `lines_of_code.count` | Counter | 程式碼行數（added/removed） |
| `pull_request.count` | Counter | PR 數量 |
| `commit.count` | Counter | Commit 數量 |
| `cost.usage` | Gauge | 即時成本（USD） |
| `token.usage` | Counter | Token 使用量 (input/output/cache) |
| `code_edit_tool.decision` | Counter | 工具決策（accepted/rejected） |
| `active_time.total` | Histogram | 活躍時間分佈 |

**事件追蹤**：

| 事件名稱 | 觸發時機 | 包含屬性 |
|---------|---------|---------|
| `user_prompt` | 用戶發送 prompt | prompt_text (optional), token_count |
| `tool_result` | 工具執行完成 | tool_name, exit_code, duration |
| `api_request` | LLM API 調用 | model, input_tokens, output_tokens |
| `api_error` | API 錯誤 | error_type, error_message |
| `tool_decision` | 工具被接受/拒絕 | tool_name, decision (accepted/rejected) |

**標準屬性**（所有事件都包含）：

```yaml
session.id: "ses_abc123"
organization.id: "org_xyz789"
user.account_uuid: "uuid-1234"
user.email: "dev@company.com"
terminal.type: "vscode"
```

**多團隊支援（自定義 Resource Attributes）**：

```bash
export OTEL_RESOURCE_ATTRIBUTES="department=engineering,team.id=platform,cost_center=eng-123"
claude-code
```

**動態認證（otelHeadersHelper script）**：

```bash
# .claude/otel_headers_helper.sh
#!/bin/bash
echo "Authorization: Bearer $(get_current_auth_token)"
echo "X-Tenant-ID: $(get_tenant_id)"
```

```json
{
  "telemetry": {
    "headers_helper": ".claude/otel_headers_helper.sh"
  }
}
```

**安全性考量**：

| 設定 | 預設值 | 說明 |
|------|--------|------|
| `log_user_prompts` | `false` | 不記錄 prompt 內容（隱私保護） |
| `log_tool_details` | `false` | 不記錄 MCP 工具名稱（避免洩漏內部工具） |
| `sample_rate` | `1.0` | 取樣率（1.0 = 100% 記錄） |

**啟用完整日誌**（僅開發環境）：
```bash
export OTEL_LOG_USER_PROMPTS=1
export OTEL_LOG_TOOL_DETAILS=1
```

---

### 5.4 第三方監控整合

#### Datadog LLM Observability

**整合方式**：
```python
from anthropic import Anthropic
from ddtrace import tracer

client = Anthropic(api_key="sk-ant-api-xxx")

with tracer.trace("claude_code_session", service="engineering"):
    response = client.messages.create(
        model="claude-sonnet-4-5",
        messages=[{"role": "user", "content": "Design a REST API"}]
    )
```

**功能**：
- ✅ 異常偵測 (Anomaly Detection)
- ✅ 成本追蹤
- ✅ 延遲分析
- ✅ 與 APM 整合

#### Honeycomb

**特性**：
- ✅ Advanced querying（任意維度分析）
- ✅ Trace 完整視覺化
- ✅ 高基數維度支援（per-user 追蹤）

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT="https://api.honeycomb.io"
export OTEL_EXPORTER_OTLP_HEADERS="x-honeycomb-team=YOUR_API_KEY"
export CLAUDE_CODE_ENABLE_TELEMETRY=1
claude-code
```

#### Grafana Cloud

**Agentless integration**：
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT="https://otlp-gateway-prod-us-central-0.grafana.net/otlp"
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Basic BASE64_ENCODED_CREDS"
export CLAUDE_CODE_ENABLE_TELEMETRY=1
claude-code
```

#### CloudZero — FinOps 成本優化

**特性**：
- ✅ 多雲成本統一追蹤
- ✅ 成本歸因（按團隊/專案/環境）
- ✅ 成本預測和告警

#### Vantage — LLM Cost Observability

**專注 LLM 成本**：
- ✅ 支援 Anthropic, OpenAI, Azure, AWS Bedrock
- ✅ 成本趨勢分析
- ✅ 預算告警

#### SigNoz — 開源選項

**自託管 OpenTelemetry 平台**：
```yaml
# docker-compose.yml
version: '3.8'
services:
  signoz:
    image: signoz/signoz:latest
    ports:
      - "4317:4317"  # OTLP gRPC
      - "3301:3301"  # UI
```

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export CLAUDE_CODE_ENABLE_TELEMETRY=1
claude-code
```

#### LiteLLM — 開源 LLM Gateway

**用於 Bedrock/Vertex 的開源追蹤方案**：

```python
from litellm import completion
import litellm

# 設定追蹤
litellm.success_callback = ["langfuse"]
litellm.failure_callback = ["langfuse"]

response = completion(
    model="bedrock/anthropic.claude-sonnet-v4",
    messages=[{"role": "user", "content": "Hello"}],
    metadata={
        "user": "developer@company.com",
        "team": "engineering"
    }
)
```

---

## 6. 偵測專案外使用

### 6.1 Workspace 隔離策略

**概念**：建立專用 "Claude Code" workspace，首次認證時自動建立。

**實作**：

```mermaid
graph TD
    A[開發者首次登入] --> B{選擇 Workspace}
    B -->|公司 Workspace| C[Company Engineering]
    B -->|個人 Workspace| D[Personal Projects]

    C --> E[追蹤到公司帳單]
    D --> F[追蹤到個人帳單]

    style C fill:#90EE90
    style D fill:#FFD93D
```

**按專案/團隊建立 Workspace**：

```
company-engineering
├── workspace: frontend-team
├── workspace: backend-team
├── workspace: devops-team
└── workspace: data-team
```

**透過 workspace_id 追蹤用量**：

```bash
curl https://api.anthropic.com/v1/organizations/usage_report/claude_code \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -d '{
    "group_by": ["workspace"],
    "start_time": "2026-03-01T00:00:00Z",
    "end_time": "2026-03-02T00:00:00Z"
  }'
```

---

### 6.2 API Key 分配策略

**每個開發者或專案分配獨立 API Key**：

```
開發者 A: sk-ant-api-dev-alice-xxxx
開發者 B: sk-ant-api-dev-bob-xxxx
專案 X: sk-ant-api-project-x-xxxx
```

**透過 Admin API 管理 API Keys**：

**Endpoint**: `/v1/organizations/api_keys`

```bash
# List API Keys
curl https://api.anthropic.com/v1/organizations/api_keys \
  -H "x-api-key: sk-ant-admin-xxxxx"
```

**Response**：
```json
{
  "data": [
    {
      "id": "key_abc123",
      "name": "dev-alice",
      "created_at": "2026-03-01T00:00:00Z",
      "last_used_at": "2026-03-05T14:32:10Z",
      "status": "active"
    }
  ]
}
```

**用 Usage API 按 api_key_id 過濾追蹤**：

```bash
curl https://api.anthropic.com/v1/organizations/usage_report/messages \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -d '{
    "group_by": ["api_key"],
    "start_time": "2026-03-01T00:00:00Z",
    "end_time": "2026-03-05T23:59:59Z"
  }'
```

---

### 6.3 Managed Policy Settings（Enterprise）

**集中部署 Claude Code 設定**：

**透過 MDM (Mobile Device Management) 分發設定檔**：

**範例：限制檔案存取**

```json
{
  "name": "Company Claude Code Policy",
  "version": "1.0",
  "settings": {
    "allowed_paths": [
      "/Users/*/company-projects/**",
      "/opt/company-repos/**"
    ],
    "blocked_paths": [
      "/Users/*/Documents/Personal/**",
      "/Users/*/Downloads/**"
    ],
    "tool_permissions": {
      "bash": "restricted",
      "write": "require_confirmation",
      "read": "allow"
    }
  }
}
```

**設定部署方式**：
1. IT 管理員建立設定檔
2. 透過 MDM (Jamf / Intune) 分發到公司電腦
3. 用戶無法覆寫（強制執行）

**效果**：
- ✅ 只能存取公司專案目錄
- ✅ 不能在個人目錄使用 Claude Code
- ✅ Bash 工具需要確認

---

### 6.4 Compliance API（Enterprise）

**即時程式化存取使用資料和客戶內容**：

**Endpoint**: `/v1/organizations/compliance/data`

**功能**：
- ✅ 自動化政策執行
- ✅ 即時審計
- ✅ 選擇性資料刪除

**範例：審計特定用戶的所有 prompt**

```bash
curl https://api.anthropic.com/v1/organizations/compliance/data \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -d '{
    "user_email": "developer@company.com",
    "data_types": ["prompts", "responses"],
    "start_time": "2026-03-01T00:00:00Z",
    "end_time": "2026-03-05T23:59:59Z"
  }'
```

**範例：刪除特定 session 的資料**

```bash
curl -X DELETE https://api.anthropic.com/v1/organizations/compliance/data \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -d '{
    "session_id": "ses_abc123",
    "reason": "User requested data deletion (GDPR)"
  }'
```

---

### 6.5 Audit Log（Enterprise）

**追蹤系統活動**：

**Endpoint**: `/v1/organizations/audit_log`

**可追蹤事件**：
- 用戶登入/登出
- API Key 建立/刪除
- 設定變更
- 角色權限變更
- 成本超過閾值

**範例**：

```bash
curl https://api.anthropic.com/v1/organizations/audit_log \
  -H "x-api-key: sk-ant-admin-xxxxx" \
  -d '{
    "start_time": "2026-03-01T00:00:00Z",
    "end_time": "2026-03-05T23:59:59Z",
    "event_types": ["api_key_created", "settings_changed"]
  }'
```

**Response**：
```json
{
  "data": [
    {
      "timestamp": "2026-03-05T10:15:30Z",
      "event_type": "api_key_created",
      "actor": "admin@company.com",
      "details": {
        "api_key_name": "dev-charlie",
        "permissions": ["read", "write"]
      }
    }
  ]
}
```

**匯出權限**：僅組織擁有者和主要擁有者可匯出。

---

### 6.6 OpenTelemetry 行為分析

**監控異常使用模式**：

#### 6.6.1 監控 terminal_type 異常

**查詢**：
```
terminal.type != "vscode" AND terminal.type != "cursor"
```

**告警**：發現非 IDE 環境使用（如直接在 Terminal 執行）

#### 6.6.2 追蹤 session 時間模式

**查詢**：
```
session.start_time BETWEEN "22:00" AND "06:00"
```

**告警**：非工作時間大量使用（可能是個人專案）

#### 6.6.3 分析檔案路徑

**透過 tool_result 事件的檔案路徑判斷是否在授權專案目錄內**：

```python
def is_authorized_path(file_path: str) -> bool:
    authorized_dirs = [
        "/Users/*/company-projects",
        "/opt/company-repos"
    ]
    return any(file_path.startswith(d) for d in authorized_dirs)

# 監控腳本
for event in otel_events:
    if event.type == "tool_result" and event.tool == "Read":
        if not is_authorized_path(event.file_path):
            send_alert(f"Unauthorized file access: {event.file_path}")
```

#### 6.6.4 設定告警

**Cost Spike（成本突增）**：
```yaml
alert:
  name: "Cost Spike Detected"
  condition: "cost.usage > 100 USD in 1 hour"
  action: "Slack + Email"
```

**Unusual Token Consumption（異常 token 消耗）**：
```yaml
alert:
  name: "Unusual Token Usage"
  condition: "token.usage > 500K in 10 minutes"
  action: "Slack + Pause API Key"
```

**High Session Volume（高頻會話）**：
```yaml
alert:
  name: "High Session Volume"
  condition: "session.count > 50 per user per day"
  action: "Email to manager"
```

---

## 7. 預算控管機制

### 7.1 組織層級預算

**在 Console 設定 Spend Limit**：

```
Console → Settings → Organization → Spending Limits
```

**設定範例**：
```
Monthly Spend Limit: $10,000
Alert at 80%: $8,000
Hard stop at 100%: $10,000
```

**效果**：
- 到達 80% 時發送告警 (Email + Slack)
- 到達 100% 時自動暫停所有 API 調用

---

### 7.2 個人用戶預算

**管理員可設定每位成員的月度上限**：

```
Console → Members → Select User → Set Monthly Limit
```

**範例**：
```
Alice (Senior Dev): $500/月
Bob (Junior Dev): $200/月
Charlie (Intern): $100/月
```

**效果**：
- 用戶到達上限後自動暫停 extra usage
- 基礎訂閱包含的用量不受影響
- **MTD Spend** 欄位追蹤即時花費

---

### 7.3 Workspace 預算

**按 workspace 設定 spend limit**：

```
Console → Workspaces → Select Workspace → Spending Limits
```

**範例**：
```
frontend-team: $3,000/月
backend-team: $5,000/月
data-team: $2,000/月
```

**限制**：workspace limit 不能超過 organization limit。

---

### 7.4 Seat Tier 預算（Enterprise）

**按座位類型設定上限**：

```
Standard Seat: $50/月 per user
Premium Seat: $150/月 per user
```

**效果**：
- Standard Seat 用戶最多花 $50
- Premium Seat 用戶最多花 $150
- 超過後需要升級 Seat 或等待下個月

---

### 7.5 Extra Usage 管理

#### Claude for Teams

**預購 Extra Usage**：
```
Console → Billing → Extra Usage → Purchase Credits
```

**自動充值**：
```
Console → Billing → Auto-Recharge Settings
Trigger: When balance < $100
Recharge: $500
```

**停用 Extra Usage**：
```
Console → Settings → Organization → Disable Extra Usage
```

**效果**：
- 用戶用完基礎用量後無法繼續使用
- 適合嚴格預算控制

#### Claude for Enterprise

**按實際用量月結**：
- 無需預購
- 月底統一結算
- 可設定 hard limit

---

### 7.6 API Tier 限制

**Anthropic API 的 Usage Tiers 自帶預算控制**：

| Tier | Deposit | Monthly Limit | 升級條件 |
|------|---------|--------------|---------|
| Free | $0 | $10 | 無 |
| Tier 1 | $5 | $100 | 存款 $5 |
| Tier 2 | $40 | $500 | 累計花費 $100 |
| Tier 3 | $200 | $1,000 | 累計花費 $500 |
| Tier 4 | $400 | $5,000 | 累計花費 $1,000 |

**如何升級**：
```
Console → Billing → Upgrade Tier → Deposit
```

**自動升級**：達到累計花費門檻時自動升級（需先存款）

---

## 8. 企業安全與合規

### 8.1 單一登入（SSO）

**支援協議**：
- **SAML 2.0**
- **OIDC** (OpenID Connect)

**支援的 Identity Providers**：
- Okta
- Azure AD (Entra ID)
- Google Workspace
- OneLogin
- Ping Identity

**設定流程**：
1. Console → Settings → SSO
2. 選擇 SAML 或 OIDC
3. 輸入 IdP Metadata URL
4. 測試登入
5. 啟用

**效果**：
- ✅ 用戶用公司帳號登入
- ✅ 集中管理權限
- ✅ 強制 MFA

---

### 8.2 SCIM 自動化用戶管理

**System for Cross-domain Identity Management**

**功能**：
- ✅ 自動同步用戶（新增/刪除/停用）
- ✅ 自動同步群組
- ✅ 當員工離職時自動撤銷存取

**設定流程**：
1. Console → Settings → SCIM
2. 生成 SCIM Token
3. 在 IdP (Okta/Azure AD) 設定 SCIM endpoint
4. 測試同步
5. 啟用

**SCIM Endpoint**：
```
https://api.anthropic.com/scim/v2
```

**Token 範例**：
```
Bearer scim_token_abc123xyz
```

---

### 8.3 Domain Capture

**自動化 Workspace 註冊**：

**功能**：
- 當員工用 `@company.com` email 註冊時
- 自動加入公司 workspace
- 自動套用公司政策

**設定流程**：
1. Console → Settings → Domain Capture
2. 輸入公司網域（如 `company.com`）
3. 選擇預設 Workspace
4. 啟用

**效果**：
- ✅ 員工無法用公司 email 註冊個人帳號
- ✅ 所有用量追蹤到公司
- ✅ 離職後可統一撤銷

---

### 8.4 角色權限管理（RBAC）

**預設角色**：

| 角色 | 權限 |
|------|------|
| **Organization Owner** | 完整控制（計費、設定、用戶管理） |
| **Primary Owner** | 次級管理員（可匯出 Audit Log） |
| **Member** | 使用 Claude（無管理權限） |
| **API Key Manager** | 管理 API Keys（無計費權限） |
| **Billing Admin** | 管理計費（無用戶管理權限） |

**自訂角色**（Enterprise）：
- 可自訂權限組合
- 按團隊/專案分配

---

### 8.5 HIPAA-ready 環境

**Health Insurance Portability and Accountability Act**

**功能**：
- ✅ 符合 HIPAA 合規要求
- ✅ BAA (Business Associate Agreement) 簽署
- ✅ 加密傳輸和儲存
- ✅ 審計日誌

**限制**：
- ❌ **不含 Claude Code**（僅 API）
- ❌ 需要 Enterprise 方案

**申請流程**：
1. 聯繫 Anthropic 銷售團隊
2. 簽署 BAA
3. 啟用 HIPAA-ready 環境

---

### 8.6 資料隱私與合規

**Zero-data-retention (Enterprise API)**：
- ✅ API 流量不用於訓練模型
- ✅ 不儲存客戶內容（除 Audit Log）
- ✅ 選擇性資料刪除（Compliance API）

**認證**：
- ✅ **SOC 2 Type II** 合規
- ✅ **ISO 27001** 認證
- ✅ **GDPR** 合規
- ✅ **CCPA** 合規

**資料駐留（Data Residency）**：
- **US-only**: 1.1x 加成（資料僅存美國境內）
- **EU**: 即將推出（2026 H1）

---

### 8.7 BYOK（即將推出）

**Bring Your Own Key**

**功能**：
- ✅ 用自己的加密金鑰加密資料
- ✅ 完全控制資料存取
- ✅ 可隨時撤銷金鑰（資料無法解密）

**預計推出**: 2026 H1

---

### 8.8 VPC 隔離（Bedrock/Vertex）

**AWS Bedrock VPC 設定**：

```bash
# VPC Endpoint 設定
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxx \
  --service-name com.amazonaws.us-west-2.bedrock-runtime \
  --route-table-ids rtb-xxxxx
```

**效果**：
- ✅ LLM 流量不經過公網
- ✅ 完全隔離
- ✅ 符合企業網路政策

**Google Vertex AI VPC**：
```bash
gcloud compute networks vpc-access connectors create claude-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28
```

---

## 9. 案例研究

### 9.1 incident.io（~500K 行 TypeScript）

**公司背景**：
- SaaS 平台（事件管理）
- ~500K 行 TypeScript codebase

**使用方式**：
- 4-7 concurrent agents + git worktrees
- 平行處理多個功能分支

**成果**：
- ⚡ JavaScript 編輯器重寫：**2hr → 10min** (12x 加速)
- 💰 Build 優化：**$8** 完成 18% 改善（原需數天）
- 🔄 Feedback loop：**90s → <10s**

**關鍵策略**：
- 善用 Agent Teams 平行開發
- 投資 CLAUDE.md 文件讓 AI 理解 codebase

---

### 9.2 Altana

**公司背景**：
- AI-powered supply chain networks
- 複雜的資料處理和機器學習

**成果**：
- ⚡ **2-10x 開發速度提升**（across teams）
- 📝 稱 Claude Code 為 **"go-to pair programmer"**

**應用場景**：
- 資料管道建設
- ML 模型調試
- API 整合

---

### 9.3 Treasure Data

**公司背景**：
- Customer Data Platform (CDP)
- 大規模資料處理

**成果**：
- 📈 採用率：**20% → 80%**（6 個月內）
- ⚡ MCP Server 開發：**1 天完成**（原需 2-3 週）
- 🛠️ 支援團隊用 Claude + MCP Server 調查客戶問題

**關鍵策略**：
- 建立內部 MCP Server 生態系
- "one click" 安裝方式加速採用

---

### 9.4 Rakuten

**公司背景**：
- 日本電商巨頭
- 大型 legacy codebase

**成果**：
- ⚡ **7 小時**自主程式碼重構（原需數週）

**應用場景**：
- Legacy code 重構
- 技術債務清理

---

### 9.5 Anthropic 內部

**Security Engineering**：
- ⚡ 問題解決速度 **3x**
- 🔒 安全審計自動化

**Inference Team**：
- 📊 研究時間減少 **80%**
- 🚀 模型優化加速

**Growth Marketing**：
- 📝 分鐘級產出數百個廣告變體
- 🎨 A/B 測試速度提升

---

### 9.6 Y Combinator 新創

**HumanLayer**：
- ⚡ **7 小時 session** = 1-2 週工作量
- 🚀 Founder 用 Claude Code 做快速原型

**Vulcan Technologies**：
- 👨‍💻 非技術創辦人用 Claude Code 做原型
- 💰 **4 個月獲 $11M 種子輪**

**關鍵模式**：
- 非技術創辦人用 AI 驗證想法
- 快速 MVP 到產品化

---

### 9.7 ROI 數據總結

**Faros AI 測量**：
- **4:1 ROI**
- 每個增量 PR 成本 **$37.50** vs 開發者時間 **$150**

**工具接受率計算**：
```
Acceptance Rate = accepted / (accepted + rejected)
```

**平均接受率**：
- Edit Tool: 85-90%
- Write Tool: 80-85%
- Bash Tool: 70-75%

---

## 10. 部署最佳實踐

### 10.1 導入策略

**階段式導入**：

```mermaid
graph LR
    A["Phase 1: Pilot<br/>5-10 人<br/>2-4 週"] --> B["Phase 2: Early Adopters<br/>20-30% 團隊<br/>2-3 個月"]
    B --> C["Phase 3: Majority<br/>70-80% 團隊<br/>6 個月"]
    C --> D["Phase 4: Full Adoption<br/>全組織<br/>12 個月"]

    style A fill:#90EE90
    style B fill:#87CEEB
    style C fill:#FFD93D
    style D fill:#FF6B6B
```

#### Phase 1: Pilot (5-10 人)

**目標**：
- 建立使用模式
- 收集成本數據
- 識別問題和瓶頸

**關鍵活動**：
1. 選擇 early adopters（對 AI 有興趣的開發者）
2. 投資 **CLAUDE.md 文件**讓 AI 理解 codebase
3. 每週收集反饋
4. 追蹤成本（預計 $100-200/人/月）

**成功指標**：
- 工具接受率 > 80%
- 參與者滿意度 > 4/5
- 明確的 ROI 數據

#### Phase 2: Early Adopters (20-30% 團隊)

**目標**：
- 擴大使用範圍
- 建立內部最佳實踐
- 培訓 champions

**關鍵活動**：
1. 建立 **"one click" 安裝方式**加速採用
2. 引導新用戶從 **codebase Q&A** 和小 bug 開始
3. 內部分享會（成功案例）
4. 建立 Slack channel (#claude-code-help)

**成功指標**：
- 採用率 > 25%
- 平均每人 > 3 sessions/week
- 成本在預算範圍內

#### Phase 3: Majority (70-80% 團隊)

**目標**：
- 成為標準開發工具
- 優化成本和效能
- 自動化監控

**關鍵活動**：
1. 漸進式放開 **agentic 模式**（Agent Teams）
2. 部署 **OpenTelemetry 監控**
3. 設定 **成本告警**
4. 強制使用（新專案必須用 Claude Code）

**成功指標**：
- 採用率 > 70%
- 14.9% PR 有 AI 參與（業界平均）
- 開發速度提升 > 30%

#### Phase 4: Full Adoption (全組織)

**目標**：
- 持續優化
- 探索進階用例
- 成為競爭優勢

**關鍵活動**：
1. 建立 **Agent Army** 多代理系統
2. 自動化 code review, testing, documentation
3. 整合到 CI/CD pipeline
4. 跨團隊共享 Skills 和 Plugins

---

### 10.2 成本優化清單

#### 10.2.1 模型選擇策略

**分層使用模型**：

| 任務類型 | 推薦模型 | 原因 |
|---------|---------|------|
| 複雜架構設計 | Opus 4.6 | 需要深度推理 |
| 一般編碼 | Sonnet 4.5/4.6 | 性能與成本平衡 |
| 程式碼補全、小修改 | Haiku 4.5 | 快速且便宜 |
| 文件生成 | Sonnet 4.0 | 不需最新模型 |

**節省估算**：
- 全用 Opus：$15/1M input tokens
- 分層使用：加權平均 ~$7/1M input tokens
- **節省約 50%**

#### 10.2.2 Prompt Caching

**善用 Prompt Caching（cache hit 只要 10% 成本）**：

```python
# 將 system prompt 標記為可快取
system_prompt = {
    "type": "text",
    "text": "You are a senior software architect...",  # 3500 tokens
    "cache_control": {"type": "ephemeral"}
}
```

**效果**：
- 第一次調用：100% 費用
- 5 分鐘內第二次：10% 費用（90% 折扣）
- 1 小時內（1h cache）：10% 費用

**節省估算**：
- Cache hit rate: 30-50%
- 節省成本: 27-45%

#### 10.2.3 Batch API

**非即時任務可省 50%**：

**適用場景**：
- 批次測試（test suite 執行）
- 文件生成（API docs, README）
- 資料分析（log 分析、metrics）
- 程式碼審查（非阻塞）

**不適用場景**：
- 即時對話
- 緊急 bug 修復
- 互動式開發

#### 10.2.4 精準 Prompt

**減少不必要的 file scan**：

```python
# 不好：掃描整個 repo
prompt = "Find all TODO comments in the codebase"

# 好：限定範圍
prompt = "Find all TODO comments in src/domain/ directory"
```

**節省估算**：
- 精準 prompt 可減少 30-50% input tokens

#### 10.2.5 Agent Teams 清理

**用完要清理（閒置也消耗 token）**：

```bash
# 完成任務後立即清理
claude-code agent cleanup
```

**成本**：
- 閒置 Agent Team (5 agents)：~$0.50/hour
- 一天忘記關：~$12

#### 10.2.6 設定 Thinking Budget

**降低 output token**：

```json
{
  "model": "claude-opus-4-6",
  "thinking": {
    "type": "enabled",
    "budget_tokens": 1000
  }
}
```

**效果**：
- 限制內部思考的 token 數
- 減少 output token（output 比 input 貴 5x）

#### 10.2.7 子代理處理 Verbose 操作

**範例**：

```python
# Tech Lead (Opus) 只做高層決策
# Implementer (Sonnet) 處理詳細編碼

# 不好：Tech Lead 直接寫 code
tech_lead.execute("Write the entire user service")

# 好：Tech Lead 委派
tech_lead.delegate_to(implementer, "Write user service based on this design")
```

**節省估算**：
- Opus 寫 code：$15 input + $75 output = $90/1M tokens
- Sonnet 寫 code：$3 input + $15 output = $18/1M tokens
- **節省 80%**

---

### 10.3 雲端平台 Pin Model Version

**問題**：新模型上線時，舊版本可能未啟用導致中斷。

**解決方案**：明確指定模型版本

```bash
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-6"
export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-0"
claude-code
```

**Bedrock 設定**：
```bash
export BEDROCK_MODEL_ID="anthropic.claude-sonnet-v4:0"
```

**效果**：
- ✅ 避免自動升級導致費用增加
- ✅ 確保行為一致性
- ✅ 可控的升級時間

---

### 10.4 安全策略設定

#### 10.4.1 Managed Permissions

**限制工具行為**：

```json
{
  "tool_permissions": {
    "bash": {
      "allowed_commands": ["npm", "git", "python"],
      "blocked_commands": ["rm -rf", "curl", "wget"]
    },
    "write": {
      "require_confirmation": true,
      "blocked_paths": ["/etc/**", "/usr/**"]
    },
    "read": {
      "blocked_paths": [
        "**/.env",
        "**/*secret*",
        "**/*credentials*"
      ]
    }
  }
}
```

#### 10.4.2 Security 團隊集中管理 MCP Server

**將 .mcp.json 設定簽入 repo**：

```json
{
  "mcpServers": {
    "company-db": {
      "command": "mcp-server-postgresql",
      "args": ["--connection-string", "$DB_CONNECTION"],
      "approved_by_security": true,
      "security_review_date": "2026-03-01"
    },
    "public-api": {
      "command": "mcp-server-fetch",
      "approved_by_security": true
    }
  }
}
```

**效果**：
- ✅ 所有開發者用同一組 MCP servers
- ✅ Security 團隊集中審查
- ✅ 版本控制（Git）

---

## 11. 決策流程圖

### 11.1 選擇部署方案

```mermaid
flowchart TD
    Start["需要部署 Claude Code"] --> Q1{"團隊規模?"}

    Q1 -->|"1-5 人"| Q2{"預算?"}
    Q2 -->|"願意付訂閱費"| A1["Claude for Teams<br/>Premium Seat<br/>$100-150/月/人"]
    Q2 -->|"按用量付費"| A2["Anthropic API<br/>自行管理<br/>~$100-200/月/人"]

    Q1 -->|"5-50 人"| Q3{"需要企業功能?"}
    Q3 -->|"否"| A3["Claude for Teams<br/>或 API<br/>自建監控"]
    Q3 -->|"是"| A4["Claude for Enterprise<br/>聯繫銷售"]

    Q1 -->|"50+ 人"| Q4{"使用哪個雲端?"}
    Q4 -->|"AWS"| A5["AWS Bedrock<br/>整合 IAM + CloudTrail"]
    Q4 -->|"GCP"| A6["Google Vertex AI<br/>整合 Cloud Billing"]
    Q4 -->|"Azure"| A7["Microsoft Foundry<br/>整合 Entra ID"]
    Q4 -->|"無特定雲端"| A4

    style A1 fill:#90EE90
    style A2 fill:#87CEEB
    style A3 fill:#FFD93D
    style A4 fill:#FF6B6B
    style A5 fill:#DDA0DD
    style A6 fill:#F0E68C
    style A7 fill:#B0C4DE
```

### 11.2 預算規劃流程

```mermaid
flowchart TD
    Start["開始預算規劃"] --> Step1["1. Pilot 測試<br/>5-10 人，收集 3 個月數據"]

    Step1 --> Step2["2. 計算平均用量<br/>每人每月 tokens 和成本"]

    Step2 --> Step3["3. 估算團隊規模<br/>總人數 × 平均成本"]

    Step3 --> Step4["4. 加上 buffer<br/>總預算 × 1.2-1.5"]

    Step4 --> Step5["5. 設定監控<br/>Admin API + OpenTelemetry"]

    Step5 --> Step6{"實際成本 vs 預算?"}

    Step6 -->|"超過 80%"| Action1["告警 + 優化<br/>- 分層模型<br/>- Prompt caching<br/>- Batch API"]
    Step6 -->|"低於 60%"| Action2["擴大使用<br/>- 增加採用率<br/>- 探索新用例"]
    Step6 -->|"60-80%"| Action3["持續監控<br/>季度檢視"]

    Action1 --> Step5
    Action2 --> Step5
    Action3 --> End["預算健康"]

    style Start fill:#90EE90
    style End fill:#90EE90
    style Action1 fill:#FF6B6B
    style Action2 fill:#87CEEB
```

---

## 12. 參考資源

### 12.1 官方文件

| 資源 | URL |
|------|-----|
| **Claude Code Documentation** | https://docs.claude.ai/claude-code |
| **API Reference** | https://docs.anthropic.com/api |
| **Pricing** | https://anthropic.com/pricing |
| **Enterprise** | https://anthropic.com/enterprise |
| **Prompt Caching** | https://docs.anthropic.com/claude/docs/prompt-caching |
| **Admin API** | https://docs.anthropic.com/admin-api |

### 12.2 監控與追蹤工具

| 工具 | 類型 | URL |
|------|------|-----|
| **Langfuse** | 開源可觀測性 | https://langfuse.com |
| **Helicone** | 成本追蹤 | https://helicone.ai |
| **Datadog LLM Obs** | APM 整合 | https://datadoghq.com/llm-observability |
| **Honeycomb** | OpenTelemetry | https://honeycomb.io |
| **CloudZero** | FinOps | https://cloudzero.com |
| **Vantage** | 成本優化 | https://vantage.sh |
| **LiteLLM** | 開源 Gateway | https://github.com/BerriAI/litellm |

### 12.3 案例研究

| 公司 | 來源 |
|------|------|
| **incident.io** | https://incident.io/blog/claude-code-case-study |
| **Altana** | https://anthropic.com/customers/altana |
| **Treasure Data** | https://anthropic.com/customers/treasure-data |
| **Rakuten** | https://anthropic.com/customers/rakuten |

### 12.4 市場研究

| 報告 | 來源 |
|------|------|
| **Gartner: AI Agents Transform Enterprise** | Gartner Research (2025-11) |
| **Faros AI: Claude Code ROI Study** | https://faros.ai/blog/claude-code-roi |
| **GitHub: AI-Powered Development Report 2026** | GitHub Universe 2026 |

### 12.5 社群資源

| 資源 | URL |
|------|-----|
| **Claude Code Discord** | https://discord.gg/anthropic |
| **r/ClaudeAI** | https://reddit.com/r/ClaudeAI |
| **Anthropic Blog** | https://anthropic.com/blog |

---

## 總結

Claude Code CLI 從個人工具到企業基礎設施，需要考慮的維度遠超技術本身：

**關鍵決策點**：
1. ✅ **方案選擇**：訂閱制（Teams/Enterprise）vs PAYG（API）vs 雲端平台（Bedrock/Vertex）
2. ✅ **預算規劃**：從 pilot 數據推算，設定監控和告警
3. ✅ **用量追蹤**：Admin API + Claude Code Analytics API + OpenTelemetry
4. ✅ **成本優化**：分層模型 + Prompt Caching + Batch API + 精準 prompt
5. ✅ **安全合規**：SSO + SCIM + Managed Policy + Audit Log
6. ✅ **偵測濫用**：Workspace 隔離 + API Key 分配 + 行為分析

**企業部署黃金法則**：
- 📊 **先 Pilot，再擴大**（5-10 人 → 20-30% → 全組織）
- 💰 **持續監控成本**（每週檢視，每月優化）
- 🔒 **安全第一**（Managed Policy + 最小權限）
- 📈 **量化 ROI**（追蹤工具接受率、開發速度、成本節省）
- 🎯 **投資 Context**（CLAUDE.md 讓 AI 理解 codebase）

**2026 年趨勢**：
- 🌊 **14.9% PR 有 AI 參與**（業界平均）
- 💸 **平均每人 $100-200/月**（Sonnet 為主）
- ⚡ **2-10x 開發速度提升**（已驗證案例）
- 🏢 **40% 企業應用內建 AI Agent**（Gartner 預測）

**開始行動**：
- 今天：挑選 5-10 人 pilot 團隊
- 本週：設定 Admin API 追蹤
- 本月：部署 OpenTelemetry 監控
- 下季：擴大到 20-30% 團隊

---

**Sources**:
- Anthropic Documentation: https://docs.anthropic.com
- Anthropic Pricing: https://anthropic.com/pricing
- Claude Code Analytics API: https://docs.anthropic.com/admin-api/usage-analytics
- Admin API Reference: https://docs.anthropic.com/admin-api
- OpenTelemetry Integration: https://docs.anthropic.com/claude-code/telemetry
- incident.io Case Study: https://incident.io/blog/claude-code-case-study
- Anthropic Customer Stories: https://anthropic.com/customers
- Gartner AI Agents Report: Gartner Research 2025-11
- GitHub Universe 2026: AI-Powered Development Report

*本文件由 Agent Army Documenter 撰寫 | 更新日期: 2026-03-05*
