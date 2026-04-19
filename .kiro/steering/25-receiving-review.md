---
inclusion: manual
description: 接收审查反馈 — 技术评估优先于情感表演，验证后再实施
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

1. **READ:** Complete feedback without reacting
2. **UNDERSTAND:** Restate requirement in own words (or ask)
3. **VERIFY:** Check against codebase reality
4. **EVALUATE:** Technically sound for THIS codebase?
5. **RESPOND:** Technical acknowledgment or reasoned pushback
6. **IMPLEMENT:** One item at a time, test each

## Forbidden Responses

- ❌ "You're absolutely right!" (performative agreement)
- ❌ "Great point!" (performative)
- ❌ "Let me implement that now" (before verification)
- ✅ Restate the technical requirement
- ✅ Ask clarifying questions
- ✅ Push back with technical reasoning if wrong

## Handling Unclear Feedback

If any item is unclear: STOP. Ask for clarification on ALL unclear items before implementing anything.

## When To Push Back

- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Conflicts with architectural decisions

## Implementation Order

1. Clarify anything unclear FIRST
2. Blocking issues (breaks, security)
3. Simple fixes (typos, imports)
4. Complex fixes (refactoring, logic)
5. Test each fix individually
6. Verify no regressions
