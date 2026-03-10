# API Bridge 設計文件

> **版本**: 1.0.0 | **最後更新**: 2026-03-10
> **一句話說明**: 後端一個指令產出 API 描述檔，前端一個指令串接完成 -- AI 原生的 API 協作橋樑。

---

## 目錄

1. [總覽](#1-總覽)
2. [原理](#2-原理)
3. [API 描述檔格式](#3-api-描述檔格式)
4. [完整流程](#4-完整流程)
5. [API Catalog Repo 結構](#5-api-catalog-repo-結構)
6. [初始化與設定指南](#6-初始化與設定指南)
7. [使用情境](#7-使用情境)
8. [前端產出範例](#8-前端產出範例)
9. [版號管理](#9-版號管理)
10. [V1 範圍與未來規劃](#10-v1-範圍與未來規劃)
11. [FAQ](#11-faq)

---

## 1. 總覽

### 核心理念

API Bridge 是 Agent Army 插件系統中的 API 協作工具。它的設計哲學極其簡單：

- **後端**：執行 `/api-extract`，自動掃描原始碼，產出對 LLM 友善的 API 描述檔
- **前端**：執行 `/api-integrate`，自動讀取描述檔，生成完整的 types、client、hooks 程式碼

不需要手動撰寫 OpenAPI spec，不需要 code generator 設定檔，不需要跨團隊會議對齊 API 格式。

### 系統架構圖

```mermaid
flowchart TB
    subgraph tool["工具層 — agent-army plugin"]
        A1["/api-extract<br/>Skill A：後端掃描"]
        A2["/api-integrate<br/>Skill B：前端串接"]
    end

    subgraph data["資料層 — api-catalog repo"]
        B1["user-service/<br/>api-index.yaml + modules/*.md"]
        B2["order-service/<br/>api-index.yaml + modules/*.md"]
        B3["payment-service/<br/>api-index.yaml + modules/*.md"]
    end

    subgraph subscribe["訂閱層 — 各前端專案"]
        C1["web-app（React）<br/>.claude/api-sources.yaml"]
        C2["mobile-app（React Native）<br/>.claude/api-sources.yaml"]
        C3["admin-panel（Vue）<br/>.claude/api-sources.yaml"]
        C4["ios-app（Swift）<br/>.claude/api-sources.yaml"]
    end

    A1 -->|"掃描後端原始碼<br/>產出描述檔"| B1
    A1 -->|"掃描後端原始碼<br/>產出描述檔"| B2
    A1 -->|"掃描後端原始碼<br/>產出描述檔"| B3

    B1 -->|"訂閱 auth + users"| C1
    B1 -->|"訂閱 auth"| C2
    B2 -->|"訂閱 orders"| C1
    B2 -->|"訂閱 orders"| C3
    B3 -->|"訂閱 payments"| C1
    B3 -->|"訂閱 payments"| C3

    style tool fill:#4a9ebb,stroke:#2d7ea0,color:#fff
    style data fill:#e8a838,stroke:#c48820,color:#fff
    style subscribe fill:#6bbf6b,stroke:#4a9a4a,color:#fff
```

### 角色分工

| 角色 | 職責 | 使用的 Skill | 產出 |
|------|------|-------------|------|
| 後端開發者 | 開發 API、執行 extract | `/api-extract` | API 描述檔（YAML + MD） |
| api-catalog 維護者 | 管理描述檔版本、審核 PR | — | 版本化的 API 描述檔 |
| 前端開發者 | 訂閱所需模組、執行 integrate | `/api-integrate` | types.ts, client.ts, hooks.ts |
| CI/CD | 自動化推送與通知 | — | 自動更新、版本比對 |

---

## 2. 原理

### 三層設計

API Bridge 採用三層分離架構，各層職責獨立：

| 層級 | 名稱 | 載體 | 職責 |
|------|------|------|------|
| 工具層 | agent-army skills | `/api-extract`、`/api-integrate` | 掃描、生成、驗證 |
| 資料層 | api-catalog repo | Git 儲存庫 | 版本化的 API 知識儲存 |
| 訂閱層 | 前端 api-sources.yaml | 各前端專案設定 | 宣告依賴哪些 API 模組 |

```mermaid
flowchart LR
    subgraph 工具層
        S1["/api-extract"]
        S2["/api-integrate"]
    end

    subgraph 資料層
        C["api-catalog repo<br/>（Git 版本控制）"]
    end

    subgraph 訂閱層
        F1["前端 A"]
        F2["前端 B"]
    end

    S1 -->|"寫入"| C
    C -->|"讀取"| S2
    S2 -->|"生成程式碼"| F1
    S2 -->|"生成程式碼"| F2
```

### 為什麼不用中間 spec 格式

傳統做法是後端產出 OpenAPI spec，再用 codegen 工具轉成前端程式碼。API Bridge 刻意跳過這個環節：

| 比較 | 傳統 OpenAPI 流程 | API Bridge |
|------|-------------------|------------|
| 中間格式 | OpenAPI 3.x JSON/YAML | 無（描述檔本身就是知識載體） |
| 轉換工具 | openapi-generator, swagger-codegen | LLM 直接理解描述檔 |
| 客製化 | 修改 mustache template | Skill 內建策略，依框架自動適配 |
| 維護成本 | spec + template + generator 設定 | 描述檔即文件，零額外維護 |

**關鍵洞察**：Skill B（`/api-integrate`）的 LLM 直接閱讀 Markdown 格式的 API 描述，比解析 OpenAPI JSON 更自然、更準確。描述檔本身就是 LLM 的「知識」，不需要再經過一層機器可讀格式的轉譯。

### 為什麼拆模組

大型後端可能有 100+ endpoints。如果全部放在一個檔案中：

1. **Context window 限制**：一個 100 endpoint 的 API 描述約 8,000-12,000 tokens，加上前端程式碼 context 很容易超過有效 window
2. **前端只需要部分 API**：管理後台不需要使用者登入 API，行動端不需要報表 API
3. **版本獨立性**：auth 模組穩定不變，orders 模組頻繁更新，不應該綁在一起

### 模組拆分策略

依優先順序選擇拆分依據：

| 優先順序 | 策略 | 適用場景 | 範例 |
|----------|------|----------|------|
| 1 | 按 Controller 檔案 | NestJS, Spring, Rails | `AuthController` → `auth.md` |
| 2 | 按 OpenAPI tags | 已有 spec 的專案 | `tags: [users]` → `users.md` |
| 3 | 按路由目錄 | Express, Gin, FastAPI | `routes/orders/` → `orders.md` |
| 4 | 按業務域 | 無明確分層的專案 | LLM 分析語意分群 |

### 版號規則

採用 [Semantic Versioning 2.0.0](https://semver.org/)：

| 變更類型 | 版號 | 範例 |
|----------|------|------|
| **Major** (破壞性) | `X.0.0` | 移除 endpoint、修改 response 結構、更改 URL path |
| **Minor** (向下相容新增) | `x.Y.0` | 新增 endpoint、新增 optional 欄位 |
| **Patch** (修正) | `x.y.Z` | 修正描述文字、補充 error code |

### 驗證機制

```mermaid
flowchart LR
    subgraph 後端驗證
        E1["掃描完成"] --> E2["格式驗證<br/>（YAML schema）"]
        E2 --> E3["Endpoint 計數比對"]
        E3 --> E4["範例 request 驗證"]
    end

    subgraph 前端驗證
        I1["程式碼生成"] --> I2["TypeScript 型別檢查"]
        I2 --> I3["Build 驗證"]
        I3 --> I4["import 路徑驗證"]
    end

    E4 -->|"推到 catalog"| I1
```

- **後端產出後**：驗證 YAML 格式正確、endpoint 數量與原始碼一致、response type 完整
- **前端串接後**：驗證 `tsc --noEmit` 通過、`build` 成功、沒有未解析的 import

---

## 3. API 描述檔格式

### api-index.yaml 完整範例

```yaml
# api-index.yaml — API 服務索引檔
# 此檔案描述一個後端服務的所有 API 模組

service: user-service                    # 服務名稱（唯一識別符）
version: 2.1.0                           # 目前版本（semver）
base: /api/v1                            # API 基礎路徑
auth: Bearer token in Authorization header  # 認證方式描述

# 全域共用型別（跨模組共用的 response 結構）
shared_types: |
  type User = {
    id: string
    name: string
    email: string
    avatar?: string
    role: 'admin' | 'user' | 'moderator'
    createdAt: string       // ISO 8601
    updatedAt: string       // ISO 8601
  }

  type PaginatedResponse<T> = {
    data: T[]
    meta: {
      total: number
      page: number
      pageSize: number
      totalPages: number
    }
  }

  type ApiError = {
    code: string
    message: string
    details?: Record<string, string[]>
  }

# 模組清單
modules:
  - name: auth                           # 模組名稱（對應 modules/auth.md）
    endpoints: 4                         # Endpoint 數量（用於驗證）
    description: 登入/註冊/token 刷新     # 模組說明

  - name: users                          # 模組名稱（對應 modules/users.md）
    endpoints: 12                        # Endpoint 數量
    description: 使用者 CRUD + 搜尋 + 權限管理

  - name: orders                         # 模組名稱（對應 modules/orders.md）
    endpoints: 23                        # Endpoint 數量
    description: 訂單生命週期（建立/付款/出貨/退款）
```

#### 欄位說明

| 欄位 | 必填 | 說明 |
|------|------|------|
| `service` | 是 | 服務唯一名稱，用於 catalog 目錄命名 |
| `version` | 是 | Semver 版號，每次更新 API 時遞增 |
| `base` | 是 | 所有 endpoint 的基礎路徑前綴 |
| `auth` | 是 | 認證方式的自然語言描述 |
| `shared_types` | 否 | 跨模組共用的型別定義 |
| `modules` | 是 | 模組清單，每個模組對應一個 .md 檔 |
| `modules[].name` | 是 | 模組名稱，對應 `modules/{name}.md` |
| `modules[].endpoints` | 是 | Endpoint 數量，用於產出驗證 |
| `modules[].description` | 是 | 模組功能描述 |

### 模組 .md 檔完整範例

#### auth.md

```markdown
# Auth Module

> 認證與授權相關 API。所有 token 有效期 15 分鐘，refresh token 有效期 30 天。

## POST /auth/login

登入取得 access token。

- Body: `{ email: string, password: string }`
- Returns: `{ token: string, refreshToken: string, user: User }`
- Errors: [401 InvalidCredentials, 429 TooManyAttempts]
- Notes: 連續失敗 5 次鎖定帳號 15 分鐘

## POST /auth/register

註冊新使用者。

- Body: `{ name: string, email: string, password: string }`
- Returns: `{ token: string, user: User }`
- Errors: [400 ValidationError, 409 DuplicateEmail]
- Notes: password 最少 8 字元，需包含大小寫及數字

## POST /auth/refresh

使用 refresh token 換取新的 access token。

- Auth: required (refresh token)
- Body: `{ refreshToken: string }`
- Returns: `{ token: string, refreshToken: string }`
- Errors: [401 InvalidRefreshToken, 401 RefreshTokenExpired]

## POST /auth/logout

登出並使 refresh token 失效。

- Auth: required
- Body: `{}`
- Returns: `{ success: boolean }`
- Errors: [401 Unauthorized]
```

#### users.md

```markdown
# Users Module

> 使用者管理 API。需要 Bearer token 認證。管理員端點需要 admin 角色。

## GET /users

取得使用者列表（分頁）。

- Auth: required (admin)
- Query: `{ page?: number, pageSize?: number, search?: string, role?: string, sort?: string }`
- Returns: `PaginatedResponse<User>`
- Errors: [401 Unauthorized, 403 Forbidden]
- Notes: 預設 pageSize=20，最大 100

## GET /users/:id

取得單一使用者詳情。

- Auth: required
- Params: `{ id: string }`
- Returns: `{ user: User & { profile: UserProfile } }`
- Errors: [401 Unauthorized, 404 UserNotFound]

## POST /users

建立新使用者（管理員）。

- Auth: required (admin)
- Body: `{ name: string, email: string, password: string, role: 'admin' | 'user' | 'moderator' }`
- Returns: `{ user: User }`
- Errors: [400 ValidationError, 409 DuplicateEmail, 403 Forbidden]

## PUT /users/:id

更新使用者資料。

- Auth: required (self or admin)
- Params: `{ id: string }`
- Body: `{ name?: string, email?: string, avatar?: string }`
- Returns: `{ user: User }`
- Errors: [400 ValidationError, 404 UserNotFound, 409 DuplicateEmail]

## DELETE /users/:id

刪除使用者（軟刪除）。

- Auth: required (admin)
- Params: `{ id: string }`
- Returns: `{ success: boolean }`
- Errors: [403 Forbidden, 404 UserNotFound]

## PATCH /users/:id/role

更新使用者角色。

- Auth: required (admin)
- Params: `{ id: string }`
- Body: `{ role: 'admin' | 'user' | 'moderator' }`
- Returns: `{ user: User }`
- Errors: [403 Forbidden, 404 UserNotFound]

## GET /users/:id/orders

取得使用者的訂單列表。

- Auth: required (self or admin)
- Params: `{ id: string }`
- Query: `{ page?: number, pageSize?: number, status?: string }`
- Returns: `PaginatedResponse<Order>`
- Errors: [401 Unauthorized, 404 UserNotFound]

## POST /users/:id/avatar

上傳使用者頭像。

- Auth: required (self or admin)
- Params: `{ id: string }`
- Body: multipart/form-data `{ file: File }`
- Returns: `{ url: string }`
- Errors: [400 InvalidFileType, 413 FileTooLarge]
- Notes: 支援 jpg/png/webp，最大 5MB

## DELETE /users/:id/avatar

刪除使用者頭像。

- Auth: required (self or admin)
- Params: `{ id: string }`
- Returns: `{ success: boolean }`
- Errors: [404 UserNotFound]

## GET /users/me

取得目前登入使用者資料。

- Auth: required
- Returns: `{ user: User & { profile: UserProfile } }`
- Errors: [401 Unauthorized]

## PUT /users/me/password

修改目前使用者密碼。

- Auth: required
- Body: `{ currentPassword: string, newPassword: string }`
- Returns: `{ success: boolean }`
- Errors: [400 ValidationError, 401 InvalidCurrentPassword]

## GET /users/search

搜尋使用者（模糊搜尋 name 和 email）。

- Auth: required
- Query: `{ q: string, limit?: number }`
- Returns: `{ users: User[] }`
- Errors: [400 QueryTooShort]
- Notes: q 最少 2 個字元，limit 預設 10，最大 50
```

### 格式設計原則

| 原則 | 說明 |
|------|------|
| **LLM 友善** | 使用 Markdown 自然語言格式，LLM 無需 parser 即可理解 |
| **Token 效率** | 一個 endpoint 約 50-80 tokens，比 OpenAPI JSON 節省 60-70% |
| **人類可讀** | 開發者可以直接閱讀、PR review、手動修改 |
| **結構一致** | 每個 endpoint 固定格式：Method + Path → 說明 → Body → Returns → Errors |
| **型別內聯** | 使用 TypeScript-like 語法描述型別，LLM 可直接轉為程式碼 |

### 與 OpenAPI 的對比

| 面向 | OpenAPI 3.x | API Bridge 描述檔 |
|------|-------------|-------------------|
| 格式 | JSON/YAML（結構化） | Markdown + YAML（自然語言） |
| 大小 | 100 endpoints ≈ 50KB | 100 endpoints ≈ 15KB |
| Token 消耗 | ≈ 15,000 tokens | ≈ 4,500 tokens |
| LLM 理解度 | 需要 schema 解析知識 | 直接閱讀即理解 |
| 工具依賴 | 需要 codegen 工具鏈 | LLM 即是 codegen |
| 客製化 | 修改 template engine | 自然語言指示 |
| 學習曲線 | 熟悉 OpenAPI spec 規範 | 看一個範例即會 |
| 機器可讀 | 原生支援 | 非設計目標（面向 LLM） |
| 生態整合 | Swagger UI, Postman 等 | Agent Army 生態 |

---

## 4. 完整流程

### 端到端流程圖

```mermaid
sequenceDiagram
    actor BE as 後端開發者
    participant SA as /api-extract<br/>(Skill A)
    participant Cat as api-catalog<br/>repo
    participant SB as /api-integrate<br/>(Skill B)
    actor FE as 前端開發者

    BE->>SA: 執行 /api-extract
    activate SA
    SA->>SA: 1. 掃描原始碼<br/>（偵測框架/路由）
    SA->>SA: 2. 分析 endpoint<br/>（request/response 型別）
    SA->>SA: 3. 模組分群<br/>（按 Controller 或路由）
    SA->>SA: 4. 產出 api-index.yaml<br/>+ modules/*.md
    SA->>SA: 5. 格式驗證<br/>+ endpoint 計數比對
    SA-->>BE: 顯示掃描結果摘要
    deactivate SA

    BE->>Cat: git push（手動或 CI 自動推送）
    Cat->>Cat: 版本標記 + README 更新

    FE->>SB: 執行 /api-integrate --update
    activate SB
    SB->>SB: 1. 讀取 .claude/api-sources.yaml
    SB->>Cat: 2. 拉取描述檔
    Cat-->>SB: api-index.yaml + 訂閱的 modules
    SB->>SB: 3. 比對本地版本與遠端版本
    SB-->>FE: 4. 顯示 API diff<br/>（新增/修改/刪除的 endpoint）
    FE->>SB: 5. 確認更新
    SB->>SB: 6. 偵測前端框架<br/>（React/Vue/Angular/Swift/Kotlin）
    SB->>SB: 7. 生成 types + client + hooks
    SB->>SB: 8. 驗證 type check / build
    SB-->>FE: 顯示生成結果
    deactivate SB
```

### Skill A (`/api-extract`) 掃描策略

依優先順序掃描，找到最可靠的來源即停止：

```mermaid
flowchart TD
    Start["開始掃描"] --> P1{"1. 有 OpenAPI/Swagger spec？"}
    P1 -->|"有"| P1a["解析 openapi.yaml / swagger.json"]
    P1 -->|"無"| P2{"2. 有 GraphQL schema / .proto？"}
    P2 -->|"有"| P2a["解析 schema.graphql / *.proto"]
    P2 -->|"無"| P3{"3. 偵測到已知框架？"}
    P3 -->|"有"| P3a["按框架 pattern 掃描"]
    P3 -->|"無"| P4["4. LLM 分析 route 原始碼"]

    P1a --> Gen["產出描述檔"]
    P2a --> Gen
    P3a --> Gen
    P4 --> Gen

    subgraph 框架偵測
        P3a --> F1["FastAPI → 掃描 @app.get/post 裝飾器"]
        P3a --> F2["NestJS → 掃描 @Controller + @Get/@Post"]
        P3a --> F3["Spring → 掃描 @RestController + @RequestMapping"]
        P3a --> F4["Express → 掃描 router.get/post"]
        P3a --> F5["Gin → 掃描 r.GET/POST"]
        P3a --> F6["Rails → 掃描 routes.rb + controllers"]
    end

    style Start fill:#4a9ebb,color:#fff
    style Gen fill:#6bbf6b,color:#fff
```

**策略 1 — 現有 OpenAPI/Swagger spec**

掃描路徑：`openapi.yaml`、`openapi.json`、`swagger.yaml`、`swagger.json`、`docs/api.*`

**策略 2 — GraphQL / Protocol Buffers**

掃描路徑：`schema.graphql`、`**/*.graphql`、`**/*.proto`

**策略 3 — 框架 Pattern 偵測**

| 框架 | 語言 | 掃描目標 |
|------|------|----------|
| FastAPI | Python | `@app.get`, `@router.post`, Pydantic models |
| NestJS | TypeScript | `@Controller`, `@Get`, `@Post`, DTO classes |
| Spring Boot | Java/Kotlin | `@RestController`, `@RequestMapping`, RequestBody |
| Express | JavaScript/TS | `router.get`, `router.post`, middleware chain |
| Gin | Go | `r.GET`, `r.POST`, binding struct tags |
| Rails | Ruby | `config/routes.rb`, controller actions |

**策略 4 — LLM 分析原始碼**

當以上策略都無法偵測時，直接讓 LLM 閱讀路由檔案和 handler 原始碼，推斷 endpoint 清單。

### Skill B (`/api-integrate`) 生成策略

```mermaid
flowchart TD
    S1["1. 讀取 .claude/api-sources.yaml"] --> S2["2. 拉取描述檔<br/>（git clone / API 下載）"]
    S2 --> S3["3. 偵測前端框架"]
    S3 --> S4["4. 生成程式碼"]
    S4 --> S5["5. 驗證"]

    S3 --> D1{"偵測結果"}
    D1 -->|"React"| G1["types.ts + client.ts + hooks.ts"]
    D1 -->|"Vue"| G2["types.ts + client.ts + composables.ts"]
    D1 -->|"Angular"| G3["models.ts + service.ts"]
    D1 -->|"Swift"| G4["Models.swift + APIClient.swift"]
    D1 -->|"Kotlin"| G5["Models.kt + ApiService.kt"]

    S5 --> V1["tsc --noEmit（TypeScript）"]
    S5 --> V2["swift build（Swift）"]
    S5 --> V3["gradle build（Kotlin）"]

    style S1 fill:#4a9ebb,color:#fff
    style S5 fill:#6bbf6b,color:#fff
```

**Step 1 — 讀取 api-sources.yaml**

```yaml
# .claude/api-sources.yaml
sources:
  - service: user-service
    repo: git@github.com:myorg/api-catalog.git
    path: user-service
    version: "~2.1"          # 接受 2.1.x 的 patch 更新
    modules: [auth, users]   # 只訂閱需要的模組

  - service: order-service
    repo: git@github.com:myorg/api-catalog.git
    path: order-service
    version: "^3.0"          # 接受 3.x 的 minor 更新
    modules: [orders]
```

**Step 2 — 拉取描述檔**：從 catalog repo 下載指定版本的 `api-index.yaml` 和對應的 `modules/*.md`。

**Step 3 — 偵測前端框架**：檢查 `package.json`、`Podfile`、`build.gradle.kts` 等來判斷框架。

**Step 4 — 生成程式碼**：根據框架生成對應的 types、API client、hooks/composables。

**Step 5 — 驗證**：執行 type check 和 build，確保生成的程式碼不會破壞現有專案。

---

## 5. API Catalog Repo 結構

### 完整目錄結構

```
api-catalog/
├── README.md                          # 自動生成的 API 總覽
├── user-service/
│   ├── api-index.yaml                 # 服務索引
│   └── modules/
│       ├── auth.md                    # 認證模組（4 endpoints）
│       ├── users.md                   # 使用者模組（12 endpoints）
│       └── orders.md                  # 使用者訂單模組（23 endpoints）
├── order-service/
│   ├── api-index.yaml
│   └── modules/
│       ├── orders.md                  # 訂單 CRUD（15 endpoints）
│       ├── order-items.md             # 訂單明細（8 endpoints）
│       ├── shipping.md               # 物流追蹤（6 endpoints）
│       └── refunds.md                # 退款流程（5 endpoints）
├── payment-service/
│   ├── api-index.yaml
│   └── modules/
│       ├── payments.md               # 付款處理（7 endpoints）
│       ├── methods.md                # 付款方式管理（5 endpoints）
│       └── webhooks.md              # Webhook 回調（3 endpoints）
└── .github/                          # 或 .gitlab/
    └── workflows/
        └── update-readme.yml         # README 自動更新 workflow
```

### README.md 自動生成範例

```markdown
# API Catalog

> 此檔案由 CI 自動產生，請勿手動修改。
> 最後更新：2026-03-10T08:30:00Z

## 服務總覽

| 服務 | 版本 | 模組數 | Endpoint 總數 | 最後更新 |
|------|------|--------|---------------|----------|
| [user-service](./user-service/) | 2.1.0 | 3 | 39 | 2026-03-08 |
| [order-service](./order-service/) | 3.2.1 | 4 | 34 | 2026-03-10 |
| [payment-service](./payment-service/) | 1.5.0 | 3 | 15 | 2026-02-28 |

**總計**：3 個服務 / 10 個模組 / 88 個 endpoints

## 各服務詳情

### user-service v2.1.0

| 模組 | Endpoints | 說明 |
|------|-----------|------|
| [auth](./user-service/modules/auth.md) | 4 | 登入/註冊/token 刷新 |
| [users](./user-service/modules/users.md) | 12 | 使用者 CRUD + 搜尋 + 權限管理 |
| [orders](./user-service/modules/orders.md) | 23 | 訂單生命週期 |

### order-service v3.2.1

| 模組 | Endpoints | 說明 |
|------|-----------|------|
| [orders](./order-service/modules/orders.md) | 15 | 訂單 CRUD |
| [order-items](./order-service/modules/order-items.md) | 8 | 訂單明細 |
| [shipping](./order-service/modules/shipping.md) | 6 | 物流追蹤 |
| [refunds](./order-service/modules/refunds.md) | 5 | 退款流程 |

### payment-service v1.5.0

| 模組 | Endpoints | 說明 |
|------|-----------|------|
| [payments](./payment-service/modules/payments.md) | 7 | 付款處理 |
| [methods](./payment-service/modules/methods.md) | 5 | 付款方式管理 |
| [webhooks](./payment-service/modules/webhooks.md) | 3 | Webhook 回調 |
```

### 權限管理建議

| 角色 | 權限 | 說明 |
|------|------|------|
| 後端 CI/CD | Write（指定服務目錄） | 只能推送自己服務的描述檔 |
| 前端開發者 | Read | 只需要讀取描述檔 |
| 平台團隊 | Admin | 管理 repo 設定、branch protection |
| Bot/CI | Write（README.md） | 自動更新 README |

---

## 6. 初始化與設定指南

### 6.0 引導式初始化（推薦）

手動設定步驟繁瑣，因此 API Bridge 提供引導式 init 指令，互動式地完成所有設定。

#### 後端初始化：`/api-extract --init`

在後端專案根目錄執行，Skill 會引導你完成以下設定：

```mermaid
flowchart TD
    S["執行 /api-extract --init"] --> D1{"偵測專案類型"}
    D1 --> D2["辨識框架<br/>（NestJS / FastAPI / Spring / ...）"]
    D2 --> Q1["詢問：API Catalog repo URL？"]
    Q1 --> Q2["詢問：Service 名稱？<br/>（預設：package.json name）"]
    Q2 --> Q3["詢問：使用 GitLab 還是 GitHub？"]
    Q3 --> Q4["詢問：CI Token 環境變數名稱？<br/>（預設：API_CATALOG_TOKEN）"]
    Q4 --> G1["產出 api-docs/ 目錄結構"]
    G1 --> G2["產出 .gitlab-ci.yml 或<br/>GitHub Actions workflow"]
    G2 --> G3["更新 .gitignore（如需要）"]
    G3 --> G4["執行首次 /api-extract<br/>掃描並產出描述檔"]
    G4 --> V["顯示設定摘要 + 下一步指示"]

    style S fill:#4a9ebb,color:#fff
    style V fill:#6bbf6b,color:#fff
```

**完整互動流程範例：**

```
$ claude "/api-extract --init"

🔍 偵測到專案類型：NestJS (TypeScript)
   框架版本：@nestjs/core@10.x
   找到 8 個 Controller 檔案

📝 請回答以下問題完成初始化：

1. API Catalog repo URL
   > git@gitlab.internal.com:team/api-catalog.git

2. Service 名稱（用於 catalog 目錄命名）
   預設值：user-service（來自 package.json）
   > user-service ✓

3. 使用哪個 Git 平台？
   [1] GitLab（預設）
   [2] GitHub
   > 1

4. CI Token 環境變數名稱
   預設值：API_CATALOG_TOKEN
   > ✓（使用預設）

5. API 描述檔存放目錄
   預設值：api-docs/
   > ✓（使用預設）

⚙️ 正在設定...

  ✓ 建立 api-docs/ 目錄結構
  ✓ 產出 .gitlab-ci.yml（api-publish stage）
  ✓ 掃描 8 個 Controller，產出 5 個模組描述檔
  ✓ 驗證通過：32 個 endpoints

📋 設定摘要：
┌──────────────────────────────────────────────┐
│ Service:    user-service                      │
│ Platform:   GitLab                            │
│ Catalog:    git@gitlab.internal.com:team/...  │
│ Modules:    auth (4), users (12), orders (8), │
│             products (5), admin (3)           │
│ Endpoints:  32 total                          │
│ CI:         .gitlab-ci.yml (auto-publish)     │
└──────────────────────────────────────────────┘

📌 下一步：
  1. 在 GitLab 設定 CI 變數 API_CATALOG_TOKEN
     → Settings > CI/CD > Variables
  2. 確認描述檔內容：api-docs/
  3. git add . && git commit && git push
```

**init 產出的檔案：**

```
專案根目錄/
├── api-docs/                          # ← 新建
│   ├── api-index.yaml                 # 服務索引
│   └── modules/
│       ├── auth.md                    # 模組描述檔
│       ├── users.md
│       └── ...
├── .gitlab-ci.yml                     # ← 新增 api-publish stage
│                                      #    （或 .github/workflows/api-publish.yml）
└── .api-bridge.yaml                   # ← 新建：本地設定檔（記住 init 選擇）
```

**`.api-bridge.yaml`**（記住設定，避免重複詢問）：

```yaml
# .api-bridge.yaml — /api-extract 設定檔
# 由 /api-extract --init 自動產出

service: user-service
catalog:
  repo: git@gitlab.internal.com:team/api-catalog.git
  platform: gitlab
  token_env: API_CATALOG_TOKEN
output: api-docs/
```

之後執行 `/api-extract`（不帶 `--init`）時，會直接讀取這個設定檔，不再詢問。

---

#### 前端初始化：`/api-integrate --init`

在前端專案根目錄執行，Skill 會引導你完成訂閱設定：

```mermaid
flowchart TD
    S["執行 /api-integrate --init"] --> D1{"偵測前端框架"}
    D1 --> D2["辨識框架<br/>（React / Vue / Angular / Swift / Kotlin）"]
    D2 --> Q1["詢問：API Catalog repo URL？"]
    Q1 --> F1["連線 catalog repo<br/>讀取可用的 services"]
    F1 --> Q2["顯示可用 services 清單<br/>詢問：要訂閱哪些？"]
    Q2 --> Q3["對每個 service<br/>顯示可用 modules<br/>詢問：要訂閱哪些？"]
    Q3 --> Q4["詢問：版本策略？<br/>（latest / 鎖 minor / 鎖 patch）"]
    Q4 --> Q5["詢問：程式碼輸出目錄？<br/>（預設：src/api/{service}/）"]
    Q5 --> G1["產出 .claude/api-sources.yaml"]
    G1 --> G2["執行首次 /api-integrate<br/>生成串接程式碼"]
    G2 --> V1["執行 type check / build 驗證"]
    V1 --> V2["顯示設定摘要"]

    style S fill:#4a9ebb,color:#fff
    style V2 fill:#6bbf6b,color:#fff
```

**完整互動流程範例：**

```
$ claude "/api-integrate --init"

🔍 偵測到專案類型：React + TypeScript (Vite)
   React 版本：18.x
   已安裝：@tanstack/react-query

📝 請回答以下問題完成初始化：

1. API Catalog repo URL
   > git@gitlab.internal.com:team/api-catalog.git

🔗 連線 catalog repo...

2. 找到以下 services，要訂閱哪些？（空格分隔，或 * 全部）
   [1] user-service    v2.1.0  (5 modules, 32 endpoints)
   [2] order-service   v3.2.1  (4 modules, 34 endpoints)
   [3] payment-service v1.5.0  (3 modules, 15 endpoints)
   > 1 2

3. user-service 有以下 modules，要訂閱哪些？（空格分隔，或 * 全部）
   [1] auth      (4 endpoints)   — 登入/註冊/token 刷新
   [2] users     (12 endpoints)  — 使用者 CRUD + 搜尋
   [3] orders    (8 endpoints)   — 使用者訂單
   [4] products  (5 endpoints)   — 商品資訊
   [5] admin     (3 endpoints)   — 後台管理
   > 1 2 3

4. order-service 有以下 modules，要訂閱哪些？
   [1] orders      (15 endpoints) — 訂單 CRUD
   [2] order-items (8 endpoints)  — 訂單明細
   [3] shipping    (6 endpoints)  — 物流追蹤
   [4] refunds     (5 endpoints)  — 退款流程
   > 1

5. 版本策略
   [1] ~（鎖 patch，推薦）  — 自動接受 bug fix
   [2] ^（鎖 minor）        — 自動接受新功能
   [3] 精確鎖定             — 完全不自動更新
   > 1

6. 程式碼輸出目錄
   預設值：src/api/{service}/
   > ✓（使用預設）

7. Git 平台 Token 環境變數名稱
   預設值：GITLAB_API_TOKEN
   > ✓（使用預設）

⚙️ 正在設定...

  ✓ 產出 .claude/api-sources.yaml
  ✓ 從 catalog 拉取 user-service v2.1.0（3 modules）
  ✓ 從 catalog 拉取 order-service v3.2.1（1 module）
  ✓ 偵測到 React + React Query → 生成 hooks 模式
  ✓ 生成 src/api/user-service/（types.ts, client.ts, hooks.ts）
  ✓ 生成 src/api/order-service/（types.ts, client.ts, hooks.ts）
  ✓ tsc --noEmit 通過
  ✓ vite build 通過

📋 設定摘要：
┌──────────────────────────────────────────────┐
│ Framework:  React + TypeScript (Vite)         │
│ Catalog:    git@gitlab.internal.com:team/...  │
│ Subscriptions:                                │
│   user-service  ~2.1  [auth, users, orders]  │
│   order-service ~3.2  [orders]               │
│ Output:     src/api/{service}/                │
│ Generated:  6 files (2 services × 3 files)   │
│ Build:      ✓ PASS                           │
└──────────────────────────────────────────────┘

📌 下一步：
  1. 設定環境變數 GITLAB_API_TOKEN
  2. 在程式碼中使用生成的 hooks：
     import { useLogin, useUsers } from '@/api/user-service/hooks'
  3. 日後更新：/api-integrate --update
```

---

#### API Catalog 初始化：`/api-extract --init-catalog`

首次建立 api-catalog repo 時使用，只需執行一次：

```
$ claude "/api-extract --init-catalog"

📝 建立 API Catalog：

1. Git 平台
   [1] GitLab
   [2] GitHub
   > 1

2. Repo 路徑（會自動建立）
   > team/api-catalog

3. 設為 Private repo？
   > Yes ✓

⚙️ 正在建立...

  ✓ 建立 GitLab repo: team/api-catalog (private)
  ✓ 初始化目錄結構
  ✓ 建立 README.md（自動產生模板）
  ✓ 設定 branch protection（main: 不允許直接 push）
  ✓ 推送初始 commit

📋 Catalog repo 已就緒：
   https://gitlab.internal.com/team/api-catalog

📌 下一步：
  1. 在各後端專案執行 /api-extract --init
  2. 在各前端專案執行 /api-integrate --init
```

---

#### Init 指令速查表

| 指令 | 在哪裡執行 | 執行幾次 | 產出 |
|------|-----------|---------|------|
| `/api-extract --init-catalog` | 任意位置 | 全公司一次 | api-catalog repo |
| `/api-extract --init` | 後端專案根目錄 | 每個後端一次 | `.api-bridge.yaml` + `api-docs/` + CI config |
| `/api-integrate --init` | 前端專案根目錄 | 每個前端一次 | `.claude/api-sources.yaml` + `src/api/` |

初始化完成後，日常只需要：

| 日常操作 | 指令 | 說明 |
|----------|------|------|
| 後端更新 API | `/api-extract` | 重新掃描、更新描述檔、自動推送 |
| 前端同步 API | `/api-integrate --update` | 拉取最新、顯示 diff、更新程式碼 |

---

### 6.1 GitLab 手動設定（參考）

> 以下為手動設定步驟，若已使用 `--init` 完成設定可跳過。

#### 步驟一：建立 api-catalog repo

#### 步驟一：設定 GitLab API Token

1. 前往 **Settings → Access Tokens**
2. 建立 Project Access Token
   - 名稱：`api-catalog-push`
   - 角色：`Maintainer`
   - Scopes：`write_repository`
3. 在後端專案的 **CI/CD → Variables** 新增：
   - `API_CATALOG_TOKEN`：上一步取得的 token
   - `API_CATALOG_URL`：`https://oauth2:${API_CATALOG_TOKEN}@gitlab.com/your-group/api-catalog.git`

#### 步驟二：後端 .gitlab-ci.yml

```yaml
# .gitlab-ci.yml — 後端專案自動推送 API 描述檔到 catalog

stages:
  - extract
  - publish

variables:
  SERVICE_NAME: user-service
  CATALOG_REPO: https://oauth2:${API_CATALOG_TOKEN}@gitlab.com/your-group/api-catalog.git

# Stage 1: 使用 /api-extract 產出描述檔
api-extract:
  stage: extract
  image: node:20-slim
  script:
    - echo "API 描述檔已由開發者在本地執行 /api-extract 產出"
    - echo "此 stage 負責驗證描述檔格式正確性"
    # 驗證 api-index.yaml 存在且格式正確
    - |
      if [ ! -f "api-docs/api-index.yaml" ]; then
        echo "ERROR: api-docs/api-index.yaml not found"
        echo "請先在本地執行 /api-extract 產出描述檔"
        exit 1
      fi
    # 驗證所有模組檔案都存在
    - |
      for module in $(grep "name:" api-docs/api-index.yaml | awk '{print $3}'); do
        if [ ! -f "api-docs/modules/${module}.md" ]; then
          echo "ERROR: api-docs/modules/${module}.md not found"
          exit 1
        fi
      done
    - echo "描述檔驗證通過"
  artifacts:
    paths:
      - api-docs/
  only:
    changes:
      - api-docs/**/*
    refs:
      - main

# Stage 2: 推送到 api-catalog repo
publish-to-catalog:
  stage: publish
  image: alpine/git:latest
  dependencies:
    - api-extract
  script:
    # 設定 git 身份
    - git config --global user.email "ci@your-company.com"
    - git config --global user.name "API Catalog CI"

    # Clone catalog repo
    - git clone --depth 1 ${CATALOG_REPO} /tmp/catalog
    - cd /tmp/catalog

    # 建立服務目錄（若不存在）
    - mkdir -p ${SERVICE_NAME}/modules

    # 複製描述檔
    - cp ${CI_PROJECT_DIR}/api-docs/api-index.yaml ${SERVICE_NAME}/
    - cp ${CI_PROJECT_DIR}/api-docs/modules/*.md ${SERVICE_NAME}/modules/

    # 取得版號
    - VERSION=$(grep "version:" ${SERVICE_NAME}/api-index.yaml | awk '{print $2}')

    # 提交並推送
    - git add ${SERVICE_NAME}/
    - |
      git diff --cached --quiet || {
        git commit -m "feat(${SERVICE_NAME}): update API docs to v${VERSION}"
        git push origin main
        echo "成功推送 ${SERVICE_NAME} v${VERSION} 到 api-catalog"
      }
  only:
    changes:
      - api-docs/**/*
    refs:
      - main
```

#### 步驟三：前端 .claude/api-sources.yaml

```yaml
# .claude/api-sources.yaml — 前端專案的 API 訂閱設定

sources:
  - service: user-service
    repo: git@gitlab.com:your-group/api-catalog.git
    path: user-service
    version: "~2.1"
    modules: [auth, users]
    output: src/api/user-service      # 生成程式碼的輸出目錄

  - service: order-service
    repo: git@gitlab.com:your-group/api-catalog.git
    path: order-service
    version: "^3.0"
    modules: [orders]
    output: src/api/order-service

settings:
  platform: gitlab
  token_env: GITLAB_API_TOKEN         # 環境變數名稱
  auto_build_check: true              # 生成後自動執行 build 驗證
```

### 6.2 GitHub 手動設定（參考）

> 以下為手動設定步驟，若已使用 `--init` 完成設定可跳過。

#### 步驟一：設定 GitHub Token（Fine-grained PAT）

1. 前往 **Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. 建立新 token：
   - 名稱：`api-catalog-push`
   - Repository access：`Only select repositories` → `your-org/api-catalog`
   - Permissions：
     - Contents：`Read and write`
     - Metadata：`Read-only`
3. 在後端專案的 **Settings → Secrets and variables → Actions** 新增：
   - `API_CATALOG_TOKEN`：上一步取得的 token

#### 步驟二：後端 GitHub Actions Workflow

```yaml
# .github/workflows/api-publish.yml

name: Publish API Docs to Catalog

on:
  push:
    branches: [main]
    paths:
      - 'api-docs/**'

env:
  SERVICE_NAME: user-service
  CATALOG_REPO: your-org/api-catalog

jobs:
  validate:
    name: 驗證 API 描述檔
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 驗證 api-index.yaml 存在
        run: |
          if [ ! -f "api-docs/api-index.yaml" ]; then
            echo "::error::api-docs/api-index.yaml not found"
            exit 1
          fi

      - name: 驗證所有模組檔案
        run: |
          for module in $(grep "name:" api-docs/api-index.yaml | awk '{print $3}'); do
            if [ ! -f "api-docs/modules/${module}.md" ]; then
              echo "::error::api-docs/modules/${module}.md not found"
              exit 1
            fi
            echo "模組 ${module}.md 驗證通過"
          done

      - name: 上傳描述檔 artifact
        uses: actions/upload-artifact@v4
        with:
          name: api-docs
          path: api-docs/

  publish:
    name: 推送到 API Catalog
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - name: 下載描述檔 artifact
        uses: actions/download-artifact@v4
        with:
          name: api-docs
          path: api-docs/

      - name: Clone api-catalog repo
        run: |
          git clone https://x-access-token:${{ secrets.API_CATALOG_TOKEN }}@github.com/${{ env.CATALOG_REPO }}.git /tmp/catalog

      - name: 更新描述檔
        run: |
          cd /tmp/catalog
          mkdir -p ${{ env.SERVICE_NAME }}/modules

          cp $GITHUB_WORKSPACE/api-docs/api-index.yaml ${{ env.SERVICE_NAME }}/
          cp $GITHUB_WORKSPACE/api-docs/modules/*.md ${{ env.SERVICE_NAME }}/modules/

          VERSION=$(grep "version:" ${{ env.SERVICE_NAME }}/api-index.yaml | awk '{print $2}')

          git config user.email "github-actions[bot]@users.noreply.github.com"
          git config user.name "github-actions[bot]"
          git add ${{ env.SERVICE_NAME }}/

          if git diff --cached --quiet; then
            echo "沒有變更，跳過推送"
          else
            git commit -m "feat(${{ env.SERVICE_NAME }}): update API docs to v${VERSION}"
            git push origin main
            echo "成功推送 ${{ env.SERVICE_NAME }} v${VERSION}"
          fi

      - name: 建立 Git Tag
        run: |
          cd /tmp/catalog
          VERSION=$(grep "version:" ${{ env.SERVICE_NAME }}/api-index.yaml | awk '{print $2}')
          TAG="${{ env.SERVICE_NAME }}/v${VERSION}"

          if git tag -l "${TAG}" | grep -q "${TAG}"; then
            echo "Tag ${TAG} 已存在，跳過"
          else
            git tag "${TAG}"
            git push origin "${TAG}"
            echo "建立 tag: ${TAG}"
          fi
```

#### 步驟三：前端 .claude/api-sources.yaml

```yaml
# .claude/api-sources.yaml — 前端專案的 API 訂閱設定

sources:
  - service: user-service
    repo: git@github.com:your-org/api-catalog.git
    path: user-service
    version: "~2.1"
    modules: [auth, users]
    output: src/api/user-service

  - service: order-service
    repo: git@github.com:your-org/api-catalog.git
    path: order-service
    version: "^3.0"
    modules: [orders]
    output: src/api/order-service

  - service: payment-service
    repo: git@github.com:your-org/api-catalog.git
    path: payment-service
    version: "~1.5"
    modules: [payments]
    output: src/api/payment-service

settings:
  platform: github
  token_env: GITHUB_TOKEN
  auto_build_check: true
```

---

## 7. 使用情境

### 7.1 單一後端 + 單一前端

最簡場景：一個 NestJS 後端 + 一個 React 前端。

**步驟一：後端執行 extract**

```bash
# 在後端專案根目錄
claude "/api-extract"
```

Skill A 掃描到 NestJS 專案，自動產出：

```
api-docs/
├── api-index.yaml
└── modules/
    ├── auth.md
    └── users.md
```

**步驟二：推送到 catalog**

```bash
# 手動推送（或由 CI 自動推送）
cd /path/to/api-catalog
mkdir -p user-service/modules
cp /path/to/backend/api-docs/api-index.yaml user-service/
cp /path/to/backend/api-docs/modules/*.md user-service/modules/
git add . && git commit -m "feat(user-service): initial API docs v1.0.0" && git push
```

**步驟三：前端設定訂閱**

```yaml
# 前端專案 .claude/api-sources.yaml
sources:
  - service: user-service
    repo: git@github.com:myorg/api-catalog.git
    path: user-service
    version: "^1.0"
    modules: [auth, users]
    output: src/api/user-service
```

**步驟四：前端執行 integrate**

```bash
# 在前端專案根目錄
claude "/api-integrate"
```

Skill B 偵測到 React 專案，生成：

```
src/api/user-service/
├── types.ts
├── client.ts
└── hooks.ts
```

### 7.2 微服務 + 多個前端

三個後端服務 + 四個前端應用的複雜場景。

**訂閱矩陣**

| 前端 \ 服務 | user-service | order-service | payment-service |
|-------------|:---:|:---:|:---:|
| **web-app**（React） | auth, users | orders | payments |
| **mobile-app**（React Native） | auth | orders | payments |
| **admin-panel**（Vue） | auth, users | orders, refunds | payments, methods |
| **ios-app**（Swift） | auth | orders | payments |

**web-app 的 api-sources.yaml**

```yaml
sources:
  - service: user-service
    repo: git@github.com:myorg/api-catalog.git
    path: user-service
    version: "~2.1"
    modules: [auth, users]
    output: src/api/user-service

  - service: order-service
    repo: git@github.com:myorg/api-catalog.git
    path: order-service
    version: "^3.0"
    modules: [orders]
    output: src/api/order-service

  - service: payment-service
    repo: git@github.com:myorg/api-catalog.git
    path: payment-service
    version: "~1.5"
    modules: [payments]
    output: src/api/payment-service
```

**admin-panel 的 api-sources.yaml**

```yaml
sources:
  - service: user-service
    repo: git@github.com:myorg/api-catalog.git
    path: user-service
    version: "~2.1"
    modules: [auth, users]
    output: src/api/user-service

  - service: order-service
    repo: git@github.com:myorg/api-catalog.git
    path: order-service
    version: "^3.0"
    modules: [orders, refunds]
    output: src/api/order-service

  - service: payment-service
    repo: git@github.com:myorg/api-catalog.git
    path: payment-service
    version: "~1.5"
    modules: [payments, methods]
    output: src/api/payment-service
```

**ios-app 的 api-sources.yaml**

```yaml
sources:
  - service: user-service
    repo: git@github.com:myorg/api-catalog.git
    path: user-service
    version: "~2.1"
    modules: [auth]
    output: Sources/API/UserService

  - service: order-service
    repo: git@github.com:myorg/api-catalog.git
    path: order-service
    version: "^3.0"
    modules: [orders]
    output: Sources/API/OrderService

  - service: payment-service
    repo: git@github.com:myorg/api-catalog.git
    path: payment-service
    version: "~1.5"
    modules: [payments]
    output: Sources/API/PaymentService
```

### 7.3 大型後端（100+ endpoints）

假設一個電商後端有 127 個 endpoints。

**模組拆分實際範例**

| 模組 | Endpoints | 描述檔大小 | Token 估算 |
|------|-----------|-----------|-----------|
| auth | 4 | 0.8 KB | ~250 tokens |
| users | 12 | 2.5 KB | ~750 tokens |
| products | 18 | 3.8 KB | ~1,100 tokens |
| orders | 23 | 5.0 KB | ~1,500 tokens |
| order-items | 8 | 1.6 KB | ~500 tokens |
| cart | 6 | 1.2 KB | ~350 tokens |
| shipping | 10 | 2.1 KB | ~630 tokens |
| payments | 12 | 2.5 KB | ~750 tokens |
| refunds | 5 | 1.0 KB | ~300 tokens |
| reviews | 9 | 1.8 KB | ~540 tokens |
| notifications | 7 | 1.4 KB | ~420 tokens |
| analytics | 13 | 2.7 KB | ~810 tokens |
| **合計** | **127** | **26.4 KB** | **~7,900 tokens** |

**Context Window 計算**

```
前端程式碼 context:        ~20,000 tokens
Skill B 系統提示:           ~2,000 tokens
api-index.yaml:             ~300 tokens
訂閱的模組描述檔:
  - auth.md:                ~250 tokens
  - users.md:               ~750 tokens
  - orders.md:              ~1,500 tokens
生成的程式碼:               ~3,000 tokens
────────────────────────────────────
總計:                       ~27,800 tokens
```

如果前端訂閱全部 12 個模組（~7,900 tokens），加上前端 context（~20,000）和系統提示（~2,000），約 30,000 tokens，仍在 Claude 的 context window 舒適範圍內。但只訂閱需要的模組可以大幅提升生成品質。

**前端按需訂閱範例**

行動端 App 只需要 auth + orders + payments：

```yaml
sources:
  - service: ecommerce
    repo: git@github.com:myorg/api-catalog.git
    path: ecommerce-service
    version: "^4.0"
    modules: [auth, orders, payments]   # 只訂閱 3 個模組，~2,500 tokens
    output: src/api/ecommerce
```

### 7.4 API 版本更新

#### 新增 endpoint（Minor Bump）

後端新增了 `GET /users/:id/preferences` endpoint。

```
版號變化：2.1.0 → 2.2.0（minor bump）
```

**描述檔變更**：

`users.md` 新增一個 endpoint section：

```markdown
## GET /users/:id/preferences

取得使用者偏好設定。

- Auth: required (self or admin)
- Params: `{ id: string }`
- Returns: `{ preferences: { theme: 'light' | 'dark', language: string, notifications: boolean } }`
- Errors: [401 Unauthorized, 404 UserNotFound]
```

`api-index.yaml` 更新：

```yaml
version: 2.2.0   # 從 2.1.0 更新
modules:
  - name: users
    endpoints: 13  # 從 12 更新為 13
```

#### 修改 endpoint Breaking Change（Major Bump）

後端將 `GET /users` 的 response 從 `{ users: User[] }` 改為 `PaginatedResponse<User>`。

```
版號變化：2.2.0 → 3.0.0（major bump）
```

#### 前端收到更新通知的流程

```bash
# 前端開發者執行更新檢查
claude "/api-integrate --update"
```

Skill B 顯示的 diff 資訊：

```
╔═══════════════════════════════════════════════════════╗
║  API 更新偵測結果                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  user-service: 2.1.0 → 3.0.0 ⚠️ MAJOR UPDATE        ║
║                                                       ║
║  破壞性變更:                                          ║
║  - GET /users: response 結構變更                      ║
║    舊: { users: User[] }                              ║
║    新: PaginatedResponse<User>                        ║
║                                                       ║
║  新增:                                                ║
║  + GET /users/:id/preferences                         ║
║                                                       ║
║  order-service: 3.2.1 → 3.2.1（無變更）              ║
║  payment-service: 1.5.0 → 1.5.0（無變更）            ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

是否要更新 user-service 到 v3.0.0？(y/n)
```

確認更新後，Skill B 會重新生成 `types.ts`、`client.ts`、`hooks.ts`，並標記受影響的程式碼。

---

## 8. 前端產出範例

以下所有範例均基於 user-service 的 auth 和 users 模組。

### 8.1 React + TypeScript

#### 目錄結構

```
src/api/user-service/
├── types.ts          # API 型別定義
├── client.ts         # HTTP client（fetch + auth interceptor）
└── hooks.ts          # React Query hooks
```

#### types.ts

```typescript
// src/api/user-service/types.ts
// 由 /api-integrate 自動產出，請勿手動修改

// ─── 共用型別 ───────────────────────────────────────

export type User = {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: 'admin' | 'user' | 'moderator';
  createdAt: string;
  updatedAt: string;
};

export type UserProfile = {
  bio?: string;
  phone?: string;
  address?: string;
};

export type PaginatedResponse<T> = {
  data: T[];
  meta: {
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
  };
};

export type ApiError = {
  code: string;
  message: string;
  details?: Record<string, string[]>;
};

// ─── Auth 模組 ──────────────────────────────────────

export type LoginRequest = {
  email: string;
  password: string;
};

export type LoginResponse = {
  token: string;
  refreshToken: string;
  user: User;
};

export type RegisterRequest = {
  name: string;
  email: string;
  password: string;
};

export type RegisterResponse = {
  token: string;
  user: User;
};

export type RefreshRequest = {
  refreshToken: string;
};

export type RefreshResponse = {
  token: string;
  refreshToken: string;
};

export type LogoutResponse = {
  success: boolean;
};

// ─── Users 模組 ─────────────────────────────────────

export type GetUsersParams = {
  page?: number;
  pageSize?: number;
  search?: string;
  role?: string;
  sort?: string;
};

export type CreateUserRequest = {
  name: string;
  email: string;
  password: string;
  role: 'admin' | 'user' | 'moderator';
};

export type UpdateUserRequest = {
  name?: string;
  email?: string;
  avatar?: string;
};

export type UpdateRoleRequest = {
  role: 'admin' | 'user' | 'moderator';
};

export type ChangePasswordRequest = {
  currentPassword: string;
  newPassword: string;
};

export type SearchUsersParams = {
  q: string;
  limit?: number;
};

export type UserDetailResponse = {
  user: User & { profile: UserProfile };
};

export type UploadAvatarResponse = {
  url: string;
};
```

#### client.ts

```typescript
// src/api/user-service/client.ts
// 由 /api-integrate 自動產出，請勿手動修改

import type {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  RefreshRequest,
  RefreshResponse,
  LogoutResponse,
  GetUsersParams,
  CreateUserRequest,
  UpdateUserRequest,
  UpdateRoleRequest,
  ChangePasswordRequest,
  SearchUsersParams,
  UserDetailResponse,
  UploadAvatarResponse,
  User,
  PaginatedResponse,
  ApiError,
} from './types';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000/api/v1';

class ApiClient {
  private token: string | null = null;

  setToken(token: string | null): void {
    this.token = token;
  }

  private async request<T>(
    method: string,
    path: string,
    options: { body?: unknown; params?: Record<string, string | number | undefined> } = {},
  ): Promise<T> {
    const url = new URL(`${BASE_URL}${path}`);

    if (options.params) {
      Object.entries(options.params).forEach(([key, value]) => {
        if (value !== undefined) {
          url.searchParams.set(key, String(value));
        }
      });
    }

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(url.toString(), {
      method,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined,
    });

    if (!response.ok) {
      const error: ApiError = await response.json();
      throw new ApiClientError(response.status, error.code, error.message, error.details);
    }

    return response.json();
  }

  // ─── Auth ──────────────────────────────────────────

  async login(data: LoginRequest): Promise<LoginResponse> {
    return this.request<LoginResponse>('POST', '/auth/login', { body: data });
  }

  async register(data: RegisterRequest): Promise<RegisterResponse> {
    return this.request<RegisterResponse>('POST', '/auth/register', { body: data });
  }

  async refresh(data: RefreshRequest): Promise<RefreshResponse> {
    return this.request<RefreshResponse>('POST', '/auth/refresh', { body: data });
  }

  async logout(): Promise<LogoutResponse> {
    return this.request<LogoutResponse>('POST', '/auth/logout', { body: {} });
  }

  // ─── Users ─────────────────────────────────────────

  async getUsers(params?: GetUsersParams): Promise<PaginatedResponse<User>> {
    return this.request<PaginatedResponse<User>>('GET', '/users', { params: params as Record<string, string | number | undefined> });
  }

  async getUser(id: string): Promise<UserDetailResponse> {
    return this.request<UserDetailResponse>('GET', `/users/${id}`);
  }

  async createUser(data: CreateUserRequest): Promise<{ user: User }> {
    return this.request<{ user: User }>('POST', '/users', { body: data });
  }

  async updateUser(id: string, data: UpdateUserRequest): Promise<{ user: User }> {
    return this.request<{ user: User }>('PUT', `/users/${id}`, { body: data });
  }

  async deleteUser(id: string): Promise<{ success: boolean }> {
    return this.request<{ success: boolean }>('DELETE', `/users/${id}`);
  }

  async updateUserRole(id: string, data: UpdateRoleRequest): Promise<{ user: User }> {
    return this.request<{ user: User }>('PATCH', `/users/${id}/role`, { body: data });
  }

  async getUserOrders(id: string, params?: { page?: number; pageSize?: number; status?: string }): Promise<PaginatedResponse<unknown>> {
    return this.request<PaginatedResponse<unknown>>('GET', `/users/${id}/orders`, { params: params as Record<string, string | number | undefined> });
  }

  async uploadAvatar(id: string, file: File): Promise<UploadAvatarResponse> {
    const url = `${BASE_URL}/users/${id}/avatar`;
    const formData = new FormData();
    formData.append('file', file);

    const headers: Record<string, string> = {};
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: formData,
    });

    if (!response.ok) {
      const error: ApiError = await response.json();
      throw new ApiClientError(response.status, error.code, error.message, error.details);
    }

    return response.json();
  }

  async deleteAvatar(id: string): Promise<{ success: boolean }> {
    return this.request<{ success: boolean }>('DELETE', `/users/${id}/avatar`);
  }

  async getMe(): Promise<UserDetailResponse> {
    return this.request<UserDetailResponse>('GET', '/users/me');
  }

  async changePassword(data: ChangePasswordRequest): Promise<{ success: boolean }> {
    return this.request<{ success: boolean }>('PUT', '/users/me/password', { body: data });
  }

  async searchUsers(params: SearchUsersParams): Promise<{ users: User[] }> {
    return this.request<{ users: User[] }>('GET', '/users/search', { params: params as Record<string, string | number | undefined> });
  }
}

export class ApiClientError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
    public details?: Record<string, string[]>,
  ) {
    super(message);
    this.name = 'ApiClientError';
  }
}

export const apiClient = new ApiClient();
```

#### hooks.ts

```typescript
// src/api/user-service/hooks.ts
// 由 /api-integrate 自動產出，請勿手動修改

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './client';
import type {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  RefreshRequest,
  RefreshResponse,
  GetUsersParams,
  CreateUserRequest,
  UpdateUserRequest,
  UpdateRoleRequest,
  ChangePasswordRequest,
  SearchUsersParams,
  UserDetailResponse,
  User,
  PaginatedResponse,
} from './types';

// ─── Query Keys ────────────────────────────────────────

export const userServiceKeys = {
  all: ['user-service'] as const,
  users: () => [...userServiceKeys.all, 'users'] as const,
  userList: (params?: GetUsersParams) => [...userServiceKeys.users(), 'list', params] as const,
  userDetail: (id: string) => [...userServiceKeys.users(), 'detail', id] as const,
  userOrders: (id: string) => [...userServiceKeys.users(), 'orders', id] as const,
  me: () => [...userServiceKeys.all, 'me'] as const,
  search: (params: SearchUsersParams) => [...userServiceKeys.users(), 'search', params] as const,
};

// ─── Auth Hooks ────────────────────────────────────────

export function useLogin() {
  const queryClient = useQueryClient();
  return useMutation<LoginResponse, Error, LoginRequest>({
    mutationFn: (data) => apiClient.login(data),
    onSuccess: (data) => {
      apiClient.setToken(data.token);
      queryClient.invalidateQueries({ queryKey: userServiceKeys.me() });
    },
  });
}

export function useRegister() {
  return useMutation<RegisterResponse, Error, RegisterRequest>({
    mutationFn: (data) => apiClient.register(data),
    onSuccess: (data) => {
      apiClient.setToken(data.token);
    },
  });
}

export function useRefresh() {
  return useMutation<RefreshResponse, Error, RefreshRequest>({
    mutationFn: (data) => apiClient.refresh(data),
    onSuccess: (data) => {
      apiClient.setToken(data.token);
    },
  });
}

export function useLogout() {
  const queryClient = useQueryClient();
  return useMutation<{ success: boolean }, Error, void>({
    mutationFn: () => apiClient.logout(),
    onSuccess: () => {
      apiClient.setToken(null);
      queryClient.clear();
    },
  });
}

// ─── Users Hooks ───────────────────────────────────────

export function useUsers(params?: GetUsersParams) {
  return useQuery<PaginatedResponse<User>>({
    queryKey: userServiceKeys.userList(params),
    queryFn: () => apiClient.getUsers(params),
  });
}

export function useUser(id: string) {
  return useQuery<UserDetailResponse>({
    queryKey: userServiceKeys.userDetail(id),
    queryFn: () => apiClient.getUser(id),
    enabled: !!id,
  });
}

export function useMe() {
  return useQuery<UserDetailResponse>({
    queryKey: userServiceKeys.me(),
    queryFn: () => apiClient.getMe(),
  });
}

export function useCreateUser() {
  const queryClient = useQueryClient();
  return useMutation<{ user: User }, Error, CreateUserRequest>({
    mutationFn: (data) => apiClient.createUser(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: userServiceKeys.users() });
    },
  });
}

export function useUpdateUser() {
  const queryClient = useQueryClient();
  return useMutation<{ user: User }, Error, { id: string; data: UpdateUserRequest }>({
    mutationFn: ({ id, data }) => apiClient.updateUser(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: userServiceKeys.userDetail(id) });
      queryClient.invalidateQueries({ queryKey: userServiceKeys.users() });
    },
  });
}

export function useDeleteUser() {
  const queryClient = useQueryClient();
  return useMutation<{ success: boolean }, Error, string>({
    mutationFn: (id) => apiClient.deleteUser(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: userServiceKeys.users() });
    },
  });
}

export function useUpdateUserRole() {
  const queryClient = useQueryClient();
  return useMutation<{ user: User }, Error, { id: string; data: UpdateRoleRequest }>({
    mutationFn: ({ id, data }) => apiClient.updateUserRole(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: userServiceKeys.userDetail(id) });
      queryClient.invalidateQueries({ queryKey: userServiceKeys.users() });
    },
  });
}

export function useSearchUsers(params: SearchUsersParams) {
  return useQuery<{ users: User[] }>({
    queryKey: userServiceKeys.search(params),
    queryFn: () => apiClient.searchUsers(params),
    enabled: params.q.length >= 2,
  });
}

export function useChangePassword() {
  return useMutation<{ success: boolean }, Error, ChangePasswordRequest>({
    mutationFn: (data) => apiClient.changePassword(data),
  });
}

export function useUploadAvatar() {
  const queryClient = useQueryClient();
  return useMutation<{ url: string }, Error, { id: string; file: File }>({
    mutationFn: ({ id, file }) => apiClient.uploadAvatar(id, file),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: userServiceKeys.userDetail(id) });
      queryClient.invalidateQueries({ queryKey: userServiceKeys.me() });
    },
  });
}
```

### 8.2 Vue + TypeScript

#### 目錄結構

```
src/api/user-service/
├── types.ts          # API 型別定義（同 React 版本）
├── client.ts         # HTTP client（同 React 版本）
└── composables.ts    # Vue Composables
```

#### types.ts

與 React 版本相同（此處省略重複），型別定義與框架無關。

#### client.ts

與 React 版本相同（此處省略重複），HTTP client 與框架無關。

#### composables.ts

```typescript
// src/api/user-service/composables.ts
// 由 /api-integrate 自動產出，請勿手動修改

import { ref, computed, watch, type Ref } from 'vue';
import { apiClient, ApiClientError } from './client';
import type {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  GetUsersParams,
  CreateUserRequest,
  UpdateUserRequest,
  UpdateRoleRequest,
  ChangePasswordRequest,
  SearchUsersParams,
  UserDetailResponse,
  User,
  PaginatedResponse,
} from './types';

// ─── 通用 Composable 工具 ──────────────────────────────

function useAsyncAction<TInput, TOutput>(
  action: (input: TInput) => Promise<TOutput>,
) {
  const data = ref<TOutput | null>(null) as Ref<TOutput | null>;
  const error = ref<ApiClientError | null>(null);
  const isLoading = ref(false);

  async function execute(input: TInput): Promise<TOutput> {
    isLoading.value = true;
    error.value = null;
    try {
      const result = await action(input);
      data.value = result;
      return result;
    } catch (e) {
      error.value = e as ApiClientError;
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  return { data, error, isLoading, execute };
}

// ─── Auth Composables ──────────────────────────────────

export function useLogin() {
  const { data, error, isLoading, execute } = useAsyncAction(
    (input: LoginRequest) => apiClient.login(input),
  );

  async function login(input: LoginRequest): Promise<LoginResponse> {
    const result = await execute(input);
    apiClient.setToken(result.token);
    return result;
  }

  return { data, error, isLoading, login };
}

export function useRegister() {
  const { data, error, isLoading, execute } = useAsyncAction(
    (input: RegisterRequest) => apiClient.register(input),
  );

  async function register(input: RegisterRequest): Promise<RegisterResponse> {
    const result = await execute(input);
    apiClient.setToken(result.token);
    return result;
  }

  return { data, error, isLoading, register };
}

export function useLogout() {
  const { error, isLoading, execute } = useAsyncAction(
    () => apiClient.logout(),
  );

  async function logout(): Promise<void> {
    await execute(undefined as never);
    apiClient.setToken(null);
  }

  return { error, isLoading, logout };
}

// ─── Users Composables ─────────────────────────────────

export function useUsers(params: Ref<GetUsersParams | undefined>) {
  const data = ref<PaginatedResponse<User> | null>(null) as Ref<PaginatedResponse<User> | null>;
  const error = ref<ApiClientError | null>(null);
  const isLoading = ref(false);

  async function fetch() {
    isLoading.value = true;
    error.value = null;
    try {
      data.value = await apiClient.getUsers(params.value);
    } catch (e) {
      error.value = e as ApiClientError;
    } finally {
      isLoading.value = false;
    }
  }

  watch(params, fetch, { immediate: true, deep: true });

  return { data, error, isLoading, refetch: fetch };
}

export function useUser(id: Ref<string>) {
  const data = ref<UserDetailResponse | null>(null) as Ref<UserDetailResponse | null>;
  const error = ref<ApiClientError | null>(null);
  const isLoading = ref(false);

  async function fetch() {
    if (!id.value) return;
    isLoading.value = true;
    error.value = null;
    try {
      data.value = await apiClient.getUser(id.value);
    } catch (e) {
      error.value = e as ApiClientError;
    } finally {
      isLoading.value = false;
    }
  }

  watch(id, fetch, { immediate: true });

  return { data, error, isLoading, refetch: fetch };
}

export function useMe() {
  const data = ref<UserDetailResponse | null>(null) as Ref<UserDetailResponse | null>;
  const error = ref<ApiClientError | null>(null);
  const isLoading = ref(false);

  async function fetch() {
    isLoading.value = true;
    error.value = null;
    try {
      data.value = await apiClient.getMe();
    } catch (e) {
      error.value = e as ApiClientError;
    } finally {
      isLoading.value = false;
    }
  }

  fetch();

  const user = computed(() => data.value?.user ?? null);

  return { data, user, error, isLoading, refetch: fetch };
}

export function useCreateUser() {
  return useAsyncAction((data: CreateUserRequest) => apiClient.createUser(data));
}

export function useUpdateUser() {
  return useAsyncAction(
    ({ id, data }: { id: string; data: UpdateUserRequest }) => apiClient.updateUser(id, data),
  );
}

export function useDeleteUser() {
  return useAsyncAction((id: string) => apiClient.deleteUser(id));
}

export function useUpdateUserRole() {
  return useAsyncAction(
    ({ id, data }: { id: string; data: UpdateRoleRequest }) => apiClient.updateUserRole(id, data),
  );
}

export function useSearchUsers(params: Ref<SearchUsersParams>) {
  const data = ref<{ users: User[] } | null>(null) as Ref<{ users: User[] } | null>;
  const error = ref<ApiClientError | null>(null);
  const isLoading = ref(false);

  async function fetch() {
    if (params.value.q.length < 2) return;
    isLoading.value = true;
    error.value = null;
    try {
      data.value = await apiClient.searchUsers(params.value);
    } catch (e) {
      error.value = e as ApiClientError;
    } finally {
      isLoading.value = false;
    }
  }

  watch(params, fetch, { immediate: true, deep: true });

  return { data, error, isLoading, refetch: fetch };
}

export function useChangePassword() {
  return useAsyncAction((data: ChangePasswordRequest) => apiClient.changePassword(data));
}
```

### 8.3 Angular

#### 目錄結構

```
src/app/api/user-service/
├── models.ts         # API 型別定義
└── user.service.ts   # Angular Service（HttpClient + Observable）
```

#### models.ts

```typescript
// src/app/api/user-service/models.ts
// 由 /api-integrate 自動產出，請勿手動修改

export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  role: 'admin' | 'user' | 'moderator';
  createdAt: string;
  updatedAt: string;
}

export interface UserProfile {
  bio?: string;
  phone?: string;
  address?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
  };
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, string[]>;
}

// ─── Auth ─────────────────────────────

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  user: User;
}

export interface RegisterRequest {
  name: string;
  email: string;
  password: string;
}

export interface RegisterResponse {
  token: string;
  user: User;
}

export interface RefreshRequest {
  refreshToken: string;
}

export interface RefreshResponse {
  token: string;
  refreshToken: string;
}

// ─── Users ────────────────────────────

export interface GetUsersParams {
  page?: number;
  pageSize?: number;
  search?: string;
  role?: string;
  sort?: string;
}

export interface CreateUserRequest {
  name: string;
  email: string;
  password: string;
  role: 'admin' | 'user' | 'moderator';
}

export interface UpdateUserRequest {
  name?: string;
  email?: string;
  avatar?: string;
}

export interface UpdateRoleRequest {
  role: 'admin' | 'user' | 'moderator';
}

export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}

export interface SearchUsersParams {
  q: string;
  limit?: number;
}

export interface UserDetailResponse {
  user: User & { profile: UserProfile };
}
```

#### user.service.ts

```typescript
// src/app/api/user-service/user.service.ts
// 由 /api-integrate 自動產出，請勿手動修改

import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  RefreshRequest,
  RefreshResponse,
  GetUsersParams,
  CreateUserRequest,
  UpdateUserRequest,
  UpdateRoleRequest,
  ChangePasswordRequest,
  SearchUsersParams,
  UserDetailResponse,
  User,
  PaginatedResponse,
} from './models';

@Injectable({
  providedIn: 'root',
})
export class UserService {
  private readonly baseUrl = `${environment.apiBaseUrl}/api/v1`;

  constructor(private http: HttpClient) {}

  // ─── Auth ──────────────────────────────────────────

  login(data: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.baseUrl}/auth/login`, data);
  }

  register(data: RegisterRequest): Observable<RegisterResponse> {
    return this.http.post<RegisterResponse>(`${this.baseUrl}/auth/register`, data);
  }

  refresh(data: RefreshRequest): Observable<RefreshResponse> {
    return this.http.post<RefreshResponse>(`${this.baseUrl}/auth/refresh`, data);
  }

  logout(): Observable<{ success: boolean }> {
    return this.http.post<{ success: boolean }>(`${this.baseUrl}/auth/logout`, {});
  }

  // ─── Users ─────────────────────────────────────────

  getUsers(params?: GetUsersParams): Observable<PaginatedResponse<User>> {
    let httpParams = new HttpParams();
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          httpParams = httpParams.set(key, String(value));
        }
      });
    }
    return this.http.get<PaginatedResponse<User>>(`${this.baseUrl}/users`, { params: httpParams });
  }

  getUser(id: string): Observable<UserDetailResponse> {
    return this.http.get<UserDetailResponse>(`${this.baseUrl}/users/${id}`);
  }

  createUser(data: CreateUserRequest): Observable<{ user: User }> {
    return this.http.post<{ user: User }>(`${this.baseUrl}/users`, data);
  }

  updateUser(id: string, data: UpdateUserRequest): Observable<{ user: User }> {
    return this.http.put<{ user: User }>(`${this.baseUrl}/users/${id}`, data);
  }

  deleteUser(id: string): Observable<{ success: boolean }> {
    return this.http.delete<{ success: boolean }>(`${this.baseUrl}/users/${id}`);
  }

  updateUserRole(id: string, data: UpdateRoleRequest): Observable<{ user: User }> {
    return this.http.patch<{ user: User }>(`${this.baseUrl}/users/${id}/role`, data);
  }

  getUserOrders(id: string, params?: { page?: number; pageSize?: number; status?: string }): Observable<PaginatedResponse<unknown>> {
    let httpParams = new HttpParams();
    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          httpParams = httpParams.set(key, String(value));
        }
      });
    }
    return this.http.get<PaginatedResponse<unknown>>(`${this.baseUrl}/users/${id}/orders`, { params: httpParams });
  }

  uploadAvatar(id: string, file: File): Observable<{ url: string }> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<{ url: string }>(`${this.baseUrl}/users/${id}/avatar`, formData);
  }

  deleteAvatar(id: string): Observable<{ success: boolean }> {
    return this.http.delete<{ success: boolean }>(`${this.baseUrl}/users/${id}/avatar`);
  }

  getMe(): Observable<UserDetailResponse> {
    return this.http.get<UserDetailResponse>(`${this.baseUrl}/users/me`);
  }

  changePassword(data: ChangePasswordRequest): Observable<{ success: boolean }> {
    return this.http.put<{ success: boolean }>(`${this.baseUrl}/users/me/password`, data);
  }

  searchUsers(params: SearchUsersParams): Observable<{ users: User[] }> {
    let httpParams = new HttpParams().set('q', params.q);
    if (params.limit !== undefined) {
      httpParams = httpParams.set('limit', String(params.limit));
    }
    return this.http.get<{ users: User[] }>(`${this.baseUrl}/users/search`, { params: httpParams });
  }
}
```

### 8.4 Swift (iOS)

#### 目錄結構

```
Sources/API/UserService/
├── Models.swift       # Codable 型別定義
└── APIClient.swift    # URLSession + async/await
```

#### Models.swift

```swift
// Sources/API/UserService/Models.swift
// 由 /api-integrate 自動產出，請勿手動修改

