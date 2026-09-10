# 剧本审阅页（script_review）

给 owner 一个**像读剧本一样**过全部台词的页面：按游戏里的真实顺序（Ep0 → Ep1 → … → 功能节点 → 反应池），
每句台词旁边有「好 / 改 / 删」、评论框、和直接改字的编辑框。所有标记**自动存到云端**（Artifact 数据库），
手机电脑都能接着看；Claude 能把你的标记直接拉回来写进剧本。

取代 Codex 版 `tools/dialogue_viewer/`（那版是按节点 id 浏览的数据库视图，要手动加载 JSON、手动导出文件）。

## 流程

1. **生成页面**（每次改完剧本都重新生成，页面上会显示剧本版本和生成时间）
   ```
   powershell -File tools/godot_check/check.ps1 -Mode test -Scenario script_lint -Raw | Select-String '^    ! ' | % { $_ -replace '^    ! ','' } > tools/script_review/lint_latest.txt
   python tools/script_review/build.py
   ```
   （Claude 通常一起做；`lint_latest.txt` 是给每句台词挂上的机械检查结果，可选。）
2. **发布**：Claude 用 Artifact 工具发布 `review.html`，能力声明 `db`（存标记）+ `downloads`（备用导出）。
   同一条链接反复重发即可，标记不会丢。
3. **审阅**：打开链接，从上往下读。每个节点：
   - 点 **好 / 改 / 删**
   - 想说什么写评论框（失焦自动保存）
   - 想直接改字：点「改文字」，改完自动保存；原文会显示在下面做对照
   - 顶部可筛选：未看 / 标记改 / 标记删 / 有评论 / 有检查提示；也可以按剧集跳
4. **收回**：Claude 用 `read_db`（collection `review`，`out_dir` 存成一目录 JSON），然后
   ```
   python tools/script_review/apply.py <那个目录> --dry-run   # 先看会改什么
   python tools/script_review/apply.py <那个目录>             # 写入，自动备份
   ```
   - 「改」且文字有变 → 直接写进 `scripted_nodes.json` / `reactive_lines.json`
   - 「删」→ 不自动删（删节点会改分支图），打印成清单给剧本 session
   - 评论 → 打印成清单
5. 跑一遍 `check.ps1`（lint + 全套场景），再生成一次页面。

## 数据形状（云端每节点一份）

```
review/<node_id>  = { verdict: "keep"|"edit"|"cut"|"", comment, line|null, choices:{"0":"…"}, updated_at }
```
反应池的 id 是 `focus_click[3]` 这种。页面只写它自己这份文档，最后写入者赢；单个审阅者足够。

## 文件

- `build.py` — 数据组装 + 注入模板
- `template.html` — 页面（数据占位 `/*__DATA__*/null`）
- `review.html` — 生成物（可提交，方便对照；发布用的就是它）
- `apply.py` — 回写
- `lint_latest.txt` — 最近一次机械检查结果（生成物）
