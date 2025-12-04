# 贡献指南

感谢你愿意为本项目贡献代码！为了提高协作效率，请务必在提交 PR 前阅读本指南。

## 🛠 开发环境准备

本项目采用 **DevContainers** 标准化环境，请勿使用本地 Node.js 版本，以免产生兼容性问题。

1. **获取代码**：
   ``` bash
   git clone [https://github.com/your-org/your-project.git](https://github.com/your-org/your-project.git)
````

2.  **启动环境**：
      - 使用 VS Code 打开项目。
      - 点击右下角弹出的 "Reopen in Container"。
      - 等待依赖自动安装完成。

## 📐 分支管理策略

我们采用 **GitHub Flow** 简化模式：

  - **main**：主分支，永远保持可部署状态。**禁止直接 Push**。
  - **feat/xxx**：新功能分支，从 main 切出。
  - **fix/xxx**：Bug 修复分支，从 main 切出。

**操作示例**：

``` bash
git checkout main
git pull origin main
git checkout -b feat/user-login
```

## 💾 提交规范 (Commit Convention)

本项目启用了 `commitlint` 检查，提交信息必须符合 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

**格式**：`type(scope): description`

  - **feat**: 新功能
  - **fix**: 修复 Bug
  - **docs**: 文档变更
  - **style**: 代码格式（不影响逻辑）
  - **refactor**: 代码重构
  - **test**: 测试用例
  - **chore**: 构建/工具链变动

**正确示例**：

  - ✅ `feat(auth): add google oauth login support`
  - ✅ `fix(ui): resolve button alignment issue on mobile`

**错误示例**：

  - ❌ `update login` (类型不明)
  - ❌ `Fixed bug` (描述不清)

## 🚀 Pull Request 流程

1.  **同步主分支**：提交前请先合并 main 分支，解决潜在冲突。
2.  **运行测试**：确保 `npm test` 全部通过。
3.  **关联 Issue**：PR 描述中需包含 `Closes #123` 以自动关闭对应 Issue。
4.  **Code Review**：这就需要至少 1 位维护者 Approve 才能合并。