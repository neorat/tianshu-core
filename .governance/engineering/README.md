# 工程脚手架 — 实战编码规范

> 锁定技术栈的企业级 DDD 工程规范。安装后 AI 即可按此标准生成代码。

## 默认技术栈

| 层级 | 技术选型 | 版本 |
|------|---------|------|
| 语言 | Java | 21（LTS，支持 Record / Sealed Class） |
| 框架 | Spring Boot | 4.0+ |
| 架构验证 | ArchUnit | 1.3+ |
| 构建 | Maven | 3.6+ |
| ORM | MyBatis-Plus | 3.5+ |
| 对象映射 | MapStruct | 1.6+ |
| 数据库 | MySQL | 8.0+ |

### 可选组件

| 组件 | 用途 | 版本 |
|------|------|------|
| RocketMQ | 消息队列 / 事件总线 | 2.3+ |
| Dubbo | RPC 服务治理 | 3.x |
| Redis | 分布式缓存 / 锁 | — |
| Nacos | 配置中心 / 服务发现 | 2.x |
| Spring Batch | 批处理框架 | — |
| XXL-Job | 分布式任务调度 | — |

### Java 8 兼容说明

本规范默认使用 Java 21 特性。若项目受限于 Java 8，以下替代方案适用：

| Java 21 特性 | Java 8 替代 |
|-------------|------------|
| `record` 值对象 | 手写不可变类 + `@Getter`，无 `@Setter` |
| `sealed interface` 事件 | 普通 `abstract class` + 子类 |
| `switch` 表达式 | `if-else` 或传统 `switch` |
| `var` 局部变量 | 显式类型声明 |
| MapStruct | 手写 Converter 或 BeanUtils |
| ArchUnit | ArchUnit（本身支持 Java 8） |

## 文件索引

| 文件 | 职责 | 何时读取 |
|------|------|---------|
| structure.md | Maven 模块划分 + DDD 分层 + 包结构 | 生成任何代码前 |
| coding-rules.md | 依赖规则、注入、日志、Lombok、序列化 | 生成任何代码前 |
| naming-conventions.md | 时态准则、类后缀、方法命名、DB 命名 | 生成任何代码前 |
| exception-handling.md | 异常类层次、错误码、全局处理 | 涉及异常/错误码时 |
| mysql-conventions.md | 库/表/字段/索引/SQL 规范 | 涉及数据库设计时 |
| event-bus.md | Transactional Outbox、领域事件 | 涉及事件/MQ 时 |
| integration.md | Gateway 设计、三态语义、幂等 | 涉及外部系统集成时 |
| api-guidelines.md | REST 规范、错误码、版本策略 | 涉及 API 设计时 |
| batch-framework.md | 批处理三阶段模型、设计原则 | 涉及批处理/定时任务时 |
| config-principles.md | 配置设计 P01~P07 | 涉及配置设计时 |

## 与其他模块的关系

| 模块 | 关系 |
|------|------|
| constitution/ | constitution 定义"信仰什么原则"，engineering 定义"怎么写代码" |
| workflows/ | workflows 定义"怎么工作"（TDD、调试），engineering 定义"代码长什么样" |
| architecture/ | architecture 记录"为什么这样设计"（ADR），engineering 定义"具体怎么落地" |
| domain/ | domain 定义"业务是什么"（聚合模型），engineering 定义"代码怎么组织" |

## YAGNI 与架构投入的边界

constitution.md 第四条 YAGNI 原则适用于业务功能，不适用于架构基础设施：

- **受 YAGNI 约束**：业务功能、"以防万一"的接口、"将来可能需要"的抽象
- **不受 YAGNI 约束**：DDD 分层、端口/适配器接口、防腐层、异常体系、事件总线基础设施

这些架构投入是企业级系统的必要基础，不是过度设计。
