---
inclusion: manual
description: 子代理驱动开发 — 每任务分发独立子代理实现，双重审查（spec合规+代码质量）
---

# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review: spec compliance first, then code quality.

**Core principle:** Fresh subagent per task + two-stage review = high quality, fast iteration

## When to Use

- Have implementation plan
- Tasks mostly independent
- Want to stay in current session
- (If tasks tightly coupled → use executing-plans instead)

## The Process

For each task:
1. Dispatch implementer subagent with full task text + context
2. Handle implementer status (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED)
3. Dispatch spec reviewer subagent — confirm code matches spec
4. If spec issues → implementer fixes → re-review
5. Dispatch code quality reviewer subagent
6. If quality issues → implementer fixes → re-review
7. Mark task complete

After all tasks:
- Dispatch final code reviewer for entire implementation
- Verify tests, present merge/PR options

## Handling Implementer Status

- **DONE:** Proceed to spec review
- **DONE_WITH_CONCERNS:** Read concerns, address if needed, then review
- **NEEDS_CONTEXT:** Provide missing context, re-dispatch
- **BLOCKED:** Assess blocker — provide context / use more capable model / break task / escalate

## Red Flags

- Never skip reviews (spec OR quality)
- Never dispatch multiple implementation subagents in parallel
- Never start quality review before spec compliance is ✅
- Never move to next task with open review issues
- If subagent asks questions — answer before letting them proceed
- If reviewer finds issues — implementer fixes, reviewer re-reviews

## Prompt Templates

Templates in `.governance/workflows/subagent-driven-development/`:
- `implementer-prompt.md`
- `spec-reviewer-prompt.md`
- `code-quality-reviewer-prompt.md`
