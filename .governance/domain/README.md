# DDD 领域建模模块（可选）

> 本模块提供领域驱动设计 (DDD) 的建模模板，适用于采用 DDD 战术设计的项目。

## 设计理念

不要把 AI 当成简单的"代码生成器"。优秀的系统源自严谨的业务建模。

本模块迫使 AI 遵守"先设计模型、再写代码"的流程——将业务实体、聚合根和仓储接口作为元数据记录下来，AI 可以通过阅读这些契约，稳定地输出无偏差的代码。

## 目录结构

```
domain/
├── README.md                    # 本文件
├── _templates/
│   ├── aggregate-template.yaml  # 聚合根定义模板
│   ├── context-template.yaml    # 有界上下文模板
│   ├── ubiquitous-language-template.yaml  # 统一语言模板
│   └── persistence-template.md  # 持久化模型模板（SQL DDL）
└── contexts/                    # 各有界上下文目录（按需创建）
    └── your-context/
        ├── aggregates/
        │   └── your-aggregate.yaml
        ├── context-map.yaml
        ├── domain-services.yaml
        ├── events.yaml
        ├── repositories.yaml
        └── persistence.md
```

## 模板说明

### aggregate-template.yaml
定义聚合根的完整契约：字段、生命周期状态机、业务不变量、领域方法。AI 可据此 1:1 还原实体代码。

### context-template.yaml
定义有界上下文的边界、职责、与其他上下文的关系（上下文映射）。

### ubiquitous-language-template.yaml
统一语言字典，确保代码中的命名与业务术语一致。按子域物理隔离，避免术语冲突。

### persistence-template.md
持久化模型使用 SQL DDL 格式。大模型对标准 SQL 有极高的理解力，这比用 YAML 去"翻译"表结构要准确得多。

## 格式选择

| 内容 | 格式 | 理由 |
|------|------|------|
| 聚合定义、字段、枚举 | YAML | 纯结构化数据，AI 精确解析 |
| 表结构 | SQL DDL | 大模型训练语料中最丰富的结构化表达 |
| 状态机 | Mermaid（嵌入 Markdown） | AI 可直接转译为代码中的 Enum/Switch |
| 领域服务、策略说明 | YAML + Markdown | 接口签名用 YAML，逻辑说明用 Markdown |

## 与其他模块的关系

- `constitution/technical.md` — 定义技术栈，领域模型的实现受其约束
- `architecture/` — ADR 记录领域边界划分的决策，DNA 定义分层规则
- `specs/` — 功能规范引用领域模型，确保实现与模型一致
- `constitution/coding-standards.md` — 命名规范应与统一语言对齐

## 何时启用本模块

- 项目明确采用 DDD 战术设计
- 业务复杂度高，需要聚合边界和领域事件
- 多个有界上下文需要协作
- 需要 AI 稳定输出符合领域模型的代码