import Foundation

// MARK: - 共用型別

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let avatar: String?
    let role: UserRole
    let createdAt: String
    let updatedAt: String
}

enum UserRole: String, Codable {
    case admin
    case user
    case moderator
}

struct UserProfile: Codable {
    let bio: String?
    let phone: String?
    let address: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let meta: PaginationMeta
}

struct PaginationMeta: Codable {
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

struct APIError: Codable, LocalizedError {
    let code: String
    let message: String
    let details: [String: [String]]?

    var errorDescription: String? { message }
}

// MARK: - Auth

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let refreshToken: String
    let user: User
}

struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
}

struct RegisterResponse: Codable {
    let token: String
    let user: User
}

struct RefreshRequest: Codable {
    let refreshToken: String
}

struct RefreshResponse: Codable {
    let token: String
    let refreshToken: String
}

struct LogoutResponse: Codable {
    let success: Bool
}

// MARK: - Users

struct CreateUserRequest: Codable {
    let name: String
    let email: String
    let password: String
    let role: UserRole
}

struct UpdateUserRequest: Codable {
    let name: String?
    let email: String?
    let avatar: String?
}

struct UpdateRoleRequest: Codable {
    let role: UserRole
}

struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}

struct UserDetailResponse: Codable {
    let user: UserDetail
}

