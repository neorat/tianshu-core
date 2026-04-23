# 工程结构与模块分层规范

> 1 个有界上下文 = 1 个微服务 = 1 个 Maven 多模块工程。

## 一、Maven 模块划分

```
{project}/
├── {project}-api/        # 对外契约（二方包）
├── {project}-types/      # 共享类型（值对象、枚举，api 与 core 共用）
├── {project}-core/       # 核心业务（application / domain / infrastructure）
├── {project}-online/     # 在线服务入口（HTTP / RPC / MQ 协议适配）
└── {project}-batch/      # 批处理任务（可选）
```

### 模块职责

| 模块 | 职责 | 部署属性 |
|------|------|---------|
| `{project}-api` | RPC 接口定义、DTO。技术中立，不依赖特定 RPC 框架 | JAR，可被外部系统依赖 |
| `{project}-types` | 跨层共享的值对象、枚举。api 和 domain 都引用此模块，避免领域类型泄漏到 api 或 api 类型侵入 domain | JAR，被 api 和 core 依赖 |
| `{project}-core` | DDD 三层（application / domain / infrastructure），纯业务逻辑，不含协议适配 | JAR，被 online 和 batch 依赖 |
| `{project}-online` | 在线服务入口。包含 interfaces 层（web / rpc / mq / event），Spring Boot 主应用 | 独立可部署 |
| `{project}-batch` | 定时任务、批处理作业。包含 interfaces/task，复用 core 的领域服务 | 独立可部署（可选） |

### 依赖关系

```
{project}-online ──→ {project}-core ──→ {project}-api
{project}-batch  ──→      ↓                  ↓
                    {project}-types  ←───────┘
```

- core 依赖 api + types
- api 依赖 types
- online 依赖 core（传递依赖 api + types）
- batch 依赖 core（传递依赖 api + types）
- types 无项目内部依赖（最底层）
- online 和 batch 互不依赖，各自独立部署

### 工程模块（{company}-engineering）

工程是独立的通用基础设施仓库，不在业务工程内，业务工程通过 Maven 依赖引入。

```
# 独立仓库
{company}-engineering/
├── engineering-core/         # 基础体系：统一异常、错误码、Gateway 四态语义、领域事件基类、分布式锁接口、全链路追踪
├── engineering-web/          # Web 组件：全局异常处理器、RequestContextFilter、Instant 序列化器
├── engineering-dubbo/        # Dubbo 组件：ProviderExceptionFilter、CorrelationIdFilter、TraceFilter
├── engineering-mq/           # MQ 组件：AbstractMessageConsumer、MqExceptionHandler、TraceMessageHelper
├── engineering-mybatis/      # MyBatis 组件：BaseAuditDO、JsonTypeHandler、分页封装
├── engineering-redis/        # Redis 组件：分布式锁实现（Redisson）、RedissonAutoConfiguration
└── engineering-dp/           # 领域原语（Domain Primitive）：跨微服务共享的通用值对象、枚举
```

#### 模块职责

| 模块 | 职责 | 说明 |
|------|------|------|
| `engineering-core` | 统一异常体系（UnifiedExceptionHandler + ExceptionMapper 策略模式）、10位错误码（sealed interface）、Gateway 四态语义（IGtwCallStatus + AbstractGtwResult）、领域事件基类（DomainEvent + Publisher + Subscriber）、分布式锁接口、全链路追踪（TraceContext）、ApiResponse 统一响应、ComJsonUtil | 所有其他 engineering 模块的底层依赖 |
| `engineering-web` | WebGlobalExceptionHandler（@RestControllerAdvice）、RequestContextFilter（MDC correlationId）、Instant 序列化/反序列化器 | 依赖 core，处理 HTTP 层通用逻辑 |
| `engineering-dubbo` | ProviderExceptionFilter（Provider 异常拦截）、RpcExceptionHandler、CorrelationIdFilter（链路追踪）、TraceFilter | 依赖 core，处理 RPC 层通用逻辑 |
| `engineering-mq` | AbstractMessageConsumer（模板方法 + 追踪恢复）、MqExceptionHandler（按异常类型决定重试）、TraceMessageHelper | 依赖 core，处理消息层通用逻辑 |
| `engineering-mybatis` | BaseAuditDO（审计字段自动填充）、AuditMetaObjectHandler、JsonTypeHandler、PageQuery/PageResult 分页封装 | 依赖 core，处理持久层通用逻辑 |
| `engineering-redis` | RedisDistributedLockImpl（实现 IDistributedLockUtil）、RedissonAutoConfiguration | 依赖 core，处理 Redis 层通用逻辑 |
| `engineering-dp` | Money、PhoneNumber、Address 等跨微服务共享的领域原语 | 依赖 core。业务相关的值对象先在具体业务服务中定义，当多个微服务共用时才提升到此模块 |

