# Gruvbox 统一配色系统

这张表是 Zsh、Nano 和 bat 的共同配色规划基准。识别能力以三者处理 **Zsh/Shell 内容** 时的行为为准。

- ✅：有相对明确、独立的识别规则
- ⚠️：只在部分上下文识别，或者与其他元素共用规则
- ❌：没有独立识别规则
- —：不是 Zsh/Shell 的语法元素
- “配色”暂时采用当前 `fast-syntax-highlighting` 默认主题在 Ghostty `Gruvbox Dark Hard` 下的显示颜色
- Shell 没有对应语义的配色暂时留空，等待后续选择

| 元素 | zsh FSH | Nano `zsh.nanorc` | bat Zsh 语法 | 示例 | 是否适合统一 | 配色 |
|---|---:|---:|---:|---|---|---:|
| Comment 注释 | ✅ | ✅ | ✅ | `# comment` | ✅ 必须统一 | `#928374` |
| String 字符串 | ✅ | ✅ | ✅ | `"hello"` | ✅ 必须统一 | `#d79921` |
| Variable 变量 | ✅，但当前未单独着色 | ⚠️ 只识别变量引用 | ✅ | `$HOME`、`${name}` | ✅ | `#ebdbb2` |
| Assignment 赋值 | ✅，但当前未单独着色 | ❌ | ✅ | `name=value` | ⚠️ | `#ebdbb2` |
| Number 数字 | ⚠️ 仅数学式、循环等上下文 | ✅ | ✅ | `123`、`3.14` | ✅ | `#b16286` |
| Boolean 布尔 | ❌，按命令或普通参数处理 | ❌，按命令或普通文本处理 | ❌，未作为布尔语义区分 | `true`、`false` | ❌ |  |
| Keyword 关键字 | ✅ | ✅ | ✅ | `if`、`for`、`case` | ✅ | `#d79921` |
| Function 函数 | ⚠️ 能识别命令位置和部分函数上下文 | ⚠️ 只匹配部分函数定义 | ✅ 函数定义 | `hello() {}` | ⚠️ | `#98971a` |
| Type 类型 | — | — | — | Shell 没有类型声明语法 | ❌ |  |
| Constant 常量 | ❌，按变量或普通文本处理 | ❌ | ❌ | `$PI` | ❌ |  |
| Operator 运算符 | ⚠️ 按数学、循环、重定向等上下文拆分 | ⚠️ 只匹配部分符号 | ✅，但多种符号可能共用颜色 | `=`、`+`、`=~` | ⚠️ | `#d79921`（部分） |
| Escape 转义 | ⚠️ 插件可处理部分字符串内部转义 | ❌，与字符串共用颜色 | ❌，当前 bat 主题中与字符串共用颜色 | `\n`、`\t` | ⚠️ | `#689d6a`（部分） |
| Regex 正则 | ❌，没有独立的正则颜色 | ❌ | ❌，`=~` 可识别但正则内容未单独着色 | `[[ $x =~ ^abc+$ ]]` | ❌ |  |
| Attribute 属性 | — | — | — | 不是 Shell 语法 | ❌ |  |
| Annotation 注解 | — | — | — | 不是 Shell 语法 | ❌ |  |
| Macro 宏 | — | — | — | 不是 Shell 语法 | ❌ |  |
| Namespace 模块 | — | — | — | 不是 Shell 语法 | ❌ |  |
| Tag 标签 | — | — | — | 不是 Shell 语法 | ❌ |  |
| Diff 增删 | — | — | — | 需要单独的 Diff/Patch 语法 | ❌ |  |
| Command 命令 | ✅，并检查命令是否存在 | ⚠️ 仅固定命令列表 | ✅ 按命令位置识别，不检查是否存在 | `git`、`docker`、`ls` | ✅ | `#98971a` |
| Builtin 内置命令 | ✅ | ✅，仅固定列表 | ❌，能作为命令着色但未独立分类 | `cd`、`export`、`source` | ⚠️ | `#98971a` |
| Alias 别名 | ✅，读取当前 Shell 别名 | ❌，只能识别 `alias` 关键字 | ❌，不能读取当前 Shell 别名 | `ll`、`catp` | ❌ | `#98971a` |
| Path 路径 | ✅，目录还能加下划线 | ❌ | ⚠️ 只识别 `~` 等少量结构 | `/home/user`、`~/file` | ⚠️ | `#b16286` |
| Option 参数 | ✅ | ⚠️ 只识别少量条件参数 | ❌，当前 Zsh 语法没有独立选项作用域 | `--help`、`-la` | ⚠️ | `#689d6a` |
| Error 错误 | ✅，未知命令与部分语法错误 | ❌ | ❌，只做静态语法着色 | 错误命令、非法表达式 | ❌ | `#fb4934`；普通数学错误为 `#cc241d` |

