# 账务系统（Accounting）— 功能规范

> 由 brainstorming 工作流产出。天枢银行核心系统群的第一个落地系统。

## 概述

账务系统是天枢银行核心系统群的基石，为支付、交易、清结算、信贷核心、卡系统等上层系统提供统一的记账和账户管理能力。系统基于复式记账法，对外提供交易驱动的记账接口（调用方提交业务指令，系统内部自动拆解为借贷分录），管理客户户、内部户和虚拟子账户的全生命周期。

## 系统定位

- **有界上下文名称**：Accounting
- **分类**：核心域（Core）
- **在上下文映射中的角色**：高频 upstream，为 Payment、Transaction、Clearing、LoanCore、CardSystem 提供 OHS 服务
- **一句话职责**：银行的"账本"——账户生命周期管理 + 交易驱动记账 + 余额维护 + 日终处理

## 用户故事

### US-1: 开立客户账户

**作为**支付系统/卡系统，**我想要**调用账务系统为客户开立账户，**以便**客户可以进行资金交易。

**验收标准：**
- [ ] 指定客户号、科目代码、账户类型后，系统生成唯一 account_id（Snowflake）和 account_no（业务账号）
- [ ] 账户初始状态为 ACTIVE，余额为零
- [ ] 相同客户号 + 科目代码 + 账户类型不可重复开户（幂等）
- [ ] 发布 AccountOpenedEvent 领域事件

### US-2: 开立内部户

**作为**运营管理员，**我想要**开立银行内部账户（手续费收入户、清算过渡户等），**以便**银行内部资金流转有账可记。

**验收标准：**
- [ ] 内部户不关联客户号，关联法人实体
- [ ] 内部户类型包括：手续费收入户、清算过渡户、待处理户、差错户等
- [ ] 内部户开户后状态为 ACTIVE

### US-3: 交易驱动记账

**作为**支付系统/交易系统/信贷核心，**我想要**提交一笔业务记账指令（如"从 A 账户转 100 到 B 账户，手续费 0.5 归入手续费收入户"），**以便**账务系统自动完成复式记账。

**验收标准：**
- [ ] 调用方提交业务记账指令（结构见 FR-4），系统校验指令完整性
- [ ] 系统内部自动拆解为记账凭证 + 多条借贷分录
- [ ] 每张凭证借方合计 = 贷方合计（借贷平衡）
- [ ] 账户余额实时更新
- [ ] 相同业务流水号重复提交返回已处理结果（幂等）
- [ ] 发布 AccountingCompletedEvent 领域事件

### US-4: 全额冲正

**作为**支付系统/交易系统，**我想要**对一笔已完成的记账进行全额冲正，**以便**纠正错误记账。

**验收标准：**
- [ ] 指定原凭证号，系统生成一张反向凭证（借贷方向互换）
- [ ] 原凭证标记为已冲正，反向凭证关联原凭证
- [ ] 账户余额恢复
- [ ] 已冲正的凭证不可再次冲正
- [ ] 发布 AccountingReversedEvent 领域事件

### US-5: 账户冻结/解冻

**作为**风控系统/司法系统，**我想要**冻结指定账户的指定金额或全额，**以便**限制账户资金流出。

**验收标准：**
- [ ] 支持部分冻结（冻结指定金额）和全额冻结
- [ ] 冻结后可用余额 = 当前余额 - 冻结金额
- [ ] 同一账户可叠加多笔冻结（不同冻结源）
- [ ] 解冻时按冻结明细逐笔解冻
- [ ] 发布 AccountFrozenEvent / AccountUnfrozenEvent

### US-6: 账户状态管理

**作为**运营管理员/风控系统，**我想要**管理账户的生命周期状态和交易限制状态，**以便**控制账户的交易能力。

**验收标准：**
- [ ] 生命周期状态迁移：ACTIVE → PENDING_CLOSE → CLOSED
- [ ] 交易限制状态：NONE / STOP_PAYMENT / PARTIAL_FREEZE / FULL_FREEZE
- [ ] 活跃状态：NORMAL / DORMANT
- [ ] 止付状态下禁止出账但允许入账
- [ ] 销户前校验：余额=0、冻结金额=0、无未完成交易
- [ ] 状态变更记录审计日志

