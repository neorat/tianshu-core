# 统一异常处理规范

## 一、设计目标

1. 各层异常职责清晰，不跨层抛出技术细节
2. 统一响应结构，HTTP / RPC 出口格式一致（均使用 `ApiResponse<T>`）
3. 错误码可追溯，支持按系统、领域上下文、层级快速定位
4. 错误信息支持 `{}` 占位符，运行时填充
5. 异常通过静态工厂方法 `XxxException.of(...)` 创建，禁止直接 `new`
6. 全局异常处理逻辑抽象复用，各协议适配器各自包装
7. HTTP 统一返回 200，错误信息在响应体 `code`/`message` 中体现

---

## 二、异常类层次

```
RuntimeException
└── BusinessException（abstract）
    ├── DomainException            领域层，业务规则违反
    ├── ApplicationException       应用层，流程编排错误，携带 useCase
    └── InfrastructureException    基础设施层，技术细节封装，携带 component
```

所有异常通过静态工厂方法创建：

```java
// ✅ 正确
throw DomainException.of(OrderErrorCode.ORDER_NOT_FOUND, orderId);
throw ApplicationException.of(OrderErrorCode.CREATE_ORDER_FAILED, "createOrder", cause);
throw InfrastructureException.of(InfraErrorCode.DATABASE_ERROR, "OrderMapper", cause);

// ❌ 错误
throw new DomainException(errorCode, null, null);
```

---

## 三、错误码体系

### 编码格式：8 位纯数字 `SS DD NNNN`

```
SS   — 2位系统编码（每个系统固定，如 01）
DD   — 2位领域上下文编码
NNNN — 4位错误序号，首位标识层级：
       1XXX — Domain 层
       2XXX — Application 层
       3XXX — Infrastructure 层
       9XXX — System/Framework 层
```

### ErrorCode 接口

```java
public interface ErrorCode {
    String getCode();
    String getMessageTemplate();

    default String resolveMessage(Object... args) {
        // 自实现 {} 占位符替换
    }
}
```

### 错误码枚举组织

| 枚举 | 位置 | 编码段 |
|------|------|--------|
| `SystemErrorCode` | domain/shared/exception/ | `SS 00 9XXX` |
| `InfraErrorCode` | infrastructure/ | `SS 00 3XXX` |
| `{Context}DomainErrorCode` | domain/{context}/exception/ | `SS DD 1XXX` |
| `{Context}AppErrorCode` | application/{context}/exception/ | `SS DD 2XXX` |

---

## 四、各层使用规范

| 层 | 抛出方式 | 捕获策略 | 日志 |
|----|---------|---------|------|
| Domain | `DomainException.of(...)` 或具名子类 | 不捕获 | 无 |
| Application | `ApplicationException.of(...)` | DomainException 直接透传；其他包装后抛出 | 无 |
| Infrastructure | `InfrastructureException.of(...)` | 技术异常全部包装；DomainException 直接透传 | 无 |
| Interfaces · HTTP | 无 | 全局 `@RestControllerAdvice` 处理 | WARN / ERROR |
| Interfaces · RPC | 无 | Provider Filter 处理 | WARN / ERROR |
| Interfaces · MQ | 无 | MqExceptionHandler 按异常类型决定重试 | WARN / ERROR |

---

## 五、全局异常处理

### ExceptionHandlerSupport（抽象基类）

三种协议适配器共享同一套转换逻辑：

```java
public abstract class ExceptionHandlerSupport {
    protected ApiResponse<Void> resolveException(Throwable ex, String channel, String operation) {
        if (ex instanceof DomainException e) {
            log.warn("[{}][{}] DomainException code={}, message={}",
                    channel, operation, e.getErrorCode().getCode(), e.getResolvedMessage());
            return ApiResponse.error(e.getErrorCode().getCode(), e.getResolvedMessage());
        }
        if (ex instanceof ApplicationException e) {
            log.warn("[{}][{}] ApplicationException useCase={}, code={}",
                    channel, operation, e.getUseCase(), e.getErrorCode().getCode());
            return ApiResponse.error(e.getErrorCode().getCode(), e.getResolvedMessage());
        }
        if (ex instanceof InfrastructureException e) {
            log.error("[{}][{}] InfrastructureException component={}",
                    channel, operation, e.getComponent(), e);
            return ApiResponse.error(SystemErrorCode.SYSTEM_ERROR.getCode(), "系统繁忙，请稍后重试");
        }
        log.error("[{}][{}] UnexpectedException", channel, operation, ex);
        return ApiResponse.error(SystemErrorCode.SYSTEM_ERROR.getCode(), "系统内部错误");
    }
}
```

### MQ 适配：按异常类型决定重试

```java
// 业务异常（Domain/Application）不重试，避免死循环
// 技术异常（Infrastructure/未知）可重试
public boolean handleAndShouldRetry(Throwable ex, String topic, String msgId) {
    resolveException(ex, "MQ", topic + "#" + msgId);
    return !(ex instanceof DomainException) && !(ex instanceof ApplicationException);
}
```

---

## 六、反例

### ❌ 跨层抛出错误类型

```java
// 错误：Infrastructure 层直接抛 DomainException
} catch (SQLException e) {
    throw DomainException.of(OrderErrorCode.ORDER_NOT_FOUND);
}
// 正确
} catch (Exception e) {
    throw InfrastructureException.of(InfraErrorCode.DATABASE_ERROR, "OrderMapper", e);
}
```

### ❌ Application 层捕获 DomainException 后重新包装

```java
// 错误：丢失原始错误码语义
try {
    orderDomainService.validate(cmd);
} catch (DomainException e) {
    throw ApplicationException.of(OrderErrorCode.CREATE_FAILED, "createOrder", e);
}
// 正确：直接透传，不捕获
orderDomainService.validate(cmd);
```

### ❌ 向上暴露技术细节

```java
// 错误：把底层 message 透传出去
throw InfrastructureException.of(InfraErrorCode.DATABASE_ERROR, "Mapper", e, e.getMessage());
// 正确：只传业务相关参数
throw InfrastructureException.of(InfraErrorCode.DATABASE_ERROR, "OrderMapper", e, orderId);
```

### ❌ 在 Domain 层吞掉异常

```java
// 错误：静默忽略
try { order.validate(); } catch (DomainException e) { log.warn("ignored"); }
// 正确：不捕获
order.validate();
```
