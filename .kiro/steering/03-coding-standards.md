---
inclusion: auto
description: 代码组织与命名规范 — 文件组织、命名规范、代码风格、注释规范、Git 规范
---

# 代码组织与命名规范

## 文件组织

- 按职责拆分文件，不按技术层
- 一起变更的文件放在一起
- 每个文件有一个清晰的职责
- 优先小而聚焦的文件，避免大而杂的文件

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 包名 | 全小写，按层级组织 | `com.tianshu.domain.order.model` |
| 类名 | PascalCase，按后缀区分职责 | `OrderCommandService`, `OrderRepository` |
| 方法名 | camelCase，进行时表触发/完成时表回调 | `place()`, `onPaymentCompleted()` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 数据库表 | `t_{业务名}_snake_case`，单数 | `t_order`, `t_order_item` |
| 数据库字段 | snake_case | `apply_amount`, `created_at` |
| 索引 | 普通 `idx_{字段}`，唯一 `uk_{字段}` | `idx_customer_id`, `uk_order_no` |

## 类名后缀约定

| 类型 | 后缀 | 示例 |
|------|------|------|
| 聚合根/实体/值对象 | 无后缀 | `Order`, `Money` |
| 领域服务 | `Service` | `OrderPricingService` |
| 命令/查询服务 | `CommandService` / `QueryService` | `OrderCommandService` |
| 仓储接口/实现 | `Repository` / `RepositoryImpl` | `OrderRepository` |
| 网关接口/实现 | `Gateway` / `GatewayImpl` | `PaymentGateway` |
| 命令/查询对象 | `Command` / `Query` | `CreateOrderCommand` |
| 请求/响应 DTO | `Request` / `Response` | `CreateOrderRequest` |
| 领域事件 | `{聚合根}{事实}Event` | `OrderPlacedEvent` |
| 数据对象 | `DO` | `OrderDO` |
| 转换器 | `Converter`（infra）/ `Assembler`（app） | `OrderConverter` |

## 代码风格

- 构造器注入，禁止字段注入
- 方法参数不超过 5 个，超过封装为参数对象
- 值对象不可变（Java 21 用 `record`）
- 实体状态变更通过业务方法，禁止 setter
- 类引用必须通过 `import` 导入，禁止全限定类名
- 禁止直接使用 `ObjectMapper`，统一用 `JsonUtil`

## 注释规范

- 注释解释"为什么"，不解释"做了什么"
- 公共 API 必须有文档注释
- TODO 注释必须关联 issue 编号

## Git 规范

- 提交信息格式: `type(scope): description`
- 类型: feat / fix / refactor / test / docs / chore
- 分支命名: `feature/xxx`, `fix/xxx`, `refactor/xxx`
