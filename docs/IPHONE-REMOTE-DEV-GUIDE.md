# iPhone 遠端開發完全指南

> 用手機寫 Code — Claude Code Remote Control + SSH + 遠端桌面全攻略 (2026)

**最後更新**: 2026-03-05

---

## 目錄

- [概覽：三種遠端開發方式](#概覽三種遠端開發方式)
- [方式一：Claude Code Remote Control（推薦）](#方式一claude-code-remote-control推薦)
- [方式二：iPhone SSH 到 Mac 終端機](#方式二iphone-ssh-到-mac-終端機)
- [方式三：iPhone 遠端控制 Mac GUI 介面](#方式三iphone-遠端控制-mac-gui-介面)
- [網路穿透方案比較](#網路穿透方案比較)
- [推薦組合方案](#推薦組合方案)
- [常見問題 FAQ](#常見問題-faq)
- [資料來源](#資料來源)

---

## 概覽：三種遠端開發方式

| 方式 | 原理 | 延遲 | 頻寬需求 | 適合場景 | 成本 |
|------|------|------|---------|---------|------|
| **Claude Code Remote Control** | Anthropic 雲端中介 WebSocket | 低 | 極低（文字） | AI 輔助開發、審核代碼 | $100-200/月 (Max) |
| **SSH 終端機** | 加密文字通道 | 極低 | 極低（<128Kbps） | CLI 操作、vim 編輯、Claude Code | $0 起 |
| **遠端桌面 (VNC/RDP)** | 螢幕畫面串流 | 中-高 | 高（1-5GB/hr） | GUI IDE、Xcode、視覺操作 | $0 起 |

### 操作原理圖

```
┌─────────────┐                              ┌─────────────┐
│   iPhone    │                              │     Mac     │
│             │    方式一: Remote Control     │             │
│  Claude App ├──── HTTPS/WSS ──── Anthropic ──── claude   │
│             │    (端到端加密)     (中介)     │  (本地執行)  │
│             │                              │             │
│  SSH Client ├──── SSH (port 22) ───────────┤── sshd      │
│  (Termius)  │    方式二: 加密終端           │  + tmux     │
│             │                              │             │
│  VNC Client ├──── VNC (port 5900) ─────────┤── Screen    │
│  (Screens)  │    方式三: 畫面串流           │   Sharing   │
└─────────────┘                              └─────────────┘
        │                                           │
        └──── Tailscale VPN (100.x.x.x) ───────────┘
              (跨網路安全連線)
```

---

## 方式一：Claude Code Remote Control（推薦）

### 什麼是 Remote Control？

2026 年 2 月 25 日，Anthropic 正式發布 **Claude Code Remote Control** 功能。它讓你從 iPhone（或任何瀏覽器）繼續控制在 Mac 上運行的 Claude Code 會話。

**核心特點**：
- 程式碼永遠不離開你的 Mac — iPhone 只是遙控器
- 檔案系統、MCP servers、工具、專案設定全部保持可用
- 對話在所有連線裝置間即時同步
- 端到端加密，Anthropic 看不到你的程式碼

### 運作原理

```
iPhone Claude App                 Anthropic API               Mac Terminal
     │                               │                           │
     │  1. 掃描 QR Code 連線         │                           │
     ├──────────────────────────────►│                           │
     │                               │  2. 路由訊息到本地會話    │
     │                               ├──────────────────────────►│
     │                               │                           │ 3. 本地執行
     │                               │  4. 回傳結果              │    (讀寫檔案、
     │  5. 顯示結果                  │◄────────────────────────── │     執行指令)
     │◄──────────────────────────────│                           │
```

- **僅出站 HTTPS**：Mac 不開啟任何入站埠口
- **輪詢機制**：本地會話向 Anthropic API 註冊並輪詢工作指令
- **TLS + E2E 加密**：使用多個短期憑證，各自限定單一用途

### 前置需求

| 項目 | 需求 |
|------|------|
| 訂閱方案 | Claude **Max**（$100 或 $200/月） |
| Claude Code 版本 | >= 2.1.52 |
| iPhone App | Claude iOS App（App Store 免費下載） |
| 網路 | Mac 需保持連網 |

> **注意**：Pro 方案（$20/月）即將支援，Team/Enterprise 目前不支援。

### 安裝與設定步驟

#### 步驟 1：確認 Claude Code 版本

```bash
claude --version
# 需要 >= 2.1.52
# 若版本過舊，更新：
npm install -g @anthropic-ai/claude-code
```

#### 步驟 2：啟動 Remote Control

```bash
# 方法 A：在現有會話中啟用
claude
# 進入後輸入：
/remote-control
# 簡寫：
/rc

# 方法 B：直接啟動
claude remote-control
```

#### 步驟 3：連線 iPhone

終端機會顯示一個 **QR Code** 和 **Session URL**，三種連線方式：

1. **掃描 QR Code**：用 iPhone Claude App 掃描（按空白鍵切換 QR Code 顯示）
2. **開啟 URL**：在 iPhone 瀏覽器開啟終端機顯示的 Session URL
3. **App 內找到**：在 claude.ai/code 或 Claude App 中找到會話

#### 步驟 4：開始使用

連線成功後，你可以在 iPhone 上：
- 輸入指令讓 Claude 執行
- 審核和批准檔案修改
- 監控長時間執行的任務
- 切換回 Mac 繼續操作（多裝置即時同步）

### Voice Mode 語音功能（2026 年 3 月）

```bash
# 在 Claude Code 中啟用語音模式
/voice

# 按住空白鍵說話，放開送出指令
```

- 支援語音指令如 "refactor the authentication middleware"
- Push-to-talk 模式（非持續監聽）
- Pro、Max、Team、Enterprise 訂閱者免費使用
- 2026 年 3 月分階段推出中

### 限制

| 限制 | 說明 |
|------|------|
| 無法從手機啟動會話 | 只能繼續已在 Mac 上啟動的會話 |
| 單一會話 | 每個 Claude Code 實例同時只支援一個遠端連線 |
| 終端機必須開啟 | 關閉 Mac 終端機 = 會話結束 |
| 網路逾時 | Mac 清醒但斷網超過約 10 分鐘，會話逾時 |
| 價格門檻 | Max 方案 $100-200/月 |

---

## 方式二：iPhone SSH 到 Mac 終端機

### 運作原理

SSH（Secure Shell）在 iPhone 和 Mac 之間建立加密的文字通道。你在 iPhone 上看到的就是 Mac 的終端機畫面，所有指令都在 Mac 上執行。

```
iPhone SSH Client ──── 加密通道 (port 22) ────► Mac sshd
                                                   │
                                                   ├── tmux 會話管理
                                                   ├── Claude Code CLI
                                                   ├── vim/nano 編輯器
                                                   └── 所有 CLI 工具
```

**頻寬需求極低**：< 128Kbps 即可流暢使用（4G/5G 完全足夠）

### Mac 端設定

#### 步驟 1：啟用 SSH（遠端登入）

**GUI 方式**：
1. 系統設定（System Settings）
2. 一般 > 共享（General > Sharing）
3. 開啟「遠端登入」（Remote Login）
4. 設定允許存取的使用者

**終端機方式**：
```bash
sudo systemsetup -setremotelogin on
```

#### 步驟 2：設定 SSH 金鑰驗證（強烈建議）

```bash
# 在 Mac 上產生 Ed25519 金鑰（更快、更安全）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 金鑰位置
# 私鑰：~/.ssh/id_ed25519（權限 600）
# 公鑰：~/.ssh/id_ed25519.pub
# 目錄：~/.ssh/（權限 700）
```

#### 步驟 3：強化 SSH 安全性

編輯 `/etc/ssh/sshd_config`：

```bash
sudo nano /etc/ssh/sshd_config
```

關鍵設定：
```
# 禁用密碼登入（僅允許金鑰驗證）
PasswordAuthentication no
ChallengeResponseAuthentication no

# 禁止 root 直接登入
PermitRootLogin no

# 登入逾時
LoginGraceTime 30
MaxAuthTries 3

# 閒置會話自動斷線（5 分鐘無活動）
ClientAliveInterval 300
ClientAliveCountMax 2

# 僅允許特定使用者
AllowUsers yourusername
```

重啟 SSH 服務：
```bash
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load /System/Library/LaunchDaemons/ssh.plist
```

#### 步驟 4：安裝 tmux（會話持久化）

```bash
# 安裝
brew install tmux

# 啟動命名會話
tmux new -s dev

# 分離會話（不中斷執行）
# 按 Ctrl+B，然後按 D

# 重新連接
tmux attach -t dev

# 列出所有會話
tmux ls
```

> **為何需要 tmux？** iOS 切換 App 超過 30 秒會中斷 SSH 連線。tmux 讓你的工作在斷線後繼續運行，重連後恢復。

### iPhone 端設定

#### SSH 客戶端比較

| App | 價格 | 特色 | 推薦對象 |
|-----|------|------|---------|
| **Moshi** | 免費 | 專為 Claude Code 設計、語音輸入、Mosh 協定、Webhook 通知 | Claude Code 使用者 |
| **Termius** (免費版) | $0 | 跨平台、多標籤、AI 自動完成 | 入門使用者 |
| **WebSSH PRO** | $12.99 買斷 | 買一送全平台（iPhone/iPad/Mac）、終身更新 | Apple 生態系 |
| **Blink Shell** | $19.99/年 | 內建 VS Code、Mosh 支援、桌面級體驗 | iPad 專業開發 |
| **Prompt 3** | $99 買斷 | Mosh + Eternal Terminal、YubiKey 驗證 | 不想訂閱者 |
| **Secure ShellFish** | $29.99 買斷 | iOS Files 深度整合、tmux 支援 | 檔案管理需求 |
| **a-Shell** | 免費 | 本地 Unix 終端機（含 Python、C） | 本地開發 |
| **iSH** | 免費 | Alpine Linux 模擬器 | Linux 環境 |

#### 推薦選擇

- **免費首選**：**Moshi**（專為 AI 編碼代理設計，支援語音輸入和 Mosh 協定）
- **付費首選**：**WebSSH PRO**（$12.99 一次買斷，全 Apple 平台）
- **專業首選**：**Blink Shell**（$19.99/年，內建 VS Code）

#### 連線步驟（以 Termius 為例）

1. App Store 下載 **Termius**
2. 開啟 App → 新增主機
3. 填入：
   - Hostname: Mac 的 IP 位址（同網路）或 Tailscale IP（跨網路）
   - Port: 22
   - Username: Mac 使用者名稱
   - Authentication: 密碼或匯入 SSH 私鑰
4. 點擊連線
5. 連線後執行：
   ```bash
   tmux attach -t dev || tmux new -s dev
   claude
   ```

### SSH + Claude Code 完整工作流

```bash
# 1. Mac 端：啟動 tmux + Claude Code（出門前）
tmux new -s claude-work
claude

# 2. iPhone 端：SSH 連入（通勤中）
ssh username@100.x.x.x    # Tailscale IP
tmux attach -t claude-work

# 3. 在手機上操作 Claude Code
# 輸入指令、審核代碼、監控進度

# 4. 斷線不影響（切 App、進地鐵）
# Claude Code 在 tmux 中繼續運行

# 5. 重連恢復（網路恢復後）
ssh username@100.x.x.x
tmux attach -t claude-work
# 一切都還在！
```

### 終端機編輯器選擇

| 編輯器 | 學習曲線 | iPhone 適用性 | 推薦 |
|--------|---------|-------------|------|
| **nano** | 簡單 | 好（指令提示在畫面下方） | 新手、快速修改 |
| **vim/neovim** | 陡峭 | 優（鍵盤操作，無需滑鼠） | 進階使用者 |
| **Claude Code** | 無 | 優（自然語言操作） | AI 輔助開發 |

### 限制

| 限制 | 說明 | 解決方案 |
|------|------|---------|
| iPhone 虛擬鍵盤 | 缺少 Esc、Tab、方向鍵 | 外接藍牙鍵盤 / SSH App 虛擬按鍵列 |
| 螢幕尺寸 | 程式碼行數少、字體小 | 橫向模式 / 調整字體 / 用 iPad |
| iOS 背景限制 | 切 App 30 秒後 SSH 斷線 | tmux / Mosh 協定 |
| 無 Stage Manager | iPhone 外接螢幕僅鏡像 | 使用 iPad（支援 Stage Manager） |
| 電池消耗 | 行動網路耗電高 | Wi-Fi 優先 / 攜帶行動電源 |

---

## 方式三：iPhone 遠端控制 Mac GUI 介面

### 運作原理

VNC/RDP 將 Mac 的整個螢幕畫面壓縮後串流到 iPhone，你在 iPhone 上的觸控操作會轉換為 Mac 上的滑鼠/鍵盤事件。

```
iPhone VNC Client                           Mac Screen Sharing
     │                                           │
     │  1. 連線請求 (port 5900)                  │
     ├──────────────────────────────────────────►│
     │                                           │ 2. 擷取螢幕畫面
     │  3. 壓縮畫面串流 (H.264/HEVC)             │
     │◄──────────────────────────────────────────┤
     │                                           │
     │  4. 觸控事件 → 滑鼠/鍵盤事件              │
     ├──────────────────────────────────────────►│ 5. 在 Mac 上執行
     │                                           │
```

**頻寬需求較高**：1080p@30fps 約 1-3 GB/hr

### Mac 端設定

#### 步驟 1：啟用螢幕共享

1. **系統設定** > **一般** > **共享**
2. 開啟「螢幕共享」（Screen Sharing）
3. 點擊 (i) 設定允許的使用者
4. VNC 預設埠口：5900

> **注意**：「螢幕共享」和「遠端管理」不能同時開啟。

#### 步驟 2：防止 Mac 休眠

Mac 休眠後 VNC 無法連線。解決方案：

```bash
# 方案 A：系統設定 > 電池 > 電源轉接器 > 設定「永不休眠」

# 方案 B：使用 caffeinate 指令（SSH 遠端喚醒）
caffeinate -u -t 3600    # 保持喚醒 1 小時
caffeinate -u -t 28800   # 保持喚醒 8 小時

# 方案 C：啟用 Wake-on-LAN
# 系統設定 > 電池 > 開啟「網路喚醒」
```

#### 步驟 3：安全性強化

VNC 預設不加密，務必加強安全：

```
# 方案 A：使用 Tailscale VPN（推薦，最簡單）
# 所有流量自動加密，無需額外設定

# 方案 B：SSH Tunnel + VNC
ssh -L 5901:localhost:5900 user@mac-ip
# 然後 VNC 連線到 localhost:5901

# 方案 C：使用支援雲端中介的 App（如 RealVNC Connect）
# 無需開放公開 port，流量經雲端加密中介
```

### iPhone 端設定

#### 遠端桌面 App 比較

##### 免費 App

| App | 特色 | 限制 |
|-----|------|------|
| **Chrome Remote Desktop** | Google 帳號即可用、完全免費 | 缺少 Command/Control/Option 鍵 |
| **macOS Screen Sharing** | 系統內建 VNC | 需第三方 VNC 客戶端連線 |
| **TeamViewer (個人)** | 功能豐富 | 顯示廣告 |
| **AnyDesk (個人)** | 輕量快速 | 部分功能限制 |
| **RealVNC Lite** | 雲端中介、免開 port | 僅限非商業使用 |
| **Parsec (免費)** | 超低延遲 | 基本功能 |
| **Moonlight** | 開源、支援 AV1 | 需 NVIDIA GPU 或 Sunshine |
| **RustDesk** | 開源、可自託管 | 社群維護 |

##### 付費 App

| App | 價格 | 特色 | 推薦對象 |
|-----|------|------|---------|
| **Screens 5** | $24.99/年 或 $74 買斷 | Apple 生態最佳、Vision Pro 支援、拖放檔案 | Mac 用戶 |
| **Jump Desktop** | App Store 買斷 | RDP + VNC 雙協定、多螢幕、iPad 外接顯示器 | 跨平台 |
| **Splashtop** | $99/年 | 4K@60fps、硬體加速、軍規加密 | 高效能需求 |
| **RealVNC Connect** | $99/年/裝置 | 雲端中介、免開 port、App Store 4.8 星 | 企業用戶 |
| **Parsec Teams** | $360/年 | 最低延遲 | 遊戲/創意工作 |

#### 推薦選擇

- **免費首選**：**Chrome Remote Desktop**（零成本、設定簡單）
- **付費首選**：**Screens 5**（$24.99/年，Apple 生態最佳）
- **買斷首選**：**Jump Desktop**（一次購買，RDP + VNC 雙協定）
- **高效能首選**：**Splashtop Performance**（$13/月，4K@60fps）

#### Chrome Remote Desktop 設定步驟（免費）

**Mac 端**：
1. 開啟 Chrome 瀏覽器
2. 前往 `remotedesktop.google.com/access`
3. 點擊「下載」安裝 Chrome Remote Desktop
4. 設定 6 位數 PIN 碼
5. 給予必要的系統權限（螢幕錄製、輔助使用）

**iPhone 端**：
1. App Store 下載 **Chrome Remote Desktop**
2. 使用相同 Google 帳號登入
3. 點擊你的電腦名稱
4. 輸入 PIN 碼
5. 開始控制 Mac

#### Screens 5 設定步驟（付費推薦）

**Mac 端**：
1. 啟用螢幕共享（如上述步驟）
2. 安裝 Tailscale（跨網路存取用）

**iPhone 端**：
1. App Store 下載 **Screens 5**
2. 新增電腦 → 輸入 Mac IP 或 Tailscale IP
3. 輸入 Mac 使用者名稱和密碼
4. 連線後可使用觸控手勢操作 Mac

### 效能優化建議

| 設定 | 區域網路 (Wi-Fi) | 行動網路 (4G/5G) |
|------|-----------------|------------------|
| 解析度 | 1920x1080 或更高 | 1366x768 或更低 |
| 幀率 | 30-60 fps | 15-30 fps |
| 色彩深度 | 24-bit True Color | 16-bit High Color |
| 編碼 | H.264 硬體加速 | 自適應 / HEVC |

### 開發用途評估

| 用途 | 可行性 | 說明 |
|------|--------|------|
| VS Code | 可行 | 需外接鍵盤，觸控不如滑鼠精確 |
| Terminal + Claude Code | 可行 | 但 SSH 方式更高效 |
| Xcode | 勉強可行 | 小螢幕上 Storyboard 很難用 |
| 檔案管理 | 很好 | Screens 5 支援拖放傳輸 |
| 審核 PR / 監控 CI | 很好 | 適合快速檢查狀態 |

### 限制

| 限制 | 說明 |
|------|------|
| 觸控精度 | 不如滑鼠，右鍵操作困難 |
| 延遲 | 行動網路 50-150ms，影響流暢度 |
| 頻寬 | 1080p@30fps 約 1-3 GB/hr |
| 電池 | 畫面串流非常耗電 |
| 螢幕大小 | Mac 桌面縮在 iPhone 上很小 |
| iOS 限制 | 不支援 Stage Manager，外接螢幕僅鏡像 |

---

## 網路穿透方案比較

當 iPhone 和 Mac 不在同一個 Wi-Fi 網路時，需要網路穿透方案。

### 方案比較表

| 方案 | 成本 | 設定難度 | 安全性 | 穩定性 | 適用場景 |
|------|------|---------|--------|--------|---------|
| **Tailscale** | 免費（3 人/100 裝置） | 極簡 | 極高（WireGuard） | 極高 | **首選推薦** |
| **ZeroTier** | 免費（10 裝置） | 簡單 | 高 | 高 | Tailscale 替代 |
| **Cloudflare Tunnel** | 免費 | 中等 | 極高（零信任） | 高 | 需自有網域 |
| **ngrok** | 免費（有限） | 極簡 | 中 | 低（2hr 過期） | 臨時測試 |
| **Port Forwarding** | 免費 | 複雜 | 低 | 依 ISP | 不推薦 |

### Tailscale 設定步驟（推薦）

Tailscale 是基於 WireGuard 的零設定 VPN，像用一條網路線把 iPhone 和 Mac 連在一起。

#### Mac 端

```bash
# 方法 A：Homebrew 安裝
brew install --cask tailscale

# 方法 B：Mac App Store 下載 Tailscale

# 安裝後：
# 1. 開啟 Tailscale
# 2. 登入（Google/Microsoft/GitHub 帳號）
# 3. 記下分配的 IP（如 100.64.0.1）
```

#### iPhone 端

1. App Store 搜尋「Tailscale」並安裝
2. 使用**相同帳號**登入
3. 允許 VPN 設定
4. 完成！iPhone 和 Mac 已在同一虛擬網路

#### 連線使用

```bash
# SSH 連線（使用 Tailscale IP）
ssh username@100.64.0.1

# VNC 連線
# 在 VNC 客戶端輸入 100.64.0.1:5900
```

**免費版限制**：3 個使用者、100 台裝置 — 個人使用完全足夠。

### Cloudflare Tunnel 設定步驟（免費，需網域）

```bash
# 1. 安裝 cloudflared
brew install cloudflared

# 2. 登入
cloudflared tunnel login

# 3. 建立隧道
cloudflared tunnel create my-mac

# 4. 設定 SSH 存取
cloudflared tunnel --hostname ssh.yourdomain.com --url ssh://localhost:22

# 5. 安裝為系統服務
sudo cloudflared service install
```

---

## 推薦組合方案

### 方案 A：完全免費（$0/月）

```
SSH 客戶端：Moshi（免費，專為 Claude Code 設計）
遠端存取：Tailscale 免費版
會話管理：tmux
編輯器：vim / nano
遠端桌面：Chrome Remote Desktop（備用）
```

**設定步驟**：
1. Mac：啟用 SSH + 安裝 Tailscale + 安裝 tmux
2. iPhone：安裝 Moshi + Tailscale
3. 連線：`ssh user@[Tailscale IP]` → `tmux attach` → `claude`

**適合**：學生、個人開發者、預算有限

---

### 方案 B：經濟實惠（$12.99 一次）

```
SSH 客戶端：WebSSH PRO（$12.99 買斷，全 Apple 平台）
遠端存取：Tailscale 免費版
會話管理：tmux
遠端桌面：Chrome Remote Desktop（備用）
```

**優勢**：一次購買、iPhone/iPad/Mac 共用、終身更新

---

### 方案 C：專業開發（$24.99/年）

```
SSH 客戶端：Moshi 或 Termius
遠端存取：Tailscale 免費版
遠端桌面：Screens 5（$24.99/年）
會話管理：tmux
```

**優勢**：SSH + GUI 雙管齊下，適合需要 IDE 的場景

---

### 方案 D：AI 開發者（$100-200/月）

```
核心：Claude Code Remote Control（需 Max 訂閱）
備用 SSH：Moshi + Tailscale
備用 GUI：Screens 5 或 Chrome Remote Desktop
```

**優勢**：原生 Claude Code 體驗、MCP servers 全部可用、語音模式

---

### 方案 E：終身買斷（$99-174 一次）

```
SSH 客戶端：Prompt 3（$99 買斷）
遠端桌面：Screens 5（$74 買斷）
遠端存取：Tailscale 免費版
會話管理：tmux
```

**適合**：不喜歡訂閱制的使用者

---

### 5 年成本比較

| 方案 | 初期成本 | 年度成本 | 5 年總計 |
|------|---------|---------|---------|
| **A: 免費** | $0 | $0 | **$0** |
| **B: 經濟** | $12.99 | $0 | **$12.99** |
| **C: 專業** | $0 | $24.99 | **$124.95** |
| **D: AI 開發** | $0 | $1,200-2,400 | **$6,000-12,000** |
| **E: 買斷** | $173 | $0 | **$173** |

---

## 硬體建議

### 必備

| 設備 | 推薦 | 理由 |
|------|------|------|
| **藍牙鍵盤** | Apple Magic Keyboard / Logitech Keys-To-Go 2 | SSH 操作的核心工具，虛擬鍵盤效率太低 |
| **行動電源** | 10000mAh+ | 長時間 SSH/VNC 連線耗電 |

### 選配

| 設備 | 推薦 | 理由 |
|------|------|------|
| **藍牙滑鼠** | Logitech Pebble 2 | VNC 操作精確度大幅提升 |
| **手機支架** | 隨意 | 長時間使用減輕手臂負擔 |
| **iPad** | iPad Air / Pro | 更大螢幕、支援 Stage Manager 和外接顯示器 |

---

## 常見問題 FAQ

### Q1：用手機寫 Code 實際嗎？

**答**：取決於使用場景。
- **適合**：緊急 bug 修復、審核 PR、監控 CI/CD、Claude Code AI 輔助開發
- **不適合**：長時間大型開發（螢幕小、觸控精度差）
- **建議**：搭配藍牙鍵盤，體驗提升 10 倍

### Q2：SSH 和 VNC 該選哪個？

**答**：
- **CLI 操作（Claude Code、git、vim）**→ SSH（頻寬低、延遲低、更流暢）
- **GUI 操作（VS Code、Xcode、瀏覽器）**→ VNC（能看到完整桌面）
- **最佳方案**：兩者都設定，按需切換

### Q3：Claude Code Remote Control vs SSH，哪個更好？

**答**：
- **Remote Control** 提供原生 Claude Code 體驗，支援 MCP servers、語音模式，但需要 Max 訂閱 ($100+/月)
- **SSH + tmux** 完全免費，功能一樣完整，但操作稍不方便（純文字介面）
- **建議**：有 Max 訂閱就用 Remote Control，沒有就用 SSH + tmux

### Q4：行動網路連線穩定嗎？

**答**：
- **SSH**：極穩定，128Kbps 即可流暢。使用 Mosh 協定可抗網路切換和斷線
- **VNC**：需要較好的網路。4G 可用但有延遲，5G/Wi-Fi 最佳
- **建議**：搭配 tmux（SSH）或自動重連功能（VNC）

### Q5：安全性如何？

**答**：
- **SSH 金鑰驗證** + **Tailscale VPN** = 企業級安全
- **Remote Control** 使用端到端加密，僅出站 HTTPS
- **VNC 裸連網際網路** = 極不安全（務必用 VPN 或 SSH Tunnel）

### Q6：Mac 休眠了怎麼辦？

**答**：
- **SSH**：Mac 休眠後 SSH 斷線但 tmux 會話保留，喚醒後重連
- **VNC**：Mac 休眠後完全無法連線
- **解決**：設定「永不休眠」或啟用 Wake-on-LAN
- **遠端喚醒**：先 SSH 連入（若 SSH 仍在），執行 `caffeinate -u -t 3600`

---

## 資料來源

### Claude Code Remote Control
- [Anthropic 官方文件 - Remote Control](https://code.claude.com/docs/en/remote-control)
- [VentureBeat - Anthropic 發布 Remote Control](https://venturebeat.com/orchestration/anthropic-just-released-a-mobile-version-of-claude-code-called-remote)
- [TechCrunch - Voice Mode 推出](https://techcrunch.com/2026/03/03/claude-code-rolls-out-a-voice-mode-capability/)
- [MacStories - Remote Control 上手體驗](https://www.macstories.net/stories/hands-on-with-claude-code-remote-control/)
- [Simon Willison - Remote Control 分析](https://simonwillison.net/2026/Feb/25/claude-code-remote-control/)
- [DevOps.com - 安全架構解析](https://devops.com/claude-code-remote-control-keeps-your-agent-local-and-puts-it-in-your-pocket/)

### SSH 客戶端與設定
- [Apple Support - 遠端登入](https://support.apple.com/guide/mac-help/allow-a-remote-computer-to-access-your-mac-mchlp1066/mac)
- [Moshi - AI 編碼專用終端機](https://getmoshi.app)
- [Termius 官網](https://termius.com/pricing)
- [WebSSH 官網](https://webssh.net/)
- [Blink Shell 官網](https://blink.sh/)
- [Prompt 3 by Panic](https://panic.com/prompt/)
- [Secure ShellFish 官網](https://secureshellfish.app/)
- [SSH 安全強化 2025](https://www.msbiro.net/posts/back-to-basics-sshd-hardening/)

### 遠端桌面
- [Apple Support - 螢幕共享](https://support.apple.com/guide/mac-help/turn-screen-sharing-on-or-off-mh11848/mac)
- [Chrome Remote Desktop 設定指南](https://www.helpwire.app/blog/chrome-remote-desktop-ios/)
- [Screens 5 官網](https://apps.apple.com/us/app/screens-5-vnc-remote-desktop/id1663047912)
- [Jump Desktop 官網](https://jumpdesktop.com/)
- [Splashtop 官網](https://www.splashtop.com/pricing)
- [RealVNC 官網](https://www.realvnc.com/en/connect/pricing/)

### 網路穿透
- [Tailscale 官網](https://tailscale.com/)
- [ZeroTier 官網](https://www.zerotier.com/pricing/)
- [Cloudflare Tunnel 文件](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)
- [Tailscale vs ngrok 比較](https://tailscale.com/compare/ngrok)

### 實戰經驗
- [用 iPhone 當 SSH Client 寫程式的體驗](https://big-ears.medium.com/coding-with-your-phone-experience-with-iphone-12-pro-max-as-a-ssh-client-b967a752fe2d)
- [用 Tailscale + Termius + tmux 從 iPhone 跑 Claude Code](https://petesena.medium.com/how-to-run-claude-code-from-your-iphone-using-tailscale-termius-and-tmux-2e16d0e5f68b)
- [Claude Code 在手機上更好用](https://harper.blog/2026/01/05/claude-code-is-better-on-your-phone/)
- [NxCode - Remote Control 完整設定教學](https://www.nxcode.io/resources/news/claude-code-remote-control-mobile-terminal-handoff-guide-2026)
