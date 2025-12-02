#!/bin/bash

# 配置目标用户
TARGET_USER="Prorise-cool"

# 检查依赖工具
if ! command -v jq &> /dev/null; then
    echo "错误: 未安装 jq，请先安装。"
    exit 1
fi

echo "正在获取用户 $TARGET_USER 的所有开启 PR..."

# 1. 获取数据并存入数组
# 使用 base64 编码是为了处理标题中可能包含的空格或特殊字符，防止数组截断
raw_data=$(gh pr list --state open --json number,title,author --limit 50 | \
           jq -r ".[] | select(.author.login == \"$TARGET_USER\") | @base64")

# 2. 遍历处理
for item in $raw_data; do
    # 解码 JSON 对象
    _json=$(echo "$item" | base64 --decode)
    
    # 提取关键字段
    pr_number=$(echo "$_json" | jq -r '.number')
    pr_title=$(echo "$_json" | jq -r '.title')

    echo "----------------------------------------"
    echo "发现 PR #$pr_number: $pr_title"
    
    # 3. 交互式确认
    read -p "是否批准该 PR? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "正在批准 PR #$pr_number..."
        gh pr review "$pr_number" --approve
        echo "✅ 已批准"
    else
        echo "⏭️  已跳过"
    fi
done

echo "所有任务处理完毕。"