## 非 Shell 语义

Nano 和 bat 打开 Python、Rust、HTML、Diff 等文件时，还能识别类型、注解、宏、标签和增删行。这些元素没有对应的 Shell 配色，后续可以在同一 Gruvbox 色板中单独选择。

配套样本位于 [`tests`](tests/) 目录。



## 可独立配色能力

这里的勾只表示一件事：**当前高亮规则已经把该元素分成独立类别，可以只修改它的颜色而不连带修改其他类别。**

- `✓`：有独立的 FSH style、bat scope 或 Nano 正则规则
- `✗`：没有独立类别，当前与其他元素共用规则或根本无法识别
- 表中不使用“部分”；原本混合了多个识别能力的角色已拆成多行
- Nano 的 Shell 项目以当前加载的 `zsh.nanorc` 为准；非 Shell 项目以当前加载的 Python、Rust、HTML 和 Patch 语法为准
- “配色”以当前 FSH 在 Ghostty `Gruvbox Dark Hard` 下的实际显示为基准；Shell 没有的角色从剩余 Gruvbox 颜色中按语义补充

### 颜色分配说明

| 颜色 | 分配范围 | 预览时重点观察 |
|---|---|---|
| #ebdbb2 | 普通文本、变量、赋值、重定向 | 是否与终端默认前景一致，是否过亮 |
| #928374 | **仅用于注释** | 普通注释、文档注释是否清晰但不抢眼 |
| #d79921 | 关键字、字符串、运算符、Diff 变更 | 黄色使用范围较大，注意是否难以区分 |
| #689d6a | 转义、选项、正则、注解、Attribute | 水绿色是否适合修饰信息 |
| #b16286 | 数字、常量、Path | 紫色是否能快速定位数据和路径 |
| #98971a | 函数、命令、Builtin、Macro、Tag | 绿色是否能明确表达可执行或正常元素 |
| #b8bb26 | 第 1 层括号、Diff 新增 | 亮绿色是否过于醒目 |
| #cc241d | 非法语法、行尾空格、Diff 删除 | 红色是否能明确表达错误或删除 |
| #83a598 | Globbing、History、Type、Class、Namespace | 蓝色是否适合结构性和特殊元素 |
| #fabd2f | **仅用于 Shell 第 2 层括号** | 与第 1、3 层括号的区分度 |
| #8ec07c | **仅用于 Shell 第 3 层括号** | 与第 1、2 层括号的区分度 |
| #fb4934 | **仅用于 Shell Unknown Command** | 是否足够醒目，且不与普通 Invalid 混淆 |

### 通用文本与代码