### US-7: 虚拟子账户管理

**作为**业务系统，**我想要**在主账户下创建虚拟子账户，**以便**实现资金隔离或记账隔离。

**验收标准：**
- [ ] 资金隔离型子账户：独立余额，主账户余额 = Σ 子账户余额
- [ ] 记账隔离型子账户：虚拟余额，资金实际在主账户
- [ ] 子账户有独立的 account_id 和 virtual_no
- [ ] 资金隔离型子账户可独立记账
- [ ] 记账隔离型子账户只更新虚拟余额，实际记账在主账户

### US-8: 日终处理

**作为**账务系统（批处理），**我想要**在每日营业结束后执行日切和余额快照，**以便**为对账和报表提供数据。

**验收标准：**
- [ ] 日切：切换会计日，日切后的交易归入下一个会计日
- [ ] 余额快照：记录每个账户的日终余额
- [ ] 发生额汇总：汇总每个账户的日间借方发生额和贷方发生额
- [ ] 日切状态可查询（当前会计日、是否已日切）

### US-9: 批量记账

**作为**清结算系统/信贷核心，**我想要**通过异步方式提交批量记账请求，**以便**高效处理大批量记账。

**验收标准：**
- [ ] 通过 MQ 提交批量记账请求
- [ ] 每笔记账独立幂等
- [ ] 批量处理完成后发布汇总事件
- [ ] 单笔失败不影响其他笔记账

### US-10: 账务流水查询

**作为**对账系统/客服系统，**我想要**查询账户的账务流水，**以便**核对交易和处理客户咨询。

**验收标准：**
- [ ] 按账户号 + 时间范围查询流水
- [ ] 流水包含：凭证号、业务流水号、借贷方向、金额、交易前余额、交易后余额、业务类型、时间
- [ ] 流水不可篡改

## 功能需求

### FR-1: 账户体系

账务系统管理三类账户：

| 账户类型 | 说明 | owner_type |
|---------|------|-----------|
| 客户户（MAIN） | 客户资金归属主体，关联客户号 | CUSTOMER |
| 内部户（INTERNAL） | 银行内部管理账户，关联法人实体 | INSTITUTION |
| 资金隔离型子账户（SUB_REAL） | 挂在主账户下，独立余额 | CUSTOMER |
| 记账隔离型子账户（VIRTUAL） | 挂在主账户下，虚拟余额 | CUSTOMER |

### FR-2: 账户标识体系

三层标识，参考 `#[[file:.governance/references/business/账户唯一标识设计决策.md]]`：

| 标识 | 用途 | 生成方式 | 是否可变 |
|------|------|---------|---------|
| account_id | 系统内部唯一主键 | Snowflake | 不可变 |
| account_no | 业务账号（对内对外） | 法人代码+产品代码+顺序号+校验位 | 尽量不变 |
| virtual_no | 虚拟子账户号码 | 独立编号体系 | 尽量不变 |

- 内部服务间调用使用 accountId
- 对外接口使用 accountNo
- 外部映射（卡号→账号等）由各外部系统自行维护，不在账务系统管理

### FR-3: 余额管理

每个账户维护以下余额：

| 余额字段 | 说明 | 计算规则 |
|---------|------|---------|
| balance | 当前余额（账面余额） | 期初余额 + 借方发生额 - 贷方发生额 |
| available_balance | 可用余额 | balance - frozen_amount |
| frozen_amount | 冻结金额 | Σ 各冻结明细金额 |

金额类型统一使用 `BigDecimal`，数据库使用 `DECIMAL(18,4)`。Phase 1 人民币业务精度到分（2 位小数），但数据库预留 4 位小数，为后续多币种扩展（部分币种需要 3-4 位小数精度）和利息计算中间值避免精度丢失。

### FR-4: 交易驱动记账模型

