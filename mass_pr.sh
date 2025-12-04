#!/bin/bash

# ================= 配置区域 =================
TARGET_BRANCH="main"      # 目标合并分支，通常是 main 或 master
TOTAL_PRS=100             # 需要创建的 PR 数量
SLEEP_TIME=2             # ⚠️ 关键：每次提交后的等待秒数，防止被封号
# ===========================================

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo "错误: 当前目录不是 git 仓库。"
    exit 1
fi

echo "开始执行... 目标: 创建 $TOTAL_PRS 个 PR，间隔 $SLEEP_TIME 秒。"

for ((i=1; i<=TOTAL_PRS; i++))
do
    BRANCH_NAME="test-branch-$i"
    FILE_NAME="test-file-$i.txt"
    
    echo "----------------------------------------"
    echo "[进度 $i / $TOTAL_PRS] 正在处理分支: $BRANCH_NAME"

    # 1. 确保在主分支并拉取最新代码
    git checkout $TARGET_BRANCH > /dev/null 2>&1
    git pull origin $TARGET_BRANCH > /dev/null 2>&1

    # 2. 创建并切换到新分支
    # 如果分支已存在先删除（为了测试脚本可重用性）
    git branch -D $BRANCH_NAME > /dev/null 2>&1
    git checkout -b $BRANCH_NAME > /dev/null 2>&1

    # 3. 进行一些代码更改 (创建一个空文件或写入时间戳)
    echo "Test PR $i created at $(date)" > $FILE_NAME

    # 4. 提交更改
    git add $FILE_NAME
    git commit -m "feat: automated test commit $i" > /dev/null 2>&1

    # 5. 推送到远程
    git push -f origin $BRANCH_NAME > /dev/null 2>&1

    # 6. 使用 gh 创建 PR
    # --fill 标志会自动使用 commit 信息填充标题和内容
    # 或者使用 --title 和 --body 指定内容
    gh pr create --base $TARGET_BRANCH --head $BRANCH_NAME --title "Test PR #$i" --body "This is an automated test PR number $i"

    if [ $? -eq 0 ]; then
        echo "✅ PR #$i 创建成功"
    else
        echo "❌ PR #$i 创建失败"
        # 失败时最好暂停一下脚本，避免连续报错
        sleep 5
    fi

    # 7. ⚠️ 安全延时
    echo "等待 $SLEEP_TIME 秒以遵守 API 限制..."
    sleep $SLEEP_TIME
done

echo "所有任务完成！"