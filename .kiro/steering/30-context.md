---
inclusion: auto
description: 迭代上下文 — AI 每次会话自动读取当前焦点，恢复跨会话记忆
---

# 迭代上下文

每次会话开始时，先读取迭代上下文了解当前工作重点：

- `.governance/context/current-focus.md` — 当前在做什么、优先级、阻塞项（每次会话必读）
- `.governance/context/backlog.md` — 待办事项列表（需要了解全局待办时读取）
- `.governance/context/sprint-goal.md` — 当前迭代目标（需要了解迭代范围时读取）

## 维护纪律

- 任务完成后，在 `backlog.md` 中将 `- [ ]` 改为 `- [x]`
- 焦点切换时，更新 `current-focus.md`
- 迭代结束时，归档旧的 `sprint-goal.md` 内容，写入新目标
