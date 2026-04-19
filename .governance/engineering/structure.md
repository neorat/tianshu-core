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

### framework 模块

framework 是独立的通用工程（如异常基类、工具类、分布式锁抽象），不在业务工程内：

```
# 独立仓库
{company}-framework/
├── framework-core/       # 异常基类、通用工具、分布式锁接口
├── framework-web/        # Web 通用配置、全局异常处理
└── framework-starter/    # Spring Boot Starter 自动装配
```

业务工程通过 Maven 依赖引入，不在业务工程中维护。

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

这样 domain 层的 `Order.java` 和 types 中的 `OrderStatus.java` 在同一个包 `com.{company}.{project}.domain.order.model` 下，import 自然，不需要额外的包路径映射。

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

**应用层 assembler 职责**：
- Request DTO → Command
- Query DTO → Query 对象
- 领域对象 → Response DTO
- 使用 MapStruct 实现（编译时生成，类型安全）

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
│   │   ├── OrderRepository.java          # 仓储接口（持久化，缓存在实现类中完成）
│   │   └── PaymentRepository.java        # 仓储接口（可能对应外部系统的 Dubbo 调用）
│   ├── event/
│   │   └── OrderPlacedEvent.java         # 领域事件
│   └── exception/
│       └── OrderNotFoundException.java   # 领域异常
├── user/                                 # 聚合
│   ├── model/
│   │   └── User.java
│   ├── repository/
│   │   └── UserRepository.java
│   └── ...
└── shared/
    └── exception/
        └── BusinessException.java
```

**领域层约定**：
- 一级目录按聚合组织，每个聚合一个目录
- 领域服务直接放聚合根目录，不建 service/ 子目录
- model/ 下放聚合根、实体、值对象、枚举
- repository/ 下放所有仓储接口——不区分数据库还是外部系统，实现细节由 infrastructure 决定
- event/ 下放领域事件
- exception/ 下放领域异常
- 跨聚合共享的值对象放 types 模块，不放 domain/shared/
- domain/shared/ 只放异常基类等真正的共享基础设施

### 4.3 基础设施层（infrastructure）— 按组件类型 + 聚合组织

一级目录按技术组件，二级按聚合，三级按具体实现：

```
infrastructure/
├── mysql/
│   ├── order/
│   │   ├── OrderRepositoryImpl.java      # 仓储实现
│   │   ├── OrderMapper.java              # MyBatis-Plus Mapper
│   │   ├── OrderDO.java                  # 数据对象
│   │   ├── OrderTypeHandler.java         # 类型处理器
│   │   └── OrderConverter.java           # DO ↔ 领域对象转换
│   └── user/
│       ├── UserRepositoryImpl.java
│       ├── UserMapper.java
│       ├── UserDO.java
│       └── UserConverter.java
├── dubbo/
│   └── order/
│       └── PaymentServiceAdapter.java    # 调用外部支付服务
├── rocketmq/
│   └── order/
│       └── OrderEventPublisher.java      # 事件发布
├── redis/
│   └── order/
│       └── OrderCacheRepository.java     # 缓存实现
├── feign/
│   └── user/
│       └── UserCenterAdapter.java        # 调用用户中心
└── config/
    ├── MyBatisPlusConfig.java
    └── RedisConfig.java
```

**infrastructure converter vs application assembler**：

| 位置 | 类名 | 职责 |
|------|------|------|
| `application/assembler/` | `OrderAssembler` | DTO ↔ Command/Query/领域对象 |
| `infrastructure/mysql/order/` | `OrderConverter` | DO ↔ 领域对象 |

两者职责不同，命名不同，不要混淆。

---

## 五、Online 模块 — 在线服务入口

online 模块是在线服务的部署单元，包含 interfaces 层的 web / rpc / mq / event 适配器，以及 Spring Boot 主应用入口。

```
{project}-online/src/main/java/com/{company}/{project}/
├── interfaces/                           # 接口层 — 协议适配
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

所有协议入口都将外部信号转为 Command/Query，调用 core 模块的 application 层服务，不直接调用 domain。

---

## 六、Batch 模块 — 批处理入口

batch 模块是批处理的部署单元，包含 interfaces/task 和 Spring Batch 作业定义。

```
{project}-batch/src/main/java/com/{company}/{project}/
├── interfaces/
│   └── task/
│       └── OrderTimeoutTask.java         # 定时任务入口
├── batch/
│   ├── config/
│   │   └── BatchConfig.java
│   └── job/
│       ├── reader/
│       ├── processor/
│       └── writer/
└── DddTemplateBatchApplication.java      # Spring Boot 主应用
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

**core 模块**验证 application / domain / infrastructure 三层规则：

```java
@AnalyzeClasses(packages = "com.{company}.{project}")
class DddLayeringTest {

    // domain 不依赖上层
    @ArchTest
    static final ArchRule domain_no_upper_layers =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..application..", "..interfaces..", "..infrastructure..");

    // domain 不依赖框架
    @ArchTest
    static final ArchRule domain_no_framework =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("org.springframework..", "com.baomidou..", "org.apache.dubbo..");

    // application 不碰 repository
    @ArchTest
    static final ArchRule application_no_repository =
        noClasses().that().resideInAPackage("..application..")
            .should().dependOnClassesThat()
            .haveSimpleNameEndingWith("Repository");

    // infrastructure 不依赖 application
    @ArchTest
    static final ArchRule infrastructure_no_upper_layers =
        noClasses().that().resideInAPackage("..infrastructure..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..application..", "..interfaces..");
}
```

**online 模块**可额外验证 interfaces 层规则：

```java
@AnalyzeClasses(packages = "com.{company}.{project}.interfaces")
class InterfacesLayeringTest {

    // interfaces 只调用 application
    @ArchTest
    static final ArchRule interfaces_only_access_application =
        noClasses().that().resideInAPackage("..interfaces..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..domain..", "..infrastructure..");
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
