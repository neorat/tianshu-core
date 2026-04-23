# 标准路由表

> 按任务类型路由到需要读取的规范文件，避免每次全量加载。

## 路由规则

### 生成任何代码

**必读：**
- `engineering/structure.md` — 模块划分与包结构
- `engineering/coding-rules.md` — 依赖规则、注入、日志、Lombok
- `engineering/naming-conventions.md` — 命名规范

### 涉及架构设计或分层决策

**必读：**
- `engineering/structure.md` — 分层规则与依赖方向
- `constitution/technical.md` — 技术栈约束

**建议读：**
- `architecture/decisions/` — 相关 ADR（如已创建）

### 涉及 DDD 聚合/仓储/领域服务/值对象设计

**必读：**
- `domain/ddd-rules.md` — DDD 战术代码规范

### 涉及数据库表设计与 DDL

**必读：**
- `engineering/mysql-conventions.md` — 库/表/字段/索引/SQL 规范

### 涉及 API / 接口设计

**必读：**
- `engineering/api-guidelines.md` — REST 规范、错误码、版本策略
- `engineering/integration.md` — 外部系统集成规范

### 涉及异常处理 / 错误码

**必读：**
- `engineering/exception-handling.md` — 异常类层次、错误码体系

### 涉及领域事件 / MQ

**必读：**
- `engineering/event-bus.md` — 事件总线规范

### 涉及配置设计

**必读：**
- `engineering/config-principles.md` — P01~P07 配置设计原则

### 涉及批处理 / 定时任务

**必读：**
- `engineering/batch-framework.md` — 批处理框架规范

### 涉及系统间集成 / 上下文映射 / 跨系统交互

**必读：**
- `domain/contexts/context-map.yaml` — 上下文间关系与集成模式
- `domain/contexts/system-landscape-guide.md` — 全景导读与端到端场景走查
- `engineering/integration.md` — 外部系统集成规范

**建议读：**
- `engineering/event-bus.md` — 跨上下文事件通信规范

### 涉及新建有界上下文 / 微服务

**必读：**
- `domain/contexts/system-landscape.yaml` — 系统定义与职责边界
- `domain/contexts/context-map.yaml` — 上下文间关系
- `constitution/technical.md` — 架构约束与集成模式词汇表
- `engineering/structure.md` — 模块划分与包结构

### 涉及领域模型理解 / 业务场景分析

**必读：**
- `domain/contexts/system-landscape-guide.md` — 全景导读（5 分钟建立全局认知）

**建议读：**
- `domain/contexts/system-landscape.yaml` — 各系统核心能力与关键聚合

### 提交 Git commit

**必读：**
- `engineering/naming-conventions.md` — Git 规范部分
