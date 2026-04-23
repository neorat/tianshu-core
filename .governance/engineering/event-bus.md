# 领域事件总线规范

## 一、核心模型

### 领域事件基类（由 engineering-core 提供）

| 类型 | 位置 | 职责 |
|------|------|------|
| `DomainEvent` | `core.event` | 抽象基类，携带事件元数据，零框架依赖 |
| `DomainEventPublisher` | `core.event` | 发布端口接口，Core 层定义，Infrastructure 层实现 |
| `DomainEventSubscriber<E>` | `core.event` | 订阅端口接口，含幂等校验钩子 |

```java
@Getter
public abstract class DomainEvent implements Serializable {
    private String eventId;          // UUID
    private String eventType;        // 子类 SimpleName
    private String sourceContext;    // 来源上下文（ORDER / PAYMENT 等）
    private String aggregateId;      // 聚合根 ID
    private String aggregateType;    // 聚合根类型名
    private LocalDateTime occurredAt;

    protected DomainEvent(String sourceContext, String aggregateId, String aggregateType) {
        this.eventId = UUID.randomUUID().toString().replace("-", "");
        this.eventType = this.getClass().getSimpleName();
        this.sourceContext = sourceContext;
        this.aggregateId = aggregateId;
        this.aggregateType = aggregateType;
        this.occurredAt = LocalDateTime.now();
    }
}
```

### 子类定义示例

子类在各上下文 `domain.event` 包下定义，携带各自业务字段：

```java
// Java 21 推荐：继承 DomainEvent
public class OrderPlacedEvent extends DomainEvent {
    private final BigDecimal amount;
    private final String customerId;

    public OrderPlacedEvent(String orderId, BigDecimal amount, String customerId) {
        super("ORDER", orderId, "Order");
        this.amount = amount;
        this.customerId = customerId;
    }
}
```

### 发布与订阅接口

```java
// 发布端口 — Infrastructure 层实现
public interface DomainEventPublisher {
    void publish(DomainEvent event);
    void publishAll(List<DomainEvent> events);
}

// 订阅端口 — 各上下文 Infrastructure 层实现
public interface DomainEventSubscriber<E extends DomainEvent> {
    void onEvent(E event);
    Class<E> subscribedToEventType();
    default boolean isConsumed(E event) { return false; }  // 幂等钩子
}
```

### 聚合根集成

聚合根需支持事件注册：
- `registerEvent(DomainEvent event)`：业务操作中暂存事件
- `getDomainEvents()`：供应用层在事务中取出
- `clearDomainEvents()`：持久化到 Outbox 后清空

---

## 二、发布模式

### 模式 A：Spring ApplicationEvent（进程内）

适用于同一微服务内的模块间通信：

```java
// 发布：在 Application Service 中
applicationEventPublisher.publishEvent(new OrderPlacedEvent(order.getId(), ...));

// 消费：在同一服务的 Application 层
@EventListener
void on(OrderPlacedEvent event) { ... }
```

配合 `@TransactionalEventListener(phase = AFTER_COMMIT)` 确保事件在事务提交后才触发。

### 模式 B：Transactional Outbox（跨微服务/MQ）

适用于需要通过 MQ 跨系统传播的场景：

1. 业务操作 + 写 Outbox 表在同一事务中
2. 事务提交后，异步发送 MQ
3. 补偿任务定期扫描未发送的 Outbox 记录

```
聚合根.registerEvent() → 应用层取出 → 同事务写 Outbox → afterCommit 发 MQ
                                                          ↓
                                              OutboxRelayTask 补偿扫描
```

---

## 三、消费规范

### 幂等性

- **[强规则]** 消费者必须通过状态机检查或唯一约束保证逻辑幂等
- 不依赖"只消费一次"的假设
- `DomainEventSubscriber.isConsumed()` 提供幂等校验钩子

### 性能

- 消费逻辑不宜过重，复杂逻辑应通过异步任务或另发事件拆分

### 零框架依赖

- `DomainEvent` 所在包（Core 层）严禁引入 Spring / RocketMQ 等第三方依赖
- MQ 发送逻辑在 Infrastructure 层实现

---

## 四、约束清单

- [ ] 事件对象不可变
- [ ] 消费者幂等
- [ ] Domain 层事件类零框架依赖
- [ ] 事件发布与业务操作在同一事务中（Outbox 模式）或使用 `@TransactionalEventListener`
- [ ] 补偿任务覆盖发送失败场景
- [ ] 死信消费者处理重试耗尽的消息
