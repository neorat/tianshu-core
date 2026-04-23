# 统一异常处理规范

## 一、设计目标

1. 各层异常职责清晰，不跨层抛出技术细节
2. 统一响应结构，HTTP / RPC / MQ 出口格式一致（均使用 `ApiResponse<T>`）
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

### 编码格式：10 位纯数字 `BB AA SS NNNN`

```
BB   — 2位业务线编码（由 BusinessLineCode 定义）
AA   — 2位应用编码（由 ApplicationCode 定义，各业务工程自行扩展）
SS   — 2位分层编码：
       10 — Domain 层
       20 — Application 层
       30 — Infrastructure 层
       90 — System/Framework 层
NNNN — 4位错误序号
```

### ErrorCode 密封接口（由 engineering-core 提供）

```java
public sealed interface ErrorCode
        permits DomainErrorCode, ApplicationErrorCode, InfrastructureErrorCode, SystemErrorCode {
    String getCode();
    String getMessageTemplate();
    default String resolveMessage(Object... args) { /* {} 占位符替换 */ }
}
```

### 错误码枚举组织

| 枚举 | 位置 | 编码段 |
|------|------|--------|
| `SystemErrorCode` | engineering-core | `BB AA 90 NNNN` |
| `{Context}DomainErrorCode` | domain/{context}/exception/ | `BB AA 10 NNNN` |
| `{Context}AppErrorCode` | application/{context}/ | `BB AA 20 NNNN` |
| `{Context}InfraErrorCode` | infrastructure/ | `BB AA 30 NNNN` |

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

## 五、全局异常处理（UnifiedExceptionHandler + ExceptionMapper）

### 架构设计

三种协议适配器共享同一套异常处理逻辑，由 engineering-core 提供：

```
UnifiedExceptionHandler（协议无关入口）
    └── ExceptionMapper（策略分发器）
        ├── BusinessExceptionMappingStrategy（order=10）
        │   ├── DomainException      → WARN + 返回业务错误码
        │   ├── ApplicationException → WARN + 返回业务错误码
        │   └── InfrastructureException → ERROR + 返回"系统繁忙"
        ├── [自定义策略]（业务工程注册）
        └── DefaultExceptionMappingStrategy（order=MAX，兜底）
            └── 所有未匹配异常 → ERROR + 返回"系统内部错误"
```

### UnifiedExceptionHandler

```java
public class UnifiedExceptionHandler {
    private final ExceptionMapper exceptionMapper;

    public ApiResponse<Void> resolveException(Throwable ex, String channel, String operation) {
        var context = new ErrorContext(channel, operation);
        return exceptionMapper.resolve(ex, context);
    }
}
```

### ExceptionMapper 策略注册

```java
public class ExceptionMapper {
    public ExceptionMapper() {
        register(new BusinessExceptionMappingStrategy());  // order=10
        register(new DefaultExceptionMappingStrategy());   // order=MAX
    }

    public void register(ExceptionMappingStrategy strategy) { /* 按 order 排序 */ }
    public ApiResponse<Void> resolve(Throwable ex, ErrorContext context) { /* 按序匹配 */ }
}
```

### 自定义策略扩展

业务工程可注册自定义策略处理特定异常（如 JSR-303 校验异常、Spring Security 异常）：

```java
public class ValidationExceptionStrategy implements ExceptionMappingStrategy {
    @Override public boolean supports(Throwable ex) {
        return ex instanceof MethodArgumentNotValidException;
    }
    @Override public ApiResponse<Void> map(Throwable ex, ErrorContext context) { /* ... */ }
    @Override public int order() { return 20; }  // 优先级介于业务异常和兜底之间
}

// 注册
unifiedExceptionHandler.getExceptionMapper().register(new ValidationExceptionStrategy());
```

### 各协议适配器使用方式

```java
// HTTP — @RestControllerAdvice
@ExceptionHandler(Exception.class)
public ApiResponse<Void> handleAll(Exception ex, HttpServletRequest request) {
    return unifiedExceptionHandler.resolveException(ex, "HTTP", request.getRequestURI());
}

// Dubbo — Provider Filter
ApiResponse<Void> resp = unifiedExceptionHandler.resolveException(ex, "Dubbo", interfaceName + "#" + methodName);

// MQ — 消费异常处理
ApiResponse<Void> resp = unifiedExceptionHandler.resolveException(ex, "MQ", topic + "#" + msgId);
boolean shouldRetry = !(ex instanceof DomainException) && !(ex instanceof ApplicationException);
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
