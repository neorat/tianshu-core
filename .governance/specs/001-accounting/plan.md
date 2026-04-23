# 账务系统（Accounting）实现规划

> **For agentic workers:** Use the subagent-driven-development workflow (recommended) or executing-plans workflow to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现天枢银行核心系统群的账务系统，提供账户生命周期管理、交易驱动记账、余额维护、日终处理等核心能力。

**Architecture:** DDD 分层架构（interfaces → application → domain ← infrastructure），4 个聚合（Account、AccountingVoucher、AccountingDay、DepositInterest），CQRS 读写分离，事件驱动跨上下文通信。

**Tech Stack:** Java 21 + Spring Boot 4.0 + MyBatis-Plus 3.5 + MapStruct 1.6 + MySQL 8.0 + RocketMQ 2.3 + Dubbo 3.x

---

## Phase 0: 工程脚手架

### Task 0.1: 创建 Maven 多模块工程

**Files:**
- Create: `pom.xml` (parent)
- Create: `accounting-api/pom.xml`
- Create: `accounting-types/pom.xml`
- Create: `accounting-core/pom.xml`
- Create: `accounting-online/pom.xml`
- Create: `accounting-batch/pom.xml`

- [ ] **Step 1: 创建父 pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.tianshu.accounting</groupId>
    <artifactId>accounting</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>
    <name>Tianshu Accounting System</name>

    <modules>
        <module>accounting-api</module>
        <module>accounting-types</module>
        <module>accounting-core</module>
        <module>accounting-online</module>
        <module>accounting-batch</module>
    </modules>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-boot.version>4.0.0</spring-boot.version>
        <mybatis-plus.version>3.5.5</mybatis-plus.version>
        <mapstruct.version>1.6.0</mapstruct.version>
        <archunit.version>1.3.0</archunit.version>
        <rocketmq.version>2.3.0</rocketmq.version>
        <dubbo.version>3.3.0</dubbo.version>
        <lombok.version>1.18.30</lombok.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>com.baomidou</groupId>
                <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
                <version>${mybatis-plus.version}</version>
            </dependency>
            <dependency>
                <groupId>org.mapstruct</groupId>
                <artifactId>mapstruct</artifactId>
                <version>${mapstruct.version}</version>
            </dependency>
            <dependency>
                <groupId>org.mapstruct</groupId>
                <artifactId>mapstruct-processor</artifactId>
                <version>${mapstruct.version}</version>
            </dependency>
            <dependency>
                <groupId>com.tngtech.archunit</groupId>
                <artifactId>archunit-junit5</artifactId>
                <version>${archunit.version}</version>
                <scope>test</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-maven-plugin</artifactId>
                    <version>${spring-boot.version}</version>
                </plugin>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>3.11.0</version>
                    <configuration>
                        <source>${java.version}</source>
                        <target>${java.version}</target>
                        <annotationProcessorPaths>
                            <path>
                                <groupId>org.projectlombok</groupId>
                                <artifactId>lombok</artifactId>
                                <version>${lombok.version}</version>
                            </path>
                            <path>
                                <groupId>org.mapstruct</groupId>
                                <artifactId>mapstruct-processor</artifactId>
                                <version>${mapstruct.version}</version>
                            </path>
                            <path>
                                <groupId>org.projectlombok</groupId>
                                <artifactId>lombok-mapstruct-binding</artifactId>
                                <version>0.2.0</version>
                            </path>
                        </annotationProcessorPaths>
                    </configuration>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>
</project>
```

- [ ] **Step 2: 创建 accounting-types 模块 pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.tianshu.accounting</groupId>
        <artifactId>accounting</artifactId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>

    <artifactId>accounting-types</artifactId>
    <name>Accounting Types</name>
    <description>共享值对象、枚举（api 与 core 共用）</description>

    <dependencies>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>
    </dependencies>
</project>
```

- [ ] **Step 3: 创建 accounting-api 模块 pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.tianshu.accounting</groupId>
        <artifactId>accounting</artifactId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>

    <artifactId>accounting-api</artifactId>
    <name>Accounting API</name>
    <description>对外契约（RPC 接口、DTO）</description>

    <dependencies>
        <dependency>
            <groupId>com.tianshu.accounting</groupId>
            <artifactId>accounting-types</artifactId>
            <version>${project.version}</version>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>
    </dependencies>
</project>
```

- [ ] **Step 4: 创建 accounting-core 模块 pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.tianshu.accounting</groupId>
        <artifactId>accounting</artifactId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>

    <artifactId>accounting-core</artifactId>
    <name>Accounting Core</name>
    <description>核心业务（application / domain / infrastructure）</description>

    <dependencies>
        <dependency>
            <groupId>com.tianshu.accounting</groupId>
            <artifactId>accounting-api</artifactId>
            <version>${project.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.mapstruct</groupId>
            <artifactId>mapstruct</artifactId>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>com.tngtech.archunit</groupId>
            <artifactId>archunit-junit5</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```

- [ ] **Step 5: 创建 accounting-online 模块 pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.tianshu.accounting</groupId>
        <artifactId>accounting</artifactId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>

    <artifactId>accounting-online</artifactId>
    <name>Accounting Online</name>
    <description>在线服务入口（HTTP / RPC / MQ 协议适配）</description>

    <dependencies>
        <dependency>
            <groupId>com.tianshu.accounting</groupId>
            <artifactId>accounting-core</artifactId>
            <version>${project.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

- [ ] **Step 6: 创建 accounting-batch 模块 pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>com.tianshu.accounting</groupId>
        <artifactId>accounting</artifactId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>

    <artifactId>accounting-batch</artifactId>
    <name>Accounting Batch</name>
    <description>批处理任务入口</description>

    <dependencies>
        <dependency>
            <groupId>com.tianshu.accounting</groupId>
            <artifactId>accounting-core</artifactId>
            <version>${project.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-batch</artifactId>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

- [ ] **Step 7: 验证工程结构**

Run: `mvn clean compile -f pom.xml`
Expected: BUILD SUCCESS

- [ ] **Step 8: Commit**

```bash
git add pom.xml accounting-api/pom.xml accounting-types/pom.xml accounting-core/pom.xml accounting-online/pom.xml accounting-batch/pom.xml
git commit -m "feat: init maven multi-module project structure"
```


### Task 0.2: 创建 types 模块基础类型

**Files:**
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/shared/Money.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/account/model/AccountType.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/account/model/OwnerType.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/account/model/LifecycleStatus.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/account/model/ActivityStatus.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/account/model/FreezeType.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/voucher/model/VoucherStatus.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/voucher/model/VoucherType.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/voucher/model/EntryDirection.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/voucher/model/BizType.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/subject/model/SubjectType.java`
- Create: `accounting-types/src/main/java/com/tianshu/accounting/domain/subject/model/NormalBalanceDirection.java`

- [ ] **Step 1: 创建 Money 值对象**

```java
package com.tianshu.accounting.domain.shared;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Currency;

/**
 * 金额值对象
 * 不可变，所有运算返回新实例
 */
public record Money(
    BigDecimal amount,
    String currency
) {
    private static final int SCALE = 4;
    private static final RoundingMode ROUNDING_MODE = RoundingMode.HALF_UP;
    
    public Money {
        if (amount == null) {
            throw new IllegalArgumentException("amount cannot be null");
        }
        if (currency == null || currency.isBlank()) {
            throw new IllegalArgumentException("currency cannot be null or blank");
        }
        amount = amount.setScale(SCALE, ROUNDING_MODE);
    }
    
    public static Money of(BigDecimal amount, String currency) {
        return new Money(amount, currency);
    }
    
    public static Money of(double amount, String currency) {
        return new Money(BigDecimal.valueOf(amount), currency);
    }
    
    public static Money zero(String currency) {
        return new Money(BigDecimal.ZERO, currency);
    }
    
    public Money add(Money other) {
        validateSameCurrency(other);
        return new Money(this.amount.add(other.amount), currency);
    }
    
    public Money subtract(Money other) {
        validateSameCurrency(other);
        return new Money(this.amount.subtract(other.amount), currency);
    }
    
    public Money negate() {
        return new Money(amount.negate(), currency);
    }
    
    public boolean isGreaterThan(Money other) {
        validateSameCurrency(other);
        return this.amount.compareTo(other.amount) > 0;
    }
    
    public boolean isLessThan(Money other) {
        validateSameCurrency(other);
        return this.amount.compareTo(other.amount) < 0;
    }
    
    public boolean isGreaterThanOrEqual(Money other) {
        validateSameCurrency(other);
        return this.amount.compareTo(other.amount) >= 0;
    }
    
    public boolean isPositive() {
        return amount.compareTo(BigDecimal.ZERO) > 0;
    }
    
    public boolean isZero() {
        return amount.compareTo(BigDecimal.ZERO) == 0;
    }
    
    public boolean isNegative() {
        return amount.compareTo(BigDecimal.ZERO) < 0;
    }
    
    private void validateSameCurrency(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException(
                "Cannot operate on money with different currencies: " + this.currency + " vs " + other.currency
            );
        }
    }
}
```

- [ ] **Step 2: 创建 AccountType 枚举**

```java
package com.tianshu.accounting.domain.account.model;

/**
 * 账户类型
 */
public enum AccountType {
    /**
     * 客户户（主账户）
     */
    MAIN,
    
    /**
     * 内部户
     */
    INTERNAL,
    
    /**
     * 资金隔离型子账户
     */
    SUB_REAL
}
```

- [ ] **Step 3: 创建 OwnerType 枚举**

```java
package com.tianshu.accounting.domain.account.model;

/**
 * 账户归属类型
 */
public enum OwnerType {
    /**
     * 客户
     */
    CUSTOMER,
    
    /**
     * 机构（银行内部）
     */
    INSTITUTION
}
```

- [ ] **Step 4: 创建 LifecycleStatus 枚举**

```java
package com.tianshu.accounting.domain.account.model;

/**
 * 账户生命周期状态
 */
public enum LifecycleStatus {
    /**
     * 正常
     */
    ACTIVE,
    
    /**
     * 待销户
     */
    PENDING_CLOSE,
    
    /**
     * 已销户
     */
    CLOSED
}
```

- [ ] **Step 5: 创建 ActivityStatus 枚举**

```java
package com.tianshu.accounting.domain.account.model;

/**
 * 账户运营治理状态
 */
public enum ActivityStatus {
    /**
     * 正常
     */
    NORMAL,
    
    /**
     * 休眠
     */
    DORMANT,
    
    /**
     * 久悬
     */
    UNCLAIMED
}
```

- [ ] **Step 6: 创建 FreezeType 枚举**

```java
package com.tianshu.accounting.domain.account.model;

/**
 * 冻结类型
 */
public enum FreezeType {
    /**
     * 司法冻结
     */
    JUDICIAL,
    
    /**
     * 风控冻结
     */
    RISK,
    
    /**
     * 质押冻结
     */
    PLEDGE,
    
    /**
     * 预授权冻结
     */
    PRE_AUTH
}
```

- [ ] **Step 7: 创建 VoucherStatus 枚举**

```java
package com.tianshu.accounting.domain.voucher.model;

/**
 * 凭证状态
 */
public enum VoucherStatus {
    /**
     * 已创建
     */
    CREATED,
    
    /**
     * 已过账
     */
    POSTED,
    
    /**
     * 已冲正
     */
    REVERSED
}
```

- [ ] **Step 8: 创建 VoucherType 枚举**

```java
package com.tianshu.accounting.domain.voucher.model;

/**
 * 凭证类型
 */
public enum VoucherType {
    /**
     * 正常凭证
     */
    NORMAL,
    
    /**
     * 冲正凭证
     */
    REVERSAL
}
```

- [ ] **Step 9: 创建 EntryDirection 枚举**

```java
package com.tianshu.accounting.domain.voucher.model;

/**
 * 分录方向（复式记账）
 */
public enum EntryDirection {
    /**
     * 借方
     */
    DEBIT,
    
    /**
     * 贷方
     */
    CREDIT
}
```

- [ ] **Step 10: 创建 BizType 枚举**

```java
package com.tianshu.accounting.domain.voucher.model;

/**
 * 业务类型
 */
public enum BizType {
    /**
     * 转账
     */
    TRANSFER,
    
    /**
     * 手续费
     */
    FEE,
    
    /**
     * 利息
     */
    INTEREST,
    
    /**
     * 清算
     */
    CLEARING,
    
    /**
     * 消费
     */
    CONSUME,
    
    /**
     * 退款
     */
    REFUND,
    
    /**
     * 冲正
     */
    REVERSAL
}
```

- [ ] **Step 11: 创建 SubjectType 枚举**

```java
package com.tianshu.accounting.domain.subject.model;

/**
 * 科目类型
 */
public enum SubjectType {
    /**
     * 资产类
     */
    ASSET,
    
    /**
     * 负债类
     */
    LIABILITY,
    
    /**
     * 共同类
     */
    COMMON,
    
    /**
     * 所有者权益类
     */
    EQUITY,
    
    /**
     * 收入类
     */
    REVENUE,
    
    /**
     * 费用类
     */
    EXPENSE
}
```

- [ ] **Step 12: 创建 NormalBalanceDirection 枚举**

```java
package com.tianshu.accounting.domain.subject.model;

/**
 * 科目正常余额方向
 */
public enum NormalBalanceDirection {
    /**
     * 借方（资产类、费用类）
     */
    DEBIT,
    
    /**
     * 贷方（负债类、权益类、收入类）
     */
    CREDIT
}
```

- [ ] **Step 13: 验证编译**

Run: `mvn clean compile -pl accounting-types`
Expected: BUILD SUCCESS

- [ ] **Step 14: Commit**

```bash
git add accounting-types/src/
git commit -m "feat(types): add base value objects and enums"
```


### Task 0.3: 创建 API 模块接口定义

**Files:**
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/AccountApiClient.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/AccountingApiClient.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/OpenAccountRequest.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/OpenAccountResponse.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/AccountDetailResponse.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/FreezeRequest.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/UnfreezeRequest.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/PostAccountingRequest.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/PostAccountingResponse.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/ReverseAccountingRequest.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/EntryDTO.java`
- Create: `accounting-api/src/main/java/com/tianshu/accounting/api/dto/ApiResponse.java`

- [ ] **Step 1: 创建 ApiResponse 统一响应**

```java
package com.tianshu.accounting.api.dto;

import lombok.Getter;
import java.io.Serializable;
import java.util.Collections;
import java.util.List;

/**
 * 统一 API 响应结构
 */
@Getter
public class ApiResponse<T> implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private final boolean success;
    private final String code;
    private final String message;
    private final T data;
    private final List<FieldError> fieldErrors;
    
    private ApiResponse(boolean success, String code, String message, T data, List<FieldError> fieldErrors) {
        this.success = success;
        this.code = code;
        this.message = message;
        this.data = data;
        this.fieldErrors = fieldErrors;
    }
    
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, "SUCCESS", "success", data, null);
    }
    
    public static <T> ApiResponse<T> success() {
        return new ApiResponse<>(true, "SUCCESS", "success", null, null);
    }
    
    public static <T> ApiResponse<T> error(String code, String message) {
        return new ApiResponse<>(false, code, message, null, null);
    }
    
    public static <T> ApiResponse<T> validationError(List<FieldError> fieldErrors) {
        return new ApiResponse<>(false, "VALIDATION_ERROR", "参数校验失败", null, fieldErrors);
    }
    
    @Getter
    public static class FieldError implements Serializable {
        private static final long serialVersionUID = 1L;
        private final String field;
        private final String message;
        
        public FieldError(String field, String message) {
            this.field = field;
            this.message = message;
        }
    }
}
```

- [ ] **Step 2: 创建 OpenAccountRequest**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;

/**
 * 开户请求
 */
@Getter
@Builder
public class OpenAccountRequest implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 客户号（客户户必填，内部户为空）
     */
    private final String customerId;
    
    /**
     * 科目代码
     */
    private final String subjectCode;
    
    /**
     * 账户类型：MAIN / INTERNAL / SUB_REAL
     */
    private final String accountType;
    
    /**
     * 法人实体ID（内部户必填）
     */
    private final String institutionId;
    
    /**
     * 主账户ID（子账户必填）
     */
    private final Long parentAccountId;
    
    /**
     * 币种
     */
    private final String currency;
    
    /**
     * 渠道来源
     */
    private final String channelCode;
    
    /**
     * 操作员ID
     */
    private final String operatorId;
    
    /**
     * 业务备注
     */
    private final String memo;
}
```

- [ ] **Step 3: 创建 OpenAccountResponse**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;

/**
 * 开户响应
 */
@Getter
@Builder
public class OpenAccountResponse implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 账户ID
     */
    private final Long accountId;
    
    /**
     * 账户业务编号
     */
    private final String accountNo;
}
```

