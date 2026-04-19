# [Feature Name] — 任务清单

> 从 plan.md 生成，用于跟踪执行进度。
> 标记 [P] 的任务可以并行执行。

## 元信息

- **Spec:** `.governance/specs/NNN-<feature-name>/spec.md`
- **Plan:** `.governance/specs/NNN-<feature-name>/plan.md`
- **分支:** `feature/NNN-<feature-name>`
- **状态:** 未开始 | 进行中 | 已完成

---

## Phase 1: [用户故事/模块名]

### Task 1: [任务标题]
- **文件:** `src/path/to/file`
- **依赖:** 无
- **预估:** 2-5 分钟
- [ ] 写失败的测试
- [ ] 验证测试失败
- [ ] 写最少实现
- [ ] 验证测试通过
- [ ] 提交

### Task 2: [任务标题] [P]
- **文件:** `src/path/to/other-file`
- **依赖:** 无（可与 Task 1 并行）
- [ ] 写失败的测试
- [ ] 验证测试失败
- [ ] 写最少实现
- [ ] 验证测试通过
- [ ] 提交

### ✅ Phase 1 检查点
- [ ] 所有 Phase 1 任务完成
- [ ] 所有测试通过
- [ ] 功能可独立验证

---

## Phase 2: [用户故事/模块名]

### Task 3: [任务标题]
- **文件:** `src/path/to/file`
- **依赖:** Task 1
- [ ] 写失败的测试
- [ ] 验证测试失败
- [ ] 写最少实现
- [ ] 验证测试通过
- [ ] 提交

### ✅ Phase 2 检查点
- [ ] 所有 Phase 2 任务完成
- [ ] 所有测试通过（包括 Phase 1）
- [ ] 集成验证通过

---

## 最终检查

- [ ] 所有任务完成
- [ ] 完整测试套件通过
- [ ] 代码审查通过
- [ ] 符合 constitution.md 原则
- [ ] 准备合并/PR
