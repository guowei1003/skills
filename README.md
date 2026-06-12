# Agent Skills 技能库

个人常用的 [Cursor Agent Skills](https://cursor.com/docs/context/skills) 集合。每个技能是一组结构化指令，教 AI 助手按固定流程完成特定任务——减少重复说明，让协作更稳定、可复现。

## 技能索引

| 技能 | 说明 | 触发场景 |
|------|------|----------|
| [create-git-worktree](./create-git-worktree/) | 在 `.worktrees/` 下创建隔离 Git worktree | 创建 worktree、基于某分支开 worktree、并行开发 |

## 目录结构

```
skills/
├── README.md
└── <skill-name>/
    ├── SKILL.md              # 技能主文件（必需）
    ├── reference.md          # 详细参考（可选）
    └── scripts/              # 配套脚本（可选）
        └── ...
```

## 安装方式

### 方式一：符号链接（推荐）

适合本仓库持续更新、技能与个人目录保持同步的场景：

```bash
# 克隆本仓库
git clone <本仓库 URL> ~/github/skills

# 将单个技能链接到 Cursor 技能目录
ln -sf ~/github/skills/create-git-worktree ~/.cursor/skills/create-git-worktree

# 为脚本添加执行权限
chmod +x ~/.cursor/skills/create-git-worktree/scripts/create-worktree.sh
```

### 方式二：直接复制

适合只需一次性部署、不跟踪上游更新的场景：

```bash
cp -r create-git-worktree ~/.cursor/skills/
chmod +x ~/.cursor/skills/create-git-worktree/scripts/*.sh
```

### 方式三：项目级技能

若希望团队共享，可将技能放到目标项目的 `.cursor/skills/` 下：

```bash
mkdir -p /path/to/your-project/.cursor/skills
cp -r create-git-worktree /path/to/your-project/.cursor/skills/
```

## 使用教程

### 在 Cursor 中自动触发

安装后，Cursor Agent 会根据 `SKILL.md` 头部的 `description` 字段自动判断是否启用技能。你也可以在对话中直接说明意图，例如：

- 「基于 `feat-auth` 分支创建 worktree」
- 「新建一个 worktree 做并行开发」

### 手动调用脚本

部分技能附带可独立运行的脚本，不依赖 Agent 也能使用。以 `create-git-worktree` 为例：

```bash
# 基于已有分支创建 worktree
~/.cursor/skills/create-git-worktree/scripts/create-worktree.sh --from-branch feat-auth

# 基于 main（或默认分支）新建 main_01、main_02 … 分支与 worktree
~/.cursor/skills/create-git-worktree/scripts/create-worktree.sh --new
```

创建结果位于目标仓库的 `.worktrees/<分支名>/`，脚本会自动检查并在必要时向 `.gitignore` 追加 `.worktrees/`。

### 验证技能已加载

1. 打开 Cursor Settings → Rules / Skills，确认技能出现在列表中
2. 在 Agent 对话中提及触发词，观察 Agent 是否按技能流程执行
3. 若未生效，检查路径是否为 `~/.cursor/skills/<skill-name>/SKILL.md`（注意不是 `~/.cursor/skills-cursor/`，后者为 Cursor 内置技能目录）

## 技能规范

本仓库中的技能遵循以下约定：

- **命名**：目录名与 frontmatter 中的 `name` 一致，使用 kebab-case
- **描述**：`description` 写清「做什么」和「何时用」，便于 Agent 自动匹配
- **脚本**：放在 `scripts/` 下，路径在 `SKILL.md` 中以 `<skill-root>` 相对引用
- **语言**：工作流说明使用简体中文，命令与代码保持英文

## 贡献与维护

新增技能时：

1. 在本仓库根目录创建 `<skill-name>/SKILL.md`
2. 更新本 README 的「技能索引」表格
3. 如有脚本，确保可执行权限并在技能文档中写明用法
4. 通过符号链接或复制安装到 `~/.cursor/skills/` 后实测

## 相关链接

- [Git worktree 文档](https://git-scm.com/docs/git-worktree)