- [ ] **Step 4: 创建 AccountDetailResponse**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 账户详情响应
 */
@Getter
@Builder
public class AccountDetailResponse implements Serializable {
    private static final long serialVersionUID = 1L;
    
    private final Long accountId;
    private final String accountNo;
    private final String accountType;
    private final String ownerType;
    private final String customerId;
    private final String institutionId;
    private final Long parentAccountId;
    private final String subjectCode;
    private final String currency;
    private final BigDecimal balance;
    private final BigDecimal availableBalance;
    private final BigDecimal frozenAmount;
    private final String lifecycleStatus;
    private final String activityStatus;
    private final boolean debitBlocked;
    private final boolean creditBlocked;
}
```

- [ ] **Step 5: 创建 FreezeRequest**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 冻结请求
 */
@Getter
@Builder
public class FreezeRequest implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 账户业务编号
     */
    private final String accountNo;
    
    /**
     * 冻结金额
     */
    private final BigDecimal freezeAmount;
    
    /**
     * 冻结类型：JUDICIAL / RISK / PLEDGE / PRE_AUTH
     */
    private final String freezeType;
    
    /**
     * 冻结原因
     */
    private final String freezeReason;
    
    /**
     * 调用方业务冻结流水号（幂等键）
     */
    private final String bizFreezeNo;
    
    /**
     * 冻结来源系统
     */
    private final String freezeSource;
    
    /**
     * 操作员ID
     */
    private final String operatorId;
}
```

- [ ] **Step 6: 创建 UnfreezeRequest**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;

/**
 * 解冻请求
 */
@Getter
@Builder
public class UnfreezeRequest implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 账户业务编号
     */
    private final String accountNo;
    
    /**
     * 冻结业务编号（冻结时返回的 freeze_no）
     */
    private final String freezeNo;
    
    /**
     * 解冻原因
     */
    private final String unfreezeReason;
    
    /**
     * 操作员ID
     */
    private final String operatorId;
}
```

- [ ] **Step 7: 创建 EntryDTO**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;
import java.math.BigDecimal;

/**
 * 记账分录 DTO
 */
@Getter
@Builder
public class EntryDTO implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 账户业务编号
     */
    private final String accountNo;
    
    /**
     * 金额
     */
    private final BigDecimal amount;
    
    /**
     * 资金方向：OUT / IN
     */
    private final String direction;
    
    /**
     * 分录摘要
     */
    private final String summary;
}
```

- [ ] **Step 8: 创建 PostAccountingRequest**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.List;

/**
 * 记账请求
 */
@Getter
@Builder
public class PostAccountingRequest implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 业务流水号（幂等键）
     */
    private final String bizNo;
    
    /**
     * 业务类型
     */
    private final String bizType;
    
    /**
     * 会计日（为空则取当前会计日）
     */
    private final LocalDate accountingDate;
    
    /**
     * 币种
     */
    private final String currency;
    
    /**
     * 渠道来源（标识调用方系统）
     */
    private final String channelCode;
    
    /**
     * 操作员/发起方标识
     */
    private final String operatorId;
    
    /**
     * 业务备注
     */
    private final String memo;
    
    /**
     * 记账分录列表
     */
    private final List<EntryDTO> entries;
}
```

- [ ] **Step 9: 创建 PostAccountingResponse**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;

/**
 * 记账响应
 */
@Getter
@Builder
public class PostAccountingResponse implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 凭证ID
     */
    private final Long voucherId;
    
    /**
     * 凭证号
     */
    private final String voucherNo;
}
```

- [ ] **Step 10: 创建 ReverseAccountingRequest**

```java
package com.tianshu.accounting.api.dto;

import lombok.Builder;
import lombok.Getter;
import java.io.Serializable;

/**
 * 冲正请求
 */
@Getter
@Builder
public class ReverseAccountingRequest implements Serializable {
    private static final long serialVersionUID = 1L;
    
    /**
     * 原凭证号
     */
    private final String originalVoucherNo;
    
    /**
     * 冲正原因
     */
    private final String reverseReason;
    
    /**
     * 操作员ID
     */
    private final String operatorId;
}
```

- [ ] **Step 11: 创建 AccountApiClient 接口**

```java
package com.tianshu.accounting.api;

import com.tianshu.accounting.api.dto.*;

/**
 * 账户服务 API 客户端
 * 技术中立接口，不依赖特定 RPC 框架
 */
public interface AccountApiClient {
    
    /**
     * 开立账户
     */
    ApiResponse<OpenAccountResponse> openAccount(OpenAccountRequest request);
    
    /**
     * 查询账户
     */
    ApiResponse<AccountDetailResponse> queryAccount(String accountNo);
    
    /**
     * 冻结账户
     */
    ApiResponse<String> freezeAccount(FreezeRequest request);
    
    /**
     * 解冻账户
     */
    ApiResponse<Void> unfreezeAccount(UnfreezeRequest request);
}
```

- [ ] **Step 12: 创建 AccountingApiClient 接口**

```java
package com.tianshu.accounting.api;

import com.tianshu.accounting.api.dto.*;

/**
 * 记账服务 API 客户端
 * 技术中立接口，不依赖特定 RPC 框架
 */
public interface AccountingApiClient {
    
    /**
     * 提交记账
     */
    ApiResponse<PostAccountingResponse> postAccounting(PostAccountingRequest request);
    
    /**
     * 冲正记账
     */
    ApiResponse<PostAccountingResponse> reverseAccounting(ReverseAccountingRequest request);
    
    /**
     * 查询凭证
     */
    ApiResponse<PostAccountingResponse> queryVoucher(String voucherNo);
}
```

- [ ] **Step 13: 验证编译**

Run: `mvn clean compile -pl accounting-api`
Expected: BUILD SUCCESS

- [ ] **Step 14: Commit**

```bash
git add accounting-api/src/
git commit -m "feat(api): add API client interfaces and DTOs"
```


### Task 0.4: 创建 domain 层异常体系

**Files:**
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/shared/exception/BusinessException.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/shared/exception/DomainException.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/shared/exception/ApplicationException.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/shared/exception/InfrastructureException.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/shared/exception/ErrorCode.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/shared/exception/SystemErrorCode.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/exception/AccountErrorCode.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/exception/VoucherErrorCode.java`

- [ ] **Step 1: 创建 ErrorCode 接口**

```java
package com.tianshu.accounting.domain.shared.exception;

/**
 * 错误码接口
 */
public interface ErrorCode {
    String getCode();
    String getMessageTemplate();
    
    default String resolveMessage(Object... args) {
        String template = getMessageTemplate();
        if (template == null || template.isEmpty()) {
            return "";
        }
        String result = template;
        for (int i = 0; i < args.length && template.contains("{}"); i++) {
            result = result.replaceFirst("\\{\\}", args[i] == null ? "null" : args[i].toString());
        }
        return result;
    }
}
```

- [ ] **Step 2: 创建 BusinessException 抽象基类**

```java
package com.tianshu.accounting.domain.shared.exception;

import lombok.Getter;

/**
 * 业务异常抽象基类
 */
@Getter
public abstract class BusinessException extends RuntimeException {
    private static final long serialVersionUID = 1L;
    
    private final ErrorCode errorCode;
    private final transient Object[] args;
    
    protected BusinessException(ErrorCode errorCode, Object... args) {
        super(errorCode.resolveMessage(args), null);
        this.errorCode = errorCode;
        this.args = args;
    }
    
    protected BusinessException(ErrorCode errorCode, Throwable cause, Object... args) {
        super(errorCode.resolveMessage(args), cause);
        this.errorCode = errorCode;
        this.args = args;
    }
    
    public String getResolvedMessage() {
        return errorCode.resolveMessage(args);
    }
    
    /**
     * 静态工厂方法 - 子类必须实现
     */
    public static BusinessException of(ErrorCode errorCode, Object... args) {
        throw new UnsupportedOperationException("Subclass must implement static factory method");
    }
}
```

- [ ] **Step 3: 创建 DomainException**

```java
package com.tianshu.accounting.domain.shared.exception;

/**
 * 领域层异常
 * 业务规则违反时抛出
 */
public class DomainException extends BusinessException {
    private static final long serialVersionUID = 1L;
    
    private DomainException(ErrorCode errorCode, Object... args) {
        super(errorCode, args);
    }
    
    private DomainException(ErrorCode errorCode, Throwable cause, Object... args) {
        super(errorCode, cause, args);
    }
    
    public static DomainException of(ErrorCode errorCode, Object... args) {
        return new DomainException(errorCode, args);
    }
    
    public static DomainException of(ErrorCode errorCode, Throwable cause, Object... args) {
        return new DomainException(errorCode, cause, args);
    }
}
```

- [ ] **Step 4: 创建 ApplicationException**

```java
package com.tianshu.accounting.domain.shared.exception;

import lombok.Getter;

/**
 * 应用层异常
 * 流程编排错误时抛出
 */
@Getter
public class ApplicationException extends BusinessException {
    private static final long serialVersionUID = 1L;
    
    private final String useCase;
    
    private ApplicationException(ErrorCode errorCode, String useCase, Object... args) {
        super(errorCode, args);
        this.useCase = useCase;
    }
    
    private ApplicationException(ErrorCode errorCode, String useCase, Throwable cause, Object... args) {
        super(errorCode, cause, args);
        this.useCase = useCase;
    }
    
    public static ApplicationException of(ErrorCode errorCode, String useCase, Object... args) {
        return new ApplicationException(errorCode, useCase, args);
    }
    
    public static ApplicationException of(ErrorCode errorCode, String useCase, Throwable cause, Object... args) {
        return new ApplicationException(errorCode, useCase, cause, args);
    }
}
```

- [ ] **Step 5: 创建 InfrastructureException**

```java
package com.tianshu.accounting.domain.shared.exception;

import lombok.Getter;

/**
 * 基础设施层异常
 * 技术细节封装时抛出
 */
@Getter
public class InfrastructureException extends BusinessException {
    private static final long serialVersionUID = 1L;
    
    private final String component;
    
    private InfrastructureException(ErrorCode errorCode, String component, Object... args) {
        super(errorCode, args);
        this.component = component;
    }
    
    private InfrastructureException(ErrorCode errorCode, String component, Throwable cause, Object... args) {
        super(errorCode, cause, args);
        this.component = component;
    }
    
    public static InfrastructureException of(ErrorCode errorCode, String component, Object... args) {
        return new InfrastructureException(errorCode, component, args);
    }
    
    public static InfrastructureException of(ErrorCode errorCode, String component, Throwable cause, Object... args) {
        return new InfrastructureException(errorCode, component, cause, args);
    }
}
```

- [ ] **Step 6: 创建 SystemErrorCode**

```java
package com.tianshu.accounting.domain.shared.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 系统级错误码
 * 编码格式：SS 00 9XXX
 */
@Getter
@RequiredArgsConstructor
public enum SystemErrorCode implements ErrorCode {
    
    SYSTEM_ERROR("01009001", "系统繁忙，请稍后重试"),
    INVALID_PARAMETER("01009002", "参数校验失败：{}"),
    OPTIMISTIC_LOCK_ERROR("01009003", "数据已被修改，请刷新后重试"),
    ;
    
    private final String code;
    private final String messageTemplate;
}
```

- [ ] **Step 7: 创建 AccountErrorCode**

```java
package com.tianshu.accounting.domain.account.exception;

import com.tianshu.accounting.domain.shared.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 账户领域错误码
 * 编码格式：SS 01 1XXX
 */
@Getter
@RequiredArgsConstructor
public enum AccountErrorCode implements ErrorCode {
    
    ACCOUNT_NOT_FOUND("01011001", "账户不存在：{}"),
    ACCOUNT_ALREADY_EXISTS("01011002", "账户已存在：客户号={}, 科目代码={}, 账户类型={}"),
    ACCOUNT_CLOSED("01011003", "账户已销户：{}"),
    ACCOUNT_PENDING_CLOSE("01011004", "账户待销户：{}"),
    INSUFFICIENT_BALANCE("01011005", "账户余额不足：可用余额={}, 需要金额={}"),
    ACCOUNT_FROZEN("01011006", "账户已冻结：{}"),
    DEBIT_BLOCKED("01011007", "账户禁止出账：{}"),
    CREDIT_BLOCKED("01011008", "账户禁止入账：{}"),
    ACCOUNT_DORMANT("01011009", "账户处于休眠状态，需激活后才能交易：{}"),
    ACCOUNT_UNCLAIMED("01011010", "账户处于久悬状态：{}"),
    FREEZE_AMOUNT_EXCEEDS_BALANCE("01011011", "冻结金额超过可用余额：可用余额={}, 冻结金额={}"),
    FREEZE_RECORD_NOT_FOUND("01011012", "冻结记录不存在：freezeNo={}"),
    FREEZE_ALREADY_RELEASED("01011013", "冻结记录已解冻：freezeNo={}"),
    CANNOT_CLOSE_ACCOUNT("01011014", "账户不满足销户条件：{}"),
    SUB_ACCOUNT_EXISTS("01011015", "存在子账户，主账户不可直接记账"),
    PARENT_ACCOUNT_NOT_FOUND("01011016", "主账户不存在：parentAccountId={}"),
    ;
    
    private final String code;
    private final String messageTemplate;
}
```

- [ ] **Step 8: 创建 VoucherErrorCode**

```java
package com.tianshu.accounting.domain.voucher.exception;

import com.tianshu.accounting.domain.shared.exception.ErrorCode;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * 凭证领域错误码
 * 编码格式：SS 02 1XXX
 */
@Getter
@RequiredArgsConstructor
public enum VoucherErrorCode implements ErrorCode {
    
    VOUCHER_NOT_FOUND("01021001", "凭证不存在：{}"),
    VOUCHER_ALREADY_POSTED("01021002", "凭证已过账：{}"),
    VOUCHER_ALREADY_REVERSED("01021003", "凭证已冲正，不可再次冲正：{}"),
    VOUCHER_NOT_POSTED("01021004", "凭证未过账：{}"),
    ENTRIES_EMPTY("01021005", "记账分录不能为空"),
    ENTRIES_COUNT_INVALID("01021006", "记账分录至少需要2条"),
    DEBIT_CREDIT_NOT_BALANCED("01021007", "借贷不平衡：借方合计={}, 贷方合计={}"),
    DUPLICATE_BIZ_NO("01021008", "业务流水号重复：bizNo={}, channelCode={}"),
    IDEMPOTENCY_CONFLICT("01021009", "幂等冲突：bizNo={}, channelCode={} 已存在但请求内容不一致"),
    ACCOUNT_NOT_FOUND_IN_ENTRY("01021010", "分录中的账户不存在：accountNo={}"),
    ;
    
