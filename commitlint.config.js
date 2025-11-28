// commitlint.config.js
export default {
    extends: ["@commitlint/config-conventional"],

    // 自定义规则
    rules: {
        // 扩展允许的 type 类型
        "type-enum": [
            2,
            "always",
            [
                "feat",     // 新功能
                "fix",      // Bug 修复
                "docs",     // 文档更新
                "style",    // 代码格式（不影响功能）
                "refactor", // 重构
                "perf",     // 性能优化
                "test",     // 测试相关
                "build",    // 构建系统或外部依赖变更
                "ci",       // CI 配置文件和脚本变更
                "chore",    // 其他不修改 src 或测试文件的变更
                "revert",   // 回退之前的 commit
                "wip",      // 进行中的工作
                "workflow", // 工作流改进
                "types",    // 类型定义文件变更
                "release",  // 发布版本 commit
            ],
        ],

        // 允许中文提交
        "subject-case": [0],

        // Scope 枚举（根据你的项目模块调整）
        "scope-enum": [
            2,
            "always",
            [
                "core",     // 核心模块
                "ui",       // UI 组件
                "utils",    // 工具函数
                "api",      // API 接口
                "config",   // 配置文件
                "deps",     // 依赖更新
                "auth",     // 认证模块
                "other",    // 其他
            ],
        ],

        // 允许空 scope（某些 type 如 docs、chore 可不写 scope）
        "scope-empty": [0],

        // 标题最大长度
        "header-max-length": [2, "always", 100],
    },
    // ========== cz-git 交互式配置 ==========
    prompt: {
        // 中文化提示信息
        messages: {
            type: "选择你要提交的类型 :",
            scope: "选择一个提交范围（可选）:",
            customScope: "请输入自定义的提交范围 :",
            subject: "填写简短精炼的变更描述 :\n",
            body: '填写更加详细的变更描述（可选）。使用 "|" 换行 :\n',
            breaking: '列举非兼容性重大的变更（可选）。使用 "|" 换行 :\n',
            footerPrefixesSelect: "选择关联issue前缀（可选）:",
            customFooterPrefix: "输入自定义issue前缀 :",
            footer: "列举关联issue (可选) 例如: #31, #I3244 :\n",
            confirmCommit: "是否提交或修改commit ?",
        },

        // 类型列表（带 Emoji 和中英文说明）
        types: [
            { value: "feat", name: "feat:     ✨  新增功能 | A new feature", emoji: ":sparkles:" },
            { value: "fix", name: "fix:      🐛  修复缺陷 | A bug fix", emoji: ":bug:" },
            { value: "docs", name: "docs:     📝  文档更新 | Documentation changes", emoji: ":memo:" },
            { value: "style", name: "style:    💄  代码格式 | Markup, white-space, formatting", emoji: ":lipstick:" },
            { value: "refactor", name: "refactor: ♻️  代码重构 | A code change that neither fixes a bug nor adds a feature", emoji: ":recycle:" },
            { value: "perf", name: "perf:     ⚡️  性能提升 | A code change that improves performance", emoji: ":zap:" },
            { value: "test", name: "test:     ✅  测试相关 | Adding or correcting tests", emoji: ":white_check_mark:" },
            { value: "build", name: "build:    📦️  构建相关 | Changes that affect the build system", emoji: ":package:" },
            { value: "ci", name: "ci:       🎡  持续集成 | Changes to CI configuration files", emoji: ":ferris_wheel:" },
            { value: "chore", name: "chore:    🔨  其他修改 | Other changes that don't modify src or test files", emoji: ":hammer:" },
            { value: "revert", name: "revert:   ⏪️  回退代码 | Reverts a previous commit", emoji: ":rewind:" },
            { value: "wip", name: "wip:      🚧  进行中 | Work in progress", emoji: ":construction:" },
            { value: "workflow", name: "workflow: 📋  工作流 | Workflow improvements", emoji: ":clipboard:" },
            { value: "types", name: "types:    🏷️  类型定义 | Type definition file changes", emoji: ":label:" },
        ],

        
        // 是否使用 Emoji（会在 commit message 中显示）
        useEmoji: true,
        useAI: true,

        // Scope 相关配置
        scopes: [], // 留空，自动从 rules['scope-enum'] 中读取
        allowCustomScopes: true,
        allowEmptyScopes: true,
        customScopesAlias: "custom",
        emptyScopesAlias: "empty",

        // Subject 配置
        upperCaseSubject: false,
        markBreakingChangeMode: false,
        allowBreakingChanges: ["feat", "fix"],

        // Footer 配置
        issuePrefixes: [
            { value: "closed", name: "closed:   ISSUES has been processed" },
        ],
        customIssuePrefixAlign: "top",
        emptyIssuePrefixAlias: "skip",
        customIssuePrefixAlias: "custom",
        allowCustomIssuePrefix: true,
        allowEmptyIssuePrefix: true,

        // 确认提交
        confirmColorize: true,
        maxHeaderLength: Infinity,
        maxSubjectLength: Infinity,
        minSubjectLength: 0,
        defaultBody: "",
        defaultIssues: "",
        defaultScope: "",
        defaultSubject: "",
    },
};