struct UserDetail: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let avatar: String?
    let role: UserRole
    let createdAt: String
    let updatedAt: String
    let profile: UserProfile
}

struct UploadAvatarResponse: Codable {
    let url: String
}

struct SearchUsersResponse: Codable {
    let users: [User]
}

struct SuccessResponse: Codable {
    let success: Bool
}

struct CreateUserResponse: Codable {
    let user: User
}
```

#### APIClient.swift

```swift
// Sources/API/UserService/APIClient.swift
// 由 /api-integrate 自動產出，請勿手動修改

import Foundation

actor UserServiceClient {
    private let baseURL: String
    private var token: String?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: String = "http://localhost:3000/api/v1") {
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    // MARK: - Auth

    func login(_ request: LoginRequest) async throws -> LoginResponse {
        let response: LoginResponse = try await post("/auth/login", body: request)
        self.token = response.token
        return response
    }

    func register(_ request: RegisterRequest) async throws -> RegisterResponse {
        let response: RegisterResponse = try await post("/auth/register", body: request)
        self.token = response.token
        return response
    }

    func refresh(_ request: RefreshRequest) async throws -> RefreshResponse {
        let response: RefreshResponse = try await post("/auth/refresh", body: request)
        self.token = response.token
        return response
    }

    func logout() async throws -> LogoutResponse {
        let response: LogoutResponse = try await post("/auth/logout", body: EmptyBody())
        self.token = nil
        return response
    }

    // MARK: - Users

    func getUsers(
        page: Int? = nil,
        pageSize: Int? = nil,
        search: String? = nil,
        role: String? = nil,
        sort: String? = nil
    ) async throws -> PaginatedResponse<User> {
        var queryItems: [URLQueryItem] = []
        if let page { queryItems.append(URLQueryItem(name: "page", value: "\(page)")) }
        if let pageSize { queryItems.append(URLQueryItem(name: "pageSize", value: "\(pageSize)")) }
        if let search { queryItems.append(URLQueryItem(name: "search", value: search)) }
        if let role { queryItems.append(URLQueryItem(name: "role", value: role)) }
        if let sort { queryItems.append(URLQueryItem(name: "sort", value: sort)) }
        return try await get("/users", query: queryItems)
    }

    func getUser(id: String) async throws -> UserDetailResponse {
        return try await get("/users/\(id)")
    }

    func createUser(_ request: CreateUserRequest) async throws -> CreateUserResponse {
        return try await post("/users", body: request)
    }

    func updateUser(id: String, _ request: UpdateUserRequest) async throws -> CreateUserResponse {
        return try await put("/users/\(id)", body: request)
    }

    func deleteUser(id: String) async throws -> SuccessResponse {
        return try await delete("/users/\(id)")
    }

    func updateUserRole(id: String, _ request: UpdateRoleRequest) async throws -> CreateUserResponse {
        return try await patch("/users/\(id)/role", body: request)
    }

    func getMe() async throws -> UserDetailResponse {
        return try await get("/users/me")
    }

    func changePassword(_ request: ChangePasswordRequest) async throws -> SuccessResponse {
        return try await put("/users/me/password", body: request)
    }

    func searchUsers(q: String, limit: Int? = nil) async throws -> SearchUsersResponse {
        var queryItems = [URLQueryItem(name: "q", value: q)]
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        return try await get("/users/search", query: queryItems)
    }

    func uploadAvatar(id: String, imageData: Data, filename: String) async throws -> UploadAvatarResponse {
        let boundary = UUID().uuidString
        var request = try buildRequest("/users/\(id)/avatar", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(UploadAvatarResponse.self, from: data)
    }

    func deleteAvatar(id: String) async throws -> SuccessResponse {
        return try await delete("/users/\(id)/avatar")
    }

    // MARK: - Private

    private struct EmptyBody: Codable {}

    private func buildRequest(_ path: String, method: String, query: [URLQueryItem] = []) throws -> URLRequest {
        guard var components = URLComponents(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.init(rawValue: httpResponse.statusCode))
        }
    }

    private func get<T: Codable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        let request = try buildRequest(path, method: "GET", query: query)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    private func post<TBody: Codable, TResponse: Codable>(_ path: String, body: TBody) async throws -> TResponse {
        var request = try buildRequest(path, method: "POST")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(TResponse.self, from: data)
    }

    private func put<TBody: Codable, TResponse: Codable>(_ path: String, body: TBody) async throws -> TResponse {
        var request = try buildRequest(path, method: "PUT")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(TResponse.self, from: data)
    }

    private func patch<TBody: Codable, TResponse: Codable>(_ path: String, body: TBody) async throws -> TResponse {
        var request = try buildRequest(path, method: "PATCH")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(TResponse.self, from: data)
    }

    private func delete<T: Codable>(_ path: String) async throws -> T {
        let request = try buildRequest(path, method: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
}
```

### 8.5 Kotlin (Android)

#### 目錄結構

```
app/src/main/java/com/example/api/userservice/
├── Models.kt          # data class 定義
└── ApiService.kt      # Retrofit 介面
```

#### Models.kt

```kotlin
// app/src/main/java/com/example/api/userservice/Models.kt
// 由 /api-integrate 自動產出，請勿手動修改

package com.example.api.userservice

import com.google.gson.annotations.SerializedName

// ─── 共用型別 ─────────────────────────────────────

data class User(
    val id: String,
    val name: String,
    val email: String,
    val avatar: String? = null,
    val role: UserRole,
    val createdAt: String,
    val updatedAt: String,
)

enum class UserRole {
    @SerializedName("admin") ADMIN,
    @SerializedName("user") USER,
    @SerializedName("moderator") MODERATOR,
}

data class UserProfile(
    val bio: String? = null,
    val phone: String? = null,
    val address: String? = null,
)

data class PaginatedResponse<T>(
    val data: List<T>,
    val meta: PaginationMeta,
)

data class PaginationMeta(
    val total: Int,
    val page: Int,
    val pageSize: Int,
    val totalPages: Int,
)

data class ApiError(
    val code: String,
    val message: String,
    val details: Map<String, List<String>>? = null,
)

// ─── Auth ─────────────────────────────────────────

data class LoginRequest(
    val email: String,
    val password: String,
)

data class LoginResponse(
    val token: String,
    val refreshToken: String,
    val user: User,
)

data class RegisterRequest(
    val name: String,
    val email: String,
    val password: String,
)

data class RegisterResponse(
    val token: String,
    val user: User,
)

data class RefreshRequest(
    val refreshToken: String,
)

data class RefreshResponse(
    val token: String,
    val refreshToken: String,
)

data class LogoutResponse(
    val success: Boolean,
)

// ─── Users ────────────────────────────────────────

data class CreateUserRequest(
    val name: String,
    val email: String,
    val password: String,
    val role: UserRole,
)

data class UpdateUserRequest(
    val name: String? = null,
    val email: String? = null,
    val avatar: String? = null,
)

data class UpdateRoleRequest(
    val role: UserRole,
)

data class ChangePasswordRequest(
    val currentPassword: String,
    val newPassword: String,
)

data class UserDetail(
    val id: String,
    val name: String,
    val email: String,
    val avatar: String? = null,
    val role: UserRole,
    val createdAt: String,
    val updatedAt: String,
    val profile: UserProfile,
)

data class UserDetailResponse(
    val user: UserDetail,
)

data class UserResponse(
    val user: User,
)

data class SuccessResponse(
    val success: Boolean,
)

data class UploadAvatarResponse(
    val url: String,
)

data class SearchUsersResponse(
    val users: List<User>,
)
```

#### ApiService.kt

```kotlin
// app/src/main/java/com/example/api/userservice/ApiService.kt
// 由 /api-integrate 自動產出，請勿手動修改

package com.example.api.userservice

import okhttp3.MultipartBody
import retrofit2.http.*

interface UserServiceApi {

    // ─── Auth ──────────────────────────────────────────

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): LoginResponse

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): RegisterResponse

    @POST("auth/refresh")
    suspend fun refresh(@Body request: RefreshRequest): RefreshResponse

    @POST("auth/logout")
    suspend fun logout(): LogoutResponse

    // ─── Users ─────────────────────────────────────────

    @GET("users")
    suspend fun getUsers(
        @Query("page") page: Int? = null,
        @Query("pageSize") pageSize: Int? = null,
        @Query("search") search: String? = null,
        @Query("role") role: String? = null,
        @Query("sort") sort: String? = null,
    ): PaginatedResponse<User>

    @GET("users/{id}")
    suspend fun getUser(@Path("id") id: String): UserDetailResponse

    @POST("users")
    suspend fun createUser(@Body request: CreateUserRequest): UserResponse

    @PUT("users/{id}")
    suspend fun updateUser(
        @Path("id") id: String,
        @Body request: UpdateUserRequest,
    ): UserResponse

    @DELETE("users/{id}")
    suspend fun deleteUser(@Path("id") id: String): SuccessResponse

    @PATCH("users/{id}/role")
    suspend fun updateUserRole(
        @Path("id") id: String,
        @Body request: UpdateRoleRequest,
    ): UserResponse

    @GET("users/{id}/orders")
    suspend fun getUserOrders(
        @Path("id") id: String,
        @Query("page") page: Int? = null,
        @Query("pageSize") pageSize: Int? = null,
        @Query("status") status: String? = null,
    ): PaginatedResponse<Any>

    @Multipart
    @POST("users/{id}/avatar")
    suspend fun uploadAvatar(
        @Path("id") id: String,
        @Part file: MultipartBody.Part,
    ): UploadAvatarResponse

    @DELETE("users/{id}/avatar")
    suspend fun deleteAvatar(@Path("id") id: String): SuccessResponse

    @GET("users/me")
    suspend fun getMe(): UserDetailResponse

    @PUT("users/me/password")
    suspend fun changePassword(@Body request: ChangePasswordRequest): SuccessResponse

    @GET("users/search")
    suspend fun searchUsers(
        @Query("q") q: String,
        @Query("limit") limit: Int? = null,
    ): SearchUsersResponse
}
```

**Retrofit 初始化範例**（放在 DI 模組中）：

```kotlin
// app/src/main/java/com/example/di/NetworkModule.kt