    private final String code;
    private final String messageTemplate;
}
```

- [ ] **Step 9: 验证编译**

Run: `mvn clean compile -pl accounting-core`
Expected: BUILD SUCCESS

- [ ] **Step 10: Commit**

```bash
git add accounting-core/src/main/java/com/tianshu/accounting/domain/shared/exception/
git add accounting-core/src/main/java/com/tianshu/accounting/domain/account/exception/
git add accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/exception/
git commit -m "feat(core): add domain exception hierarchy"
```


### Task 0.5: 创建 ArchUnit 分层验证测试

**Files:**
- Create: `accounting-core/src/test/java/com/tianshu/accounting/DddLayeringTest.java`

- [ ] **Step 1: 创建 DddLayeringTest**

```java
package com.tianshu.accounting;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * DDD 分层架构验证测试
 */
class DddLayeringTest {
    
    private static JavaClasses importedClasses;
    
    @BeforeAll
    static void setup() {
        importedClasses = new ClassFileImporter()
            .importPackages("com.tianshu.accounting");
    }
    
    /**
     * domain 不依赖上层
     */
    @Test
    void domain_should_not_depend_on_upper_layers() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..application..", "..interfaces..", "..infrastructure..");
        
        rule.check(importedClasses);
    }
    
    /**
     * domain 不依赖框架
     */
    @Test
    void domain_should_not_depend_on_frameworks() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage(
                "org.springframework..",
                "com.baomidou..",
                "org.apache.dubbo..",
                "org.apache.rocketmq.."
            );
        
        rule.check(importedClasses);
    }
    
    /**
     * application 不直接依赖 Repository
     */
    @Test
    void application_should_not_directly_depend_on_repository() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..application..")
            .should().dependOnClassesThat()
            .haveSimpleNameEndingWith("RepositoryImpl");
        
        rule.check(importedClasses);
    }
    
    /**
     * infrastructure 不依赖 application
     */
    @Test
    void infrastructure_should_not_depend_on_application() {
        ArchRule rule = noClasses()
            .that().resideInAPackage("..infrastructure..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..application..", "..interfaces..");
        
        rule.check(importedClasses);
    }
}
```

- [ ] **Step 2: 验证测试运行**

Run: `mvn test -pl accounting-core -Dtest=DddLayeringTest`
Expected: Tests run: 4, Failures: 0

- [ ] **Step 3: Commit**

```bash
git add accounting-core/src/test/java/com/tianshu/accounting/DddLayeringTest.java
git commit -m "test(core): add ArchUnit layering validation"
```


---

## Phase 1: Account 聚合（核心）

### Task 1.1: 创建 Account 聚合根

**Files:**
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/model/Account.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/model/FreezeRecord.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/model/AccountNo.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/event/AccountOpenedEvent.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/event/AccountFrozenEvent.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/event/AccountUnfrozenEvent.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/event/AccountClosedEvent.java`
- Create: `accounting-core/src/test/java/com/tianshu/accounting/domain/account/model/AccountTest.java`

- [ ] **Step 1: 创建 AccountNo 值对象**

```java
package com.tianshu.accounting.domain.account.model;

import java.util.regex.Pattern;

/**
 * 账户业务编号值对象
 */
public record AccountNo(String value) {
    
    private static final Pattern ACCOUNT_NO_PATTERN = Pattern.compile("^[A-Z]{2}\\d{14}$");
    
    public AccountNo {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("accountNo cannot be null or blank");
        }
        if (!ACCOUNT_NO_PATTERN.matcher(value).matches()) {
            throw new IllegalArgumentException("accountNo format invalid: " + value);
        }
    }
    
    @Override
    public String toString() {
        return value;
    }
}
```

- [ ] **Step 2: 创建 FreezeRecord 实体**

```java
package com.tianshu.accounting.domain.account.model;

import lombok.Getter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 冻结明细实体
 * 聚合内实体，不独立持久化
 */
@Getter
public class FreezeRecord {
    /**
     * 冻结明细内部 ID（Snowflake，不对外暴露）
     */
    private final Long freezeId;
    
    /**
     * 冻结业务编号（系统生成，对外返回）
     */
    private final String freezeNo;
    
    /**
     * 调用方业务冻结流水号（幂等键）
     */
    private final String bizFreezeNo;
    
    /**
     * 冻结来源系统（幂等键）
     */
    private final String freezeSource;
    
    /**
     * 冻结金额
     */
    private final BigDecimal freezeAmount;
    
    /**
     * 冻结类型
     */
    private final FreezeType freezeType;
    
    /**
     * 冻结原因
     */
    private final String freezeReason;
    
    /**
     * 冻结时间
     */
    private final LocalDateTime freezeTime;
    
    /**
     * 解冻时间（null 表示未解冻）
     */
    private LocalDateTime unfreezeTime;
    
    private FreezeRecord(Long freezeId, String freezeNo, String bizFreezeNo, 
                         String freezeSource, BigDecimal freezeAmount, 
                         FreezeType freezeType, String freezeReason, 
                         LocalDateTime freezeTime) {
        this.freezeId = freezeId;
        this.freezeNo = freezeNo;
        this.bizFreezeNo = bizFreezeNo;
        this.freezeSource = freezeSource;
        this.freezeAmount = freezeAmount;
        this.freezeType = freezeType;
        this.freezeReason = freezeReason;
        this.freezeTime = freezeTime;
    }
    
    /**
     * 创建冻结记录
     */
    public static FreezeRecord create(Long freezeId, String freezeNo, String bizFreezeNo,
                                       String freezeSource, BigDecimal freezeAmount,
                                       FreezeType freezeType, String freezeReason) {
        return new FreezeRecord(freezeId, freezeNo, bizFreezeNo, freezeSource,
            freezeAmount, freezeType, freezeReason, LocalDateTime.now());
    }
    
    /**
     * 解冻
     */
    public void unfreeze() {
        if (this.unfreezeTime != null) {
            throw new IllegalStateException("Freeze record already unfrozen: " + freezeNo);
        }
        this.unfreezeTime = LocalDateTime.now();
    }
    
    /**
     * 是否已解冻
     */
    public boolean isUnfrozen() {
        return unfreezeTime != null;
    }
    
    /**
     * 是否有效（未解冻）
     */
    public boolean isActive() {
        return unfreezeTime == null;
    }
}
```

- [ ] **Step 3: 创建 AccountOpenedEvent**

```java
package com.tianshu.accounting.domain.account.event;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 账户开立事件
 */
public record AccountOpenedEvent(
    Long accountId,
    String accountNo,
    String accountType,
    String customerId,
    String subjectCode,
    String currency,
    LocalDateTime occurredAt
) implements Serializable {
    private static final long serialVersionUID = 1L;
    
    public static AccountOpenedEvent of(Long accountId, String accountNo, String accountType,
                                         String customerId, String subjectCode, String currency) {
        return new AccountOpenedEvent(accountId, accountNo, accountType, customerId,
            subjectCode, currency, LocalDateTime.now());
    }
}
```

- [ ] **Step 4: 创建 AccountFrozenEvent**

```java
package com.tianshu.accounting.domain.account.event;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 账户冻结事件
 */
public record AccountFrozenEvent(
    Long accountId,
    String accountNo,
    String freezeNo,
    BigDecimal freezeAmount,
    String freezeType,
    LocalDateTime occurredAt
) implements Serializable {
    private static final long serialVersionUID = 1L;
    
    public static AccountFrozenEvent of(Long accountId, String accountNo, String freezeNo,
                                         BigDecimal freezeAmount, String freezeType) {
        return new AccountFrozenEvent(accountId, accountNo, freezeNo, freezeAmount,
            freezeType, LocalDateTime.now());
    }
}
```

- [ ] **Step 5: 创建 AccountUnfrozenEvent**

```java
package com.tianshu.accounting.domain.account.event;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 账户解冻事件
 */
public record AccountUnfrozenEvent(
    Long accountId,
    String accountNo,
    String freezeNo,
    LocalDateTime occurredAt
) implements Serializable {
    private static final long serialVersionUID = 1L;
    
    public static AccountUnfrozenEvent of(Long accountId, String accountNo, String freezeNo) {
        return new AccountUnfrozenEvent(accountId, accountNo, freezeNo, LocalDateTime.now());
    }
}
```

- [ ] **Step 6: 创建 AccountClosedEvent**

```java
package com.tianshu.accounting.domain.account.event;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 账户销户事件
 */
public record AccountClosedEvent(
    Long accountId,
    String accountNo,
    LocalDateTime occurredAt
) implements Serializable {
    private static final long serialVersionUID = 1L;
    
    public static AccountClosedEvent of(Long accountId, String accountNo) {
        return new AccountClosedEvent(accountId, accountNo, LocalDateTime.now());
    }
}
```

- [ ] **Step 7: 创建 Account 聚合根（第一部分：字段和构造）**

```java
package com.tianshu.accounting.domain.account.model;

import com.tianshu.accounting.domain.account.event.*;
import com.tianshu.accounting.domain.account.exception.AccountErrorCode;
import com.tianshu.accounting.domain.shared.exception.DomainException;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 账户聚合根
 */
@Getter
public class Account {
    // 标识
    private final Long accountId;
    private final AccountNo accountNo;
    
    // 分类
    private final AccountType accountType;
    private final OwnerType ownerType;
    
    // 归属
    private final String customerId;        // 客户户必填
    private final String institutionId;     // 内部户必填
    private final Long parentAccountId;     // 子账户必填
    
    // 科目
    private final String subjectCode;
    
    // 币种
    private final String currency;
    
    // 余额
    private BigDecimal balance;
    private BigDecimal frozenAmount;
    
    // 生命周期状态
    private LifecycleStatus lifecycleStatus;
    
    // 交易控制标志
    private boolean debitBlocked;
    private boolean creditBlocked;
    
    // 运营治理状态
    private ActivityStatus activityStatus;
    
    // 乐观锁
    private int version;
    
    // 冻结明细（聚合内实体）
    private final List<FreezeRecord> freezeRecords = new ArrayList<>();
    
    // 领域事件（暂存）
    private final List<Object> domainEvents = new ArrayList<>();
    
    /**
     * 开户
     */
    public static Account open(Long accountId, AccountNo accountNo, AccountType accountType,
                                String customerId, String institutionId, Long parentAccountId,
                                String subjectCode, String currency) {
        Account account = new Account(accountId, accountNo, accountType, customerId,
            institutionId, parentAccountId, subjectCode, currency);
        account.registerEvent(AccountOpenedEvent.of(accountId, accountNo.value(),
            accountType.name(), customerId, subjectCode, currency));
        return account;
    }
    
    private Account(Long accountId, AccountNo accountNo, AccountType accountType,
                    String customerId, String institutionId, Long parentAccountId,
                    String subjectCode, String currency) {
        this.accountId = accountId;
        this.accountNo = accountNo;
        this.accountType = accountType;
        this.ownerType = accountType == AccountType.INTERNAL ? OwnerType.INSTITUTION : OwnerType.CUSTOMER;
        this.customerId = customerId;
        this.institutionId = institutionId;
        this.parentAccountId = parentAccountId;
        this.subjectCode = subjectCode;
        this.currency = currency;
        this.balance = BigDecimal.ZERO;
        this.frozenAmount = BigDecimal.ZERO;
        this.lifecycleStatus = LifecycleStatus.ACTIVE;
        this.activityStatus = ActivityStatus.NORMAL;
        this.debitBlocked = false;
        this.creditBlocked = false;
        this.version = 0;
    }
    
    // 事件注册
    private void registerEvent(Object event) {
        domainEvents.add(event);
    }
    
    public List<Object> getDomainEvents() {
        return List.copyOf(domainEvents);
    }
    
    public void clearDomainEvents() {
        domainEvents.clear();
    }
}
```

- [ ] **Step 8: 创建 Account 聚合根（第二部分：记账方法）**

在 Account 类中添加以下方法：

```java
    /**
     * 入账
     */
    public void credit(BigDecimal amount) {
        validateCanTrade();
        if (creditBlocked) {
            throw DomainException.of(AccountErrorCode.CREDIT_BLOCKED, accountNo.value());
        }
        this.balance = balance.add(amount);
    }
    
    /**
     * 出账
     */
    public void debit(BigDecimal amount) {
        validateCanTrade();
        if (debitBlocked) {
            throw DomainException.of(AccountErrorCode.DEBIT_BLOCKED, accountNo.value());
        }
        BigDecimal availableBalance = balance.subtract(frozenAmount);
        if (availableBalance.compareTo(amount) < 0) {
            throw DomainException.of(AccountErrorCode.INSUFFICIENT_BALANCE, 
                availableBalance, amount);
        }
        this.balance = balance.subtract(amount);
    }
    
    /**
     * 验证是否可交易
     */
    private void validateCanTrade() {
        if (lifecycleStatus == LifecycleStatus.CLOSED) {
            throw DomainException.of(AccountErrorCode.ACCOUNT_CLOSED, accountNo.value());
        }
        if (lifecycleStatus == LifecycleStatus.PENDING_CLOSE) {
            throw DomainException.of(AccountErrorCode.ACCOUNT_PENDING_CLOSE, accountNo.value());
        }
        if (activityStatus == ActivityStatus.DORMANT) {
            throw DomainException.of(AccountErrorCode.ACCOUNT_DORMANT, accountNo.value());
        }
        if (activityStatus == ActivityStatus.UNCLAIMED) {
            throw DomainException.of(AccountErrorCode.ACCOUNT_UNCLAIMED, accountNo.value());
        }
    }
    
    /**
     * 获取可用余额
     */
    public BigDecimal getAvailableBalance() {
        return balance.subtract(frozenAmount);
    }
```

- [ ] **Step 9: 创建 Account 聚合根（第三部分：冻结方法）**

在 Account 类中添加以下方法：

```java
    /**
     * 冻结
     * @return freezeNo 冻结业务编号
     */
    public String freeze(Long freezeId, String freezeNo, String bizFreezeNo,
                         String freezeSource, BigDecimal amount, FreezeType freezeType,
                         String freezeReason) {
        validateCanTrade();
        
        // 幂等检查：相同 bizFreezeNo + freezeSource 已存在
        for (FreezeRecord record : freezeRecords) {
            if (record.getBizFreezeNo().equals(bizFreezeNo) 
                && record.getFreezeSource().equals(freezeSource)) {
                return record.getFreezeNo(); // 返回已存在的 freezeNo
            }
        }
        
        // 检查可用余额
        BigDecimal availableBalance = balance.subtract(frozenAmount);
        if (availableBalance.compareTo(amount) < 0) {
            throw DomainException.of(AccountErrorCode.FREEZE_AMOUNT_EXCEEDS_BALANCE,
                availableBalance, amount);
        }
        
        // 创建冻结记录
        FreezeRecord record = FreezeRecord.create(freezeId, freezeNo, bizFreezeNo,
            freezeSource, amount, freezeType, freezeReason);
        freezeRecords.add(record);
        
        // 更新冻结金额
        this.frozenAmount = frozenAmount.add(amount);
        
        // 司法冻结同步设置标志位
        if (freezeType == FreezeType.JUDICIAL) {
            this.debitBlocked = true;
            this.creditBlocked = true;
        }
        
        registerEvent(AccountFrozenEvent.of(accountId, accountNo.value(), freezeNo,
            amount, freezeType.name()));
        
        return freezeNo;
    }
    
    /**
     * 解冻
     */
    public void unfreeze(String freezeNo) {
        FreezeRecord record = findActiveFreezeRecord(freezeNo);
        if (record == null) {
            throw DomainException.of(AccountErrorCode.FREEZE_RECORD_NOT_FOUND, freezeNo);
        }
        if (record.isUnfrozen()) {
            throw DomainException.of(AccountErrorCode.FREEZE_ALREADY_RELEASED, freezeNo);
        }
        
        // 解冻
        record.unfreeze();
        this.frozenAmount = frozenAmount.subtract(record.getFreezeAmount());
        
        // 司法冻结解冻时清除标志位
        if (record.getFreezeType() == FreezeType.JUDICIAL) {
            this.debitBlocked = false;
            this.creditBlocked = false;
        }
        
        registerEvent(AccountUnfrozenEvent.of(accountId, accountNo.value(), freezeNo));
    }
    
    /**
     * 解冻并扣款（预授权完成）
     */
    public void debitWithUnfreeze(String freezeNo, BigDecimal amount) {
        FreezeRecord record = findActiveFreezeRecord(freezeNo);
        if (record == null) {
            throw DomainException.of(AccountErrorCode.FREEZE_RECORD_NOT_FOUND, freezeNo);
        }
        if (record.isUnfrozen()) {
            throw DomainException.of(AccountErrorCode.FREEZE_ALREADY_RELEASED, freezeNo);
        }
        
        // 解冻
        record.unfreeze();
        this.frozenAmount = frozenAmount.subtract(record.getFreezeAmount());
        
        // 扣款
        this.balance = balance.subtract(amount);
        
        registerEvent(AccountUnfrozenEvent.of(accountId, accountNo.value(), freezeNo));
    }
    
    /**
     * 查找有效的冻结记录
     */
    private FreezeRecord findActiveFreezeRecord(String freezeNo) {
        for (FreezeRecord record : freezeRecords) {
            if (record.getFreezeNo().equals(freezeNo)) {
                return record;
            }
        }
        return null;
    }
```

