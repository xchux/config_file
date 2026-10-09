# ai-center

通用 AI coding agent 設定：一份規則 / skills / agents / MCP，對應到各 CLI 與 IDE 的格式。

## 目錄結構

```
ai-center/
├── AGENTS.md                 # 共用全域指令（所有工具共用的單一來源）
├── mcp/servers.json          # MCP server 清單（canonical）：context7 / sequential-thinking / playwright / fetch / github / brave-search
├── skills/                   # 個人 Agent Skills（ECC 沒有的才放這裡）
│   ├── acquire-codebase-knowledge/  # 產出 docs/codebase/ 七份文件（vendored，見下方來源）
│   └── system-design-diagram/       # Mermaid 架構 / 系統設計圖
├── agents/codex/*.toml       # Codex subagents（~/.codex/agents；ECC Codex plugin 不含 agents）
├── claude/                   # Claude Code
│   ├── settings.json         #   ~/.claude/settings.json（權限、ruff hook）
│   ├── CLAUDE.md             #   ~/.claude/CLAUDE.md（@import AGENTS.md）
│   └── mcp.json              #   .mcp.json 格式；install.sh 以 `claude mcp add-json -s user` 註冊
├── codex/config.toml         # ~/.codex/config.toml（Codex 只支援 TOML）
├── agy/rules/                # agy / Antigravity workspace rules（複製到 <repo>/.agents/rules/）
├── ide/
│   ├── vscode/               #   settings.json / mcp.json / extensions.json
│   └── cursor/               #   mcp.json (~/.cursor/mcp.json) + rules/*.mdc
├── ecc/                      # ECC 多 AI 安裝（版本 + 模組選擇單一來源）
│   ├── ecc-install.json
│   └── ecc.sh
└── install.sh                # 建立 symlink（會先備份既有檔案）
```

## 安裝

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx   # 建議寫進 ~/.zshrc
export BRAVE_API_KEY=xxx                      # https://api-dashboard.search.brave.com（免費額度）
./install.sh --dry-run          # 先預覽
./install.sh                    # 全部
./install.sh claude             # 只裝單一工具：claude|codex|agy|cursor
```

需求：`node`/`npx`（多數 MCP）、`uv`/`uvx`（fetch MCP）、`python3`（hook 與 Claude / agy MCP 註冊）。

## 各工具對照

| | 全域指令 | Skills | Subagents | MCP 設定 | MCP 遠端欄位 / 環境變數語法 |
|---|---|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/` | `~/.claude/agents/*.md` | `~/.claude.json`（CLI 管理）/ 專案 `.mcp.json` | `"type":"http","url"` / `${VAR}` |
| Codex CLI | `~/.codex/AGENTS.md` | `~/.agents/skills/` | `~/.codex/agents/*.toml` | `~/.codex/config.toml` `[mcp_servers.x]` | `url` + `bearer_token_env_var` |
| VS Code (Copilot) | `AGENTS.md`（`chat.useAgentsMdFile`） | `chat.useAgentSkills` | — | `.vscode/mcp.json` **`servers`** | `"type":"http","url"` / `${input:id}`、`${env:VAR}` |
| Cursor | `AGENTS.md` / `.cursor/rules/*.mdc` | — | — | `~/.cursor/mcp.json` | `url` / `${env:VAR}` |
| agy / Antigravity | `~/.gemini/config/AGENTS.md`、`.agents/rules/` | `~/.gemini/config/skills/` | — | `~/.gemini/config/mcp_config.json`（`agy mcp add` 寫入） | `url`（舊 `serverUrl`）/ 不支援變數 |

## ECC：一處維護、多 AI 共享

分兩層，各自只有一個維護點：

