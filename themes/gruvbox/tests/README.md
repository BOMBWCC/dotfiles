# Nano 与 bat 配色测试

这些样本按照文件扩展名触发 Nano 和 bat 对应的语法定义。

| 文件 | 主要测试元素 |
|---|---|
| `test.zsh` | Shell 注释、字符串、变量、数字、关键字、函数、命令、路径和参数 |
| `test-invalid.zsh` | Shell 非法语法和错误结构；仅查看，不要执行 |
| `test.py` | 布尔值、常量、类型提示、装饰器、函数、正则和转义 |
| `test.rs` | 类型、常量、属性、宏、模块和函数 |
| `test.html` | 标签、属性、字符串、注释和转义实体 |
| `test.patch` | Diff 文件头、区块、增加行和删除行 |

使用 bat 查看：

```sh
bat themes/gruvbox/tests/test.zsh
bat themes/gruvbox/tests/test-invalid.zsh
bat themes/gruvbox/tests/test.py
bat themes/gruvbox/tests/test.rs
bat themes/gruvbox/tests/test.html
bat themes/gruvbox/tests/test.patch
```

使用 Nano 查看时，把上面命令中的 `bat` 换成 `nano`。修改配色配置后重新打开文件即可看到效果。

Zsh 的交互式 FSH 效果不能通过静态文件完整复现。可以从 `test.zsh` 中逐行复制到命令行，对比相同元素。

## 覆盖情况

| 测试文件 | 覆盖的独立颜色角色 |
|---|---|
| `test.zsh` | 普通/二级注释、单/双引号字符串、Escape、Number、Variable、Assignment、Keyword、Function、Builtin、Alias 调用、Operator、三层 Bracket、Option、Test Option、Path、Directory、Environment、Executable、Unknown Command、Globbing、Redirection、History Expansion、Regex |
| `test-invalid.zsh` | Invalid；文件故意缺少右括号与 `fi`，不要执行 |
| `test.py` | 文档注释、Keyword、String、Escape、Number、Boolean、Language Constant、Variable、Assignment、Function、Type、Class、Annotation、Regex、Operator、Trailing Space |
| `test.rs` | 文档注释、Keyword、String、Escape、Number、Boolean、Constant、Function、Type、Class、Namespace、Macro、Annotation、Operator |
| `test.html` | Comment、Tag、Attribute、String、Language Constant/Entity |
| `test.patch` | Diff 新增、删除、区块和文件头 |

以下行为不能只靠静态文件完整验证：

- FSH 的 Executable、Unknown Command 和 Directory 依赖当前机器的真实环境。
- Nano 和 bat 不处理上一条命令的 Exit Code；Command Status 已从配色角色中排除。
- `test.py` 的 `Trailing spaces after this marker:` 行末保留了四个真实空格，用于检查 Nano 的行尾空格背景色；编辑器或格式化工具可能自动删除它。