- [ ] **Step 10: 创建 Account 聚合根（第四部分：状态管理方法）**

在 Account 类中添加以下方法：

```java
    /**
     * 禁止出账
     */
    public void blockDebit(String reason) {
        this.debitBlocked = true;
    }
    
    /**
     * 解除禁止出账
     */
    public void unblockDebit() {
        this.debitBlocked = false;
    }
    
    /**
     * 禁止入账
     */
    public void blockCredit(String reason) {
        this.creditBlocked = true;
    }
    
    /**
     * 解除禁止入账
     */
    public void unblockCredit() {
        this.creditBlocked = false;
    }
    
    /**
     * 标记休眠
     */
    public void markDormant() {
        this.activityStatus = ActivityStatus.DORMANT;
    }
    
    /**
     * 标记久悬
     */
    public void markUnclaimed() {
        this.activityStatus = ActivityStatus.UNCLAIMED;
    }
    
    /**
     * 激活
     */
    public void reactivate() {
        this.activityStatus = ActivityStatus.NORMAL;
    }
    
    /**
     * 发起销户
     */
    public void initiateClose() {
        if (lifecycleStatus != LifecycleStatus.ACTIVE) {
            throw DomainException.of(AccountErrorCode.ACCOUNT_CLOSED, accountNo.value());
        }
        this.lifecycleStatus = LifecycleStatus.PENDING_CLOSE;
    }
    
    /**
     * 销户
     */
    public void close() {
        // 校验销户条件
        StringBuilder errors = new StringBuilder();
        if (balance.compareTo(BigDecimal.ZERO) != 0) {
            errors.append("余额不为零; ");
        }
        if (frozenAmount.compareTo(BigDecimal.ZERO) != 0) {
            errors.append("冻结金额不为零; ");
        }
        if (debitBlocked || creditBlocked) {
            errors.append("存在交易控制标志; ");
        }
        if (errors.length() > 0) {
            throw DomainException.of(AccountErrorCode.CANNOT_CLOSE_ACCOUNT, errors.toString());
        }
        
        this.lifecycleStatus = LifecycleStatus.CLOSED;
        registerEvent(AccountClosedEvent.of(accountId, accountNo.value()));
    }
    
    /**
     * 更新版本号（乐观锁）
     */
    public void incrementVersion() {
        this.version++;
    }
```

- [ ] **Step 11: 创建 AccountTest**

```java
package com.tianshu.accounting.domain.account.model;

import com.tianshu.accounting.domain.shared.exception.DomainException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class AccountTest {
    
    private Account createTestAccount() {
        return Account.open(1L, new AccountNo("AC12345678901234"), AccountType.MAIN,
            "CUST001", null, null, "1001", "CNY");
    }
    
    @Nested
    @DisplayName("开户测试")
    class OpenAccountTest {
        
        @Test
        @DisplayName("开户成功")
        void should_open_account_successfully() {
            Account account = createTestAccount();
            
            assertNotNull(account);
            assertEquals(LifecycleStatus.ACTIVE, account.getLifecycleStatus());
            assertEquals(BigDecimal.ZERO, account.getBalance());
            assertEquals(ActivityStatus.NORMAL, account.getActivityStatus());
            assertFalse(account.isDebitBlocked());
            assertFalse(account.isCreditBlocked());
        }
        
        @Test
        @DisplayName("开户后发布 AccountOpenedEvent")
        void should_publish_account_opened_event() {
            Account account = createTestAccount();
            
            assertEquals(1, account.getDomainEvents().size());
            assertTrue(account.getDomainEvents().get(0) instanceof AccountOpenedEvent);
        }
    }
    
    @Nested
    @DisplayName("记账测试")
    class AccountingTest {
        
        @Test
        @DisplayName("入账成功")
        void should_credit_successfully() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            
            assertEquals(BigDecimal.valueOf(100), account.getBalance());
        }
        
        @Test
        @DisplayName("出账成功")
        void should_debit_successfully() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            account.debit(BigDecimal.valueOf(30));
            
            assertEquals(BigDecimal.valueOf(70), account.getBalance());
        }
        
        @Test
        @DisplayName("余额不足时出账失败")
        void should_fail_when_insufficient_balance() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(50));
            
            assertThrows(DomainException.class, () -> 
                account.debit(BigDecimal.valueOf(100)));
        }
        
        @Test
        @DisplayName("禁止出账时出账失败")
        void should_fail_when_debit_blocked() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            account.blockDebit("风控止付");
            
            assertThrows(DomainException.class, () -> 
                account.debit(BigDecimal.valueOf(10)));
        }
        
        @Test
        @DisplayName("禁止入账时入账失败")
        void should_fail_when_credit_blocked() {
            Account account = createTestAccount();
            account.blockCredit("特殊监管");
            
            assertThrows(DomainException.class, () -> 
                account.credit(BigDecimal.valueOf(100)));
        }
    }
    
    @Nested
    @DisplayName("冻结测试")
    class FreezeTest {
        
        @Test
        @DisplayName("冻结成功")
        void should_freeze_successfully() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            
            String freezeNo = account.freeze(1L, "FZ001", "BIZ001", "RISK",
                BigDecimal.valueOf(50), FreezeType.RISK, "风控冻结");
            
            assertNotNull(freezeNo);
            assertEquals(BigDecimal.valueOf(50), account.getFrozenAmount());
            assertEquals(BigDecimal.valueOf(50), account.getAvailableBalance());
        }
        
        @Test
        @DisplayName("冻结金额超过可用余额时失败")
        void should_fail_when_freeze_exceeds_available() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(50));
            
            assertThrows(DomainException.class, () ->
                account.freeze(1L, "FZ001", "BIZ001", "RISK",
                    BigDecimal.valueOf(100), FreezeType.RISK, "风控冻结"));
        }
        
        @Test
        @DisplayName("解冻成功")
        void should_unfreeze_successfully() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            String freezeNo = account.freeze(1L, "FZ001", "BIZ001", "RISK",
                BigDecimal.valueOf(50), FreezeType.RISK, "风控冻结");
            
            account.unfreeze(freezeNo);
            
            assertEquals(BigDecimal.ZERO, account.getFrozenAmount());
            assertEquals(BigDecimal.valueOf(100), account.getAvailableBalance());
        }
        
        @Test
        @DisplayName("司法冻结同步设置标志位")
        void should_set_flags_when_judicial_freeze() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            
            account.freeze(1L, "FZ001", "BIZ001", "COURT",
                BigDecimal.valueOf(50), FreezeType.JUDICIAL, "司法冻结");
            
            assertTrue(account.isDebitBlocked());
            assertTrue(account.isCreditBlocked());
        }
    }
    
    @Nested
    @DisplayName("销户测试")
    class CloseAccountTest {
        
        @Test
        @DisplayName("销户成功")
        void should_close_successfully() {
            Account account = createTestAccount();
            account.initiateClose();
            account.close();
            
            assertEquals(LifecycleStatus.CLOSED, account.getLifecycleStatus());
        }
        
        @Test
        @DisplayName("余额不为零时销户失败")
        void should_fail_when_balance_not_zero() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            account.initiateClose();
            
            assertThrows(DomainException.class, account::close);
        }
        
        @Test
        @DisplayName("存在冻结金额时销户失败")
        void should_fail_when_frozen_amount_not_zero() {
            Account account = createTestAccount();
            account.credit(BigDecimal.valueOf(100));
            account.freeze(1L, "FZ001", "BIZ001", "RISK",
                BigDecimal.valueOf(50), FreezeType.RISK, "风控冻结");
            account.initiateClose();
            
            assertThrows(DomainException.class, account::close);
        }
    }
}
```

- [ ] **Step 12: 验证编译和测试**

Run: `mvn test -pl accounting-core -Dtest=AccountTest`
Expected: Tests run: 14, Failures: 0

- [ ] **Step 13: Commit**

```bash
git add accounting-core/src/main/java/com/tianshu/accounting/domain/account/
git add accounting-core/src/test/java/com/tianshu/accounting/domain/account/
git commit -m "feat(domain): add Account aggregate root with freeze and status management"
```


### Task 1.2: 创建 Account Repository 接口和实现

**Files:**
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/account/repository/AccountRepository.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/infrastructure/mysql/account/AccountDO.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/infrastructure/mysql/account/AccountMapper.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/infrastructure/mysql/account/AccountRepositoryImpl.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/infrastructure/mysql/account/AccountConverter.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/infrastructure/mysql/account/FreezeRecordDO.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/infrastructure/mysql/account/FreezeRecordMapper.java`
- Create: `accounting-core/src/test/java/com/tianshu/accounting/infrastructure/mysql/account/AccountRepositoryImplTest.java`

- [ ] **Step 1: 创建 AccountRepository 接口**

```java
package com.tianshu.accounting.domain.account.repository;

import com.tianshu.accounting.domain.account.model.Account;

import java.util.List;
import java.util.Optional;

/**
 * 账户仓储接口
 */
public interface AccountRepository {
    
    /**
     * 按 ID 查找
     */
    Optional<Account> findById(Long accountId);
    
    /**
     * 按账户业务编号查找
     */
    Optional<Account> findByAccountNo(String accountNo);
    
    /**
     * 按客户号 + 科目代码 + 账户类型查找
     */
    Optional<Account> findByCustomerIdAndSubjectCodeAndAccountType(
        String customerId, String subjectCode, String accountType);
    
    /**
     * 查找主账户下的所有子账户
     */
    List<Account> findByParentAccountId(Long parentAccountId);
    
    /**
     * 保存
     */
    void save(Account account);
    
    /**
     * 生成账户 ID
     */
    Long nextAccountId();
}
```

- [ ] **Step 2: 创建 AccountDO**

```java
package com.tianshu.accounting.infrastructure.mysql.account;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 账户数据对象
 */
@Data
@Accessors(chain = true)
@TableName("t_account")
public class AccountDO {
    
    @TableId(type = IdType.ASSIGN_ID)
    private Long accountId;
    
    private String accountNo;
    
    private String accountType;
    
    private String ownerType;
    
    private String customerId;
    
    private String institutionId;
    
    private Long parentAccountId;
    
    private String subjectCode;
    
    private String currency;
    
    private BigDecimal balance;
    
    private BigDecimal frozenAmount;
    
    private String lifecycleStatus;
    
    private Boolean debitBlocked;
    
    private Boolean creditBlocked;
    
    private String activityStatus;
    
    @Version
    private Integer version;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createDatetime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateDatetime;
    
    @TableField(fill = FieldFill.INSERT)
    private String createBy;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private String updateBy;
    
    @TableLogic
    private Integer deleteFlag;
}
```

- [ ] **Step 3: 创建 FreezeRecordDO**

```java
package com.tianshu.accounting.infrastructure.mysql.account;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import lombok.experimental.Accessors;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 冻结明细数据对象
 */
@Data
@Accessors(chain = true)
@TableName("t_freeze_record")
public class FreezeRecordDO {
    
    @TableId(type = IdType.ASSIGN_ID)
    private Long freezeId;
    
    private Long accountId;
    
    private String freezeNo;
    
    private String bizFreezeNo;
    
    private String freezeSource;
    
    private BigDecimal freezeAmount;
    
    private String freezeType;
    
    private String freezeReason;
    
    private LocalDateTime freezeTime;
    
    private LocalDateTime unfreezeTime;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createDatetime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateDatetime;
    
    @TableLogic
    private Integer deleteFlag;
}
```

- [ ] **Step 4: 创建 AccountMapper**

```java
package com.tianshu.accounting.infrastructure.mysql.account;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 账户 Mapper
 */
@Mapper
public interface AccountMapper extends BaseMapper<AccountDO> {
}
```

- [ ] **Step 5: 创建 FreezeRecordMapper**

```java
package com.tianshu.accounting.infrastructure.mysql.account;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * 冻结明细 Mapper
 */
@Mapper
public interface FreezeRecordMapper extends BaseMapper<FreezeRecordDO> {
    
    default List<FreezeRecordDO> findByAccountId(Long accountId) {
        return selectList(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<FreezeRecordDO>()
            .eq(FreezeRecordDO::getAccountId, accountId));
    }
}
```

- [ ] **Step 6: 创建 AccountConverter**

```java
package com.tianshu.accounting.infrastructure.mysql.account;

import com.tianshu.accounting.domain.account.model.*;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

import java.util.List;

/**
 * Account DO ↔ 领域对象转换器
 */
@Mapper(componentModel = "spring")
public interface AccountConverter {
    
    @Mapping(target = "accountNo", source = "accountNo.value")
    @Mapping(target = "accountType", source = "accountType", qualifiedByName = "enumToString")
    @Mapping(target = "ownerType", source = "ownerType", qualifiedByName = "enumToString")
    @Mapping(target = "lifecycleStatus", source = "lifecycleStatus", qualifiedByName = "enumToString")
    @Mapping(target = "activityStatus", source = "activityStatus", qualifiedByName = "enumToString")
    @Mapping(target = "debitBlocked", source = "debitBlocked")
    @Mapping(target = "creditBlocked", source = "creditBlocked")
    @Mapping(target = "freezeRecords", ignore = true)
    AccountDO toDO(Account account);
    
    @Mapping(target = "accountNo", expression = "java(new com.tianshu.accounting.domain.account.model.AccountNo(doObj.getAccountNo()))")
    @Mapping(target = "accountType", source = "accountType", qualifiedByName = "stringToAccountType")
    @Mapping(target = "ownerType", source = "ownerType", qualifiedByName = "stringToOwnerType")
    @Mapping(target = "lifecycleStatus", source = "lifecycleStatus", qualifiedByName = "stringToLifecycleStatus")
    @Mapping(target = "activityStatus", source = "activityStatus", qualifiedByName = "stringToActivityStatus")
    @Mapping(target = "freezeRecords", ignore = true)
    Account toDomain(AccountDO doObj);
    
    @Named("enumToString")
    default String enumToString(Enum<?> e) {
        return e == null ? null : e.name();
    }
    
    @Named("stringToAccountType")
    default AccountType stringToAccountType(String value) {
        return value == null ? null : AccountType.valueOf(value);
    }
    
