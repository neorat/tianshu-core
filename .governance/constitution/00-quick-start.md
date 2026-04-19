# 快速开始指南

> 安装完成后的第一件事。5 分钟内让框架为你的项目工作。

## 第一步：填写项目宪法（必须）

安装脚本已将模板文件放到位，但以下三个文件需要根据你的项目实际情况填写：

### 1. `constitution/product.md` — 产品目标

回答：这个项目为谁解决什么问题？

```markdown
## 产品愿景
[一句话]

## 核心用户
[列出 2-3 个角色]

## 非目标
[明确不做的事]
```

不需要写很多。一页纸足够。关键是让 AI 助手理解项目的边界。

### 2. `constitution/technical.md` — 技术约束

回答：用什么技术栈？有什么硬性约束？

```markdown
## 技术栈
| 层级 | 技术 | 版本 |
|------|------|------|

## 架构原则
- [2-3 条核心原则]
```

如果项目已有现成的技术文档（如 README 中的技术栈说明），可以直接引用：
```markdown
技术栈和架构约束详见项目文档：
#[[file:../../README.md]]
```

### 3. `constitution/coding-standards.md` — 编码规范

回答：命名怎么写？代码怎么组织？

同样，如果项目已有编码规范文档，直接用 `#[[file:]]` 引用即可。

## 第二步：验证安装

在 Kiro 中输入以下内容，确认 steering 文件生效：

```
请列出你当前加载的所有 steering 规则
```

你应该看到 constitution 和核心工作流（TDD、调试、验证）被自动加载。

## 第三步：开始第一个功能

```
#brainstorming 我想实现 [你的功能描述]
```

框架会引导你走完：需求分析 → 设计 → 计划 → 实现 的完整流程。

## 与已有文档的整合

如果项目已有技术文档，不需要重复填写 constitution 模板——用 `#[[file:]]` 引用即可：

| 已有文档 | 对应 constitution 文件 | 整合方式 |
|---------|----------------------|---------|
| `README.md` | `product.md` + `technical.md` | 提取相关部分引用 |
| 已有的编码规范文档 | `coding-standards.md` | 在模板中引用 |
| `.cursor/rules/` | `coding-standards.md` | 迁移或引用 |

### 示例：引用已有文档

```markdown
# 技术栈与架构约束

本项目的技术栈和架构约束详见项目 README：

#[[file:../../README.md]]

## 补充约束（README 未覆盖的部分）

- [如有额外约束写在这里]
```

## 不需要做的事

- ❌ 不需要一次性填完所有内容——先填 technical.md，其他按需补充
- ❌ 不需要把已有文档复制粘贴——用 `#[[file:]]` 引用
- ❌ 不需要修改 `.governance/` 下的工作流文件——它们是通用的
- ❌ 不需要记住所有工作流——看 `workflows/00-routing.md` 的路由图
- ❌ 不需要一开始就启用所有可选模块——先用核心层，按需渐进启用

## 第四步：启用可选模块（按需）

安装脚本会交互式询问是否启用可选模块。如果安装时跳过了，后续可以手动启用。

### 架构治理模块

适用于：有明确分层架构、需要防止架构腐化的项目。

```bash
# 创建目录
mkdir -p .governance/architecture/decisions
mkdir -p .governance/architecture/dna

# 创建第一个 ADR
cp .governance/architecture/_templates/adr-template.md \
   .governance/architecture/decisions/adr-001-your-decision.md

# 填写标准路由表
# 编辑 .governance/constitution/standards-routing.md
```

### 迭代上下文模块

适用于：开发周期超过一周、需要跨会话保持上下文的项目。

```bash
# 编辑当前焦点（每次开始新阶段时更新）
# 编辑 .governance/context/current-focus.md

# 编辑待办事项
# 编辑 .governance/context/backlog.md
```

### DDD 领域建模模块

适用于：明确采用 DDD 战术设计的项目。

```bash
# 创建第一个有界上下文
mkdir -p .governance/domain/contexts/your-context/aggregates

# 从模板创建聚合定义
cp .governance/domain/_templates/aggregate-template.yaml \
   .governance/domain/contexts/your-context/aggregates/your-aggregate.aggregate.yaml

# 创建统一语言字典
cp .governance/domain/_templates/ubiquitous-language-template.yaml \
   .governance/domain/ubiquitous-language/your-context-terms.yaml
```
