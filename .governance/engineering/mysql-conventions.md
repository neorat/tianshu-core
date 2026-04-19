# MySQL 研发规范

## 1. 命名规范

### 数据库
- 前缀 `d_`，小写字母 + 数字 + 下划线，长度 ≤32，必须体现业务含义

### 表
- 前缀 `t_`，小写字母 + 数字 + 下划线，长度 ≤32，使用单数
- 禁止大写、中文、特殊字符、MySQL 关键字

### 字段
- 小写字母 + 数字 + 下划线，长度 ≤32，必须体现字段含义

### 索引
- 唯一索引前缀 `uk_`，普通索引前缀 `idx_`

## 2. 库设计

- 字符集 `utf8mb4`，排序规则 `utf8mb4_general_ci`
- dev / test / prod 环境必须物理隔离

## 3. 表设计

- 引擎 `InnoDB`
- 主键字段名 `id`，仅作内部技术标识，禁止承载业务语义，禁止自增（推荐雪花算法）
- **[强规则]** 每个业务表必须设计至少一个业务唯一键，通过唯一索引保障
- **[强规则]** 跨表关联必须使用业务唯一键，禁止使用主键 `id` 关联

### 必备审计字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `create_datetime` | DATETIME | `CURRENT_TIMESTAMP` | 创建时间 |
| `update_datetime` | DATETIME | `CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` | 修改时间 |
| `create_by` | VARCHAR | — | 创建者 |
| `update_by` | VARCHAR | — | 修改者 |
| `delete_flag` | TINYINT(1) | 0 | 逻辑删除（0-未删除，1-已删除） |

### 限制

- 单表字段 ≤50（超过按冷热分表）
- 单表索引 ≤5
- 禁止 text / blob 大字段（确实需要时除外）
- 禁止外键（关联关系由应用层维护）
- 表必须有 COMMENT

## 4. 字段设计

| 类型 | 推荐 | 禁止 |
|------|------|------|
| 整数 | `int` / `bigint` | varchar 存数字 |
| 金额 | `decimal(11,2)` | float / double |
| 利率/费率 | `decimal(13,6)` | float / double |
| 字符串 | `varchar(N)`，N ≤5000 | char（统一用 varchar） |
| 时间 | `datetime`（优先） | varchar 存日期 |
| 布尔 | `tinyint(1)` | bit / varchar |
| 状态枚举 | `VARCHAR` ≤16 字符（优先）或 `tinyint(4)` | char |

### 字段约束

- 建议 NOT NULL，设置合理默认值
- 敏感信息（手机号、身份证）必须加密存储
- **每个字段必须有 COMMENT**，状态/枚举字段必须列出所有值

## 5. 索引设计

- 仅为 WHERE / JOIN / ORDER BY 高频字段建索引
- 单索引字段数 ≤3
- 区分度高的字段靠左（最左前缀匹配）
- 定期清理无效、低频、冗余索引

## 6. SQL 规范

### 查询
- 禁止 `SELECT *`
- WHERE 条件禁止对索引字段做函数/计算
- 禁止隐式类型转换
- IN 参数 ≤100
- 禁止前导模糊 `LIKE '%xxx'`
- 所有查询加 LIMIT
- 分页用书签法（`WHERE id > last_id LIMIT n`），禁止大偏移
- 上线前用 EXPLAIN 确认索引命中

### 写入
- 禁止 `REPLACE INTO`
- 禁止 `UPDATE SET xxx = NULL`
- 禁止无 WHERE 的 UPDATE / DELETE

### 事务
- 事务最小化，仅包含必要操作
- 禁止事务内调用外部接口或执行耗时逻辑

### 安全
- 禁止 SQL 拼接，必须使用参数化查询

## 7. 禁止项

- 存储过程、触发器、视图