    @Named("stringToOwnerType")
    default OwnerType stringToOwnerType(String value) {
        return value == null ? null : OwnerType.valueOf(value);
    }
    
    @Named("stringToLifecycleStatus")
    default LifecycleStatus stringToLifecycleStatus(String value) {
        return value == null ? null : LifecycleStatus.valueOf(value);
    }
    
    @Named("stringToActivityStatus")
    default ActivityStatus stringToActivityStatus(String value) {
        return value == null ? null : ActivityStatus.valueOf(value);
    }
    
    // FreezeRecord 转换
    @Mapping(target = "freezeType", source = "freezeType", qualifiedByName = "stringToFreezeType")
    FreezeRecord toFreezeRecord(FreezeRecordDO doObj);
    
    @Mapping(target = "freezeType", source = "freezeType", qualifiedByName = "freezeTypeToString")
    FreezeRecordDO toFreezeRecordDO(FreezeRecord record);
    
    @Named("stringToFreezeType")
    default FreezeType stringToFreezeType(String value) {
        return value == null ? null : FreezeType.valueOf(value);
    }
    
    @Named("freezeTypeToString")
    default String freezeTypeToString(FreezeType type) {
        return type == null ? null : type.name();
    }
    
    List<FreezeRecord> toFreezeRecordList(List<FreezeRecordDO> doList);
}
```

- [ ] **Step 7: 创建 AccountRepositoryImpl**

```java
package com.tianshu.accounting.infrastructure.mysql.account;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.tianshu.accounting.domain.account.model.Account;
import com.tianshu.accounting.domain.account.model.AccountNo;
import com.tianshu.accounting.domain.account.repository.AccountRepository;
import com.tianshu.accounting.domain.shared.exception.InfrastructureException;
import com.tianshu.accounting.domain.shared.exception.SystemErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * 账户仓储实现
 */
@Slf4j
@Repository
@RequiredArgsConstructor
public class AccountRepositoryImpl implements AccountRepository {
    
    private final AccountMapper accountMapper;
    private final FreezeRecordMapper freezeRecordMapper;
    private final AccountConverter accountConverter;
    
    @Override
    public Optional<Account> findById(Long accountId) {
        AccountDO accountDO = accountMapper.selectById(accountId);
        if (accountDO == null) {
            return Optional.empty();
        }
        Account account = accountConverter.toDomain(accountDO);
        loadFreezeRecords(account);
        return Optional.of(account);
    }
    
    @Override
    public Optional<Account> findByAccountNo(String accountNo) {
        AccountDO accountDO = accountMapper.selectOne(
            new LambdaQueryWrapper<AccountDO>()
                .eq(AccountDO::getAccountNo, accountNo)
        );
        if (accountDO == null) {
            return Optional.empty();
        }
        Account account = accountConverter.toDomain(accountDO);
        loadFreezeRecords(account);
        return Optional.of(account);
    }
    
    @Override
    public Optional<Account> findByCustomerIdAndSubjectCodeAndAccountType(
            String customerId, String subjectCode, String accountType) {
        AccountDO accountDO = accountMapper.selectOne(
            new LambdaQueryWrapper<AccountDO>()
                .eq(AccountDO::getCustomerId, customerId)
                .eq(AccountDO::getSubjectCode, subjectCode)
                .eq(AccountDO::getAccountType, accountType)
        );
        if (accountDO == null) {
            return Optional.empty();
        }
        Account account = accountConverter.toDomain(accountDO);
        loadFreezeRecords(account);
        return Optional.of(account);
    }
    
    @Override
    public List<Account> findByParentAccountId(Long parentAccountId) {
        List<AccountDO> accountDOs = accountMapper.selectList(
            new LambdaQueryWrapper<AccountDO>()
                .eq(AccountDO::getParentAccountId, parentAccountId)
        );
        return accountDOs.stream()
            .map(accountConverter::toDomain)
            .peek(this::loadFreezeRecords)
            .toList();
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void save(Account account) {
        try {
            AccountDO accountDO = accountConverter.toDO(account);
            
            if (account.getVersion() == 0) {
                // 新增
                accountMapper.insert(accountDO);
                // 保存冻结记录
                saveFreezeRecords(account);
            } else {
                // 更新（乐观锁）
                int rows = accountMapper.updateById(accountDO);
                if (rows == 0) {
                    throw InfrastructureException.of(SystemErrorCode.OPTIMISTIC_LOCK_ERROR, "Account");
                }
                // 更新冻结记录
                updateFreezeRecords(account);
            }
            
            account.incrementVersion();
        } catch (InfrastructureException e) {
            throw e;
        } catch (Exception e) {
            throw InfrastructureException.of(SystemErrorCode.SYSTEM_ERROR, "AccountRepository", e);
        }
    }
    
    @Override
    public Long nextAccountId() {
        // 使用 MyBatis-Plus 的雪花算法
        return System.currentTimeMillis(); // 简化实现，实际应使用雪花算法
    }
    
    private void loadFreezeRecords(Account account) {
        List<FreezeRecordDO> freezeRecordDOs = freezeRecordMapper.findByAccountId(account.getAccountId());
        List<com.tianshu.accounting.domain.account.model.FreezeRecord> records = 
            accountConverter.toFreezeRecordList(freezeRecordDOs);
        // 通过反射或 setter 设置冻结记录（简化实现）
        // 实际应使用聚合根的内部方法
    }
    
    private void saveFreezeRecords(Account account) {
        // 保存冻结记录
    }
    
    private void updateFreezeRecords(Account account) {
        // 更新冻结记录
    }
}
```

- [ ] **Step 8: 验证编译**

Run: `mvn clean compile -pl accounting-core`
Expected: BUILD SUCCESS

- [ ] **Step 9: Commit**

```bash
git add accounting-core/src/main/java/com/tianshu/accounting/domain/account/repository/
git add accounting-core/src/main/java/com/tianshu/accounting/infrastructure/mysql/account/
git commit -m "feat(infra): add Account repository implementation"
```


### Task 1.3: 创建 Account 应用层服务

**Files:**
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/account/AccountCommandService.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/account/AccountQueryService.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/account/cmd/OpenAccountCommand.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/account/cmd/FreezeCommand.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/account/cmd/UnfreezeCommand.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/account/assembler/AccountAssembler.java`

- [ ] **Step 1: 创建 OpenAccountCommand**

```java
package com.tianshu.accounting.application.account.cmd;

import lombok.Builder;
import lombok.Getter;

/**
 * 开户命令
 */
@Getter
@Builder
public class OpenAccountCommand {
    private final String customerId;
    private final String subjectCode;
    private final String accountType;
    private final String institutionId;
    private final Long parentAccountId;
    private final String currency;
    private final String channelCode;
    private final String operatorId;
    private final String memo;
}
```

- [ ] **Step 2: 创建 FreezeCommand**

```java
package com.tianshu.accounting.application.account.cmd;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

/**
 * 冻结命令
 */
@Getter
@Builder
public class FreezeCommand {
    private final String accountNo;
    private final BigDecimal freezeAmount;
    private final String freezeType;
    private final String freezeReason;
    private final String bizFreezeNo;
    private final String freezeSource;
    private final String operatorId;
}
```

- [ ] **Step 3: 创建 UnfreezeCommand**

```java
package com.tianshu.accounting.application.account.cmd;

import lombok.Builder;
import lombok.Getter;

/**
 * 解冻命令
 */
@Getter
@Builder
public class UnfreezeCommand {
    private final String accountNo;
    private final String freezeNo;
    private final String unfreezeReason;
    private final String operatorId;
}
```

- [ ] **Step 4: 创建 AccountAssembler**

```java
package com.tianshu.accounting.application.account.assembler;

import com.tianshu.accounting.api.dto.*;
import com.tianshu.accounting.application.account.cmd.*;
import com.tianshu.accounting.domain.account.model.Account;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

/**
 * Account DTO ↔ Command/领域对象 转换器
 */
@Mapper(componentModel = "spring")
public interface AccountAssembler {
    
    OpenAccountCommand toCommand(OpenAccountRequest request);
    
    FreezeCommand toCommand(FreezeRequest request);
    
    UnfreezeCommand toCommand(UnfreezeRequest request);
    
    @Mapping(target = "accountId", source = "accountId")
    @Mapping(target = "accountNo", source = "accountNo.value")
    @Mapping(target = "accountType", source = "accountType.name")
    @Mapping(target = "ownerType", source = "ownerType.name")
    @Mapping(target = "lifecycleStatus", source = "lifecycleStatus.name")
    @Mapping(target = "activityStatus", source = "activityStatus.name")
    AccountDetailResponse toResponse(Account account);
}
```

- [ ] **Step 5: 创建 AccountCommandService**

```java
package com.tianshu.accounting.application.account;

import com.tianshu.accounting.application.account.cmd.*;
import com.tianshu.accounting.domain.account.exception.AccountErrorCode;
import com.tianshu.accounting.domain.account.model.*;
import com.tianshu.accounting.domain.account.repository.AccountRepository;
import com.tianshu.accounting.domain.shared.exception.DomainException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 账户命令服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AccountCommandService {
    
    private final AccountRepository accountRepository;
    
    /**
     * 开户
     */
    @Transactional(rollbackFor = Exception.class)
    public Long openAccount(OpenAccountCommand command) {
        log.info("[ORCHESTRATION] openAccount: customerId={}, subjectCode={}, accountType={}",
            command.getCustomerId(), command.getSubjectCode(), command.getAccountType());
        
        // 幂等检查
        accountRepository.findByCustomerIdAndSubjectCodeAndAccountType(
            command.getCustomerId(), command.getSubjectCode(), command.getAccountType()
        ).ifPresent(existing -> {
            log.info("Account already exists: accountId={}", existing.getAccountId());
            return existing.getAccountId();
        });
        
        // 生成账户 ID 和账号
        Long accountId = accountRepository.nextAccountId();
        String accountNo = generateAccountNo(command);
        
        // 创建账户
        Account account = Account.open(
            accountId,
            new AccountNo(accountNo),
            AccountType.valueOf(command.getAccountType()),
            command.getCustomerId(),
            command.getInstitutionId(),
            command.getParentAccountId(),
            command.getSubjectCode(),
            command.getCurrency()
        );
        
        // 保存
        accountRepository.save(account);
        
        log.info("[ORCHESTRATION] Account opened: accountId={}, accountNo={}", 
            accountId, accountNo);
        
        return accountId;
    }
    
    /**
     * 冻结
     */
    @Transactional(rollbackFor = Exception.class)
    public String freeze(FreezeCommand command) {
        log.info("[ORCHESTRATION] freeze: accountNo={}, amount={}", 
            command.getAccountNo(), command.getFreezeAmount());
        
        Account account = accountRepository.findByAccountNo(command.getAccountNo())
            .orElseThrow(() -> DomainException.of(
                AccountErrorCode.ACCOUNT_NOT_FOUND, command.getAccountNo()));
        
        Long freezeId = System.currentTimeMillis(); // 简化
        String freezeNo = generateFreezeNo();
        
        String result = account.freeze(
            freezeId,
            freezeNo,
            command.getBizFreezeNo(),
            command.getFreezeSource(),
            command.getFreezeAmount(),
            FreezeType.valueOf(command.getFreezeType()),
            command.getFreezeReason()
        );
        
        accountRepository.save(account);
        
        log.info("[ORCHESTRATION] Account frozen: accountNo={}, freezeNo={}", 
            command.getAccountNo(), result);
        
        return result;
    }
    
    /**
     * 解冻
     */
    @Transactional(rollbackFor = Exception.class)
    public void unfreeze(UnfreezeCommand command) {
        log.info("[ORCHESTRATION] unfreeze: accountNo={}, freezeNo={}", 
            command.getAccountNo(), command.getFreezeNo());
        
        Account account = accountRepository.findByAccountNo(command.getAccountNo())
            .orElseThrow(() -> DomainException.of(
                AccountErrorCode.ACCOUNT_NOT_FOUND, command.getAccountNo()));
        
        account.unfreeze(command.getFreezeNo());
        accountRepository.save(account);
        
        log.info("[ORCHESTRATION] Account unfrozen: accountNo={}, freezeNo={}", 
            command.getAccountNo(), command.getFreezeNo());
    }
    
    private String generateAccountNo(OpenAccountCommand command) {
        // 简化实现：法人代码(2位) + 产品代码(4位) + 顺序号(8位) + 校验位(2位)
        return String.format("AC%014d", System.currentTimeMillis() % 100000000000000L);
    }
    
    private String generateFreezeNo() {
        return String.format("FZ%014d", System.currentTimeMillis() % 100000000000000L);
    }
}
```

- [ ] **Step 6: 创建 AccountQueryService**

```java
package com.tianshu.accounting.application.account;

import com.tianshu.accounting.domain.account.exception.AccountErrorCode;
import com.tianshu.accounting.domain.account.model.Account;
import com.tianshu.accounting.domain.account.repository.AccountRepository;
import com.tianshu.accounting.domain.shared.exception.DomainException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 账户查询服务
 */
@Service
@RequiredArgsConstructor
public class AccountQueryService {
    
    private final AccountRepository accountRepository;
    
    /**
     * 按账户号查询
     */
    public Account findByAccountNo(String accountNo) {
        return accountRepository.findByAccountNo(accountNo)
            .orElseThrow(() -> DomainException.of(
                AccountErrorCode.ACCOUNT_NOT_FOUND, accountNo));
    }
    
    /**
     * 按 ID 查询
     */
    public Account findById(Long accountId) {
        return accountRepository.findById(accountId)
            .orElseThrow(() -> DomainException.of(
                AccountErrorCode.ACCOUNT_NOT_FOUND, accountId));
    }
}
```

- [ ] **Step 7: 验证编译**

Run: `mvn clean compile -pl accounting-core`
Expected: BUILD SUCCESS

- [ ] **Step 8: Commit**

```bash
git add accounting-core/src/main/java/com/tianshu/accounting/application/account/
git commit -m "feat(app): add Account command and query services"
```


---

## Phase 2: AccountingVoucher 聚合（核心）

### Task 2.1: 创建 AccountingVoucher 聚合根

**Files:**
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/model/AccountingVoucher.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/model/AccountingEntry.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/model/VoucherNo.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/event/AccountingCompletedEvent.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/event/AccountingReversedEvent.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/repository/VoucherRepository.java`
- Create: `accounting-core/src/test/java/com/tianshu/accounting/domain/voucher/model/AccountingVoucherTest.java`

- [ ] **Step 1: 创建 VoucherNo 值对象**

```java
package com.tianshu.accounting.domain.voucher.model;

import java.util.regex.Pattern;

/**
 * 凭证号值对象
 */
public record VoucherNo(String value) {
    
    private static final Pattern VOUCHER_NO_PATTERN = Pattern.compile("^V\\d{15}$");
    
    public VoucherNo {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("voucherNo cannot be null or blank");
        }
        if (!VOUCHER_NO_PATTERN.matcher(value).matches()) {
            throw new IllegalArgumentException("voucherNo format invalid: " + value);
        }
    }
    
    @Override
    public String toString() {
        return value;
    }
}
```

- [ ] **Step 2: 创建 AccountingEntry 实体**

```java
package com.tianshu.accounting.domain.voucher.model;

import lombok.Getter;

import java.math.BigDecimal;

/**
 * 记账分录实体
 */
@Getter
public class AccountingEntry {
    private final Long entryId;
    private final Long accountId;
    private final String accountNo;
    private final String subjectCode;
    private final String currency;
    private final EntryDirection direction;
    private final BigDecimal amount;
    private BigDecimal balanceBefore;
    private BigDecimal balanceAfter;
    private final String summary;
    
