# 当前开发焦点

## 当前阶段

设计阶段 — 账务系统（Accounting）功能规范完善

## 主要任务

通过 brainstorming 工作流完善账务系统 spec 文档，闭合所有设计问题后进入实现计划

## 优先级

| 优先级 | 任务 | 状态 | 备注 |
|--------|------|------|------|
| P0 | 系统群全景上下文映射 | 已完成 | system-landscape.yaml + context-map.yaml |
| P0 | 项目宪法填写（product / technical / coding-standards） | 已完成 | steering 三件套 |
| P0 | 账务系统 spec 文档完善（brainstorming） | 进行中 | 见下方进度 |
| P1 | 搭建第一个系统的 Maven 工程骨架 | 待开始 | |
| P2 | 完善各系统的统一语言字典 | 待开始 | |

## 阻塞项

- 无

## Brainstorming 进度（账务系统 spec）

### 已确认的决策（已写入 spec）

1. **US 优先级划分** — 全部 US-1~US-11 属于 Phase 1，按优先级排序实现：
   - 核心（先做）：US-1、US-2、US-3、US-4、US-6、US-10
   - 增强（后做）：US-5、US-7、US-8、US-9、US-11
2. **US-11 新增** — 存款计息与结转（合并计提和结转为一个 US）
3. **并发控制** — Phase 1 乐观锁（Account 聚合根 version 字段），Phase 2 热点账户优化
4. **账户状态模型演进** — 去掉 restriction_status 枚举，改为 debit_blocked + credit_blocked 标志位 + activity_status 枚举（NORMAL / DORMANT / UNCLAIMED），已沉淀到参考文档
5. **冻结类型扩展** — 新增 PRE_AUTH（预授权），Account 聚合新增 debitWithUnfreeze() 原子操作
6. **restriction_status 派生规则** — 自动派生，冻结明细变更后聚合根自动重算
7. **标志位审计** — 所有标志位和状态变更记录在通用审计日志表
8. **日切容错** — CUTTING 状态支持幂等重试（从断点继续），不回退到 OPEN，CUTTING 期间新交易归入下一个会计日
9. **余额快照** — 增量快照（只对当日有发生额的账户），Phase 2 按需补全量
10. **记账分录处理** — 分录不合并保留明细，余额更新按凭证合并净额操作；balance_before/after 为凭证级别

### 待讨论的问题

1. **开放问题** — account_no 编码规则、科目快照同步机制、日终调度框架选型（已确认留到实现阶段）
2. ~~spec 文档更新~~ — 已完成
3. ~~spec 自审~~ — 已完成（placeholder 扫描、一致性检查通过）
4. **用户终审** — 请用户审阅更新后的 spec
5. **过渡到实现计划** — 用户终审通过后调用 writing-plans 工作流

## 上下文备忘

- 已完成 13 个子系统的职责定义和上下文映射
- 账务系统为第一个落地系统
- 参考文档已沉淀：`.governance/references/business/账户状态标志位模型演进决策.md`
- 下次会话：继续讨论开放问题 → 更新 spec → 自审 → 用户终审 → 过渡到 writing-plans
