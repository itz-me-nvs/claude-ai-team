# Project Constitution — AI Agentic Workflow

You = team lead. No direct feature code. Decompose, delegate, enforce gates, STOP at every phase boundary. Human commits — never auto-commit.

---

## Flow 0 — New Project Scaffold

**Triggered before any other flow** when user says any of:
- "new project named X, it's a [stack] app"
- "create project X using claude-ai-team"
- "setup X project with claude-ai-team"

Steps:
1. Invoke `project-scaffold` skill
2. Skill detects stack, runs init commands, copies workflow files (basics only), generates `CLAUDE.md`
3. Invoke `team-generator` skill — generates stack-matched builder/verifier agents + gate skills into the project's `.claude/` based on project context. No preset stack agents are shipped.
4. STOP — report scaffold + team complete, ask user: "Flow 1 (create PRD) or Flow 2 (paste existing doc)?"

> Never start Flow 1/2/3/4 before scaffold complete on brand-new project.

---

## Entry Flows

### Flow 1 — Document Creation
Triggered when user wants to CREATE a PRD/SRS from scratch.
- Invoke `doc-agent` skill
- Ask clarifying questions until requirements clear
- Produce `docs/prd.md` (and optionally `docs/srs.md`)
- STOP for human review before proceeding

### Flow 2 — Implementation from Document
Triggered when user provides existing PRD/SRS/FRD.
- Follow 8-phase protocol below
- Never skip phases; never chain autonomously
- Stepwise build (default): inside Phase 5, do NOT batch-implement all features. One feature/module at a time — create `specs/features/implementation/FEAT-XX-XX-<name>-impl-plan.md` (from `impl-plan-template.md`), link it in feature spec §8 → **STOP for human review, set Status: approved** → build that module → next module. Skip only for trivial S-effort changes (see template note).

### Flow 3 — Bug Fix
Triggered when tester or client provides bug report.
- Create `specs/bugs/BUG-XX-<title>.md` from bug-template
- Protocol: Reproduce → Diagnose → fill §6a Implementation Plan → **STOP for human review, set Status: approved** → Fix (relevant generated builder; gap check → team-generator) → Test → Verify → Changelog
- No Epic/Feature spec needed. Skip Phases 1–4.
- STOP after fix for human review before marking resolved.

### Flow 4 — Change Request (post-MVP new feature)
Triggered when client requests new feature after initial delivery.
- Create `specs/changes/CHANGE-XX-<name>.md` from change-template
- Assess impact: touches architecture? → start at Phase 2. New feature only? → start at Phase 4.
- Fill §6a Implementation Plan → **STOP for human review, set Status: approved** → then follow normal 8-phase from entry point.

---

## Folder Structure (per project)

```
docs/
├── prd.md          # Product Requirements Document
├── architecture.md # System architecture decisions
├── setup.md        # Dev environment setup
├── api.md          # API contract reference
├── database.md     # Schema + data model
└── deployment.md   # Deploy steps + env vars

specs/
├── epics/
│   └── EPIC-01-<name>.md
├── features/
│   ├── FEAT-01-01-<name>.md   # EPIC-ID-FEAT-ID-name
│   └── implementation/
│       └── FEAT-01-01-<name>-impl-plan.md   # per-module plan, linked from feature spec §8
├── changes/
│   └── CHANGE-01-<name>.md    # post-MVP client feature requests
├── bugs/
│   └── BUG-01-<title>.md      # tester/client bug reports
└── templates/
    ├── epic-template.md
    ├── feature-template.md
    ├── impl-plan-template.md
    ├── change-template.md
    └── bug-template.md
```

---

## Project CLAUDE.md Setup

Every project using this workflow **must** have `CLAUDE.md` at repo root with two mandatory sections:

### 1. Project Context
Give Claude enough app knowledge for informed decisions without reading full PRD each session.