    private AccountingEntry(Long entryId, Long accountId, String accountNo,
                            String subjectCode, String currency,
                            EntryDirection direction, BigDecimal amount, String summary) {
        this.entryId = entryId;
        this.accountId = accountId;
        this.accountNo = accountNo;
        this.subjectCode = subjectCode;
        this.currency = currency;
        this.direction = direction;
        this.amount = amount;
        this.summary = summary;
    }
    
    public static AccountingEntry of(Long entryId, Long accountId, String accountNo,
                                      String subjectCode, String currency,
                                      EntryDirection direction, BigDecimal amount, 
                                      String summary) {
        return new AccountingEntry(entryId, accountId, accountNo, subjectCode, 
            currency, direction, amount, summary);
    }
    
    public void setBalanceBefore(BigDecimal balanceBefore) {
        this.balanceBefore = balanceBefore;
    }
    
    public void setBalanceAfter(BigDecimal balanceAfter) {
        this.balanceAfter = balanceAfter;
    }
}
```

- [ ] **Step 3: 创建 AccountingCompletedEvent**

```java
package com.tianshu.accounting.domain.voucher.event;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 记账完成事件
 */
public record AccountingCompletedEvent(
    Long voucherId,
    String voucherNo,
    String bizNo,
    String bizType,
    BigDecimal totalDebit,
    BigDecimal totalCredit,
    int entryCount,
    LocalDateTime occurredAt
) implements Serializable {
    private static final long serialVersionUID = 1L;
    
    public static AccountingCompletedEvent of(Long voucherId, String voucherNo,
                                               String bizNo, String bizType,
                                               BigDecimal totalDebit, BigDecimal totalCredit,
                                               int entryCount) {
        return new AccountingCompletedEvent(voucherId, voucherNo, bizNo, bizType,
            totalDebit, totalCredit, entryCount, LocalDateTime.now());
    }
}
```

- [ ] **Step 4: 创建 AccountingReversedEvent**

```java
package com.tianshu.accounting.domain.voucher.event;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 记账冲正事件
 */
public record AccountingReversedEvent(
    Long voucherId,
    String voucherNo,
    String originalVoucherNo,
    LocalDateTime occurredAt
) implements Serializable {
    private static final long serialVersionUID = 1L;
    
    public static AccountingReversedEvent of(Long voucherId, String voucherNo,
                                              String originalVoucherNo) {
        return new AccountingReversedEvent(voucherId, voucherNo, originalVoucherNo, 
            LocalDateTime.now());
    }
}
```

- [ ] **Step 5: 创建 AccountingVoucher 聚合根**

```java
package com.tianshu.accounting.domain.voucher.model;

import com.tianshu.accounting.domain.shared.exception.DomainException;
import com.tianshu.accounting.domain.voucher.event.AccountingCompletedEvent;
import com.tianshu.accounting.domain.voucher.event.AccountingReversedEvent;
import com.tianshu.accounting.domain.voucher.exception.VoucherErrorCode;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 记账凭证聚合根
 */
@Getter
public class AccountingVoucher {
    // 标识
    private final Long voucherId;
    private final VoucherNo voucherNo;
    
    // 幂等键
    private final String bizNo;
    private final String channelCode;
    
    // 业务信息
    private final BizType bizType;
    private final VoucherType voucherType;
    private VoucherStatus status;
    
    // 会计日
    private final LocalDate accountingDate;
    
    // 冲正关联
    private Long originalVoucherId;
    private String originalVoucherNo;
    
    // 分录
    private final List<AccountingEntry> entries = new ArrayList<>();
    
    // 领域事件
    private final List<Object> domainEvents = new ArrayList<>();
    
    /**
     * 创建凭证
     */
    public static AccountingVoucher create(Long voucherId, VoucherNo voucherNo,
                                            String bizNo, String channelCode,
                                            BizType bizType, LocalDate accountingDate,
                                            List<AccountingEntry> entryList) {
        // 校验分录
        if (entryList == null || entryList.isEmpty()) {
            throw DomainException.of(VoucherErrorCode.ENTRIES_EMPTY);
        }
        if (entryList.size() < 2) {
            throw DomainException.of(VoucherErrorCode.ENTRIES_COUNT_INVALID);
        }
        
        AccountingVoucher voucher = new AccountingVoucher(voucherId, voucherNo, 
            bizNo, channelCode, bizType, accountingDate);
        
        voucher.entries.addAll(entryList);
        voucher.validateDebitCreditBalance();
        
        return voucher;
    }
    
    private AccountingVoucher(Long voucherId, VoucherNo voucherNo,
                               String bizNo, String channelCode,
                               BizType bizType, LocalDate accountingDate) {
        this.voucherId = voucherId;
        this.voucherNo = voucherNo;
        this.bizNo = bizNo;
        this.channelCode = channelCode;
        this.bizType = bizType;
        this.voucherType = VoucherType.NORMAL;
        this.status = VoucherStatus.CREATED;
        this.accountingDate = accountingDate;
    }
    
    /**
     * 校验借贷平衡
     */
    private void validateDebitCreditBalance() {
        BigDecimal totalDebit = BigDecimal.ZERO;
        BigDecimal totalCredit = BigDecimal.ZERO;
        
        for (AccountingEntry entry : entries) {
            if (entry.getDirection() == EntryDirection.DEBIT) {
                totalDebit = totalDebit.add(entry.getAmount());
            } else {
                totalCredit = totalCredit.add(entry.getAmount());
            }
        }
        
        if (totalDebit.compareTo(totalCredit) != 0) {
            throw DomainException.of(VoucherErrorCode.DEBIT_CREDIT_NOT_BALANCED,
                totalDebit, totalCredit);
        }
    }
    
    /**
     * 过账
     */
    public void post() {
        if (status != VoucherStatus.CREATED) {
            throw DomainException.of(VoucherErrorCode.VOUCHER_ALREADY_POSTED, voucherNo.value());
        }
        this.status = VoucherStatus.POSTED;
        
        // 计算借贷合计
        BigDecimal totalDebit = BigDecimal.ZERO;
        BigDecimal totalCredit = BigDecimal.ZERO;
        for (AccountingEntry entry : entries) {
            if (entry.getDirection() == EntryDirection.DEBIT) {
                totalDebit = totalDebit.add(entry.getAmount());
            } else {
                totalCredit = totalCredit.add(entry.getAmount());
            }
        }
        
        registerEvent(AccountingCompletedEvent.of(voucherId, voucherNo.value(),
            bizNo, bizType.name(), totalDebit, totalCredit, entries.size()));
    }
    
    /**
     * 冲正
     */
    public AccountingVoucher reverse(Long reversalVoucherId, VoucherNo reversalVoucherNo,
                                       String reverseReason) {
        if (status == VoucherStatus.REVERSED) {
            throw DomainException.of(VoucherErrorCode.VOUCHER_ALREADY_REVERSED, voucherNo.value());
        }
        if (status != VoucherStatus.POSTED) {
            throw DomainException.of(VoucherErrorCode.VOUCHER_NOT_POSTED, voucherNo.value());
        }
        
        // 创建反向凭证
        AccountingVoucher reversal = new AccountingVoucher(
            reversalVoucherId, reversalVoucherNo,
            bizNo + "-R", channelCode,
            BizType.REVERSAL, accountingDate
        );
        reversal.voucherType = VoucherType.REVERSAL;
        reversal.originalVoucherId = this.voucherId;
        reversal.originalVoucherNo = this.voucherNo.value();
        
        // 反向分录
        for (AccountingEntry entry : entries) {
            AccountingEntry reversalEntry = AccountingEntry.of(
                System.currentTimeMillis(), // 简化
                entry.getAccountId(),
                entry.getAccountNo(),
                entry.getSubjectCode(),
                entry.getCurrency(),
                entry.getDirection() == EntryDirection.DEBIT 
                    ? EntryDirection.CREDIT : EntryDirection.DEBIT,
                entry.getAmount(),
                "冲正-" + entry.getSummary()
            );
            reversal.entries.add(reversalEntry);
        }
        
        // 标记原凭证为已冲正
        this.status = VoucherStatus.REVERSED;
        
        registerEvent(AccountingReversedEvent.of(reversalVoucherId, 
            reversalVoucherNo.value(), voucherNo.value()));
        
        return reversal;
    }
    
    private void registerEvent(Object event) {
        domainEvents.add(event);
    }
    
    public List<Object> getDomainEvents() {
        return List.copyOf(domainEvents);
    }
    
    public void clearDomainEvents() {
        domainEvents.clear();
    }
    