| 颜色角色 | 元素/示例 | Shell FSH | bat | Nano | 配色 |
|---|---|:---:|:---:|:---:|---|
| 普通文本 Text | 未命中其他规则的文本 | ✓ | ✓ | ✓ | #ebdbb2 |
| 普通注释 Comment | `# comment`、`// comment` | ✓ | ✓ | ✓ | #928374 |
| 文档/二级注释 Documentation | `## comment`、`///`、`/** */` | ✗ | ✓ | ✓ | #928374 |
| 关键字 Keyword | `if`、`for`、`case`、`return` | ✓ | ✓ | ✓ | #d79921 |
| 单引号字符串 Single String | `'hello'` | ✓ | ✓ | ✓ | #d79921 |
| 双引号字符串 Double String | `"hello"` | ✓ | ✓ | ✓ | #d79921 |
| 转义字符 Escape | `\n`、`\t` | ✓ | ✓ | ✗ | #689d6a |
| 数字 Number | `123`、`3.14` | ✓ | ✓ | ✓ | #b16286 |
| 布尔值 Boolean | `true`、`false` | ✗ | ✓ | ✓ | #b16286 |
| 空值/语言常量 Language Constant | `null`、`None` | ✗ | ✓ | ✓ | #b16286 |
| 变量引用 Variable | `$HOME`、`${name}` | ✓ | ✓ | ✓ | #ebdbb2 |
| 赋值左侧 Assignment | `name=value` 中的 `name` | ✓ | ✓ | ✗ | #ebdbb2 |
| 函数定义 Function Definition | `hello() {}`、`def hello()` | ✓ | ✓ | ✓ | #98971a |
| 任意函数/命令调用 Function Call | `hello`、`git` 所在的调用位置 | ✓ | ✓ | ✗ | #98971a |
| 已知内置命令 Builtin | `cd`、`export`、`source` | ✓ | ✓ | ✓ | #98971a |
| Alias 调用 | 当前 Shell 中定义的 `ll`、`catp` | ✓ | ✗ | ✗ | #98971a |
| 通用运算符 Operator | `=`、`+`、`&&`、`=~` | ✓ | ✓ | ✓ | #d79921 |
| 普通括号 Bracket | 不区分嵌套层级的 `()`、`[]`、`{}` | ✗ | ✓ | ✗ | #b8bb26 |
| 第 1 层括号 Bracket Level 1 | 最外层括号 | ✓ | ✗ | ✗ | #b8bb26 |
| 第 2 层括号 Bracket Level 2 | 第二层嵌套括号 | ✓ | ✗ | ✗ | #fabd2f |
| 第 3 层括号 Bracket Level 3 | 第三层嵌套括号 | ✓ | ✗ | ✗ | #8ec07c |
| 正则表达式 Regex | `^abc+[0-9]$` | ✗ | ✓ | ✗ | #689d6a |
| 非法语法 Invalid | 静态语法可判定的非法符号或结构 | ✓ | ✓ | ✗ | #cc241d |
| 行尾空格 Trailing Space | 行尾多余空格 | ✗ | ✗ | ✓ | #cc241d |

### Shell 专属元素

| 颜色角色 | 元素/示例 | Shell FSH | bat | Nano | 配色 |
|---|---|:---:|:---:|:---:|---|
| 通用命令选项 Option | `--help`、`-la` | ✓ | ✓ | ✗ | #689d6a |
| 条件判断选项 Test Option | `-f`、`-d`、`-n`、`-z` | ✓ | ✓ | ✓ | #689d6a |
| Path | `/home/user`、`~/file` 的完整路径 | ✓ | ✗ | ✗ | #b16286 |
| Directory | 根据文件系统确认目标是目录 | ✓ | ✗ | ✗ | #b16286 + underline |
| Environment | `$HOME`、`$PATH`；实际使用变量规则 | ✓ | ✓ | ✓ | #ebdbb2 |
| Executable | 根据当前环境确认命令真实存在 | ✓ | ✗ | ✗ | #98971a |
| Unknown Command | 根据当前环境确认命令不存在 | ✓ | ✗ | ✗ | #fb4934 |
| Globbing | `*`、`?`、`[]` | ✓ | ✓ | ✗ | #83a598 |
| Redirection | `>`、`>>`、`<`、`2>`，与普通运算符分开 | ✓ | ✓ | ✗ | #ebdbb2 |
| History Expansion | `!!`、`!$` | ✓ | ✓ | ✗ | #83a598 |

`Command Status` 不属于语法高亮，已经排除在配色角色之外；当前由 Starship 提示符单独展示。

### 非 Shell 代码元素

| 颜色角色 | 元素/示例 | Shell FSH | bat | Nano | 配色 |
|---|---|:---:|:---:|:---:|---|
| 类型 Type | `int`、`String`、`usize` | ✗ | ✓ | ✓ | #83a598 |
| 类/接口 Class | `class Theme`、`interface App` | ✗ | ✓ | ✓ | #83a598 |
| 命名空间/模块 Namespace | `std::io`、模块名称 | ✗ | ✓ | ✗ | #83a598 |
| 宏 Macro | `println!()` | ✗ | ✓ | ✓ | #98971a |
| 注解/装饰器 Annotation | `@Override`、`@decorator` | ✗ | ✓ | ✓ | #689d6a |
| HTML/XML Tag | `<div>` | ✗ | ✓ | ✓ | #98971a |
| HTML/XML Attribute | `class="theme"` | ✗ | ✓ | ✓ | #689d6a |
| Diff 新增 Inserted | `+added line` | ✗ | ✓ | ✓ | #b8bb26 |
| Diff 删除 Deleted | `-removed line` | ✗ | ✓ | ✓ | #cc241d |
| Diff 区块 Changed | `@@ -1,2 +1,2 @@` | ✗ | ✓ | ✓ | #d79921 |
