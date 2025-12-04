## Header

**githubaction演示** 是一个基于 **React + Vite** 搭建的轻量级前端示例项目，用于演示在实际项目中如何集成 GitHub Actions、Git Hooks、依赖升级和基础前端工程化实践。

## Badges

> 预留徽章位（请在配置好对应 GitHub Actions / 服务后替换链接）

[![CI Status](https://img.shields.io/github/actions/workflow/status/OWNER/REPO/ci.yml?branch=main)](https://github.com/OWNER/REPO/actions)
[![Release](https://img.shields.io/github/v/release/OWNER/REPO)](https://github.com/OWNER/REPO/releases)
[![License](https://img.shields.io/github/license/OWNER/REPO)](./LICENSE)

## Introduction

**githubaction演示** 通过一个最小可用的 React + Vite 应用，串联起从本地开发、代码提交规范、自动化检查，到 GitHub Actions CI/CD 与依赖安全扫描（如 Dependabot）的完整流程。  
你可以将它作为模板，快速搭建符合现代前端工程标准的开源项目或内部演示仓库。

## Key Features

- ✅ **轻量级 React + Vite 脚手架**：使用 Vite 提供极速启动体验，内置基础的 `App` 组件和样式结构。
- 🚀 **完整前端工程化链路**：集成 ESLint、Prettier、TypeScript，配合 `lint-staged` 与 Husky 在提交前自动检查与修复代码。
- ⚡ **Git Hooks & 提交规范**：通过 Husky + Commitizen + commitlint 约束提交信息格式，帮助团队保持清晰的提交记录。
- ✅ **GitHub Actions & 依赖升级示例**：提供 `.github/dependabot.yml`，演示如何自动检测 NPM 依赖与 GitHub Actions 工作流更新。
- ⚡ **安全演示案例（可选）**：包含 `vulnerable.js` 展示典型 XSS 漏洞场景，适合在安全审计或培训中做示例说明。

## Installation

**环境要求**

- Node.js >= 18（推荐与本地/CI Node 版本保持一致）
- 包管理工具：推荐使用 `pnpm`（也可根据需要改为 `npm` / `yarn`）

**克隆仓库**

```bash
git clone https://github.com/OWNER/REPO.git
cd REPO
```

**安装依赖（以 pnpm 为例）**

```bash
pnpm install
```

如使用 `npm`：

```bash
npm install
```

## Usage Example

项目默认入口位于 `src/main.tsx`，并在 `src/App.tsx` 中渲染一个简单的 Hello World 与版本号：

```tsx
import { VERSION } from "./version"

export default function App() {
  return (
    <div>
      <p>Version: {VERSION}</p>
      <p>Hello World</p>
    </div>
  )
}
```

**本地启动开发服务器**

```bash
pnpm dev
```

随后在浏览器中访问 `http://localhost:5173`（Vite 默认端口），即可看到页面上显示：

- **Version: 1.0.0**（来自 `src/version.ts`）
- **Hello World**


## License

本项目建议采用 **MIT License** 或其他与你团队/公司政策兼容的开源协议。  
如需对协议进行自定义，请在仓库根目录新增或更新 `LICENSE` 文件，并同步更新本章节描述。