#### 依赖关系

```
engineering-web     ──→ engineering-core
engineering-dubbo   ──→ engineering-core
engineering-mq      ──→ engineering-core
engineering-mybatis ──→ engineering-core
engineering-redis   ──→ engineering-core
engineering-dp      ──→ engineering-core
```

#### engineering-core 包结构

```
com.ddd.engineering.core/
├── codes/          # 错误码体系（ErrorCode sealed interface + 分层子接口）
├── exception/      # 异常体系（BusinessException + UnifiedExceptionHandler + ExceptionMapper）
├── gateway/        # Gateway 四态语义（IGtwCallStatus + AbstractGtwResult + IGtwRespInfo）
├── event/          # 领域事件基类（DomainEvent + DomainEventPublisher + DomainEventSubscriber）
├── trace/          # 全链路追踪（TraceContext + TraceConstants + Filter/Aspect）
├── util/           # 工具类（ComJsonUtil、IDistributedLockUtil）
└── vo/             # 通用值对象（ApiResponse、ErrorContext、RequestContext、UserContext）
```

#### 异常体系分层

```
engineering-core:
  ├── BusinessException（abstract）     # 异常基类
  │   ├── DomainException（abstract）
  │   ├── ApplicationException（abstract）
  │   └── InfrastructureException（abstract）
  ├── UnifiedExceptionHandler           # 协议无关的统一异常处理入口
  ├── ExceptionMapper                   # 策略模式分发器
  ├── ExceptionMappingStrategy          # 策略接口
  ├── BusinessExceptionMappingStrategy  # 业务异常策略（order=10）
  └── DefaultExceptionMappingStrategy   # 兜底策略（order=MAX）

engineering-web:
  └── WebGlobalExceptionHandler         # @RestControllerAdvice，委托 UnifiedExceptionHandler

engineering-dubbo:
  └── ProviderExceptionFilter           # Dubbo Provider Filter，委托 UnifiedExceptionHandler
  └── RpcExceptionHandler               # RPC 异常最终处理

engineering-mq:
  └── MqExceptionHandler                # 消费异常处理，按异常类型决定重试
  └── AbstractMessageConsumer           # 通用消费者基类（模板方法 + 追踪恢复）
```

#### dp 模块的提升原则

dp 模块存放的是跨微服务共享的领域原语，遵循以下原则：

1. **先在业务服务中定义** — 新的值对象、枚举等先放在具体业务服务的 types 或 domain 模块中
2. **多服务共用时提升** — 当两个及以上微服务需要共用同一个值对象时，才提升到 `engineering-dp`
3. **通用业务语义** — dp 中的类型应具有通用业务语义（如 Money、PhoneNumber、Address），而非某个特定业务的专属概念

---

## 二、types 模块

解决的问题：某些值对象和枚举需要同时出现在 api 的 DTO 和 domain 的聚合中。如果放在 domain 里，api 就要依赖 domain；如果放在 api 里，domain 就要依赖 api。types 模块打破这个循环。

**包路径与 domain 层保持一致**，打包后 types 中的类在 classpath 上与 domain 层的类处于同一包结构下：