| 層 | 內容 | 唯一維護點 |
|---|---|---|
| 上游共用庫 | [ECC](https://github.com/affaan-m/ECC) 的 agents / skills / rules / hooks | `ecc/ecc.sh` 的 `ECC_VERSION` + `ecc/ecc-install.json`（模組選擇） |
| 個人層 | 只放 ECC 沒有的個人偏好：規則、MCP、Codex agents | `AGENTS.md`、`skills/`、`agents/`、`mcp/servers.json` → `install.sh` |

ECC 不複製進本 repo，由各 AI 原生機制安裝；升級只改 `ECC_VERSION` 後重跑。

| AI | ECC 安裝方式 | 範圍 | 支援程度 |
|---|---|---|---|
| Claude Code | 原生 plugin（`claude/settings.json` 已宣告 `ecc@ecc`） | 使用者 | 完整（含 hooks） |
| Codex | 原生 plugin `codex plugin add ecc@ecc` | 使用者 | 完整（hooks 需在 Codex 內信任） |
| Cursor | `ecc install --target cursor` → `.cursor/` | 專案 | rules / agents / skills |
| agy / Antigravity | `ecc install --target antigravity` → `.agents/` | 專案 | rules / agents / skills |

```bash
./ecc/ecc.sh home                              # Claude + Codex（每台機器一次）
./ecc/ecc.sh --dry-run project ~/work/my-repo  # 預覽專案層（cursor antigravity）
./ecc/ecc.sh project ~/work/my-repo cursor     # 只裝指定 AI
./ecc/ecc.sh doctor ~/work/my-repo             # 檢查
```

調整要裝哪些 ECC 模組：改 `ecc/ecc-install.json` 的 `profile`（`minimal` / `core` / `full`）與
`include` / `exclude`（如 `lang:python`、`framework:django`、`capability:security`），所有專案層 AI 同步套用。

注意：
- ECC 的 GateGuard hook（Claude）會在首次寫檔前要求說明；嫌干擾可在 `claude/settings.json` 的 `env` 加 `"ECC_GATEGUARD": "off"`。
- ECC 自帶 `chrome-devtools` MCP；若不需要，安裝前 `export ECC_DISABLED_MCPS=chrome-devtools`。
- 專案層 adapter 會寫入 `.cursor/`、`.agents/`，要決定是否 commit；agy / Antigravity 的 `.agents/` 不可被 `.gitignore` 忽略，否則不會載入。
- 個人 skills 與 ECC skills 同名不衝突：Claude / Codex 中 ECC 以 `ecc:` 命名空間載入。

## 注意事項

- **機密**：所有設定只用環境變數佔位，不要把 token 寫進 repo。agy 的 `mcp_config.json` 不支援變數展開，因此 `install.sh agy` 以 `agy mcp add` 註冊、在安裝當下展開 `${GITHUB_PERSONAL_ACCESS_TOKEN}`（token 只存在 `~/.gemini/config/`；換 token 後重跑 `./install.sh agy`，未設定時跳過 github）。
- **Codex 沒有 JSON 設定**：官方只吃 `config.toml`。
- **VS Code 系 IDE 共用 settings**：Cursor、Antigravity 都是 VS Code fork，`ide/vscode/settings.json` 可直接貼到它們的 User settings（WSL 下位於 Windows 端 `%APPDATA%\<Code|Cursor|Antigravity>\User\settings.json`）。
- **新增 MCP server**：先改 `mcp/servers.json`，再同步到 `claude/mcp.json`、`codex/config.toml`、`ide/*/` 各檔（注意欄位名差異，見上表）；agy 由 `install.sh` 直接讀 `mcp/servers.json`，免改。
- **新增 skill**：在 `skills/<name>/SKILL.md` 加 frontmatter（`name`、`description`），重跑 `./install.sh`。
- **Vendored skill**：`skills/acquire-codebase-knowledge` 複製自 [github/awesome-copilot](https://github.com/github/awesome-copilot/tree/main/skills/acquire-codebase-knowledge)（MIT，commit `143a3d9`，v1.3）；更新時重新複製該目錄。與 ECC 的 `codebase-onboarding` 功能相近，差在它會產出固定七份 `docs/codebase/*.md`。
- agy / Antigravity IDE 共用 `~/.gemini/config/`，`./install.sh agy` 一次設定兩者；專案的 `.agents/` 若被 `.gitignore` 忽略，rules / skills 不會載入。
