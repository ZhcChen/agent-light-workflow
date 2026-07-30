# agent-light-workflow

面向 agent 编码场景的轻工作流模板仓库，当前内置的是 **Codex 版轻工作流**。

定位很简单：**纯文档工作流 + 薄初始化脚本**。它不提供隐藏 runtime、后台调度器或 Pi / 其他 harness 专用目录，只负责把一个空项目初始化成适合 Codex 长期协作的最小结构。

## 当前为什么先落 Codex 版

- 当前这类模型已经足够强，普通工程任务通常不需要重型编排
- Codex 原生更适合吃项目根目录的 `AGENTS.md`
- `pi-light-ce` 里的 `.pi/prompts/` 是 Pi 专用入口，在 Codex 里没有直接等价物
- 因此这里先把提示词整理成 `docs/prompts/*.md` 参考文件，方便直接复制、改写或团队内约定

## 工作流阶段

- `brainstorm`：需求不清、范围未定、方案分叉时才使用
- `plan`：形成正式计划并落到 `docs/plans/`
- `execute`：按计划小步执行并持续验证
- `review`：对照计划检查结果、回归和偏差
- `compound`：把可复用经验沉淀到 `docs/solutions/`

## 生成后的目录结构

```text
AGENTS.md
docs/
  brainstorms/
    TEMPLATE.md
  plans/
    TEMPLATE.md
  reviews/
    TEMPLATE.md
  solutions/
    TEMPLATE.md
  prompts/
    README.md
    brainstorm.md
    plan.md
    execute.md
    review.md
    compound.md
```

## 初始化用法

在本目录下执行：

```bash
./init.sh .
./init.sh /path/to/project
./init.sh --force /path/to/project
```

说明：

- 默认目标目录是当前目录
- 若目标文件已存在，默认跳过
- 传 `--force` 时覆盖模板文件

## 初始化后会写入什么

- `AGENTS.md`：项目级协作约束，优先供 Codex 读取
- `docs/brainstorms/TEMPLATE.md`：前置收敛模板
- `docs/plans/TEMPLATE.md`：正式计划模板
- `docs/reviews/TEMPLATE.md`：审查 / 验证记录模板
- `docs/solutions/TEMPLATE.md`：沉淀模板
- `docs/prompts/*.md`：可直接复制给 Codex 的轻工作流参考提示词

## 如何使用这些提示词

- Codex 不会自动把 `docs/prompts/*.md` 当作内建命令
- 这些文件是**参考提示词资产**
- 用法通常是：打开对应文件，按当前任务替换上下文，再粘贴给 Codex

最常见的实际用法：

1. 需求不清时，看 `docs/prompts/brainstorm.md`
2. 要开始正式做事时，看 `docs/prompts/plan.md`
3. 已有计划要开工时，看 `docs/prompts/execute.md`
4. 改动做完要复核时，看 `docs/prompts/review.md`
5. 有可复用经验时，看 `docs/prompts/compound.md`

## 设计取舍

- 默认轻，不上重 runtime
- 文档是主产物，不靠隐藏命令
- 计划优先写正式文件，不把真实内容写进 `TEMPLATE.md`
- 非微小任务先有 plan，再 execute
- 只在值得复用时才做 compound

## 适用场景

适合：

- 单仓库开发
- 中小型功能 / 修复
- 需要稳定计划、执行、复核节奏
- 想给 Codex 一个清晰的项目级行为边界

不适合直接解决的事：

- 多服务复杂编排
- 长链路自动审批系统
- 需要隐藏状态机或重型任务调度的场景
