---
inclusion: manual
description: 请求代码审查 — 完成任务后分发 code-reviewer 子代理进行审查
---

# Requesting Code Review

Dispatch a code-reviewer subagent to catch issues before they cascade.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)

## How to Request

1. Get git SHAs (BASE_SHA, HEAD_SHA)
2. Dispatch code-reviewer subagent with template from `.governance/workflows/requesting-code-review/code-reviewer.md`
3. Act on feedback:
   - Fix Critical issues immediately
   - Fix Important issues before proceeding
   - Note Minor issues for later
   - Push back if reviewer is wrong (with reasoning)

## Integration with Workflows

- **Subagent-Driven:** Review after EACH task
- **Executing Plans:** Review after each batch (3 tasks)
- **Ad-Hoc:** Review before merge