package com.example.di

import com.example.api.userservice.UserServiceApi
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

object NetworkModule {

    private var token: String? = null

    fun setToken(token: String?) {
        this.token = token
    }

    private val authInterceptor = Interceptor { chain ->
        val request = chain.request().newBuilder().apply {
            token?.let { addHeader("Authorization", "Bearer $it") }
        }.build()
        chain.proceed(request)
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(authInterceptor)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl("http://10.0.2.2:3000/api/v1/")
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    val userServiceApi: UserServiceApi = retrofit.create(UserServiceApi::class.java)
}
```

---

## 9. 版號管理

### Semver 規則詳細說明

| 版號區段 | 何時遞增 | 範例 | 前端影響 |
|----------|----------|------|----------|
| **Major** (`X.0.0`) | 破壞性變更：移除 endpoint、修改 response 結構、更改 URL、移除必填欄位 | `2.1.0 → 3.0.0` | 必須更新，可能需要修改業務邏輯 |
| **Minor** (`x.Y.0`) | 向下相容新增：新增 endpoint、新增 optional 欄位、新增 optional query param | `2.1.0 → 2.2.0` | 建議更新，不會破壞現有程式碼 |
| **Patch** (`x.y.Z`) | 修正：修正描述文字、補充 error code 說明、修正錯字 | `2.1.0 → 2.1.1` | 可選更新，不影響程式碼 |

### 自動版號判斷邏輯

```mermaid
flowchart TD
    Start["比對前後描述檔差異"] --> Q1{"有 endpoint 被移除？"}
    Q1 -->|"有"| Major["Major Bump"]
    Q1 -->|"無"| Q2{"有 endpoint URL 被修改？"}
    Q2 -->|"有"| Major
    Q2 -->|"無"| Q3{"有 response 結構變更？"}
    Q3 -->|"有"| Q3a{"是新增 optional 欄位？"}
    Q3a -->|"是"| Minor["Minor Bump"]
    Q3a -->|"否"| Major
    Q3 -->|"無"| Q4{"有新增 endpoint？"}
    Q4 -->|"有"| Minor
    Q4 -->|"無"| Q5{"有新增 optional 參數？"}
    Q5 -->|"有"| Minor
    Q5 -->|"無"| Patch["Patch Bump"]