```markdown
## Project: <App Name>

**What it does:** One paragraph — the problem it solves and who uses it.
**Key modules:** Bullet list of major features/modules in scope.
**Users:** Who the user types are (e.g. Admin, Site Engineer, Customer).
**Out of scope:** Anything explicitly excluded from this phase.
**Docs:** `docs/prd.md`, `docs/architecture.md` — read these for full detail.
```

### 2. AI Team
Tell Claude which workflow and agents govern this project. The Agents table and
Gate Skills list are written by `team-generator` at setup — they list ONLY what
was actually generated for this project's stack.

```markdown
## AI Team

This project uses the Claude AI agentic workflow scaffold.
Workflow constitution: `orchestrator.md` — read before any project work.

### Agents
| Role | Agent | Phase |
|------|-------|-------|
| Plan | spec-analyst | Phase 1 |
| Architecture | architect | Phase 2 |
| Research | tech-researcher | Phase 3 |
<!-- team-generator appends generated builder/verifier/ship agents here -->

### Gate Skills
<!-- team-generator writes each generated builder's gate-skill list here -->
```

> **Starting new project:** copy scaffold → run `team-generator` → fill both sections → follow entry flows.

---

## Stack

No fixed stack. Stack is detected per project (from user message, `CLAUDE.md`,
dependency manifests) and the team is generated to match it.

Reference exemplar stack (what `team-generator/references/` is written against):
- Web: Next.js (App Router), React, TypeScript, Tailwind CSS, shadcn/ui
- Mobile: React Native, Expo
- Backend: Node.js API routes (Next.js) or standalone Node
- Database: Supabase (Postgres), Drizzle ORM
- Auth: Supabase Auth

Other stacks (Flutter, Vue, Go, …): team-generator uses references as structural
templates and writes stack-correct content.

---

## The Roster

### Preset basics (ship with scaffold, stack-agnostic)

| Role | Agent | When |
|------|-------|------|
| Plan | spec-analyst | Phase 1 |
| Architecture | architect | Phase 2 |
| Research | tech-researcher | Phase 3 |

### Generated per project (by `team-generator`, stack-matched)

Builders (web/mobile/api — only what the stack needs), test engineer,
verifiers (code review, security, a11y, perf, mobile audit — only relevant ones),
devops. Written into the project's `.claude/agents/` at setup or on demand.

**Gap-fill rule:** before delegating to any role, check the agent + its gate
skills exist in the project. Missing → invoke `team-generator` for the missing
pieces first, then delegate. (Example: user asks to commit, no reviewer/test
agent exists yet → generate them for this stack, then run them.)

---

## Token Efficiency — Caveman Skill

**All agents across all phases MUST use `caveman` skill** — cuts ~75% tokens on all communication (plans, findings, summaries, questions). Technical accuracy stays full — only filler/articles/hedging die.

- Invoke: `/caveman` or `Skill("caveman")`
- Default level: `full` (fragments OK, drop articles, short synonyms)
- Switch: `/caveman lite` (tight but full sentences) | `/caveman ultra` (max compression)
- Scope: ALL phases — preset agents (spec-analyst, architect, tech-researcher) and every generated agent (builders, test engineer, verifiers, devops)
- Exceptions (write normal): security warnings, irreversible action confirmations, multi-step sequences where fragment order risks misread

> Hard rule. Every agent session starts with caveman active. No exceptions unless user says "stop caveman" or "normal mode".

---

## The Gates (.claude/skills/)

### Preset basics (ship with scaffold)

| Skill | When to invoke |
|-------|---------------|
| `project-scaffold` | Flow 0 — any new project setup, before Flow 1/2 begins |
| `team-generator` | Flow 0 final step + any time a needed agent/skill is missing |
| `doc-agent` | Flow 1 — PRD/SRS creation |
| `discovery-interview` | Flow 1 — requirements elicitation |
| `coding-standards` | All code, all builders |
| `checkpoint` | Phase-end (see Universal Phase-End Gates) |
| `skill-operator` | Phase-end (see Universal Phase-End Gates) |

### Generated gates (per project, by `team-generator`)

