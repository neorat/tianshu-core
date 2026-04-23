# 外部系统集成规范

## 一、Gateway 设计原则

**[强规则]** 一个外部系统 = 一个 Gateway 接口 + 一个实现类。

| 原则 | 说明 |
|------|------|
| 接口位置 | `domain/{context}/repository/` |
| 实现位置 | `infrastructure/{component}/{context}/` |
| 禁止 | 将同一系统拆分为多个 Gateway |

### 入参规范

- Gateway 入参优先直接使用领域对象（聚合根、值对象），不强制定义独立 Command
- GatewayImpl 负责从领域对象提取字段，组装外部系统报文
- 仅当需要跨多个聚合组合字段、或入参与领域对象结构差异过大时，才定义独立 Command

### 出参规范

- 返回独立的 Result 对象，继承 `AbstractGtwResult`
- 外部响应 → 内部 Result 的映射在 GatewayImpl 中完成
- **[强规则]** Gateway 返回的 Result 可直接作为领域层值对象使用，避免冗余转换

---

## 二、四态语义（IGtwCallStatus + AbstractGtwResult）

### 核心类型（由 engineering-core 提供）

| 类型 | 位置 | 职责 |
|------|------|------|
| `GatewayCallStatusEnum` | `core.gateway` | 四态枚举：SUCCESS / REJECTED / PROCESSING / UNKNOWN |
| `IGtwCallStatus` | `core.gateway` | 调用状态接口，提供 isSuccess/isRejected/isProcessing/isUnknown 便捷方法 |
| `IGtwRespInfo` | `core.gateway` | 响应信息接口，外部原始响应码（一等公民）+ 内部标准响应码（default 透传） |
| `AbstractGtwResult` | `core.gateway` | 抽象基类，同时实现 IGtwCallStatus + IGtwRespInfo + Serializable |

### GatewayCallStatusEnum 四态模型

```java
public enum GatewayCallStatusEnum {
    SUCCESS,     // 调用成功，业务受理通过
    REJECTED,    // 业务明确拒绝（如额度不足），不可重试
    PROCESSING,  // 已受理，终态待确认（异步场景）
    UNKNOWN      // 状态不确定（RPC 异常、超时），可重试
}
```

### AbstractGtwResult 使用方式

各 Gateway Result 继承 `AbstractGtwResult`，补充各自业务字段，通过静态工厂方法构建：

```java
@Getter
public class PaymentResult extends AbstractGtwResult {
    private final String transactionId;
    private final BigDecimal amount;

    private PaymentResult(GatewayCallStatusEnum callStatus,
                          String outRespCode, String outRespDesc,
                          String transactionId, BigDecimal amount) {
        super(callStatus, outRespCode, outRespDesc);
        this.transactionId = transactionId;
        this.amount = amount;
    }

    public static PaymentResult success(String txnId, BigDecimal amount) {
        return new PaymentResult(GatewayCallStatusEnum.SUCCESS, null, null, txnId, amount);
    }

    public static PaymentResult rejected(String outRespCode, String outRespDesc) {
        return new PaymentResult(GatewayCallStatusEnum.REJECTED, outRespCode, outRespDesc, null, null);
    }

    public static PaymentResult unknown(String outRespCode, String outRespDesc) {
        return new PaymentResult(GatewayCallStatusEnum.UNKNOWN, outRespCode, outRespDesc, null, null);
    }
}
```

### IGtwRespInfo 响应信息透传

`IGtwRespInfo` 将外部响应码作为一等公民，内部标准码默认透传：

```java
public interface IGtwRespInfo {
    String getOutRespCode();           // 外部原始响应码（必须实现）
    String getOutRespDesc();           // 外部原始响应描述（必须实现）
    default String getStdCode()   { return getOutRespCode(); }   // 内部标准码，默认透传
    default String getStdDesc()   { return getOutRespDesc(); }   // 内部标准描述，默认透传
    default boolean hasRespInfo() { return getOutRespCode() != null || getOutRespDesc() != null; }
}
```

业务工程可覆写 `getStdCode()` / `getStdDesc()` 做响应码映射转换。

### 映射规则

| 状态 | 语义 | 映射时机 | 调用方处理 |
|------|------|---------|-----------|
| `SUCCESS` | 外部系统明确成功 | RPC 成功 + 业务成功 + 数据完整 | 更新状态为成功 |
| `REJECTED` | 外部系统明确拒绝 | RPC 成功 + 业务拒绝 + 数据非空 | 更新状态为失败，不可重试 |
| `PROCESSING` | 已受理，终态待确认 | RPC 成功 + 业务受理 + 结果未出 | 不更新终态，等待回调或查询 |
| `UNKNOWN` | 状态不确定 | RPC 返回 null / 数据为空 / 网络异常 | 不更新状态，等待重试或补偿 |

### 关键判定原则

- `result == null` → 一律 `UNKNOWN`
- `catch Exception` → `UNKNOWN`（网络层异常，状态不确定）
- 只有 RPC 成功 + 业务成功 + 数据完整 → `SUCCESS`
- 异步场景（如代扣）受理成功但结果未出 → `PROCESSING`

### GatewayImpl 中的映射模板

```java
public PaymentResult pay(Order order) {
    try {
        ExternalPayResponse resp = externalClient.pay(buildRequest(order));
        if (resp == null) {
            return PaymentResult.unknown(null, "response is null");
        }
        if ("0000".equals(resp.getCode())) {
            return PaymentResult.success(resp.getTxnId(), resp.getAmount());
        }
        return PaymentResult.rejected(resp.getCode(), resp.getDesc());
    } catch (Exception e) {
        log.error("[GATEWAY] pay failed, orderId={}", order.getId(), e);
        return PaymentResult.unknown("EXCEPTION", e.getMessage());
    }
}
```

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
