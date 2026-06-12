---
name: create-git-worktree
description: 在当前 Git 仓库的 .worktrees/ 目录下创建隔离 worktree。检测是否为 Git 仓库（非 Git 则中断），根据用户意图选择已有分支或新建 main_XX 分支，并确保 .gitignore 包含 .worktrees。当用户说创建 worktree、基于某分支创建 worktree、新建 worktree 时使用。
---

# 创建 Git Worktree

**开始时宣布：**「我正在使用 create-git-worktree 技能创建隔离 worktree。」

## 前置检查（必须）

1. 确认当前工作区在 Git 仓库内：

```bash
git rev-parse --git-dir >/dev/null 2>&1
```

**若失败：** 告知用户「当前目录不是 Git 仓库」，**立即中断**，不执行后续步骤。

2. 获取仓库根目录：

```bash
git rev-parse --show-toplevel
```

所有 worktree 创建在 `<repo-root>/.worktrees/` 下。

## 解析用户意图

根据用户描述选择模式：

| 用户表述示例 | 模式 | 行为 |
|-------------|------|------|
| 基于 xxx 分支创建 worktree | `--from-branch` | 目录名 = `xxx`，检出已有分支 `xxx` |
| 从 xxx 分支创建 worktree | `--from-branch` | 同上 |
| 创建一个新的 worktree | `--new` | 新建 `main_01`（或递增 `main_02`…），基于最新 `main` |
| 新建 worktree / 开个 worktree | `--new` | 同上 |

### 分支名提取（--from-branch）

从用户输入中提取分支名，常见模式：

- `基于 <branch> 分支`
- `从 <branch> 分支`
- `checkout <branch> 的 worktree`

提取失败时，向用户确认分支名后再继续。

### 新 worktree（--new）规则

1. 分支名：`main_01`、`main_02`… 取第一个未被占用的编号（分支或 `.worktrees/main_XX` 目录已存在则递增）。
2. 基准分支：优先 `main`；若无 `main`（本地或 `origin/main`），使用仓库默认分支（`origin/HEAD` → `init.defaultBranch` → 回退 `main`）。
3. 创建前 `git fetch origin <base>`，基于最新远程基准创建。

## 执行脚本（推荐）

优先执行 bundled 脚本，避免手写命令偏差。脚本位于本技能目录下的 `scripts/create-worktree.sh`：

```bash
# 基于已有分支
<skill-root>/scripts/create-worktree.sh --from-branch <branch>

# 新建 worktree
<skill-root>/scripts/create-worktree.sh --new
```

安装到 Cursor 后，`<skill-root>` 通常为 `~/.cursor/skills/create-git-worktree`。

在仓库根目录或任意子目录执行均可（脚本内部会解析 `git rev-parse --show-toplevel`）。

## .gitignore 检查

脚本会自动处理；若手动创建，必须验证：

```bash
git check-ignore -q .worktrees
```

未被忽略时，在 `.gitignore` 追加：

```gitignore
.worktrees/
```

**不要自动提交** `.gitignore` 变更，除非用户明确要求。

## 完成后报告

```
worktree 已就绪：<绝对路径>
分支：<branch>
基准：<base-ref>（--new 模式）
```

若用户需要在新 worktree 中继续开发，提示其 `cd` 到该路径。

## 错误处理

| 情况 | 处理 |
|------|------|
| 非 Git 仓库 | 中断，不创建 |
| 目标目录已存在 | 报告路径，询问是否换名或清理 |
| 分支不存在 | 报告分支名，建议 `git branch -a` 核对 |
| worktree 已绑定该分支 | 报告 `git worktree list`，不重复创建 |

## 示例

**示例 1**

```
用户：基于 feat-dev-ai 分支创建 worktree
```

```bash
<skill-root>/scripts/create-worktree.sh --from-branch feat-dev-ai
```

→ `.worktrees/feat-dev-ai`，检出 `feat-dev-ai`

**示例 2**

```
用户：创建一个新的 worktree
```

```bash
<skill-root>/scripts/create-worktree.sh --new
```

→ `.worktrees/main_01`，新分支 `main_01`，基于最新 `main`（或默认分支）

## 红线

- **绝不**在非 Git 目录继续执行
- **绝不**跳过 `.gitignore` 检查
- **绝不**在未确认时覆盖已有 worktree 目录
- **始终**用分支名作为 `.worktrees/` 下的目录名
