### 17.1.4. 实战演练：从零搭建多环境验证 Demo

理论已经讲透，现在我们来真刀真枪地实践一遍。我们将从零创建一个 Vite 前端项目，模拟真实的开发场景，亲眼见证变量的自动切换和审批流程的触发。

**第一阶段：本地项目初始化**

首先，我们需要在本地构建一个最基础的 React 应用，并将其推送到 GitHub，如果您在第十六节的项目没有删除，可以继续复用，教程为了完整性快速搭建一个最小可测试案例

| 步骤              | 执行操作/命令                                               | 说明                          |
| :---------------- | :---------------------------------------------------------- | :---------------------------- |
| **1. 创建项目**   | `npm create vite@latest vite-cicd-demo -- --template react` | 使用 Vite 快速生成 React 模板 |
| **2. 安装依赖**   | `cd vite-cicd-demo`<br>`npm install`                        | 进入目录并安装 Node 依赖      |
| **3. Git 初始化** | `git init`                                                  | 初始化本地 Git 仓库           |
| **4. 修改代码**   | 编辑 `src/App.jsx`                                          | 替换为下方提供的测试代码      |

**文件路径**：`src/App.jsx`

我们将修改 App 组件，让它能够读取并展示环境变量，以便我们验证注入是否成功。

```jsx
import './App.css'

function App() {
  return (
    <div style={{ padding: '20px', textAlign: 'center' }}>
      <h1>持续交付多环境演示</h1>
      <div className="card">
        {/* 读取并展示环境变量 */}
        {/* 注意：Vite 仅暴露 VITE_ 开头的变量以防止密钥泄露 */}
        <p>
          当前 API 地址: <strong>{import.meta.env.VITE_API_URL}</strong>
        </p>
      </div>
    </div>
  )
}

export default App
```

**第二阶段：GitHub 环境配置（关键）**

这是核心步骤，我们需要在 GitHub 仓库中创建两个环境，并分别设置不同的变量。请在 GitHub 仓库的 `Settings` -\> `Environments` 页面执行以下操作：

| 环境名称       | 需配置的变量 (Name: Value)                        | 保护规则配置 (Protection Rules)                                  |
| :------------- | :------------------------------------------------ | :--------------------------------------------------------------- |
| **Staging**    | `VITE_API_URL`: `https://staging-api.example.com` | 无需配置，保持默认                                               |
| **Production** | `VITE_API_URL`: `https://prod-api.example.com`    | 勾选 **Required reviewers**<br>在搜索框输入你的 GitHub ID 并选中 |

**第三阶段：编写 CD 流水线**

为了代码复用和易于维护，我们采用 **Composite Action** 的方式，将构建和验证逻辑提取为可复用的组件。

**步骤 1：创建可复用的 Composite Action**

首先，我们需要创建一个可复用的构建和验证 action，这样两个环境可以共享相同的构建逻辑。

**文件路径**：`.github/actions/build-and-verify/action.yml`

```yaml
name: 'Build and Verify'
description: '构建项目并验证输出'

inputs:
  expected_domain:
    description: '期望在构建产物中找到的域名'
    required: true
  verify_message:
    description: '验证步骤的提示消息'
    required: false
    default: '正在检查构建产物...'
  vite_api_url:
    description: 'Vite API URL 环境变量值'
    required: true

runs:
  using: 'composite'
  steps:
    # 注意：checkout 步骤应在工作流中完成，以便能够找到本 action 文件
    # 注意：vars 上下文在 composite action 中不可用，需要通过 input 参数传递
    - uses: actions/setup-node@v4
      with:
        node-version: 18

    - name: Install dependencies
      shell: bash
      run: npm install

    - name: Build
      shell: bash
      run: npm run build
      env:
        VITE_API_URL: ${{ inputs.vite_api_url }}

    - name: Verify Output
      shell: bash
      run: |
        echo "${{ inputs.verify_message }}"
        grep -r "${{ inputs.expected_domain }}" dist/ || echo "Build failed to inject variable"
```

**步骤 2：定义工作流文件**

现在创建工作流文件，使用上面创建的 composite action。

**重要提示**：

- 使用本地 composite action（`./.github/actions/...`）时，必须先执行 `actions/checkout@v4`，否则 GitHub Actions 无法找到 action.yml 文件
- `vars` 上下文在 composite action 中不可用，需要通过 `inputs` 参数传递环境变量值

**文件路径**：`.github/workflows/cd-pipeline.yml`