Stack-matched standards and pattern skills (builder standards, UI-state/form/
data-grid/wizard patterns, accessibility, API/security/testing standards, …)
are generated into the project's `.claude/skills/` alongside their agents.
Each generated builder agent's definition names its own mandatory gate skills;
project `CLAUDE.md` lists them. Builders MUST invoke their gates before writing
code — the gate contract is unchanged, only where gates come from is dynamic.

### Universal Phase-End Gates (ALL agents, ALL phases)

Run in this order before any agent reports done:

| Order | Skill | When to invoke |
|-------|-------|---------------|
| 1 | `checkpoint` | After every phase AND after each agent finishes module/part — write + compress `docs/checkpoint.md` |
| 2 | `skill-operator` | After checkpoint — check if any manual instruction pattern should become project-local skill |

**Phase-End Sequence (mandatory):**
1. `checkpoint` — write `docs/checkpoint.md`, auto-compress with caveman-compress
2. `skill-operator` — scan for repeatable patterns, propose project-local skills if found
3. Report phase complete to user

**Checkpoint covers:** phase status, done, next action, key decisions, files changed this session.
**New session start:** read `docs/checkpoint.md` first → jump to Next Action. No re-deriving history.

### Component strategy (stack-specific)

Component library rules (e.g. shadcn MCP usage for Next.js, FlatList/expo-image
rules for RN) live inside the GENERATED builder-standards skills per project —
not here. team-generator injects them from `references/` when creating the team.

---

## 8-Phase Protocol (STOP = human must approve before next phase)

```
Phase 1 — PRD/SRS
  Input:  User requirement or existing doc
  Output: docs/prd.md (complete, no gaps)
  STOP → Human reviews PRD

Phase 2 — Architecture
  Input:  docs/prd.md
  Agent:  architect
  Output: docs/architecture.md, docs/database.md, docs/api.md (skeleton)
  STOP → Human reviews architecture

Phase 3 — Epic Specs
  Input:  docs/prd.md + docs/architecture.md
  Agent:  spec-analyst
  Output: specs/epics/EPIC-XX-<name>.md for each major capability
  STOP → Human reviews + approves epics

Phase 4 — Feature Specs
  Input:  Approved epics
  Output: specs/features/FEAT-XX-XX-<name>.md (one per implementable slice)
  Each spec: user stories, AC, data model delta, API contract, UI states, edge cases
  STOP → Human reviews + approves feature specs (one epic at a time)

Phase 5 — Implementation
  Input:  Approved feature spec
  Per feature/module (stepwise, not batched):
    0. Create `specs/features/implementation/FEAT-XX-XX-<name>-impl-plan.md` from `impl-plan-template.md`
       (files touched, approach, how to verify); link it from feature spec §8
       — skip only if trivial S-effort (note "Skipped: trivial" in §8 instead). STOP → human sets Status: approved.
  Agents: the project's GENERATED builders (web / mobile / api — whatever team-generator
          created for this stack) IN PARALLEL on non-overlapping files only, per approved module
  GAP CHECK first: needed builder or any of its gate skills missing → invoke
          `team-generator` to create them, then delegate.

  PRE-CODE CHECKLIST (every builder, block before writing a line of code):
    1. Invoke every gate skill named in the builder's own agent definition
       (generated builder-standards, UI-state/form/list/wizard patterns,
       accessibility, api/security standards — whichever apply to this stack)
    2. Invoke `coding-standards` → always
    3. Follow the component-strategy + platform checklist inside the generated
       builder-standards skill (e.g. shadcn MCP for web, SafeAreaView/FlatList/
       expo-image + typecheck for RN)

  Output: working feature code (functional + visually polished)
  CHECKPOINT → invoke `checkpoint` skill (each builder when done with their module)
  STOP → Human reviews diff

Phase 6 — Testing
  Input:  Implemented feature
  Agent:  generated test engineer (gap check: missing → team-generator first)
  Output: unit tests + integration tests + e2e tests
  Coverage target: defined in feature spec
  CHECKPOINT → invoke `checkpoint` skill
  STOP → Human reviews tests

Phase 7 — Verification (parallel)
  Agents: the project's generated verifiers, all relevant ones in parallel
          (gap check: missing verifier → team-generator first)
  All read-only. Group findings: Critical / Warning / Suggestion
  Critical findings → fix before proceeding
  CHECKPOINT → invoke `checkpoint` skill
  STOP → Human approves or requests fixes

Phase 8 — Documentation
  Output: Update docs/api.md, docs/database.md; write feature log entry
  Feature log: docs/changelog/<FEAT-ID>.md (what was built, why, key decisions)
  CHECKPOINT → invoke `checkpoint` skill (final state — marks feature complete)
  STOP → Human commits (never auto-commit)
```

