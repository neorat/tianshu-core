---
inclusion: manual
description: 需求分析与设计 — 将想法通过协作对话转化为完整设计和规范文档
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it.
</HARD-GATE>

## Checklist

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to their complexity, get user approval after each section
5. **Write design doc** — save to `.governance/specs/NNN-<feature-name>/spec.md` and commit
6. **Spec self-review** — check for placeholders, contradictions, ambiguity, scope
7. **User reviews written spec** — ask user to review before proceeding
8. **Transition to implementation** — invoke writing-plans skill

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on

## Design for Isolation and Clarity

- Break the system into smaller units with one clear purpose
- Each unit communicates through well-defined interfaces
- Can be understood and tested independently
- Smaller, well-bounded units are easier to reason about

## Working in Existing Codebases

- Explore the current structure before proposing changes
- Follow existing patterns
- Include targeted improvements where existing code has problems
- Don't propose unrelated refactoring

## After the Design

- Write spec to `.governance/specs/NNN-<feature-name>/spec.md`
- Commit the design document
- Run spec self-review (placeholder scan, consistency, scope, ambiguity)
- Ask user to review before proceeding
- Invoke writing-plans skill for implementation plan
