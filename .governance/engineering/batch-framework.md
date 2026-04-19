# 批处理框架规范

> 适用于所有定时任务和批处理作业的设计与实现。

## 一、分层职责

```
{project}-batch (调度入口)
  └── Handler / Job：接收调度信号，委托给 Task/Processor，不含业务逻辑

{project}-core (领域层)
  └── batch/：批处理框架抽象基类（纯 Java，无框架依赖）

infrastructure/ (任务实现)
  └── Task 类：继承 core 层抽象基类，实现具体的 read/process/write
```

**原则**：Handler 只做调度适配，Task 住在 infrastructure 可被 online 复用。

---

## 二、任务分类

| 类型 | 场景 | 频率 | 关键要求 |
|------|------|------|----------|
| 补偿型 | Outbox 补偿、超时重试 | 10s~60s | 幂等、分布式锁、小批量 |
| 数据修复型 | 存量数据补全、迁移 | 一次性 | ID Range 游标、可中断 |
| 告警型 | 积压检查、超时告警 | 1~5min | 轻量查询、阈值可配 |
| 对账型 | 资金对账、结果核对 | 日终 | 全量扫描、差异记录 |
| 清理型 | 过期数据归档 | 日终 | 批量操作、可中断 |
| 同步型 | 数据同步、刷新 | 按需 | 增量优先、全量兜底 |

---

## 三、核心数据流：Read → Process → Write

```
readBatch(ctx)             process(T item)           writeBatch(ctx, results)
┌─────────────┐           ┌──────────────┐           ┌──────────────────┐
│ 批量读取源数据 │ ──T──▶  │ 逐条转换/处理  │ ──R──▶  │ 批量写入处理结果   │
│ List<T>      │           │ T → R         │           │ List<R>           │
└─────────────┘           └──────────────┘           └──────────────────┘
```

**Config vs Context 分离**：
- `BatchConfig`：不可变初始配置（batchSize / logInterval / skipOnException）
- `BatchContext`：运行时可变上下文（游标位置 / 统计 / 中断标志）

---

## 四、设计原则

| 编号 | 原则 | 要点 |
|------|------|------|
| P01 | 幂等性 | 依赖数据状态判断，而非执行次数 |
| P02 | 分布式锁 | 基类内置锁编排，子类提供 lockKey() |
| P03 | ID Range 游标 | 禁止一次性 SELECT *，分批游标滚动 |
| P04 | 远程中断 | 配置中心开关刹车，BatchResult 携带游标支持断点续做 |
| P05 | 条件跳过 | shouldSkip() 钩子，跳过与失败分别统计 |
| P06 | 异常隔离 | skipOnException 控制单条失败是否终止整批 |
| P07 | 五维统计 | read / process / write / skip / error |
| P08 | 日志节奏 | logInterval 控制打印频率，避免日志爆炸 |
| P09 | 配置外置 | 运行时可调参，无需重启 |
| P10 | 事务边界 | 每批独立事务，禁止大事务包裹整批 |
| P11 | 生命周期钩子 | beforeProcess / afterProcess 扩展点 |
| P12 | 子任务编排 | 多个 Processor 串行/并行，各自独立 checkpoint |

---

## 五、框架抽象基类

```java
public abstract class SimpleBatchProcessor<T, R> {

    // 子类必须实现
    protected abstract List<T> readBatch(BatchContext ctx);
    protected abstract R process(T data) throws Exception;
    protected abstract void writeBatch(BatchContext ctx, List<R> results) throws Exception;
    protected abstract String getLogTag();

    // 子类可选覆盖
    protected String lockKey() { return null; }
    protected boolean shouldSkip(T data) { return false; }
    protected void beforeProcess(BatchContext ctx) throws Exception {}
    protected void afterProcess(BatchContext ctx) throws Exception {}
    protected boolean checkExternalInterrupt() { return false; }

    // 执行入口（内置分布式锁编排）
    public BatchResult execute(BatchConfig config) { ... }
}
```

---

## 六、两种 Task 模式

| 维度 | SimpleBatchProcessor（RPW 三阶段） | 补偿型 Task（状态推进） |
|------|-------------------------------------|------------------------|
| 场景 | 数据修复、迁移、对账 | Outbox 补偿、超时重试 |
| 数据流 | readBatch → process → writeBatch | scanPending → processOne |
| 游标 | ID Range 滚动 | 状态扫描直到空 |
| 写入 | 攒批后一次写 | 逐条更新状态 |

---

## 七、Spring Batch 集成（可选）

使用 Spring Batch 时，遵循其 Reader-Processor-Writer 模型，但设计原则（P01~P12）同样适用。

```
{project}-batch/
└── job/
    ├── reader/      # ItemReader
    ├── processor/   # ItemProcessor
    └── writer/      # ItemWriter
```
