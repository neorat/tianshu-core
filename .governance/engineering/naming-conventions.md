# 命名规范

## 零、通用时态准则

适用于方法名与字段名，命名须体现业务动作或数据所处的时态：

- **进行时**：触发动作 / 输入参数。用一般现在时动词或动名词
  - 方法：`accept()` `submit()` `approve()` `place()`
  - 字段：`applyAmount` `repayAmount` `orderQuantity`
- **完成时**：响应已发生的事实 / 业务结果回填。用过去分词或含完成语义的名词
  - 方法：`onApproved()` `onFunded()` `onShipped()`
  - 字段：`grantedAmount` `approvedAt` `shippedAt`

> 判断方法：这是"触发/输入"还是"结果/回填"？前者进行时，后者完成时。

---

## 一、包名（package）

| 层级 | 包路径模式 | 示例 |
|------|-----------|------|
| api 模块 | `com.{company}.{project}.api.{context}.{client\|dto\|constant}` | `com.ddd.template.api.order.client` |
| 应用层 | `com.{company}.{project}.application.{usecase}.{cmd\|qry\|event}` | `com.ddd.template.application.order.cmd` |
| 领域层 | `com.{company}.{project}.domain.{domain}.{model\|port\|exception}` | `com.ddd.template.domain.order.model.aggregate` |
| 基础设施层 | `com.{company}.{project}.infrastructure.{component}.{domain}` | `com.ddd.template.infrastructure.persistence.order` |
| 接口层 | `com.{company}.{project}.interfaces.{protocol}` | `com.ddd.template.interfaces.web` |

---

## 二、类名后缀

| 类型 | 后缀规则 | 示例 |
|------|---------|------|
| 聚合根 | 业务名词，无后缀 | `Order` |
| 实体 | 业务名词，无后缀 | `OrderItem` |
| 值对象 | 业务名词，无后缀 | `Money`, `PhoneNumber`, `OrderStatus` |
| 领域服务 | `{业务}Service` | `OrderValidationService` |
| 命令服务 | `{用例}CommandService` | `OrderCommandService` |
| 查询服务 | `{用例}QueryService` | `OrderQueryService` |
| 仓储接口 | `{聚合根}Repository` | `OrderRepository` |
| 仓储实现 | `{聚合根}RepositoryImpl` | `OrderRepositoryImpl` |
| 外部网关接口 | `{系统/能力}Gateway` | `PaymentGateway` |
| 外部网关实现 | `{系统/能力}GatewayImpl` | `PaymentGatewayImpl` |
| 命令对象 | `{动作}Command` | `CreateOrderCommand` |
| 查询对象 | `{动作}Query` | `OrderDetailQuery` |
| 请求 DTO | `{动作}Request` | `CreateOrderRequest` |
| 响应 DTO | `{动作}Response` | `CreateOrderResponse` |
| 领域事件 | `{聚合根}{事实}Event` | `OrderPlacedEvent` |
| Controller | `{上下文}Controller` | `OrderController` |
| RPC Provider | `{上下文}ServiceProvider` | `OrderServiceProvider` |
| 数据对象 | `{表业务名}DO` | `OrderDO` |
| Mapper | `{聚合根}Mapper` | `OrderMapper` |
| Assembler | `{上下文}Assembler` | `OrderAssembler` |
| 枚举 | `{业务名}Enum` 或直接业务名词 | `OrderStatusEnum` 或 `OrderStatus`（Java 21 推荐后者） |
| 异常 | `{范围}Exception` | `OrderNotFoundException` |
| 配置类 | `{技术组件}Config` | `MyBatisPlusConfig` |
| 测试类 | `{被测类名}Test` | `OrderCommandServiceTest` |

---

## 三、方法名

### Repository 方法

| 语义 | 命名规则 | 示例 |
|------|---------|------|
| 按 ID 查单条 | `findById` | `findById(OrderId id)` |
| 查列表 | `findAllBy{字段}` | `findAllByCustomerId(...)` |
| 保存/更新 | `save` | `save(Order aggregate)` |
| 删除 | `remove` | `removeById(OrderId id)` |

### 业务领域方法

| 时态 | 语义 | 示例 |
|------|------|------|
| 进行时 | 下单 | `place(CreateOrderCommand cmd)` |
| 进行时 | 提交审批 | `submitForApproval()` |
| 进行时 | 取消 | `cancel(String reason)` |
| 完成时 | 支付结果回调 | `onPaymentCompleted(PaymentResult result)` |
| 完成时 | 发货结果回调 | `onShipped(ShipmentResult result)` |
| 布尔判断 | — | `isExpired()`, `canCancel()`, `hasCompleted()` |

---

## 四、数据库命名

| 对象 | 规则 | 示例 |
|------|------|------|
| 表名 | `t_{业务名}_snake_case`，单数 | `t_order`, `t_order_item` |
| 字段名 | snake_case | `apply_amount`, `created_at` |
| 普通索引 | `idx_{字段}` | `idx_customer_id` |
| 唯一索引 | `uk_{字段}` | `uk_order_no` |
| 枚举值 | 全大写 | `INIT`, `SUCCESS`, `FAILED` |

---

## 五、Git 规范

- 提交信息格式：`type(scope): description`
- 类型：`feat` / `fix` / `refactor` / `test` / `docs` / `chore`
- 分支命名：`feature/xxx`, `fix/xxx`, `refactor/xxx`
