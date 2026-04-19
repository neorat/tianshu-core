# 外部系统集成规范

## 一、Gateway 设计原则

**[强规则]** 一个外部系统 = 一个 Gateway 接口 + 一个实现类。

| 原则 | 说明 |
|------|------|
| 接口位置 | `domain/{context}/port/gateway/` |
| 实现位置 | `infrastructure/external/{context}/` |
| 禁止 | 将同一系统拆分为多个 Gateway |

### 入参规范

- Gateway 入参优先直接使用领域对象（聚合根、值对象），不强制定义独立 Command
- GatewayImpl 负责从领域对象提取字段，组装外部系统报文
- 仅当需要跨多个聚合组合字段、或入参与领域对象结构差异过大时，才定义独立 Command

### 出参规范

- 返回独立的 Result 对象，字段命名遵循项目统一语言
- 外部响应 → 内部 Result 的映射在 GatewayImpl 中完成
- **[强规则]** Gateway 返回的 Result 可直接作为领域层值对象使用，避免冗余转换

---

## 二、三态语义（IGtwCallStatus）

所有 Gateway 返回的 Result 必须实现统一的调用状态接口：

```java
public interface IGtwCallStatus {
    GatewayCallStatusEnum getCallStatus();
    default boolean isSuccess()  { return getCallStatus() == GatewayCallStatusEnum.SUCCESS; }
    default boolean isUnknown()  { return getCallStatus() == GatewayCallStatusEnum.UNKNOWN; }
    default boolean isRejected() { return getCallStatus() == GatewayCallStatusEnum.REJECTED; }
}
```

### 映射规则

| 状态 | 语义 | 映射时机 | 调用方处理 |
|------|------|---------|-----------|
| `SUCCESS` | 外部系统明确成功 | RPC 成功 + 业务成功 + 数据完整 | 更新状态为成功 |
| `REJECTED` | 外部系统明确拒绝 | RPC 成功 + 业务拒绝 + 数据非空 | 更新状态为失败 |
| `UNKNOWN` | 状态不确定 | RPC 返回 null / 数据为空 / 网络异常 | 不更新状态，等待重试或补偿 |

### 关键判定原则

- `result == null` → 一律 `UNKNOWN`
- `catch Exception` → `UNKNOWN`（网络层异常，状态不确定）
- 只有 RPC 成功 + 业务成功 + 数据完整 → `SUCCESS`

---

## 三、幂等性保障

- 每个外部请求必须包含唯一请求号
- 在发送请求前，必须持久化该幂等号，处于 `SENDING` 状态
- 外部系统应支持按请求号去重

---

## 四、超时与重试

- **查询类（Read-Only）**：允许重试，超时配置 `connect=1s, read=3s`
- **写入类（Mutation）**：禁止在 HTTP 层盲目重试。超时作为 `UNKNOWN` 处理，由补偿任务查询确认

---

## 五、回调接收

1. **验签与安全**：回调入口的签名校验在接口层完成
2. **幂等校验**：根据外部流水号查询是否已处理，已处理直接返回成功
3. **状态映射**：将外部状态映射为内部状态，严禁将外部原始响应码直接透传

---

## 六、状态映射

- 严禁将外部系统的原始响应码直接抛出给调用方
- 在 GatewayImpl 中将外部响应码映射为项目标准 ErrorCode
