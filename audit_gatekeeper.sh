#!/bin/bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${BLUE}=== 🛡️  Release Gatekeeper: Approved PR Audit ===${NC}"
echo "Scanning for Approved PRs..."

# 1. 获取数据
# 关键字段：
# - mergeable: 能够直接判断是否有冲突 (MERGEABLE vs CONFLICTING)
# - headRefName: 分支名
DATA=$(gh pr list --search "is:open review:approved" \
  --json number,title,author,url,statusCheckRollup,mergeable,headRefName \
  --limit 30)

# 打印表头
printf "${GRAY}%-6s %-10s %-12s %-15s %s${NC}\n" "ID" "Result" "Conflict?" "Author" "Title / Action"
echo "--------------------------------------------------------------------------------"

# 2. 核心逻辑管道
echo "$DATA" | jq -r '
  .[] | 
  [
    .number,
    .mergeable,
    (if (.statusCheckRollup | length) > 0 then (.statusCheckRollup | map(.state) | .[0]) else "NO_CI" end),
    .author.login,
    .title
  ] | @tsv
' | while IFS=$'\t' read -r number mergeable ci_status author title; do

    # --- 逻辑层：多维审计 ---

    # Audit 1: 标题合规性检查 (Conventional Commits)
    # 规则：必须以 feat, fix, docs, style, refactor, perf, test, chore 开头
    if [[ "$title" =~ ^(feat|fix|docs|style|refactor|perf|test|chore)(\(.+\))?:.+ ]]; then
        is_naming_good=true
    else
        is_naming_good=false
    fi

    # Audit 2: 冲突与 CI 检查
    # 初始化状态
    status_icon="?"
    status_text="UNKNOWN"
    status_color="$GRAY"
    action_msg=""

    if [ "$mergeable" == "CONFLICTING" ]; then
        # 即使 Approved，有冲突也是最高级阻断
        status_text="BLOCKED"
        status_color="$RED"
        action_msg="${RED}✘ Conflict detected${NC}"
    
    elif [ "$ci_status" == "FAILURE" ]; then
        # CI 失败
        status_text="CI_FAIL"
        status_color="$RED"
        action_msg="${RED}✘ CI Failed${NC}"

    elif [ "$is_naming_good" = false ]; then
        # 技术上能合，但违反团队规范
        status_text="RENAME"
        status_color="$YELLOW"
        action_msg="${YELLOW}⚠ Bad Title (Not conventional)${NC}"

    else
        # 一切完美
        status_text="READY"
        status_color="$GREEN"
        action_msg="${GREEN}✔ Ready to merge${NC}"
    fi

    # 格式化 Mergeable 字段显示
    if [ "$mergeable" == "MERGEABLE" ]; then
        merge_display="Clean"
        merge_color="$GRAY"
    else
        merge_display="CONFLICT"
        merge_color="$RED"
    fi

    # --- 渲染层 ---
    # 截断标题用于展示，保留原始标题用于逻辑判断
    if [ "${#title}" -gt 40 ]; then
        display_title="${title:0:38}..."
    else
        display_title="$title"
    fi

    # 最终打印
    # 这里的价值在于：一眼看出"哪些能点按钮"，"哪些需要改标题"，"哪些需要修冲突"
    printf "#%-5s ${status_color}%-10s${NC} ${merge_color}%-12s${NC} %-15s %s\n" \
        "$number" \
        "$status_text" \
        "$merge_display" \
        "$author" \
        "$display_title"
    
    # 如果有问题，在下一行打印具体建议 (可选)
    if [ -n "$action_msg" ] && [ "$status_text" != "READY" ]; then
         printf "%-35s ↳ %b\n" "" "$action_msg"
    fi

done

echo -e "${BLUE}=== End of Audit ===${NC}"