    style Major fill:#e74c3c,color:#fff
    style Minor fill:#f39c12,color:#fff
    style Patch fill:#27ae60,color:#fff
```

### 版號比對流程

前端的 `api-sources.yaml` 使用版本範圍語法（與 npm semver 相同）：

| 語法 | 意義 | 接受範圍 |
|------|------|----------|
| `"~2.1"` | 接受 patch 更新 | `>=2.1.0 <2.2.0` |
| `"^2.1"` | 接受 minor 更新 | `>=2.1.0 <3.0.0` |
| `"2.1.0"` | 精確鎖定 | 只接受 `2.1.0` |
| `"*"` | 永遠最新 | 任何版本 |

### 鎖版本 vs Latest 的使用建議

| 策略 | 適用場景 | 優點 | 風險 |
|------|----------|------|------|
| 精確鎖定 `"2.1.0"` | 生產環境、穩定期 | 完全可預測 | 錯過安全修正 |
| Patch 更新 `"~2.1"` | **推薦預設值** | 自動獲得修正 | 極低風險 |
| Minor 更新 `"^2.1"` | 開發環境、積極更新 | 自動獲得新功能 | 需注意新增欄位 |
| Latest `"*"` | 原型開發、概念驗證 | 永遠最新 | 可能遇到破壞性變更 |

---

## 10. V1 範圍與未來規劃

### V1（首次發布）

**支援的後端框架**

| 框架 | 語言 | 偵測方式 |
|------|------|----------|
| FastAPI | Python | `@app.get`, `@router.post`, Pydantic BaseModel |
| NestJS | TypeScript | `@Controller`, `@Get/@Post`, DTO class |
| Express | JavaScript/TS | `router.get/post`, middleware chain |
| Spring Boot | Java/Kotlin | `@RestController`, `@RequestMapping` |
| Gin | Go | `r.GET/POST`, binding struct |
| Rails | Ruby | `config/routes.rb`, controller actions |

**支援的前端框架**

| 框架 | 語言 | 產出 |
|------|------|------|
| React | TypeScript | types.ts + client.ts + hooks.ts（React Query） |
| Vue | TypeScript | types.ts + client.ts + composables.ts |
| Angular | TypeScript | models.ts + service.ts（HttpClient） |
| Swift (iOS) | Swift | Models.swift + APIClient.swift（async/await） |
| Kotlin (Android) | Kotlin | Models.kt + ApiService.kt（Retrofit） |

**支援的 API 類型**

- REST API（JSON request/response）
- Multipart file upload
- Query parameter / Path parameter
- Bearer token 認證

**V1 不包含**

- GraphQL
- gRPC / Connect
- WebSocket / SSE
- OAuth2 完整流程（僅支援 Bearer token）
- API 版本管理（如 `/v1/` → `/v2/` 遷移）

### V2（規劃中）

| 功能 | 說明 |
|------|------|
| GraphQL 支援 | 掃描 `.graphql` schema，生成 typed queries/mutations |
| gRPC / Connect 支援 | 掃描 `.proto` 檔案，生成 typed client |
| WebSocket / SSE 支援 | 描述雙向通訊和事件串流 API |
| OAuth2 完整流程 | 支援 Authorization Code、PKCE、Client Credentials 等 flow |
| 自動 diff 通知 | CI 偵測到版本更新時自動通知訂閱的前端 repo |
| Monorepo 原生支援 | 單一 repo 內多個 service 的掃描和管理 |

### V3（構想）

| 功能 | 說明 |
|------|------|
| Mock server 自動生成 | 根據描述檔自動啟動 mock API server |
| Breaking change 自動偵測 | CI 層級的 breaking change 攔截 + 通知 |
| Postman / Insomnia collection 匯出 | 將描述檔轉為 collection 格式方便手動測試 |
| API 健康監控整合 | 串接 uptime monitoring，描述檔中標記 SLA |
| 多語言 SDK 生成 | Python、Ruby、PHP 等非前端語言的 client 生成 |
| API 使用量追蹤 | 統計哪些前端使用了哪些 endpoint |

---

## 11. FAQ

### Q1: 後端沒有 OpenAPI spec 怎麼辦？

完全不需要。`/api-extract` 的掃描策略會依序嘗試框架 pattern 偵測和 LLM 原始碼分析。只要你的後端有可讀的路由定義和 handler 函式，Skill A 就能產出描述檔。OpenAPI spec 只是「優先使用」的來源之一，不是必要條件。

### Q2: 支援 monorepo 嗎？

V1 部分支援。如果你的 monorepo 中每個 service 是獨立的子目錄（如 `packages/user-service/`、`packages/order-service/`），可以在各子目錄分別執行 `/api-extract`。V2 將提供原生的 monorepo 掃描支援，一次掃描所有 service。

### Q3: 前端不是 TypeScript 怎麼辦？

V1 支援 Swift 和 Kotlin 的原生型別產出。如果你的前端是純 JavaScript，生成的 `types.ts` 仍然有價值 -- 它可以當作 JSDoc 型別參考，且 `client.ts` 移除型別標注後就是合法的 JavaScript。V2 計劃支援更多語言。

### Q4: 如何處理 Auth？

描述檔的 `auth` 欄位以自然語言描述認證方式（如 `Bearer token in Authorization header`）。生成的 `client.ts` 會內建 `setToken()` 方法和 auth interceptor。對於 OAuth2 等複雜流程，V1 建議在 `api-index.yaml` 的 `auth` 欄位詳細描述 flow，Skill B 會據此生成對應的認證邏輯。

### Q5: 如何處理 pagination？

在 `api-index.yaml` 的 `shared_types` 中定義 `PaginatedResponse<T>` 型別，所有分頁 endpoint 使用統一格式。生成的 types 會包含 `PaginationMeta`，hooks 會支援 page/pageSize 參數。如果你的分頁格式不同（如 cursor-based），在描述檔中直接寫出你的 response 結構即可。

### Q6: 描述檔跟 OpenAPI 的差異？

API Bridge 描述檔是為 LLM 設計的，用 Markdown 撰寫，token 效率比 OpenAPI JSON 高 60-70%。OpenAPI 是機器可讀的標準格式，適合 Swagger UI、Postman 等工具。兩者不衝突 -- 如果你已經有 OpenAPI spec，`/api-extract` 會優先使用它作為掃描來源，然後轉成更 token 效率的描述檔格式。

### Q7: 需要裝什麼？

只需要 Claude Code CLI 和 agent-army 插件。不需要額外安裝 code generator、template engine 或 schema validator。所有掃描和生成都由 LLM 在 Claude Code session 中完成。

### Q8: 描述檔會過時嗎？

如果後端修改了 API 但沒有重新執行 `/api-extract`，描述檔就會過時。建議的做法是在 CI pipeline 中加入自動推送（參考第 6 節的 CI 設定），確保每次合併到 main 時自動更新描述檔。Skill A 的驗證機制也會比對 endpoint 數量，幫助發現遺漏。

### Q9: 可以手動修改描述檔嗎？

可以。描述檔是純 Markdown + YAML，任何人都可以直接編輯。這在以下場景特別有用：

- 補充 LLM 掃描遺漏的細節（如特殊的 error code）
- 添加業務語境說明（如「此 endpoint 每日有 1000 次 rate limit」）
- 修正 LLM 推斷錯誤的型別

### Q10: 多個後端團隊如何協作？

每個後端 service 在 api-catalog repo 中有獨立的目錄，彼此互不干擾。透過 CI token 的權限控制，每個後端 CI 只能推送自己服務的目錄。前端透過 `api-sources.yaml` 宣告訂閱哪些服務的哪些模組，實現精細的依賴管理。
