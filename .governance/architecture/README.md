# 架构治理模块（可选）

> 本模块提供"三位一体"架构治理能力，适用于需要架构决策追溯和分层约束的项目。

## 设计理念：三位一体 (Governance Trinity)

架构治理分为三个互补层次：

| 层次 | 载体 | 回答的问题 | 推荐格式 |
|------|------|-----------|---------|
| DNA（元数据） | `dna/` 目录下的 YAML 文件 | 结构"是什么"？ | YAML |
| History（决策纪实） | `decisions/` 目录下的 ADR | "为什么这么做"？ | Markdown |
| Manual（落地手册） | `constitution/` 或项目文档 | 具体"怎么写"？ | Markdown |

三者的关系：
- DNA 定义架构骨架（层级、依赖方向、集成规则），供 AI 精确读取
- History 记录每个架构决策的上下文、备选方案和权衡，供人类和 AI 理解"为什么"
- Manual 是研发一线的操作手册，展示真实目录树、代码模板和规范

## 目录结构

```
architecture/
├── README.md              # 本文件
├── _templates/
│   ├── adr-template.md    # 架构决策记录模板
│   └── dna-template.yaml  # 架构元数据模板
├── decisions/             # ADR 存放目录（按需创建）
│   └── adr-001-xxx.md
└── dna/                   # 架构元数据存放目录（按需创建）
    └── layering.yaml
```

## 使用方式

### 1. 记录架构决策 (ADR)

当做出影响系统结构的决策时，使用 `_templates/adr-template.md` 创建 ADR：

```bash
cp _templates/adr-template.md decisions/adr-001-your-decision.md
```

ADR 编号自增，格式为 `adr-NNN-kebab-case-title.md`。

### 2. 定义架构元数据 (DNA)

当需要让 AI 精确理解架构约束时，使用 `_templates/dna-template.yaml` 创建元数据：

```bash
cp _templates/dna-template.yaml dna/layering.yaml
```

常见的 DNA 文件：
- `layering.yaml` — 分层架构定义（层级名称、依赖方向）
- `integration-rules.yaml` — 外部系统集成约束
- `exception-rules.yaml` — 异常体系元数据

### 3. 与 constitution 的关系

- `constitution/technical.md` 定义技术栈和高层架构原则
- `architecture/dna/` 定义精确的架构元数据（机器可读）
- `architecture/decisions/` 记录决策历史（人机共读）

三者不重复：technical.md 说"用什么"，DNA 说"结构是什么"，ADR 说"为什么这样"。

## 格式选择指南

| 内容类型 | 推荐格式 | 理由 |
|---------|---------|------|
| 分层规则、依赖方向 | YAML | 纯键值对，AI 精确解析 |
| 架构决策记录 | Markdown | 重点在因果推理，自然语言更合适 |
| 数据库表结构 | SQL DDL | 大模型对标准 SQL 理解力极高 |
| 状态机、流程图 | Mermaid | 纯文本结构化表达，AI 可直接转译为代码 |
| 编码规范、操作手册 | Markdown + 代码块 | Good/Bad 对比案例是 AI 学习的最佳素材 |

## 何时启用本模块

- 项目有明确的分层架构（如 DDD 六边形、Clean Architecture）
- 需要追溯架构决策历史
- 多人协作或 AI 辅助开发，需要防止架构腐化
- 项目生命周期超过 3 个月