```yaml
name: CD Pipeline Demo

on:
  push:
    branches: ['main']

jobs:
  # 阶段 1: 构建并部署到 Staging
  build-staging:
    runs-on: ubuntu-latest
    environment: Staging # 核心：绑定 Staging 环境，自动读取对应变量
    steps:
      # 必须先 checkout 代码，才能使用本地的 composite action
      - uses: actions/checkout@v4

      - name: Build and Verify
        uses: ./.github/actions/build-and-verify
        with:
          expected_domain: 'staging-api.example.com'
          verify_message: '正在检查构建产物...'
          vite_api_url: ${{ vars.VITE_API_URL }}

  # 阶段 2: 构建并部署到 Production
  build-production:
    needs: build-staging # 必须等 Staging 成功
    runs-on: ubuntu-latest
    environment: Production # 核心：绑定 Production 环境（将触发人工审批）
    steps:
      # 必须先 checkout 代码，才能使用本地的 composite action
      - uses: actions/checkout@v4

      - name: Build and Verify
        uses: ./.github/actions/build-and-verify
        with:
          expected_domain: 'prod-api.example.com'
          verify_message: '生产环境构建完成！'
          vite_api_url: ${{ vars.VITE_API_URL }}
```

**核心配置解析：**

- **Composite Action 的优势**：
  - **代码复用**：两个环境共享相同的构建逻辑，避免重复代码
  - **易于维护**：修改构建流程只需在一个地方更新
  - **一致性保证**：确保 Staging 和 Production 使用完全相同的构建流程

- **工作流配置**：
  - `needs: build-staging`：确保了串行执行顺序，测试环境挂了，生产环境根本不会开始
  - `environment: Production`：这是触发"审批弹窗"的开关。Runner 运行到此时，会向 GitHub 查询该环境是否有保护规则
  - `uses: ./.github/actions/build-and-verify`：引用本地创建的 composite action，通过 `with` 参数传入不同环境的配置
  - `vars.VITE_API_URL`：为什么用 `vars` 而不是 `env`？
    
    **`vars` vs `env` 的区别**：
    
    | 上下文 | 用途 | 数据来源 | 示例 |
    |:---|:---|:---|:---|
    | **`vars`** | 访问 GitHub 仓库/组织/环境级别的**变量**（非敏感） | Settings > Variables 或 Settings > Environments > Variables | `${{ vars.VITE_API_URL }}` |
    | **`env`** | 访问 workflow 中定义的**环境变量**或系统环境变量 | workflow 文件中的 `env:` 关键字，或系统环境变量 | `${{ env.NODE_VERSION }}` |
    | **`secrets`** | 访问 GitHub 仓库/组织/环境级别的**密钥**（敏感） | Settings > Secrets 或 Settings > Environments > Secrets | `${{ secrets.API_KEY }}` |
    
    **在本例中的选择**：
    - 我们在 GitHub 的 **Environments**（Staging/Production）中设置了 `VITE_API_URL` 变量
    - 这些变量存储在 GitHub 的配置中，不是 workflow 文件中的 `env:`
    - 因此必须使用 `vars.VITE_API_URL` 来访问
    
    **如果改用 `env` 的方式**（不推荐，因为无法区分环境）：
    ```yaml
    env:
      VITE_API_URL: 'https://staging-api.example.com'  # 硬编码，无法区分环境
    steps:
      - run: echo ${{ env.VITE_API_URL }}
    ```

**第四阶段：执行与验证**

将上述代码提交并推送到 GitHub 后，打开仓库的 **Actions** 页面，观察流水线的运行状态。

| 观察阶段               | 现象描述                                          | 操作/结果                                                   |
| :--------------------- | :------------------------------------------------ | :---------------------------------------------------------- |
| **1. Staging 运行**    | `build-staging` 任务显示为绿色（Success）         | 点击日志 `Verify Output`，能看到 `staging-api` 字符串       |
| **2. Production 等待** | `build-production` 任务显示为 **黄色（Waiting）** | 界面出现提示：`Review required`                             |
| **3. 人工审批**        | 点击 **Review deployments** 按钮                  | 选择 Production 环境，输入备注，点击 **Approve and deploy** |
| **4. Production 运行** | `build-production` 任务由黄变绿                   | 点击日志 `Verify Output`，能看到 `prod-api` 字符串          |

通过这个实战，我们亲手验证了：代码虽然是一份，但通过不同的 **Environment** 绑定，最终生成了包含不同配置的构建产物，且生产环境的发布被牢牢控制在审批流程之中。