调用方提交业务指令，账务系统内部拆解为复式分录。

**接口分层设计**：

账务系统提供两层记账接口，兼顾灵活性与易用性：

| 层次 | 接口 | 调用方职责 | 适用场景 |
|------|------|-----------|---------|
| 底层通用接口 | postAccounting(AccountingCommand) | 调用方自行组装完整 entries | 清结算批量记账、复杂多方记账 |
| 场景化快捷接口 | transfer(TransferCommand) | 只需提供源/目标账户和金额 | 转账 |
| 场景化快捷接口 | consume(ConsumeCommand) | 只需提供账户、金额、商户 | 卡消费/退款 |

- 场景化接口内部调用底层通用接口，由账务系统根据 bizType 自动补全手续费分录、过渡户分录等
- Phase 1 先实现底层通用接口 + transfer 快捷接口，其他场景化接口按需扩展
- Phase 2 可引入记账模板引擎，通过配置化方式支持更多场景

**底层通用记账指令（输入）**：
```
{
  "bizNo": "PAY202604210001",        // 业务流水号（幂等键）
  "bizType": "TRANSFER",             // 业务类型
  "accountingDate": "2026-04-21",    // 会计日（为空则取当前会计日）
  "currency": "CNY",                 // 币种（ISO 4217，Phase 1 仅支持 CNY）
  "channelCode": "PAYMENT",          // 渠道来源（标识调用方系统）
  "operatorId": "SYS_PAYMENT",       // 操作员/发起方标识
  "memo": "转账 A→B + 手续费",        // 业务备注（可选）
  "entries": [
    { "accountNo": "A001", "amount": 100.00, "direction": "OUT", "summary": "转账出款" },
    { "accountNo": "B001", "amount": 100.00, "direction": "IN",  "summary": "转账入款" },
    { "accountNo": "A001", "amount": 0.50,   "direction": "OUT", "summary": "手续费扣收" },
    { "accountNo": "FEE001", "amount": 0.50, "direction": "IN",  "summary": "手续费收入" }
  ]
}
```

**指令字段说明**：

| 字段 | 必填 | 说明 |
|------|------|------|
| bizNo | 是 | 业务流水号，作为幂等键，全局唯一 |
| bizType | 是 | 业务类型（TRANSFER / FEE / INTEREST / CLEARING 等） |
| accountingDate | 否 | 会计日，为空则取当前 OPEN 状态的会计日 |
| currency | 是 | 币种，Phase 1 仅支持 CNY |
| channelCode | 是 | 渠道来源，标识调用方系统 |
| operatorId | 是 | 操作员或发起方系统标识，用于审计追溯 |
| memo | 否 | 业务备注 |
| entries | 是 | 记账分录列表，至少 2 条 |
| entries[].accountNo | 是 | 账户业务账号 |
| entries[].amount | 是 | 金额，必须大于 0 |
| entries[].direction | 是 | 资金方向：OUT（出账）/ IN（入账） |
| entries[].summary | 否 | 分录摘要 |

**内部拆解为复式分录**：
- 系统根据账户科目的 normal_balance_direction 自动确定借贷方向
- 资产类（ASSET）/费用类（EXPENSE）账户：增加记借方，减少记贷方
- 负债类（LIABILITY）/收入类（REVENUE）/所有者权益类（EQUITY）账户：增加记贷方，减少记借方
- 共同类（COMMON）账户：无固定方向，按实际业务的资金流向确定借贷方向（如清算资金往来、货币兑换）
- 生成记账凭证，校验借贷平衡

**科目类型完整分类**：

| 科目类型 | 英文标识 | normal_balance_direction | 典型科目 |
|---------|---------|------------------------|---------|
| 资产类 | ASSET | DEBIT | 存放央行款项、发放贷款 |
| 负债类 | LIABILITY | CREDIT | 客户存款、同业存放 |
| 共同类 | COMMON | 按余额方向确定 | 清算资金往来、货币兑换 |
| 所有者权益类 | EQUITY | CREDIT | 实收资本、盈余公积 |
| 收入类 | REVENUE | CREDIT | 利息收入、手续费收入 |
| 费用类 | EXPENSE | DEBIT | 利息支出、业务费用 |

