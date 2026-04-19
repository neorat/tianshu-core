---
inclusion: manual
description: 执行实现计划 — 加载计划、批量执行任务、检查点审查
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify questions or concerns
3. If concerns: Raise them before starting
4. If no concerns: Proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly
3. Run verifications as specified
4. Mark as completed

### Step 3: Complete Development

After all tasks complete:
- Verify all tests pass
- Present options: merge locally, create PR, keep branch, or discard

## When to Stop and Ask for Help

- Hit a blocker
- Plan has critical gaps
- Don't understand an instruction
- Verification fails repeatedly

## Integration

- **writing-plans** — Creates the plan this workflow executes
- **test-driven-development** — TDD discipline during implementation
- **verification-before-completion** — Verify before claiming done