```
# types 模块
{project}-types/src/main/java/com/{company}/{project}/domain/
├── order/
│   └── model/
│       ├── OrderStatus.java          # 枚举（api DTO 和 domain 聚合都用）
│       └── OrderType.java            # 枚举
├── user/
│   └── model/
│       └── UserLevel.java            # 枚举
└── shared/
    └── Money.java                    # 跨聚合值对象

# domain 层（core 模块）
{project}-core/src/main/java/com/{company}/{project}/domain/
├── order/
│   ├── model/
│   │   ├── Order.java                # 聚合根（直接 import OrderStatus，同包）
│   │   └── OrderItem.java
│   └── ...
└── ...
```

**放入 types 的判断标准**：
- 需要同时出现在 api DTO 和 domain 模型中 → 放 types
- 只在 domain 内部使用 → 留在 domain（core 模块）
- 只在 api DTO 中使用 → 留在 api

---

## 三、API 模块

```
{project}-api/src/main/java/com/{company}/{project}/api/
├── OrderApiClient.java       # RPC 接口（纯 Java 接口，技术中立）
├── dto/
│   ├── CreateOrderRequest.java
│   ├── CreateOrderResponse.java
│   └── OrderDetailResponse.java
└── constant/
    └── OrderApiConstants.java
```

**约定**：
- 接口不使用任何 RPC 框架注解，保持技术中立
- DTO 只放纯数据对象，不含业务逻辑
- 值对象/枚举类型引用 types 模块

---

## 四、Core 模块 DDD 分层

core 模块只包含 application / domain / infrastructure 三层，**不包含 interfaces 层**。interfaces 层按部署形态拆分到 online 和 batch 模块。

### 分层总览

```
{project}-core/src/main/java/com/{company}/{project}/
├── application/             # 应用层 — 用例编排
├── domain/                  # 领域层 — 业务核心
└── infrastructure/          # 基础设施层 — 技术实现
```

### 4.1 应用层（application）— 按用例组织

```
application/
├── order/
│   ├── OrderCommandService.java      # 写操作编排（服务直接放用例根目录）
│   ├── OrderQueryService.java        # 读操作编排
│   ├── cmd/
│   │   └── CreateOrderCommand.java
│   ├── qry/
│   │   └── OrderDetailQuery.java
│   └── assembler/
│       └── OrderAssembler.java       # DTO ↔ Command/Query/领域对象 互转
└── user/
    ├── UserCommandService.java
    ├── UserQueryService.java
    └── assembler/
        └── UserAssembler.java
```

### 4.2 领域层（domain）— 按聚合组织

```
domain/
├── order/                                # 聚合
│   ├── OrderPricingService.java          # 领域服务
│   ├── OrderQueryService.java            # 领域查询服务
│   ├── model/
│   │   ├── Order.java                    # 聚合根
│   │   ├── OrderItem.java                # 实体
│   │   └── ShippingAddress.java          # 值对象 / 枚举
│   ├── repository/
│   │   ├── OrderRepository.java          # 仓储接口
│   │   └── PaymentRepository.java        # 仓储接口
│   ├── event/
│   │   └── OrderPlacedEvent.java         # 领域事件
│   └── exception/
│       └── OrderNotFoundException.java   # 领域异常
├── user/
│   ├── model/
│   │   └── User.java
│   ├── repository/
│   │   └── UserRepository.java
│   └── ...
└── shared/
    └── exception/
        └── BusinessException.java
```

### 4.3 基础设施层（infrastructure）— 按组件类型 + 聚合组织

```
infrastructure/
├── mysql/
│   ├── order/
│   │   ├── OrderRepositoryImpl.java
│   │   ├── OrderMapper.java
│   │   ├── OrderDO.java
│   │   ├── OrderTypeHandler.java
│   │   └── OrderConverter.java
│   └── user/
│       ├── UserRepositoryImpl.java
│       ├── UserMapper.java
│       ├── UserDO.java
│       └── UserConverter.java
├── dubbo/
│   └── order/
│       └── PaymentServiceAdapter.java
├── rocketmq/
│   └── order/
│       └── OrderEventPublisher.java
├── redis/
│   └── order/
│       └── OrderCacheRepository.java
├── feign/
│   └── user/
│       └── UserCenterAdapter.java
└── config/
    ├── MyBatisPlusConfig.java
    └── RedisConfig.java
```

