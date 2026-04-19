# [上下文名] — 持久化模型

> 使用 SQL DDL 定义表结构。大模型对标准 SQL 有极高的理解力，
> 这比用 YAML/JSON 去"翻译"表结构要准确得多。

## 表结构

### t_[context]_[entity]

```sql
CREATE TABLE `t_context_entity` (
    `id`              BIGINT          NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    -- ── 业务字段 ──────────────────────────────────
    -- [根据聚合定义填写]
    -- ── 状态字段 ──────────────────────────────────
    `status`          VARCHAR(32)     NOT NULL                COMMENT '状态',
    -- ── 审计字段 ──────────────────────────────────
    `created_time`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_time`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `created_by`      VARCHAR(64)     NOT NULL DEFAULT ''     COMMENT '创建人',
    `updated_by`      VARCHAR(64)     NOT NULL DEFAULT ''     COMMENT '更新人',
    PRIMARY KEY (`id`),
    -- ── 索引 ──────────────────────────────────────
    -- KEY `idx_xxx` (`field1`, `field2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='[表中文名]';
```

## 聚合 ↔ 表映射

| 聚合/实体 | 表名 | 说明 |
|-----------|------|------|
| [AggregateName] | `t_context_entity` | [映射说明] |

## 字段映射备注

[如有领域模型字段与数据库列名不一致的情况，在此说明映射关系]