### FR-5: 科目引用

科目体系外部化，参考 `#[[file:.governance/references/business/账务系统科目体系设计决策.md]]`：

- 科目主数据由参数中心/产品中心维护
- 账务系统本地保留科目快照/缓存：subject_code、subject_name、normal_balance_direction、subject_type
- Phase 1 先在账务系统内置科目表，接口按外部化设计
- 开户时必须指定科目代码

### FR-6: 幂等控制

- 以业务流水号（bizNo）作为幂等键
- 相同 bizNo 重复提交，返回已处理的凭证结果
- 幂等记录持久化，不依赖缓存

### FR-7: 全额冲正

- 指定原凭证号，生成反向凭证（借贷方向互换，金额不变）
- 原凭证标记为 REVERSED，反向凭证标记为 REVERSAL 并关联原凭证号
- 已冲正凭证不可再次冲正
- 冲正操作本身也有幂等控制

### FR-8: 账户状态机

参考 `#[[file:.governance/references/business/账户状态机设计决策.md]]`，MVP 阶段采用两个维度：

**生命周期状态（lifecycle_status）**：
```
ACTIVE → PENDING_CLOSE → CLOSED
```

**交易限制状态（restriction_status）**：
```
NONE / STOP_PAYMENT / PARTIAL_FREEZE / FULL_FREEZE
```

**活跃状态（activity_status）**：
```
NORMAL / DORMANT
```

状态变更规则：
- STOP_PAYMENT：禁止出账，允许入账（银行内部风控/运营触发，不冻结金额，仅限制交易方向）
- PARTIAL_FREEZE：冻结指定金额，可用余额减少，出入账均允许但出账受可用余额限制
- FULL_FREEZE：禁止出账，禁止入账（司法冻结/严重风险场景，冻结全部金额，账户完全不可交易）
- DORMANT：需激活后才能交易
- CLOSED：终态，不可恢复，销户前必须校验余额=0、冻结=0、无未完成交易

### FR-9: 冻结明细管理

一个账户可同时存在多笔冻结（不同冻结源）：

| 字段 | 说明 |
|------|------|
| freeze_id | 冻结明细 ID |
| account_id | 账户 ID |
| freeze_amount | 冻结金额 |
| freeze_type | 冻结类型（JUDICIAL / RISK / PLEDGE） |
| freeze_reason | 冻结原因 |
| freeze_source | 冻结来源系统 |
| freeze_time | 冻结时间 |
| unfreeze_time | 解冻时间（null 表示未解冻） |

### FR-10: 虚拟子账户

参考 `#[[file:.governance/references/business/虚拟子账户设计决策.md]]`：

**资金隔离型（SUB_REAL）**：
- 独立 account_id，parent_account_id 关联主账户
- 独立余额，可独立记账
- 主账户余额 = Σ 子账户余额

**记账隔离型（VIRTUAL）**：
- 独立 account_id，parent_account_id 关联主账户
- 虚拟余额（dimension_balance），资金实际在主账户
- 记账时更新主账户真实余额 + 子账户虚拟余额
- 虚拟账户不可直接出金

### FR-11: 日终处理

- **日切**：切换会计日，维护 AccountingDay 聚合
- **余额快照**：记录每个账户的日终余额（balance、available_balance、frozen_amount）
- **发生额汇总**：汇总每个账户的日间借方发生额和贷方发生额
- 日切状态：OPEN → CUTTING → CLOSED
- 日切后的交易归入下一个会计日

### FR-12: 存款计息（预留边界）

参考 `#[[file:.governance/references/business/计息职责归属决策.md]]` 和 `#[[file:.governance/references/business/存款计息跨域数据依赖决策.md]]`：

