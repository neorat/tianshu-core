---
inclusion: auto
description: 标准路由表 — 按任务类型路由到对应的 engineering 规范文件，避免全量加载
---

# 标准路由表

> 按任务类型路由到需要读取的规范文件，避免每次全量加载。

## 路由规则

### 生成任何代码

**必读：**
- `.governance/engineering/structure.md` — 模块划分与包结构
- `.governance/engineering/coding-rules.md` — 依赖规则、注入、日志、Lombok
- `.governance/engineering/naming-conventions.md` — 命名规范

### 涉及架构设计或分层决策

**必读：**
- `.governance/engineering/structure.md` — 分层规则与依赖方向
- `.governance/constitution/technical.md` — 技术栈约束

**建议读：**
- `.governance/architecture/decisions/` — 相关 ADR（如已创建）

### 涉及 DDD 聚合/仓储/领域服务/值对象设计

**必读：**
- `.governance/domain/` — 对应上下文的聚合定义

### 涉及数据库表设计与 DDL

**必读：**
- `.governance/engineering/mysql-conventions.md` — 库/表/字段/索引/SQL 规范

### 涉及 API / 接口设计

**必读：**
- `.governance/engineering/api-guidelines.md` — REST 规范、错误码、版本策略
- `.governance/engineering/integration.md` — 外部系统集成规范

### 涉及异常处理 / 错误码

**必读：**
- `.governance/engineering/exception-handling.md` — 异常类层次、错误码体系

### 涉及领域事件 / MQ

**必读：**
- `.governance/engineering/event-bus.md` — 事件总线规范

### 涉及配置设计

**必读：**
- `.governance/engineering/config-principles.md` — P01~P07 配置设计原则

### 涉及批处理 / 定时任务

**必读：**
- `.governance/engineering/batch-framework.md` — 批处理框架规范

### 提交 Git commit

**必读：**
- `.governance/engineering/naming-conventions.md` — Git 规范部分
