# 工作流路由图

> 不知道该用哪个工作流？从这里开始。

## 快速路由

```
你现在要做什么？
│
├─ 💡 "我有一个新想法/新需求"
│   └─→ brainstorming（需求分析与设计）
│       产出: specs/NNN-xxx/spec.md
│       下一步: writing-plans
│
├─ 📋 "我有 spec，要写实现计划"
│   └─→ writing-plans（编写实现计划）
│       产出: specs/NNN-xxx/plan.md
│       下一步: 选择执行方式 ↓
│       ├─ subagent-driven-development（推荐，同会话，子代理逐任务执行+双重审查）
│       └─ executing-plans（独立会话，批量执行+检查点）
│
├─ 🔨 "我有 plan，要开始写代码"
│   ├─ 任务独立？ → subagent-driven-development
│   └─ 任务耦合？ → executing-plans
│
├─ 🐛 "遇到 bug / 测试失败 / 行为异常"
│   └─→ systematic-debugging（系统化调试四阶段）
│       铁律: 先找根因，再修复
│
├─ ✅ "我觉得做完了"
│   └─→ verification-before-completion（完成前验证）
│       铁律: 没有运行验证命令 = 没有完成
│
├─ 👀 "要请人审查代码"
│   └─→ requesting-code-review（请求代码审查）
│
├─ 📝 "收到了审查反馈"
│   └─→ receiving-code-review（接收审查反馈）
│       原则: 验证后再实施，技术正确性 > 社交舒适
│
└─ 📚 "我有外部资料要整理"
    └─→ importing-references（导入参考资料）
        输入: AI 对话、技术文章、文档链接
        产出: .governance/references/ 下的结构化文档
```

## 完整生命周期

```
需求 → brainstorming → spec.md
                          ↓
                    writing-plans → plan.md
                          ↓
              ┌─── subagent-driven-development ───┐
              │    (每任务: 实现→spec审查→质量审查)  │
              │           或                       │
              │    executing-plans                 │
              │    (批量执行+检查点)                │
              └───────────────────────────────────┘
                          ↓
                  (贯穿全程的纪律)
              ┌─ test-driven-development (TDD)
              ├─ systematic-debugging (遇 bug 时)
              ├─ verification-before-completion (声称完成前)
              └─ requesting/receiving-code-review (审查)
```

## 始终生效 vs 按需引用

| 类型 | 工作流 | 何时生效 |
|------|--------|---------|
| 始终生效 | test-driven-development | 写任何代码时 |
| 始终生效 | systematic-debugging | 遇到任何问题时 |
| 始终生效 | verification-before-completion | 声称完成前 |
| 按需引用 | brainstorming | 有新需求时 `#brainstorming` |
| 按需引用 | writing-plans | 写计划时 `#writing-plans` |
| 按需引用 | executing-plans | 执行计划时 `#executing-plans` |
| 按需引用 | subagent-driven-development | 子代理开发时 `#subagent-dev` |
| 按需引用 | requesting-code-review | 请求审查时 `#code-review` |
| 按需引用 | receiving-code-review | 收到反馈时 `#receiving-review` |
| 按需引用 | importing-references | 整理外部资料时 `#importing-references` |

## 常见场景速查

| 场景 | 工作流组合 |
|------|-----------|
| 从零开始做一个功能 | brainstorming → writing-plans → subagent-driven-development |
| 拿到别人写的 spec 直接实现 | writing-plans → executing-plans |
| 修一个 bug | systematic-debugging → test-driven-development |
| 重构现有代码 | test-driven-development（先有测试覆盖，再重构） |
| 做完了要提 PR | verification-before-completion → requesting-code-review |