- 当前放在账务域内，作为独立聚合（DepositInterest），拥有独立的聚合根和持久化
- 存款计息通过 Account 聚合的应用服务接口（AccountRepository / AccountQueryService）获取账户和余额数据，禁止通过 SQL join 直接穿透访问 Account 聚合的表
- 代码边界清晰，后续可独立为 deposit-core
- Phase 1 同库不同表，通过应用层接口交互，确保聚合边界完整
- 不与贷款计息混用同一个引擎

## 聚合设计

### 聚合一：Account（账户）

**职责**：账户生命周期管理、余额维护、冻结/解冻

**聚合根**：Account
- 标识：account_id（Snowflake）
- 核心字段：account_no、account_type、owner_type、owner_id、parent_account_id、subject_code、currency、balance、available_balance、frozen_amount、lifecycle_status、restriction_status、activity_status
- 值对象：Money（金额）、AccountNo（账户号码）
- 实体：FreezeRecord（冻结明细，聚合内实体）

**不变量**：
- INV-01：available_balance = balance - frozen_amount
- INV-02：frozen_amount ≥ 0
- INV-03：资金隔离型子账户的主账户余额 = Σ 子账户余额
- INV-04：销户时 balance = 0 且 frozen_amount = 0

**领域方法**：
- open()：开户
- credit(amount)：入账（增加余额）
- debit(amount)：出账（减少余额，校验可用余额）
- freeze(amount, type, reason, source)：冻结
- unfreeze(freezeId)：解冻
- stopPayment(reason)：止付
- resumePayment()：恢复付款
- markDormant()：标记休眠
- reactivate()：激活
- close()：销户

**领域事件**：
- AccountOpenedEvent
- AccountFrozenEvent
- AccountUnfrozenEvent
- AccountClosedEvent

### 聚合二：AccountingVoucher（记账凭证）

**职责**：记账指令受理、分录拆解、借贷平衡校验、冲正

**聚合根**：AccountingVoucher
- 标识：voucher_id（Snowflake）
- 核心字段：voucher_no、biz_no（幂等键）、biz_type、voucher_type（NORMAL / REVERSAL）、status（CREATED / POSTED / REVERSED）、accounting_date、original_voucher_id（冲正关联）
- 实体：AccountingEntry（记账分录，聚合内实体）

**AccountingEntry 字段**：
- entry_id、voucher_id、account_id、account_no、subject_code、direction（DEBIT / CREDIT）、amount、balance_before、balance_after、summary

**不变量**：
- INV-05：每张凭证 Σ 借方金额 = Σ 贷方金额（借贷平衡）
- INV-06：凭证一旦 POSTED 不可修改，只能冲正
- INV-07：已 REVERSED 的凭证不可再次冲正

**领域方法**：
- create(bizNo, bizType, entries)：创建凭证并拆解分录
- post()：过账（更新账户余额）
- reverse()：全额冲正

**领域事件**：
- AccountingCompletedEvent
- AccountingReversedEvent

### 聚合三：AccountingDay（会计日）

**职责**：会计日管理、日切控制

**聚合根**：AccountingDay
- 标识：accounting_date（LocalDate）
- 核心字段：status（OPEN / CUTTING / CLOSED）、opened_at、closed_at

**不变量**：
- INV-08：同一时刻只有一个会计日处于 OPEN 状态
- INV-09：CLOSED 的会计日不可重新打开

**领域方法**：
- open()：开启新会计日
- startCutOff()：开始日切
- completeCutOff()：完成日切

**领域事件**：
- DayCutOffCompletedEvent

## 对外接口

### 同步 RPC 接口（Dubbo）

| 接口 | 方法 | 调用方 |
|------|------|--------|
| AccountApiClient | openAccount(request) | 支付、卡系统、信贷核心 |
| AccountApiClient | queryAccount(accountNo) | 所有系统 |
| AccountApiClient | freezeAccount(request) | 风控系统 |
| AccountApiClient | unfreezeAccount(request) | 风控系统 |
| AccountingApiClient | postAccounting(request) | 支付、交易、信贷核心 |
| AccountingApiClient | reverseAccounting(request) | 支付、交易 |
| AccountingApiClient | queryVoucher(voucherNo) | 对账系统 |
| AccountingApiClient | queryEntries(accountNo, dateRange) | 对账系统、客服 |

