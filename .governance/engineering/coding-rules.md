# 编码规则

> 适用于所有层的通用编码约束。

## 依赖规则

- 领域层不依赖任何其他层
- 应用层只依赖领域层
- 基础设施层实现领域层接口
- 接口层依赖应用层
- **[强规则]** 禁止跨领域上下文直接调用对方的 Repository，获取数据须通过其 ApplicationService 或 DomainService

## 注入方式

- 使用构造器注入，避免字段注入
- 接口优于实现类
- Java 21 可结合 `final` 字段 + 构造器注入

## 不可变性

- 值对象必须不可变（Java 21 用 `record`，Java 8 用 `@Getter` 无 `@Setter`）
- 实体状态变更通过业务方法，禁止 setter
- 领域事件不可变

## import 规范

- **[强规则]** 类引用必须通过 `import` 语句导入，禁止在代码中使用全限定类名
- 唯一例外：同一文件中存在两个同名类时，可对其中一个使用全限定类名

## 序列化

- 所有需要序列化的类（RPC 传输对象、MQ 消息体、缓存对象）必须实现 `Serializable`
- 必须显式声明 `private static final long serialVersionUID = 1L`
- Java 21 的 `record` 类型天然支持序列化

## Lombok 规范

- 优先使用最小必要注解，能用 `@Getter` 解决的不使用 `@Data`
- 枚举类只使用 `@Getter`，不使用 `@Data`
- 不可变对象（异常类、值对象、只读 VO）只加 `@Getter`，不加 `@Setter`
- `@Getter` 与 `@Setter` 需要并存时，直接使用 `@Data`
- 建造者模式使用 `@Builder`，不使用 `@Setter`
- Java 21 项目中，值对象优先用 `record` 替代 Lombok

## 日志规范

- **[强规则]** 核心操作必须包含语义化前缀，便于全链路监控追踪：
  - `[ORCHESTRATION]`：编排驱动、流程推进
  - `[GATEWAY]`：外部系统交互的起始、参数、响应
  - `[RETRY]`：自动化重试逻辑触发
  - `[TRANSACTION]`：事务提交关键节点
  - `[BATCH]`：批处理任务执行
- 关键状态变更日志必须包含核心业务标识（如 `orderId`、`applicationId`）

## 方法参数

- **[强规则]** 方法参数不得超过 5 个
- 超过时封装为参数对象（Command / Query / VO），以 `@Builder` 构建
- 适用于所有层的所有方法，包括 Gateway 接口方法

## 映射转换

- **[强规则]** 接口层进入应用层的参数必须进行强类型转换
- API 层使用 `String` / `Integer` 等原始类型，Core 层使用 `Enum`、值对象等强类型
- 转换逻辑收拢在 Assembler / Converter 类中
- Java 21 项目优先使用 MapStruct（编译时生成，类型安全）

## JSON 序列化

- **[强规则]** 禁止直接注入或使用 `ObjectMapper`
- 统一使用项目封装的 JsonUtil 工具类，保证全局序列化行为一致
- JsonUtil 内部持有统一配置的 ObjectMapper（含 JavaTimeModule、忽略未知属性等）

## 应用层依赖

- **[强规则]** 应用层（CommandService / QueryService）禁止直接注入 Repository 或 Gateway
- 应用层的数据获取与外部交互通过领域服务完成
- 应用层仅负责：用例编排、领域服务调用、事件发布
- 例外：QueryService 可直接注入 Repository 用于读侧优化（CQRS）

## 异常治理

- **[强规则]** 接口层禁止直接编写 `try-catch` 捕获业务/系统异常
- 异常向上抛出，由全局异常处理器收拢并适配为统一响应
- 接口层只负责调用与映射，不承载异常转换逻辑

## HTTP 响应

- HTTP 接口统一返回 HTTP 200 状态码
- 错误信息通过响应体 `success=false` + `code` + `message` 体现
- Controller 方法统一返回 `ApiResponse<T>`
