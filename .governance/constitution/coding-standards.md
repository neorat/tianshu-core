# 代码组织与命名规范

> 本文件是模板。安装到具体项目后，根据项目实际情况填写。

## 文件组织

- 按职责拆分文件，不按技术层
- 一起变更的文件放在一起
- 每个文件有一个清晰的职责
- 优先小而聚焦的文件，避免大而杂的文件

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | [例: kebab-case] | `user-service.ts` |
| 类名 | [例: PascalCase] | `UserService` |
| 函数名 | [例: camelCase] | `getUserById` |
| 常量 | [例: UPPER_SNAKE_CASE] | `MAX_RETRY_COUNT` |
| 数据库表 | [例: snake_case] | `user_sessions` |

## 代码风格

- [例: 使用 ESLint + Prettier 统一格式]
- [例: 函数不超过 30 行]
- [例: 文件不超过 300 行]
- [例: 嵌套不超过 3 层]

## 注释规范

- 注释解释"为什么"，不解释"做了什么"
- 公共 API 必须有文档注释
- TODO 注释必须关联 issue 编号

## Git 规范

- 提交信息格式: `type(scope): description`
- 类型: feat / fix / refactor / test / docs / chore
- 分支命名: `feature/xxx`, `fix/xxx`, `refactor/xxx`