### 异步 MQ 接口（RocketMQ）

| Topic | 消费方 | 说明 |
|-------|--------|------|
| BATCH_ACCOUNTING_REQUEST | 账务系统 | 批量记账请求（清结算、信贷核心发送） |
| ACCOUNTING_COMPLETED | 支付、交易、清结算 | 记账完成事件 |
| ACCOUNTING_REVERSED | 支付、交易 | 冲正完成事件 |
| ACCOUNT_STATUS_CHANGED | 风控、对账 | 账户状态变更事件 |

## 非功能需求

- **性能**：单笔同步记账 < 50ms（P99），日终日切 < 30 分钟（千万级账户）
- **一致性**：记账操作必须事务一致，账户余额与分录严格一致
- **幂等**：所有写操作必须幂等
- **审计**：所有状态变更和记账操作不可篡改，保留完整审计轨迹
- **可用性**：记账服务 99.99% 可用

## 非目标（明确不做的事）

| 不做的事 | 理由 | 后续迭代 |
|---------|------|---------|
| 在途余额 | MVP 不需要，后续完善 | Phase 2 |
| 多币种余额 | MVP 不需要，后续完善 | Phase 2 |
| 部分冲正 | 复杂度高，先做全额冲正 | Phase 2 |
| 红字记账 | 先用冲正模式 | 按需 |
| 总账账户（GL） | 属于财务系统范畴 | Phase 3 |
| 多法人账套 | 后续扩展 | Phase 3 |
| 外部映射管理（卡号→账号） | 由卡系统等外部系统维护 | — |
| 贷款计息 | 由信贷核心负责 | — |
| 前端/管理后台 | 专注后端微服务 | — |
| 额度控制型子账户 | 由额度中心负责 | — |
| compliance_status | 合规状态维度，Phase 2 补充 | Phase 2 |

## 遗留决策与演进路径

| 决策点 | 当前方案 | 演进方向 |
|--------|---------|---------|
| 存款计息 | 放在账务域内，独立聚合，通过应用层接口获取账户数据 | 后续可能独立为 deposit-core |
| 科目体系 | 账务系统内置科目表，接口按外部化设计 | Phase 2 迁移到参数中心 |
| 批量计息数据 | 同库，通过应用层接口查询 | Phase 2 CDC 同步 + 独立库 |
| 账户状态 | lifecycle + restriction + activity 三维度 | Phase 2 补充 compliance_status |
| 批量记账 | 异步 MQ | 按需优化吞吐 |

## 开放问题

- [ ] account_no 的具体编码规则（法人代码位数、产品代码位数、校验位算法）需要在实现阶段确定
- [ ] 科目快照的同步机制（Phase 1 内置，具体同步策略待定）
- [ ] 日终批处理的调度框架选型（XXL-Job vs Spring Batch）

## 参考文档

- `#[[file:.governance/references/business/银行完整账户体系设计.md]]`
- `#[[file:.governance/references/business/账户唯一标识设计决策.md]]`
- `#[[file:.governance/references/business/账户状态机设计决策.md]]`
- `#[[file:.governance/references/business/账务系统科目体系设计决策.md]]`
- `#[[file:.governance/references/business/虚拟子账户设计决策.md]]`
- `#[[file:.governance/references/business/计息职责归属决策.md]]`
- `#[[file:.governance/references/business/存款计息跨域数据依赖决策.md]]`
- `#[[file:.governance/domain/contexts/context-map.yaml]]`
- `#[[file:.governance/domain/contexts/system-landscape.yaml]]`

## 审查清单

- [x] 无 [NEEDS CLARIFICATION] 标记残留
- [x] 需求可测试且无歧义
- [x] 成功标准可衡量
- [x] 无推测性或"可能需要"的功能
- [x] 非目标明确列出
- [x] 遗留决策和演进路径记录完整
- [x] 所有设计决策有参考文档支撑
