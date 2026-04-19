---
inclusion: manual
description: 编写实现计划 — 将 spec 转化为详细的分步实现计划，每步 2-5 分钟
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context. Document everything: which files to touch, code, testing, docs. Bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

**Save plans to:** `.governance/specs/NNN-<feature-name>/plan.md`

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking into separate plans — one per subsystem.

## File Structure

Before defining tasks, map out which files will be created or modified. Design units with clear boundaries and well-defined interfaces.

## Bite-Sized Task Granularity

Each step is one action (2-5 minutes):
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code" - step
- "Run the tests" - step
- "Commit" - step

## No Placeholders

Every step must contain actual content. Never write:
- "TBD", "TODO", "implement later"
- "Add appropriate error handling"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code)

## Self-Review

After writing the plan:
1. **Spec coverage** — Can you point to a task for each requirement?
2. **Placeholder scan** — Any red flags?
3. **Type consistency** — Do names match across tasks?

## Execution Handoff

After saving the plan, offer:
1. **Subagent-Driven (recommended)** — Fresh subagent per task, review between tasks
2. **Inline Execution** — Execute tasks in this session with checkpoints