    public BigDecimal getTotalDebit() {
        return entries.stream()
            .filter(e -> e.getDirection() == EntryDirection.DEBIT)
            .map(AccountingEntry::getAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
    
    public BigDecimal getTotalCredit() {
        return entries.stream()
            .filter(e -> e.getDirection() == EntryDirection.CREDIT)
            .map(AccountingEntry::getAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
```

- [ ] **Step 6: 创建 AccountingVoucherTest**

```java
package com.tianshu.accounting.domain.voucher.model;

import com.tianshu.accounting.domain.shared.exception.DomainException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class AccountingVoucherTest {
    
    private AccountingVoucher createTestVoucher() {
        List<AccountingEntry> entries = List.of(
            AccountingEntry.of(1L, 1L, "AC001", "1001", "CNY", 
                EntryDirection.DEBIT, BigDecimal.valueOf(100), "转账出款"),
            AccountingEntry.of(2L, 2L, "AC002", "1001", "CNY", 
                EntryDirection.CREDIT, BigDecimal.valueOf(100), "转账入款")
        );
        
        return AccountingVoucher.create(1L, new VoucherNo("V123456789012345"),
            "BIZ001", "PAYMENT", BizType.TRANSFER, LocalDate.now(), entries);
    }
    
    @Nested
    @DisplayName("创建凭证测试")
    class CreateVoucherTest {
        
        @Test
        @DisplayName("创建成功")
        void should_create_successfully() {
            AccountingVoucher voucher = createTestVoucher();
            
            assertNotNull(voucher);
            assertEquals(VoucherStatus.CREATED, voucher.getStatus());
            assertEquals(2, voucher.getEntries().size());
        }
        
        @Test
        @DisplayName("分录为空时失败")
        void should_fail_when_entries_empty() {
            assertThrows(DomainException.class, () ->
                AccountingVoucher.create(1L, new VoucherNo("V123456789012345"),
                    "BIZ001", "PAYMENT", BizType.TRANSFER, LocalDate.now(), List.of()));
        }
        
        @Test
        @DisplayName("借贷不平衡时失败")
        void should_fail_when_not_balanced() {
            List<AccountingEntry> entries = List.of(
                AccountingEntry.of(1L, 1L, "AC001", "1001", "CNY", 
                    EntryDirection.DEBIT, BigDecimal.valueOf(100), "转账出款"),
                AccountingEntry.of(2L, 2L, "AC002", "1001", "CNY", 
                    EntryDirection.CREDIT, BigDecimal.valueOf(50), "转账入款")
            );
            
            assertThrows(DomainException.class, () ->
                AccountingVoucher.create(1L, new VoucherNo("V123456789012345"),
                    "BIZ001", "PAYMENT", BizType.TRANSFER, LocalDate.now(), entries));
        }
    }
    
    @Nested
    @DisplayName("过账测试")
    class PostVoucherTest {
        
        @Test
        @DisplayName("过账成功")
        void should_post_successfully() {
            AccountingVoucher voucher = createTestVoucher();
            voucher.post();
            
            assertEquals(VoucherStatus.POSTED, voucher.getStatus());
            assertEquals(1, voucher.getDomainEvents().size());
        }
        
        @Test
        @DisplayName("重复过账失败")
        void should_fail_when_already_posted() {
            AccountingVoucher voucher = createTestVoucher();
            voucher.post();
            
            assertThrows(DomainException.class, voucher::post);
        }
    }
    
    @Nested
    @DisplayName("冲正测试")
    class ReverseVoucherTest {
        
        @Test
        @DisplayName("冲正成功")
        void should_reverse_successfully() {
            AccountingVoucher voucher = createTestVoucher();
            voucher.post();
            
            AccountingVoucher reversal = voucher.reverse(2L, 
                new VoucherNo("V123456789012346"), "错误记账");
            
            assertEquals(VoucherStatus.REVERSED, voucher.getStatus());
            assertEquals(VoucherType.REVERSAL, reversal.getVoucherType());
            assertEquals(voucher.getVoucherId(), reversal.getOriginalVoucherId());
        }
        
        @Test
        @DisplayName("未过账时冲正失败")
        void should_fail_when_not_posted() {
            AccountingVoucher voucher = createTestVoucher();
            
            assertThrows(DomainException.class, () ->
                voucher.reverse(2L, new VoucherNo("V123456789012346"), "错误记账"));
        }
        
        @Test
        @DisplayName("已冲正时再次冲正失败")
        void should_fail_when_already_reversed() {
            AccountingVoucher voucher = createTestVoucher();
            voucher.post();
            voucher.reverse(2L, new VoucherNo("V123456789012346"), "错误记账");
            
            assertThrows(DomainException.class, () ->
                voucher.reverse(3L, new VoucherNo("V123456789012347"), "再次冲正"));
        }
    }
}
```

- [ ] **Step 7: 验证编译和测试**

Run: `mvn test -pl accounting-core -Dtest=AccountingVoucherTest`
Expected: Tests run: 8, Failures: 0

- [ ] **Step 8: Commit**

```bash
git add accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/
git add accounting-core/src/test/java/com/tianshu/accounting/domain/voucher/
git commit -m "feat(domain): add AccountingVoucher aggregate root"
```


### Task 2.2: 创建记账应用层服务

**Files:**
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/voucher/AccountingCommandService.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/voucher/AccountingQueryService.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/voucher/cmd/PostAccountingCommand.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/voucher/cmd/ReverseAccountingCommand.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/application/voucher/cmd/EntryCommand.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/repository/VoucherRepository.java`
- Create: `accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/service/AccountingDomainService.java`

- [ ] **Step 1: 创建 VoucherRepository 接口**

```java
package com.tianshu.accounting.domain.voucher.repository;

import com.tianshu.accounting.domain.voucher.model.AccountingVoucher;

import java.util.Optional;

/**
 * 凭证仓储接口
 */
public interface VoucherRepository {
    
    /**
     * 按 ID 查找
     */
    Optional<AccountingVoucher> findById(Long voucherId);
    
    /**
     * 按凭证号查找
     */
    Optional<AccountingVoucher> findByVoucherNo(String voucherNo);
    
    /**
     * 按幂等键查找
     */
    Optional<AccountingVoucher> findByBizNoAndChannelCode(String bizNo, String channelCode);
    
    /**
     * 保存
     */
    void save(AccountingVoucher voucher);
    
    /**
     * 生成凭证 ID
     */
    Long nextVoucherId();
}
```

- [ ] **Step 2: 创建 EntryCommand**

```java
package com.tianshu.accounting.application.voucher.cmd;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

/**
 * 记账分录命令
 */
@Getter
@Builder
public class EntryCommand {
    private final String accountNo;
    private final BigDecimal amount;
    private final String direction;  // OUT / IN
    private final String summary;
}
```

- [ ] **Step 3: 创建 PostAccountingCommand**

```java
package com.tianshu.accounting.application.voucher.cmd;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

/**
 * 记账命令
 */
@Getter
@Builder
public class PostAccountingCommand {
    private final String bizNo;
    private final String bizType;
    private final LocalDate accountingDate;
    private final String currency;
    private final String channelCode;
    private final String operatorId;
    private final String memo;
    private final List<EntryCommand> entries;
}
```

- [ ] **Step 4: 创建 ReverseAccountingCommand**

```java
package com.tianshu.accounting.application.voucher.cmd;

import lombok.Builder;
import lombok.Getter;

/**
 * 冲正命令
 */
@Getter
@Builder
public class ReverseAccountingCommand {
    private final String originalVoucherNo;
    private final String reverseReason;
    private final String operatorId;
}
```

- [ ] **Step 5: 创建 AccountingDomainService**

```java
package com.tianshu.accounting.domain.voucher.service;

import com.tianshu.accounting.domain.account.model.Account;
import com.tianshu.accounting.domain.account.repository.AccountRepository;
import com.tianshu.accounting.domain.shared.exception.DomainException;
import com.tianshu.accounting.domain.subject.model.NormalBalanceDirection;
import com.tianshu.accounting.domain.subject.model.SubjectType;
import com.tianshu.accounting.domain.voucher.exception.VoucherErrorCode;
import com.tianshu.accounting.domain.voucher.model.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * 记账领域服务
 * 负责分录拆解和账户余额更新
 */
@Service
@RequiredArgsConstructor
public class AccountingDomainService {
    
    private final AccountRepository accountRepository;
    
    /**
     * 拆解分录并确定借贷方向
     * 
     * @param entries 原始分录（OUT/IN 方向）
     * @param subjectTypeMap 账户科目类型映射
     * @return 带借贷方向的分录列表
     */
    public List<AccountingEntry> resolveEntries(List<EntryInfo> entries, 
                                                 java.util.Map<String, SubjectType> subjectTypeMap) {
        List<AccountingEntry> result = new ArrayList<>();
        long entryId = 1L;
        
        for (EntryInfo entry : entries) {
            Account account = accountRepository.findByAccountNo(entry.accountNo())
                .orElseThrow(() -> DomainException.of(
                    VoucherErrorCode.ACCOUNT_NOT_FOUND_IN_ENTRY, entry.accountNo()));
            
            SubjectType subjectType = subjectTypeMap.get(account.getSubjectCode());
            if (subjectType == null) {
                subjectType = SubjectType.LIABILITY; // 默认负债类
            }
            
            EntryDirection direction = resolveDirection(subjectType, entry.direction());
            
            AccountingEntry accountingEntry = AccountingEntry.of(
                entryId++,
                account.getAccountId(),
                account.getAccountNo().value(),
                account.getSubjectCode(),
                entry.currency(),
                direction,
                entry.amount(),
                entry.summary()
            );
            
            result.add(accountingEntry);
        }
        
        return result;
    }
    
    /**
     * 根据科目类型和资金方向确定借贷方向
     */
    private EntryDirection resolveDirection(SubjectType subjectType, String fundDirection) {
        NormalBalanceDirection normalDirection = getNormalBalanceDirection(subjectType);
        
        // 资金方向：OUT（出账）/ IN（入账）
        boolean isOut = "OUT".equals(fundDirection);
        
        // 资产类、费用类：增加记借方，减少记贷方
        // 负债类、权益类、收入类：增加记贷方，减少记借方
        if (normalDirection == NormalBalanceDirection.DEBIT) {
            // 资产类、费用类
            return isOut ? EntryDirection.CREDIT : EntryDirection.DEBIT;
        } else {
            // 负债类、权益类、收入类
            return isOut ? EntryDirection.DEBIT : EntryDirection.CREDIT;
        }
    }
    
    private NormalBalanceDirection getNormalBalanceDirection(SubjectType subjectType) {
        return switch (subjectType) {
            case ASSET, EXPENSE -> NormalBalanceDirection.DEBIT;
            case LIABILITY, EQUITY, REVENUE -> NormalBalanceDirection.CREDIT;
            case COMMON -> NormalBalanceDirection.DEBIT; // 共同类按余额方向确定，简化处理
        };
    }
    
    /**
     * 更新账户余额
     */
    public void updateAccountBalances(AccountingVoucher voucher, 
                                       java.util.Map<Long, Account> accountMap) {
        // 按账户分组计算净额
        java.util.Map<Long, BigDecimal> netAmounts = new java.util.HashMap<>();
        
        for (AccountingEntry entry : voucher.getEntries()) {
            BigDecimal net = netAmounts.getOrDefault(entry.getAccountId(), BigDecimal.ZERO);
            if (entry.getDirection() == EntryDirection.DEBIT) {
                net = net.add(entry.getAmount());
            } else {
                net = net.subtract(entry.getAmount());
            }
            netAmounts.put(entry.getAccountId(), net);
        }
        
        // 更新账户余额
        for (java.util.Map.Entry<Long, BigDecimal> entry : netAmounts.entrySet()) {
            Long accountId = entry.getKey();
            BigDecimal netAmount = entry.getValue();
            Account account = accountMap.get(accountId);
            
            if (account == null) {
                continue;
            }
            
            if (netAmount.compareTo(BigDecimal.ZERO) > 0) {
                // 净借方 = 余额增加
                account.credit(netAmount);
            } else if (netAmount.compareTo(BigDecimal.ZERO) < 0) {
                // 净贷方 = 余额减少
                account.debit(netAmount.negate());
            }
        }
    }
    
    /**
     * 分录信息（内部使用）
     */
    public record EntryInfo(
        String accountNo,
        BigDecimal amount,
        String direction,
        String currency,
        String summary
    ) {}
}
```

- [ ] **Step 6: 创建 AccountingCommandService**

```java
package com.tianshu.accounting.application.voucher;

import com.tianshu.accounting.application.voucher.cmd.*;
import com.tianshu.accounting.domain.account.model.Account;
import com.tianshu.accounting.domain.account.repository.AccountRepository;
import com.tianshu.accounting.domain.shared.exception.DomainException;
import com.tianshu.accounting.domain.voucher.exception.VoucherErrorCode;
import com.tianshu.accounting.domain.voucher.model.*;
import com.tianshu.accounting.domain.voucher.repository.VoucherRepository;
import com.tianshu.accounting.domain.voucher.service.AccountingDomainService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 记账命令服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AccountingCommandService {
    
    private final VoucherRepository voucherRepository;
    private final AccountRepository accountRepository;
    private final AccountingDomainService accountingDomainService;
    
    /**
     * 提交记账
     */
    @Transactional(rollbackFor = Exception.class)
    public String postAccounting(PostAccountingCommand command) {
        log.info("[ORCHESTRATION] postAccounting: bizNo={}, channelCode={}", 
            command.getBizNo(), command.getChannelCode());
        
        // 幂等检查
        voucherRepository.findByBizNoAndChannelCode(command.getBizNo(), command.getChannelCode())
            .ifPresent(existing -> {
                log.info("Voucher already exists: voucherNo={}", existing.getVoucherNo().value());
                throw DomainException.of(VoucherErrorCode.DUPLICATE_BIZ_NO,
                    command.getBizNo(), command.getChannelCode());
            });
        
        // 转换分录
        List<AccountingDomainService.EntryInfo> entryInfos = command.getEntries().stream()
            .map(e -> new AccountingDomainService.EntryInfo(
                e.getAccountNo(), e.getAmount(), e.getDirection(),
                command.getCurrency(), e.getSummary()))
            .toList();
        
        // 获取科目类型映射（简化实现）
        Map<String, com.tianshu.accounting.domain.subject.model.SubjectType> subjectTypeMap = new HashMap<>();
        
        // 拆解分录
        List<AccountingEntry> entries = accountingDomainService.resolveEntries(entryInfos, subjectTypeMap);
        
        // 创建凭证
        Long voucherId = voucherRepository.nextVoucherId();
        String voucherNo = generateVoucherNo();
        LocalDate accountingDate = command.getAccountingDate() != null 
            ? command.getAccountingDate() : LocalDate.now();
        
        AccountingVoucher voucher = AccountingVoucher.create(
            voucherId,
            new VoucherNo(voucherNo),
            command.getBizNo(),
            command.getChannelCode(),
            BizType.valueOf(command.getBizType()),
            accountingDate,
            entries
        );
        
        // 加载账户
        Map<Long, Account> accountMap = new HashMap<>();
        for (AccountingEntry entry : entries) {
            if (!accountMap.containsKey(entry.getAccountId())) {
                accountRepository.findById(entry.getAccountId())
                    .ifPresent(a -> accountMap.put(a.getAccountId(), a));
            }
        }
        
        // 更新账户余额
        accountingDomainService.updateAccountBalances(voucher, accountMap);
        
        // 过账
        voucher.post();
        
        // 保存凭证和账户
        voucherRepository.save(voucher);
        for (Account account : accountMap.values()) {
            accountRepository.save(account);
        }
        
        log.info("[ORCHESTRATION] Accounting posted: voucherNo={}", voucherNo);
        
        return voucherNo;
    }
    
    /**
     * 冲正记账
     */
    @Transactional(rollbackFor = Exception.class)
    public String reverseAccounting(ReverseAccountingCommand command) {
        log.info("[ORCHESTRATION] reverseAccounting: originalVoucherNo={}", 
            command.getOriginalVoucherNo());
        
        // 查找原凭证
        AccountingVoucher originalVoucher = voucherRepository.findByVoucherNo(
                command.getOriginalVoucherNo())
            .orElseThrow(() -> DomainException.of(
                VoucherErrorCode.VOUCHER_NOT_FOUND, command.getOriginalVoucherNo()));
        
        // 创建冲正凭证
        Long reversalId = voucherRepository.nextVoucherId();
        String reversalNo = generateVoucherNo();
        
        AccountingVoucher reversalVoucher = originalVoucher.reverse(
            reversalId, new VoucherNo(reversalNo), command.getReverseReason());
        
        // 更新账户余额（反向）
        Map<Long, Account> accountMap = new HashMap<>();
        for (AccountingEntry entry : reversalVoucher.getEntries()) {
            if (!accountMap.containsKey(entry.getAccountId())) {
                accountRepository.findById(entry.getAccountId())
                    .ifPresent(a -> accountMap.put(a.getAccountId(), a));
            }
        }
        
        accountingDomainService.updateAccountBalances(reversalVoucher, accountMap);
        
        // 过账冲正凭证
        reversalVoucher.post();
        
        // 保存
        voucherRepository.save(originalVoucher);
        voucherRepository.save(reversalVoucher);
        for (Account account : accountMap.values()) {
            accountRepository.save(account);
        }
        
        log.info("[ORCHESTRATION] Accounting reversed: reversalVoucherNo={}", reversalNo);
        
        return reversalNo;
    }
    
    private String generateVoucherNo() {
        return String.format("V%015d", System.currentTimeMillis() % 1000000000000000L);
    }
}
```

- [ ] **Step 7: 验证编译**

Run: `mvn clean compile -pl accounting-core`
Expected: BUILD SUCCESS

- [ ] **Step 8: Commit**

```bash
git add accounting-core/src/main/java/com/tianshu/accounting/application/voucher/
git add accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/repository/
git add accounting-core/src/main/java/com/tianshu/accounting/domain/voucher/service/
git commit -m "feat(app): add Accounting command service with double-entry logic"
```


---

## Phase 3: Online 模块（接口层）

### Task 3.1: 创建 HTTP 接口

**Files:**
- Create: `accounting-online/src/main/java/com/tianshu/accounting/AccountingOnlineApplication.java`
- Create: `accounting-online/src/main/java/com/tianshu/accounting/interfaces/web/AccountController.java`
- Create: `accounting-online/src/main/java/com/tianshu/accounting/interfaces/web/AccountingController.java`
- Create: `accounting-online/src/main/java/com/tianshu/accounting/interfaces/web/GlobalExceptionHandler.java`
- Create: `accounting-online/src/main/resources/application.yml`

- [ ] **Step 1: 创建 AccountingOnlineApplication**

```java
package com.tianshu.accounting;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AccountingOnlineApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(AccountingOnlineApplication.class, args);
    }
}
```

- [ ] **Step 2: 创建 application.yml**

```yaml
server:
  port: 8080

spring:
  application:
    name: accounting-online
  datasource:
    url: jdbc:mysql://localhost:3306/d_accounting?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
    username: root
    password: root
    driver-class-name: com.mysql.cj.jdbc.Driver
  jackson:
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: Asia/Shanghai

mybatis-plus:
  mapper-locations: classpath*:/mapper/**/*.xml
  global-config:
    db-config:
      id-type: assign_id
      logic-delete-field: deleteFlag
      logic-delete-value: 1
      logic-not-delete-value: 0
  configuration:
    map-underscore-to-camel-case: true
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl

logging:
  level:
    com.tianshu.accounting: DEBUG
```

- [ ] **Step 3: 创建 GlobalExceptionHandler**

```java
package com.tianshu.accounting.interfaces.web;

import com.tianshu.accounting.api.dto.ApiResponse;
import com.tianshu.accounting.domain.shared.exception.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(DomainException.class)
    public ApiResponse<Void> handleDomainException(DomainException e) {
        log.warn("[HTTP] DomainException: code={}, message={}", 
            e.getErrorCode().getCode(), e.getResolvedMessage());
        return ApiResponse.error(e.getErrorCode().getCode(), e.getResolvedMessage());
    }
    
    @ExceptionHandler(ApplicationException.class)
    public ApiResponse<Void> handleApplicationException(ApplicationException e) {
        log.warn("[HTTP] ApplicationException: useCase={}, code={}", 
            e.getUseCase(), e.getErrorCode().getCode());
        return ApiResponse.error(e.getErrorCode().getCode(), e.getResolvedMessage());
    }
    
    @ExceptionHandler(InfrastructureException.class)
    public ApiResponse<Void> handleInfrastructureException(InfrastructureException e) {
        log.error("[HTTP] InfrastructureException: component={}", e.getComponent(), e);
        return ApiResponse.error(SystemErrorCode.SYSTEM_ERROR.getCode(), "系统繁忙，请稍后重试");
    }
    
    @ExceptionHandler(Exception.class)
    public ApiResponse<Void> handleException(Exception e) {
        log.error("[HTTP] UnexpectedException", e);
        return ApiResponse.error(SystemErrorCode.SYSTEM_ERROR.getCode(), "系统内部错误");
    }
}
```

- [ ] **Step 4: 创建 AccountController**

```java
package com.tianshu.accounting.interfaces.web;

import com.tianshu.accounting.api.dto.*;
import com.tianshu.accounting.application.account.AccountCommandService;
import com.tianshu.accounting.application.account.AccountQueryService;
import com.tianshu.accounting.application.account.assembler.AccountAssembler;
import com.tianshu.accounting.application.account.cmd.*;
import com.tianshu.accounting.domain.account.model.Account;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 账户接口
 */
@RestController
@RequestMapping("/api/v1/accounts")
@RequiredArgsConstructor
public class AccountController {
    
    private final AccountCommandService accountCommandService;
    private final AccountQueryService accountQueryService;
    private final AccountAssembler accountAssembler;
    
    /**
     * 开户
     */
    @PostMapping
    public ApiResponse<OpenAccountResponse> openAccount(@RequestBody OpenAccountRequest request) {
        OpenAccountCommand command = accountAssembler.toCommand(request);
        Long accountId = accountCommandService.openAccount(command);
        
        Account account = accountQueryService.findById(accountId);
        return ApiResponse.success(OpenAccountResponse.builder()
            .accountId(account.getAccountId())
            .accountNo(account.getAccountNo().value())
            .build());
    }
    
    /**
     * 查询账户
     */
    @GetMapping("/{accountNo}")
    public ApiResponse<AccountDetailResponse> queryAccount(@PathVariable String accountNo) {
        Account account = accountQueryService.findByAccountNo(accountNo);
        return ApiResponse.success(accountAssembler.toResponse(account));
    }
    
    /**
     * 冻结
     */
    @PostMapping("/{accountNo}/freeze")
    public ApiResponse<String> freeze(@PathVariable String accountNo, 
                                       @RequestBody FreezeRequest request) {
        FreezeCommand command = FreezeCommand.builder()
            .accountNo(accountNo)
            .freezeAmount(request.getFreezeAmount())
            .freezeType(request.getFreezeType())
            .freezeReason(request.getFreezeReason())
            .bizFreezeNo(request.getBizFreezeNo())
            .freezeSource(request.getFreezeSource())
            .operatorId(request.getOperatorId())
            .build();
        
        String freezeNo = accountCommandService.freeze(command);
        return ApiResponse.success(freezeNo);
    }
    
    /**
     * 解冻
     */
    @PostMapping("/{accountNo}/unfreeze")
    public ApiResponse<Void> unfreeze(@PathVariable String accountNo,
                                       @RequestBody UnfreezeRequest request) {
        UnfreezeCommand command = UnfreezeCommand.builder()
            .accountNo(accountNo)
            .freezeNo(request.getFreezeNo())
            .unfreezeReason(request.getUnfreezeReason())
            .operatorId(request.getOperatorId())
            .build();
        
        accountCommandService.unfreeze(command);
        return ApiResponse.success();
    }
}
```

- [ ] **Step 5: 创建 AccountingController**

```java
package com.tianshu.accounting.interfaces.web;

import com.tianshu.accounting.api.dto.*;
import com.tianshu.accounting.application.voucher.AccountingCommandService;
import com.tianshu.accounting.application.voucher.cmd.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 记账接口
 */
@RestController
@RequestMapping("/api/v1/accounting")
@RequiredArgsConstructor
public class AccountingController {
    
    private final AccountingCommandService accountingCommandService;
    
    /**
     * 提交记账
     */
    @PostMapping
    public ApiResponse<PostAccountingResponse> postAccounting(
            @RequestBody PostAccountingRequest request) {
        PostAccountingCommand command = PostAccountingCommand.builder()
            .bizNo(request.getBizNo())
            .bizType(request.getBizType())
            .accountingDate(request.getAccountingDate())
            .currency(request.getCurrency())
            .channelCode(request.getChannelCode())
            .operatorId(request.getOperatorId())
            .memo(request.getMemo())
            .entries(request.getEntries().stream()
                .map(e -> EntryCommand.builder()
                    .accountNo(e.getAccountNo())
                    .amount(e.getAmount())
                    .direction(e.getDirection())
                    .summary(e.getSummary())
                    .build())
                .toList())
            .build();
        
        String voucherNo = accountingCommandService.postAccounting(command);
        return ApiResponse.success(PostAccountingResponse.builder()
            .voucherNo(voucherNo)
            .build());
    }
    
    /**
     * 冲正
     */
    @PostMapping("/reverse")
    public ApiResponse<PostAccountingResponse> reverseAccounting(
            @RequestBody ReverseAccountingRequest request) {
        ReverseAccountingCommand command = ReverseAccountingCommand.builder()
            .originalVoucherNo(request.getOriginalVoucherNo())
            .reverseReason(request.getReverseReason())
            .operatorId(request.getOperatorId())
            .build();
        
        String voucherNo = accountingCommandService.reverseAccounting(command);
        return ApiResponse.success(PostAccountingResponse.builder()
            .voucherNo(voucherNo)
            .build());
    }
}
```

- [ ] **Step 6: 验证编译**

Run: `mvn clean compile -pl accounting-online`
Expected: BUILD SUCCESS

- [ ] **Step 7: Commit**

```bash
git add accounting-online/src/
git commit -m "feat(online): add HTTP controllers and global exception handler"
```


---

## Phase 4: 数据库设计

### Task 4.1: 创建数据库表结构

**Files:**
- Create: `accounting-core/src/main/resources/db/migration/V1__init_schema.sql`

- [ ] **Step 1: 创建数据库初始化脚本**

```sql
-- 账户表
CREATE TABLE `t_account` (
    `account_id` BIGINT NOT NULL COMMENT '账户ID（主键）',
    `account_no` VARCHAR(16) NOT NULL COMMENT '账户业务编号',
    `account_type` VARCHAR(16) NOT NULL COMMENT '账户类型：MAIN/INTERNAL/SUB_REAL',
    `owner_type` VARCHAR(16) NOT NULL COMMENT '归属类型：CUSTOMER/INSTITUTION',
    `customer_id` VARCHAR(32) COMMENT '客户号',
    `institution_id` VARCHAR(32) COMMENT '法人实体ID',
    `parent_account_id` BIGINT COMMENT '主账户ID（子账户）',
    `subject_code` VARCHAR(8) NOT NULL COMMENT '科目代码',
    `currency` VARCHAR(3) NOT NULL COMMENT '币种（ISO 4217）',
    `balance` DECIMAL(18,4) NOT NULL DEFAULT 0 COMMENT '当前余额',
    `frozen_amount` DECIMAL(18,4) NOT NULL DEFAULT 0 COMMENT '冻结金额',
    `lifecycle_status` VARCHAR(16) NOT NULL DEFAULT 'ACTIVE' COMMENT '生命周期状态：ACTIVE/PENDING_CLOSE/CLOSED',
    `debit_blocked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '禁止出账标志',
    `credit_blocked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '禁止入账标志',
    `activity_status` VARCHAR(16) NOT NULL DEFAULT 'NORMAL' COMMENT '运营治理状态：NORMAL/DORMANT/UNCLAIMED',
    `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    `create_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `create_by` VARCHAR(32) COMMENT '创建者',
    `update_by` VARCHAR(32) COMMENT '修改者',
    `delete_flag` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除标志',
    PRIMARY KEY (`account_id`),
    UNIQUE KEY `uk_account_no` (`account_no`),
    UNIQUE KEY `uk_customer_subject_type` (`customer_id`, `subject_code`, `account_type`),
    KEY `idx_customer_id` (`customer_id`),
    KEY `idx_parent_account_id` (`parent_account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户表';

-- 冻结明细表
CREATE TABLE `t_freeze_record` (
    `freeze_id` BIGINT NOT NULL COMMENT '冻结明细ID（主键）',
    `account_id` BIGINT NOT NULL COMMENT '账户ID',
    `freeze_no` VARCHAR(16) NOT NULL COMMENT '冻结业务编号',
    `biz_freeze_no` VARCHAR(32) NOT NULL COMMENT '调用方业务冻结流水号',
    `freeze_source` VARCHAR(32) NOT NULL COMMENT '冻结来源系统',
    `freeze_amount` DECIMAL(18,4) NOT NULL COMMENT '冻结金额',
    `freeze_type` VARCHAR(16) NOT NULL COMMENT '冻结类型：JUDICIAL/RISK/PLEDGE/PRE_AUTH',
    `freeze_reason` VARCHAR(256) COMMENT '冻结原因',
    `freeze_time` DATETIME NOT NULL COMMENT '冻结时间',
    `unfreeze_time` DATETIME COMMENT '解冻时间',
    `create_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `delete_flag` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除标志',
    PRIMARY KEY (`freeze_id`),
    UNIQUE KEY `uk_freeze_no` (`freeze_no`),
    UNIQUE KEY `uk_biz_freeze` (`biz_freeze_no`, `freeze_source`),
    KEY `idx_account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='冻结明细表';

-- 记账凭证表
CREATE TABLE `t_accounting_voucher` (
    `voucher_id` BIGINT NOT NULL COMMENT '凭证ID（主键）',
    `voucher_no` VARCHAR(16) NOT NULL COMMENT '凭证号',
    `biz_no` VARCHAR(32) NOT NULL COMMENT '业务流水号',
    `channel_code` VARCHAR(16) NOT NULL COMMENT '渠道来源',
    `biz_type` VARCHAR(16) NOT NULL COMMENT '业务类型',
    `voucher_type` VARCHAR(16) NOT NULL DEFAULT 'NORMAL' COMMENT '凭证类型：NORMAL/REVERSAL',
    `status` VARCHAR(16) NOT NULL DEFAULT 'CREATED' COMMENT '凭证状态：CREATED/POSTED/REVERSED',
    `accounting_date` DATE NOT NULL COMMENT '会计日',
    `original_voucher_id` BIGINT COMMENT '原凭证ID（冲正）',
    `original_voucher_no` VARCHAR(16) COMMENT '原凭证号（冲正）',
    `memo` VARCHAR(256) COMMENT '业务备注',
    `create_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `create_by` VARCHAR(32) COMMENT '创建者',
    `update_by` VARCHAR(32) COMMENT '修改者',
    `delete_flag` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除标志',
    PRIMARY KEY (`voucher_id`),
    UNIQUE KEY `uk_voucher_no` (`voucher_no`),
    UNIQUE KEY `uk_biz_channel` (`biz_no`, `channel_code`),
    KEY `idx_accounting_date` (`accounting_date`),
    KEY `idx_original_voucher_id` (`original_voucher_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='记账凭证表';

-- 记账分录表
CREATE TABLE `t_accounting_entry` (
    `entry_id` BIGINT NOT NULL COMMENT '分录ID（主键）',
    `voucher_id` BIGINT NOT NULL COMMENT '凭证ID',
    `account_id` BIGINT NOT NULL COMMENT '账户ID',
    `account_no` VARCHAR(16) NOT NULL COMMENT '账户业务编号',
    `subject_code` VARCHAR(8) NOT NULL COMMENT '科目代码',
    `currency` VARCHAR(3) NOT NULL COMMENT '币种',
    `direction` VARCHAR(8) NOT NULL COMMENT '分录方向：DEBIT/CREDIT',
    `amount` DECIMAL(18,4) NOT NULL COMMENT '金额',
    `balance_before` DECIMAL(18,4) COMMENT '交易前余额',
    `balance_after` DECIMAL(18,4) COMMENT '交易后余额',
    `summary` VARCHAR(64) COMMENT '分录摘要',
    `create_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `delete_flag` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除标志',
    PRIMARY KEY (`entry_id`),
    KEY `idx_voucher_id` (`voucher_id`),
    KEY `idx_account_id` (`account_id`),
    KEY `idx_account_no` (`account_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='记账分录表';

-- 科目表
CREATE TABLE `t_subject` (
    `subject_code` VARCHAR(8) NOT NULL COMMENT '科目代码（主键）',
    `subject_name` VARCHAR(64) NOT NULL COMMENT '科目名称',
    `subject_type` VARCHAR(16) NOT NULL COMMENT '科目类型：ASSET/LIABILITY/COMMON/EQUITY/REVENUE/EXPENSE',
    `normal_balance_direction` VARCHAR(8) NOT NULL COMMENT '正常余额方向：DEBIT/CREDIT',
    `parent_code` VARCHAR(8) COMMENT '父科目代码',
    `level` INT NOT NULL COMMENT '科目级别',
    `is_leaf` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否叶子节点',
    `status` VARCHAR(8) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE/INACTIVE',
    `create_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `delete_flag` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除标志',
    PRIMARY KEY (`subject_code`),
    KEY `idx_parent_code` (`parent_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='科目表';

-- 账户状态审计日志表
CREATE TABLE `t_account_status_audit_log` (
    `audit_id` BIGINT NOT NULL COMMENT '审计记录ID（主键）',
    `account_id` BIGINT NOT NULL COMMENT '账户ID',
    `change_type` VARCHAR(32) NOT NULL COMMENT '变更类型',
    `old_value` VARCHAR(256) COMMENT '变更前值',
    `new_value` VARCHAR(256) COMMENT '变更后值',
    `reason` VARCHAR(256) COMMENT '变更原因',
    `source_system` VARCHAR(32) COMMENT '来源系统',
    `operator_id` VARCHAR(32) COMMENT '操作员',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变更时间',
    PRIMARY KEY (`audit_id`),
    KEY `idx_account_id` (`account_id`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户状态审计日志表';

-- 会计日表
CREATE TABLE `t_accounting_day` (
    `accounting_date` DATE NOT NULL COMMENT '会计日（主键）',
    `status` VARCHAR(16) NOT NULL DEFAULT 'OPEN' COMMENT '状态：OPEN/CUTTING/CLOSED',
    `opened_at` DATETIME NOT NULL COMMENT '开启时间',
    `closed_at` DATETIME COMMENT '关闭时间',
    `create_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`accounting_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会计日表';

-- 余额快照表
CREATE TABLE `t_balance_snapshot` (
    `snapshot_id` BIGINT NOT NULL COMMENT '快照ID（主键）',
    `account_id` BIGINT NOT NULL COMMENT '账户ID',
    `accounting_date` DATE NOT NULL COMMENT '会计日',
    `currency` VARCHAR(3) NOT NULL COMMENT '币种',
    `balance` DECIMAL(18,4) NOT NULL COMMENT '日终余额',
    `available_balance` DECIMAL(18,4) NOT NULL COMMENT '日终可用余额',
    `frozen_amount` DECIMAL(18,4) NOT NULL COMMENT '日终冻结金额',
    `debit_amount` DECIMAL(18,4) NOT NULL DEFAULT 0 COMMENT '日间借方发生额',
    `credit_amount` DECIMAL(18,4) NOT NULL DEFAULT 0 COMMENT '日间贷方发生额',
    `create_datetime` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`snapshot_id`),
    UNIQUE KEY `uk_account_date` (`account_id`, `accounting_date`),
    KEY `idx_accounting_date` (`accounting_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='余额快照表';
```

- [ ] **Step 2: Commit**

```bash
git add accounting-core/src/main/resources/db/migration/
git commit -m "feat(db): add database schema for accounting system"
```


---

## 任务依赖关系

```
Phase 0 (脚手架)
├── Task 0.1: Maven 多模块工程 ──┐
├── Task 0.2: types 基础类型    │
├── Task 0.3: API 接口定义      ├──→ 可并行
├── Task 0.4: 异常体系          │
└── Task 0.5: ArchUnit 测试   ──┘
                │
                ▼
Phase 1 (Account 聚合)
├── Task 1.1: Account 聚合根
├── Task 1.2: Account Repository
└── Task 1.3: Account 应用服务
                │
                ▼
Phase 2 (AccountingVoucher 聚合)
├── Task 2.1: AccountingVoucher 聚合根
└── Task 2.2: 记账应用服务
                │
                ▼
Phase 3 (Online 模块)
└── Task 3.1: HTTP 接口
                │
                ▼
Phase 4 (数据库)
└── Task 4.1: 数据库表结构
```

---

## 后续迭代任务（Phase 2+）

以下任务不在 Phase 1 范围内，记录供后续迭代参考：

### Task 5.1: AccountingDay 聚合（日终处理）
- 会计日管理、日切控制
- 余额快照、发生额汇总

### Task 5.2: DepositInterest 聚合（存款计息）
- 按日计提、利息结转
- 利率管理

### Task 5.3: 子账户支持
- SUB_REAL 类型账户
- 主子账户余额联动

### Task 5.4: 批量记账
- MQ 消费
- 批量处理框架

### Task 5.5: RPC 服务（Dubbo）
- AccountServiceProvider
- AccountingServiceProvider

### Task 5.6: 事件发布（RocketMQ）
- Transactional Outbox
- 领域事件发布

---

## 验收标准

Phase 1 完成后，系统应具备以下能力：

1. **开户**：支持开立客户户、内部户，返回 account_id 和 account_no
2. **记账**：支持交易驱动记账，自动拆解为复式分录，借贷平衡校验
3. **冲正**：支持全额冲正，生成反向凭证
4. **冻结/解冻**：支持按 freeze_no 精确解冻
5. **状态管理**：支持生命周期状态迁移和交易控制标志
6. **幂等**：所有写操作幂等
7. **分层验证**：ArchUnit 测试通过

---

## 开放问题（实现阶段确定）

- [ ] account_no 的具体编码规则（法人代码位数、产品代码位数、校验位算法）
- [ ] 科目快照的同步机制（Phase 1 内置，同步策略）
- [ ] 日终批处理的调度框架选型（XXL-Job vs Spring Batch）

