# 技术栈与架构约束

## 默认技术栈

| 层级 | 技术选型 | 版本 | 理由 |
|------|---------|------|------|
| 语言 | Java | 21 LTS | Record / Sealed Class / Pattern Matching |
| 框架 | Spring Boot | 4.0+ | 主应用框架 |
| 架构验证 | ArchUnit | 1.3+ | 编译时分层约束检测 |
| 构建 | Maven | 3.6+ | 多模块依赖管理 |
| ORM | MyBatis-Plus | 3.5+ | 灵活 SQL 映射 + 类型安全查询 |
| 对象映射 | MapStruct | 1.6+ | 编译时生成，类型安全 |
| 数据库 | MySQL | 8.0+ | 主数据库 |

## 可选组件

| 组件 | 用途 | 启用条件 |
|------|------|---------|
| RocketMQ | 消息队列 / 事件总线 | 需要跨系统事件传播时 |
| Dubbo | RPC 服务治理 | 需要 RPC 通信时 |
| Redis | 分布式缓存 / 锁 | 需要缓存或分布式锁时 |
| Nacos | 配置中心 / 服务发现 | 需要动态配置时 |
| Spring Batch | 批处理框架 | 需要复杂批处理时 |
| XXL-Job | 分布式任务调度 | 需要定时任务时 |

## 架构原则

- DDD 分层架构：interfaces → application → domain ← infrastructure
- 领域层零框架依赖，纯业务逻辑
- CQRS：Command / Query 职责分离
- 事件驱动：跨上下文通过领域事件通信
- 依赖倒置：domain 定义 Repository 接口，infrastructure 实现
- ArchUnit 编译时强制分层约束
- 1 个有界上下文 = 1 个微服务

## 系统群与有界上下文

本项目包含 13 个有界上下文，完整定义见 `domain/contexts/system-landscape.yaml`。

| 分类 | 有界上下文 |
|------|-----------|
| 核心（core） | Transaction, Payment, Accounting, Clearing, RiskControl, CustomerCenter, ProductCenter, CreditLimit, LoanProcess, LoanCore |
| 支撑（supporting） | Reconciliation, CardSystem |
| 通用（generic） | UserCenter |

## 上下游语义约定

本项目采用"模型影响力方向"定义上下游关系：

- upstream（上游）= 模型的权威方 / 服务提供方，模型变更会影响下游
- downstream（下游）= 模型的消费方 / 适配方，需要适配上游模型
- 注意：调用方向可能与上下游方向相反（下游调用上游的服务）

详细的上下文间关系见 `domain/contexts/context-map.yaml`。

## 集成模式词汇表

| 缩写 | 全称 | 含义 |
|------|------|------|
| ACL | Anti-Corruption Layer | 下游用防腐层隔离上游模型 |
| OHS | Open Host Service | 上游提供标准化服务接口 |
| CF | Conformist | 下游直接遵从上游模型 |
| PL | Published Language | 双方约定标准化数据格式 |
| SK | Shared Kernel | 共享核心领域模型（谨慎使用） |
| PT | Partnership | 双方协同演进 |

## Java 8 兼容模式

若项目受限于 Java 8，以下替代方案适用：

| Java 21 特性 | Java 8 替代 |
|-------------|------------|
| `record` | 手写不可变类 + Lombok `@Getter` |
| `sealed interface` | `abstract class` + 子类 |
| `switch` 表达式 | 传统 `switch` / `if-else` |
| MapStruct | 手写 Converter |
| ArchUnit | ArchUnit（本身支持 Java 8） |
| Spring Boot 4.0 | Spring Boot 2.7+ |

详细规范见 `engineering/README.md`。