---

## 五、Online 模块 — 在线服务入口

```
{project}-online/src/main/java/com/{company}/{project}/
├── interfaces/
│   ├── web/
│   │   └── OrderController.java          # HTTP
│   ├── rpc/
│   │   └── OrderServiceProvider.java     # Dubbo / gRPC
│   ├── mq/
│   │   └── OrderEventListener.java       # MQ 消费
│   └── event/
│       └── OrderPaymentEventListener.java # 进程内事件消费
└── DddTemplateOnlineApplication.java     # Spring Boot 主应用
```

---

## 六、Batch 模块 — 批处理入口

```
{project}-batch/src/main/java/com/{company}/{project}/
├── interfaces/
│   └── task/
│       └── OrderTimeoutTask.java
├── batch/
│   ├── config/
│   │   └── BatchConfig.java
│   └── job/
│       ├── reader/
│       ├── processor/
│       └── writer/
└── DddTemplateBatchApplication.java
```

---

## 七、分层依赖规则

```
interfaces（online / batch 模块）
    ↓
application（含 assembler）
    ↓
domain  ←──  infrastructure（实现 domain 定义的 repository 接口）
    ↓
types（共享值对象/枚举）
```

### 严格约束

| 规则 | 说明 |
|------|------|
| domain 零上层依赖 | 不依赖 application、interfaces、infrastructure |
| domain 零框架依赖 | 不引入 Spring / MyBatis / Jackson 等框架类 |
| application 不碰 repository | 不直接注入 Repository，通过领域服务间接使用 |
| infrastructure 实现 domain 接口 | 依赖倒置：domain 定义 Repository，infrastructure 实现 |
| infrastructure 编译时不依赖 api | 运行时通过 Spring 注入 RPC 实现 |
| interfaces 只调用 application | 不直接调用 domain 或 infrastructure |
| online 和 batch 互不依赖 | 各自独立部署，通过 core 共享业务逻辑 |

### 对象隔离

| 层 | 使用的对象 | 禁止使用的对象 |
|---|-----------|-------------|
| interfaces | Request/Response DTO、types 中的枚举/VO | DO、领域聚合 |
| application | Command、Query、领域对象、types | DO |
| domain | 聚合、实体、VO、事件、types | DO、DTO |
| infrastructure | DO、领域对象（通过 Converter 转换）、types | DTO |

---

## 八、ArchUnit 分层验证

使用 ArchUnit 在测试时强制执行分层规则，`mvn test` 即可检测违规。

```java
@AnalyzeClasses(packages = "com.{company}.{project}")
class DddLayeringTest {
    @ArchTest
    static final ArchRule domain_no_upper_layers =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..application..", "..interfaces..", "..infrastructure..");

    @ArchTest
    static final ArchRule domain_no_framework =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("org.springframework..", "com.baomidou..", "org.apache.dubbo..");

    @ArchTest
    static final ArchRule application_no_repository =
        noClasses().that().resideInAPackage("..application..")
            .should().dependOnClassesThat()
            .haveSimpleNameEndingWith("Repository");

    @ArchTest
    static final ArchRule infrastructure_no_upper_layers =
        noClasses().that().resideInAPackage("..infrastructure..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..application..", "..interfaces..");
}
```

---

## 九、核心架构纪律

1. **领域层禁飞区**：domain/ 下禁止引入任何框架类
2. **DO ≠ 领域对象**：infrastructure 的 Converter 负责 DO ↔ 领域对象转换
3. **DTO ≠ Command**：application 的 Assembler 负责 DTO ↔ Command/Query 转换
4. **出入口防漏**：Controller 不返回领域对象，通过 Assembler 转为 Response DTO
5. **事务边界在 application 层**：一个用例一个事务
6. **查询侧可绕过 domain 层**：QueryService 可直接访问 infrastructure 优化性能（CQRS 读侧）
7. **部署隔离**：online 处理实时请求，batch 处理离线任务，各自独立部署和扩缩容
