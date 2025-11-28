import globals from "globals";
import eslintJs from "@eslint/js";
import tseslint from "typescript-eslint";
import eslintPluginReact from "eslint-plugin-react";
import eslintPluginReactHooks from "eslint-plugin-react-hooks";
import eslintConfigPrettier from "eslint-config-prettier";

export default tseslint.config(
  // 全局忽略文件
  {
    ignores: ["dist", "node_modules", "*.config.js", "public"],
  },
  // 应用于所有文件的基础配置
  eslintJs.configs.recommended,
  ...tseslint.configs.recommended,
  // React 相关的专属配置
  {
    files: ["src/**/*.{ts,tsx}"],
    plugins: {
      react: eslintPluginReact,
      "react-hooks": eslintPluginReactHooks,
    },
    languageOptions: {
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
      },
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      ...eslintPluginReact.configs.recommended.rules,
      ...eslintPluginReactHooks.configs.recommended.rules,
      "react/react-in-jsx-scope": "off", // React 17+ 无需在作用域中引入 React
    },
  },
  // 必须放在最后，用于关闭与 Prettier 冲突的规则
  eslintConfigPrettier
);