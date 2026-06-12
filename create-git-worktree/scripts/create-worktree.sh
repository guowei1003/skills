#!/usr/bin/env bash
# 在 Git 仓库的 .worktrees/ 下创建 worktree。
# 用法:
#   create-worktree.sh --from-branch <branch>
#   create-worktree.sh --new
set -euo pipefail

MODE=""
BRANCH_ARG=""

usage() {
  cat <<'EOF'
用法:
  create-worktree.sh --from-branch <branch>   基于已有分支创建 worktree
  create-worktree.sh --new                    基于 main（或默认分支）创建 main_XX worktree
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from-branch)
      MODE="from-branch"
      BRANCH_ARG="${2:-}"
      shift 2
      ;;
    --new)
      MODE="new"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "错误: 必须指定 --from-branch 或 --new" >&2
  usage >&2
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "错误: 当前目录不是 Git 仓库，已中断。" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
WORKTREES_DIR="$REPO_ROOT/.worktrees"
GITIGNORE="$REPO_ROOT/.gitignore"

ensure_gitignore() {
  if git -C "$REPO_ROOT" check-ignore -q .worktrees 2>/dev/null; then
    return 0
  fi
  if [[ -f "$GITIGNORE" ]] && grep -qE '^\.worktrees/?$' "$GITIGNORE"; then
    return 0
  fi
  printf '\n.worktrees/\n' >> "$GITIGNORE"
  echo "已在 .gitignore 中添加 .worktrees/"
}

resolve_ref() {
  local branch="$1"
  if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
    echo "$branch"
    return 0
  fi
  git -C "$REPO_ROOT" fetch origin "$branch" --quiet 2>/dev/null || true
  if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    echo "origin/$branch"
    return 0
  fi
  return 1
}

get_base_branch() {
  if git -C "$REPO_ROOT" show-ref --verify --quiet refs/heads/main \
    || git -C "$REPO_ROOT" show-ref --verify --quiet refs/remotes/origin/main; then
    echo "main"
    return 0
  fi

  local default=""
  default="$(git -C "$REPO_ROOT" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
    | sed 's@^refs/remotes/origin/@@' || true)"
  if [[ -n "$default" ]]; then
    echo "$default"
    return 0
  fi

  local configured=""
  configured="$(git -C "$REPO_ROOT" config --get init.defaultBranch 2>/dev/null || true)"
  if [[ -n "$configured" ]]; then
    echo "$configured"
    return 0
  fi

  echo "main"
}

next_main_branch_name() {
  local n=1 candidate
  while true; do
    candidate="$(printf 'main_%02d' "$n")"
    if ! git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$candidate" \
      && [[ ! -d "$WORKTREES_DIR/$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
    n=$((n + 1))
  done
}

mkdir -p "$WORKTREES_DIR"
ensure_gitignore

if [[ "$MODE" == "from-branch" ]]; then
  if [[ -z "$BRANCH_ARG" ]]; then
    echo "错误: --from-branch 需要分支名称" >&2
    exit 1
  fi

  BRANCH="$BRANCH_ARG"
  WORKTREE_PATH="$WORKTREES_DIR/$BRANCH"

  if [[ -d "$WORKTREE_PATH" ]]; then
    echo "错误: worktree 目录已存在: $WORKTREE_PATH" >&2
    exit 1
  fi

  START_REF=""
  if ! START_REF="$(resolve_ref "$BRANCH")"; then
    echo "错误: 分支不存在（本地或 origin）: $BRANCH" >&2
    exit 1
  fi

  git -C "$REPO_ROOT" worktree add "$WORKTREE_PATH" "$BRANCH" 2>/dev/null \
    || git -C "$REPO_ROOT" worktree add -B "$BRANCH" "$WORKTREE_PATH" "$START_REF"

  echo "worktree 已创建: $WORKTREE_PATH"
  echo "分支: $BRANCH"
  echo "基于: $START_REF"
  exit 0
fi

BASE_BRANCH="$(get_base_branch)"
NEW_BRANCH="$(next_main_branch_name)"
WORKTREE_PATH="$WORKTREES_DIR/$NEW_BRANCH"

git -C "$REPO_ROOT" fetch origin "$BASE_BRANCH" --quiet 2>/dev/null || true

START_REF=""
if ! START_REF="$(resolve_ref "$BASE_BRANCH")"; then
  echo "错误: 无法解析基准分支: $BASE_BRANCH" >&2
  exit 1
fi

git -C "$REPO_ROOT" worktree add -b "$NEW_BRANCH" "$WORKTREE_PATH" "$START_REF"

echo "worktree 已创建: $WORKTREE_PATH"
echo "新分支: $NEW_BRANCH"
echo "基于: $START_REF ($BASE_BRANCH)"