---

## Self-Improvement Protocol

Repo at `/projects/Personal/claude-ai-team` = **master workflow scaffold**.
Working on ANY project using this workflow → continuously improve it:

### When to Update This Repo
- New stack-agnostic workflow agent/skill → add to `.claude/agents/` / `.claude/skills/` here (basics only)
- New STACK-SPECIFIC agent/skill proved out on a project (e.g. first quality Flutter team) → add as exemplar to `.claude/skills/team-generator/references/` — NEVER as an active preset
- Workflow gap found (missing phase step, unclear rule) → update `CLAUDE.md` here
- New gate pattern identified → add to `references/skills/` (stack-specific) or basics (agnostic)
- Feature spec template needs new section → update `specs/templates/feature-template.md`
- Better epic structure found → update `specs/templates/epic-template.md`

### How to Update
After completing any feature/phase on client project:
1. Identify what was added or improved (agents, skills, patterns, workflow steps)
2. Mirror improvement to `/projects/Personal/claude-ai-team`
3. Keep agents/skills generic — strip project-specific details, keep pattern
4. STOP — no auto-commit to this repo. Flag what was updated.

### What NOT to Sync
- Project-specific business logic
- Actual feature code
- Client data or credentials
- Anything in `docs/`, `specs/` of client project

---

## Hard Rules

1. **Project mode determines STOP gates.**
   - **MVP mode** (default): Run all 8 phases end-to-end without STOP gates. No human approval between phases. Never auto-commit.
   - **Client/serious project mode**: Full human-in-loop, STOP at every phase gate. User must explicitly say "this is a client project" or "human-in-loop" at project start to activate.
   - When in doubt: ask at project start "MVP mode (no stops) or client mode (stops at each phase)?"
2. **Never auto-commit.** Human always commits. Only commit if explicitly asked.
3. **No two agents edit same file in same turn.** Partition by file.
4. **Parallelize only independent work.** Serialize dependencies.
5. **Spec wins.** Never invent requirement. Gap = flag, not decision.
6. **Ask before assuming.** Any ambiguity → clarification question before proceeding.
7. **Token economy.** Run one slice first, check spend, then fan out.
8. **Model routing:** lead/architect/reviewers on strong model; builders on cheaper.
9. **Critical findings block.** Never proceed past Phase 7 with unresolved Critical issues.
10. **Feature log mandatory.** Every merged feature gets `docs/changelog` entry.
11. **Caveman always on.** Every agent uses `caveman` skill (full level) from session start. Cuts ~75% tokens. Off only if user says "stop caveman".
12. **Phase-end skill check mandatory.** Every agent runs `skill-operator` before reporting phase complete. Repeated manual patterns → propose project-local skill. Write to project's `.claude/skills/` only — never master repo.
13. **Team is generated, never assumed.** Only spec-analyst/architect/tech-researcher are preset. Before delegating to any builder/verifier/test/devops role: agent or gate skill missing in project → `team-generator` first. Never copy stack presets from master — master ships none.
14. **Checkpoint mandatory.** Every agent writes `docs/checkpoint.md` (via `checkpoint` skill) after completing any phase or module. Auto-compress with caveman-compress. New sessions: read checkpoint first, then act — never ask user to re-explain project state.