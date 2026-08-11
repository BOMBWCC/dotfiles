# bombwcc/dotfiles

使用 [Chezmoi](https://www.chezmoi.io/) 管理的个人终端配置，支持 macOS、Ubuntu 和 Debian 12。Linux 安装器会读取 `/etc/os-release`；其他 Linux 发行版会在修改软件包前明确退出。核心环境保持轻量，开发语言、AI Agent、服务器服务和 macOS 应用通过扩展按需安装。

## 快速开始

在新机器上一条命令安装 Chezmoi、克隆并应用配置：

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply BOMBWCC
```

应用后，选择一个安装档位：

```sh
# 先预览，不执行安装
dotfiles-install --dry-run minimal

# 最小可用终端环境
dotfiles-install minimal

# 最小环境 + 全部通用 CLI
dotfiles-install full
```

安装完成后重新打开终端。需要时将 Zsh 设为默认 Shell：

```sh
chsh -s "$(command -v zsh)"
```

> 私有仓库或已配置 GitHub SSH 的机器可改用 `git@github.com:BOMBWCC/dotfiles.git`。

## 安装档位

所有安装命令都可以重复执行。以后某个档位加入了新工具，更新仓库后重新运行同一命令即可补装；软件升级仍由 `brew upgrade`、`apt upgrade` 等包管理器负责。

### `minimal`

面向低配 VPS 和新机器的最小可用 Shell 环境。

| macOS | Ubuntu 和 Debian 12 |
| --- | --- |
| Git、wget、Nano、jq、ripgrep | ca-certificates、Zsh、Git、curl、wget、unzip、Nano、jq、ripgrep、rsync、OpenSSH Client、tmux |
| Starship、btop、fastfetch | Starship、zoxide、fastfetch |
| eza、bat、fd、procs、zoxide、fzf | 仓库可用时安装 btop、bat、fd、eza、procs、fzf |

macOS 使用系统自带的 Zsh、curl、SSH、rsync 等基础命令，因此不会重复安装。Ubuntu 和 Debian 12 会为 `batcat` 和 `fdfind` 创建兼容命令 `bat`、`fd`。Debian 12 只使用已经配置的 APT 仓库；不会添加 backports 或第三方软件源。仓库中没有的可选软件包会显示 `SKIP`，不会阻断其他安装步骤。

Zinit 只管理 Zsh 插件，并在首次启动 Zsh 时自动安装。当前插件包括 `zsh-completions`和 `fast-syntax-highlighting`；最小安装中的 fzf 可用时还会启用 `fzf-tab`。

### `full`

`full` 总是先执行 `minimal`，再安装通用增强工具：

```text
SQLite、7-Zip、yq、sd、broot、Yazi、lazygit、delta、GitHub CLI、
direnv、xh、gping、doggo、mdcat、tealdeer、FFmpeg、yt-dlp、Codex Security CLI
```

macOS 使用 Homebrew。Ubuntu 和 Debian 12 使用当前 APT 仓库；仓库中不存在的可选工具会显示 `SKIP`，不会阻断其他工具。Codex Security 会按需准备受支持的 Node.js 和 Python，再全局安装官方 `@openai/codex-security` 包。

### `extension`

扩展保持按需安装，不包含在 `full` 中：

```sh
dotfiles-install extension dev
dotfiles-install extension ai
dotfiles-install extension server
dotfiles-install extension mac
```

| 扩展 | 平台 | 当前内容 |
| --- | --- | --- |
| `dev` | macOS、Ubuntu 和 Debian 12 | Python、uv、fnm、Node.js LTS、Rust/Cargo、tree-sitter |
| `ai` | macOS、Ubuntu 和 Debian 12 | Codex CLI、Claude Code、Oh My Pi、Herdr；macOS 另含 CodexBar |
| `server` | Ubuntu 和 Debian 12 | OpenSSH Server、vnStat、fail2ban、UFW，以及仓库可用时的 Docker/Compose/Buildx |
| `mac` | macOS | Ghostty、Docker Desktop、MesloLG Nerd Font、Noto Serif CJK SC、CodexBar、Squirrel/Rime |

AI 扩展中的 Codex CLI 和 Claude Code 依赖 Node.js/npm，先执行 `dotfiles-install extension dev` 并重新打开 Zsh。安装结束后重新打开 Zsh，或执行 `exec zsh`，即可加载 fnm 和用户命令目录。服务器扩展不会显式调用服务启用或启动命令，也不修改防火墙规则；但 Debian 软件包的默认行为仍可能启用或启动服务。

## 安装器结构

Chezmoi 将安装器应用到：

```text
~/.local/bin/dotfiles-install
~/.local/lib/bombwcc-dotfiles/
├── common.sh          # 平台检测、dry-run、APT/Homebrew 等公共能力
├── installers/        # 非普通系统包的专用安装器
├── profiles/          # minimal 与 full
└── extensions/        # dev、ai、server、mac
```

安装来源约定：

- 普通 CLI：APT 或 Homebrew；
- Zsh 插件：Zinit；
- 系统仓库不适合的工具：`installers/` 中的官方脚本或 GitHub Release；
- 开发、AI、服务器及 macOS 专属内容：对应 extension。

一个工具只保留一个主要安装来源，避免与 Zinit、APT、Homebrew 重复安装。

安装结束时会输出英文状态摘要，含义如下：

```text
Ready    command is available after the run
Missing  command is still unavailable
Planned  dry-run installation plan; no readiness claim
SKIP     optional package or platform action was not performed
```

## 管理配置

仓库通过 `.chezmoiroot` 将 `home/` 指定为 Chezmoi 源目录。常用操作：

```sh
chezmoi diff       # 查看将要应用的变化
chezmoi apply      # 应用配置
chezmoi update     # 拉取远端并应用
chezmoi cd         # 进入本地源仓库
```

主要配置包括 Zsh、Git、Starship、tmux、Nano、ripgrep、bat、btop、fastfetch、Ghostty 和 macOS Rime。

### 本机私有配置

机器差异和敏感环境变量放入未纳入 Git 的：

```text
~/.zshrc.local
```

可参考：

```text
~/.config/zsh/private.zsh.example
```

认证文件、API Key、SSH 私钥、GitHub hosts、Codex/Claude 登录数据和 Docker Registry 凭据不应提交。

## Ghostty 与 SSH

macOS Ghostty 配置位于：

```text
~/.config/ghostty/config.ghostty
```

配置启用了：

```ini
shell-integration-features = no-cursor,ssh-env,ssh-terminfo
```

Ghostty 会包装交互式 `ssh`，首次连接时给缺少 `xterm-ghostty` 的远端安装 terminfo；失败时回退到 `xterm-256color`。这可避免远端 Zsh 出现退格方向错误、光标重绘异常等问题。

## 主题

终端配色统一使用 Gruvbox Dark Hard，并为 Starship、Nano、bat、btop、fastfetch 和 Ghostty提供对应配置。颜色约定见 [`themes/gruvbox/color-system.md`](themes/gruvbox/color-system.md)。

## 测试

```sh
sh tests/test-dotfiles-install.sh
sh tests/test-git-pager.sh
sh tests/test-nano-config.sh

# 需要 Docker 和网络访问
sh tests/test-debian-12-install.sh

# 检查安装计划
dotfiles-install --dry-run --os macos full
dotfiles-install --dry-run --os linux minimal
```

安装器使用 POSIX shell 编写。提交前还应执行：

```sh
sh -n home/dot_local/bin/executable_dotfiles-install
chezmoi --source "$PWD" managed
chezmoi --source "$PWD" apply --dry-run --verbose
```

## 说明

这是个人配置仓库，默认选择和快捷键带有明显个人偏好。运行 `chezmoi diff` 和 `dotfiles-install --dry-run ...` 后再应用到已有环境。
