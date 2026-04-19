# API 设计规范

## REST 规范

- 使用标准 HTTP 方法（GET / POST / PUT / DELETE）
- 资源命名使用复数（如 `/orders`、`/users`）
- URL 路径版本控制：`/api/v1/`
- 向后兼容原则，废弃 API 提前通知

## 统一响应结构

HTTP 与 RPC 共用同一个 `ApiResponse<T>`，全系统只有这一套响应结构：

```java
public class ApiResponse<T> {
    private boolean success;
    private String code;       // 成功固定 "SUCCESS"，失败为 8 位错误码
    private String message;
    private T data;
    private List<FieldError> fieldErrors;  // 仅参数校验失败时填充

    public static <T> ApiResponse<T> success(T data) { ... }
    public static <T> ApiResponse<T> error(String code, String message) { ... }
    public static <T> ApiResponse<T> validationError(List<FieldError> fieldErrors) { ... }
}
```

## 错误码格式

采用 8 位纯数字 `SS DD NNNN`，详见 `exception-handling.md`。

## Controller 规范

- 统一返回 `ApiResponse<T>`
- HTTP 统一返回 200 状态码，错误信息在响应体中
- 不使用 `ResponseEntity` 包装
- 不在 Controller 中编写 `try-catch`
