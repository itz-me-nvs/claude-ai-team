---
name: team-generator
description: >
  Meta-skill that generates project-local agents and skills matched to the project's
  actual stack and context. Invoked at project setup (from project-scaffold Flow 0)
  to create the full builder/verifier team, and on-demand mid-work whenever a needed
  agent or skill is missing (e.g. about to commit but no reviewer/test agent exists).
  Uses references/ exemplars as quality templates, adapts them to the detected stack.
  Writes into the current project's .claude/ only — never the master claude-ai-team repo.
  Triggers: "setup the team", "generate agents", "generate skills for this project",
  missing-agent gap detected at any phase, or /team-generator.
---

# Team Generator

## Purpose

The master repo ships only stack-agnostic basics (spec-analyst, architect,
tech-researcher + workflow skills). Builders, verifiers, and standards skills are
NOT preset — they are generated per project, matched to that project's stack.
A Next.js project never gets React Native agents; a Flutter project gets
Flutter-specific ones, not React presets.

---

## When to Invoke

### 1. Setup time (primary)
`project-scaffold` invokes this as its final step, after stack detection and
workflow-file copy. Generates the full team for the detected stack.

### 2. On-demand gap fill (runtime)
Any time during any phase, before delegating to a role, check the project's
`.claude/agents/` and `.claude/skills/`. If the needed agent or skill does not
exist → invoke team-generator to create just that one, then proceed.

Examples:
- User asks to commit → testing + review needed → no test agent or reviewer
  exists → generate `test-engineer` + `code-reviewer` for this stack, then run them.
- Phase 5 starts on a web module → no web builder exists → generate it.
- Feature adds file uploads → no security standards skill exists → generate it.

### 3. Manual
User says "setup the team", "generate agents for this project", or `/team-generator`.

---

## Process

### Step 1 — Read project context

Gather, in order (stop when stack + scope are clear):
1. Project `CLAUDE.md` — stack line, key modules, project description
2. `package.json` / `pubspec.yaml` / `go.mod` etc. — actual dependencies
3. `docs/prd.md`, `docs/architecture.md` if present — feature surface
   (forms? tables? auth? uploads? realtime? mobile?)

### Step 2 — Decide the team

Map project needs → roles. Generate ONLY what the project needs:

| Project signal | Generate |
|----------------|----------|
| Web UI (Next.js/React/Vue/etc.) | web builder agent + web standards/UI-pattern skills |
| Mobile (RN/Expo/Flutter) | mobile builder agent + mobile standards/a11y/security skills |
| API/DB layer | api integrator agent + api/security standards skills |
| Any code at all | code reviewer agent, test engineer agent + testing standards skill |
| UI of any kind | a11y auditor agent + accessibility standards skill |
| Auth/user data/payments | security auditor agent + security standards skill |
| Perf-sensitive (large lists, media, SSR) | perf auditor agent |
| Deploy target defined | devops agent |

At setup time, generate the whole table's matches. At gap-fill time, generate
only the missing role.

### Step 3 — Adapt from references

For each agent/skill to generate:
1. Look in `references/agents/` and `references/skills/` (in the master repo's
   copy of this skill) for the closest exemplar
2. Exemplar exists for this stack (e.g. Next.js, RN/Expo) → copy and adapt:
   strip anything irrelevant to this project, inject project-specific context
   (stack versions, folder structure, chosen libraries)
3. No exemplar for this stack (e.g. Flutter, Vue, Go) → use the closest
   exemplar as a STRUCTURAL template only (frontmatter shape, section layout,
   tone, gate style) and write stack-correct content. Use tech-researcher or
   WebSearch if current best practices are uncertain.

Reference exemplars (Next.js + RN/Expo stack):
- Agents: frontend-builder, mobile-builder, api-integrator, test-engineer,
  code-reviewer, security-auditor, a11y-auditor, perf-auditor, mobile-auditor, devops
- Skills: frontend-builder-standards, ui-state-gate, form-patterns,
  data-grid-patterns, stepper-wizard-patterns, accessibility-standards,
  api-integration-standards, security-standards, testing-standards,
  mobile-builder-standards, mobile-ui-patterns, mobile-accessibility-standards,
  mobile-security-standards, health-check

### Step 4 — Write into the project

- Agents → `<project-root>/.claude/agents/<name>.md`
- Skills → `<project-root>/.claude/skills/<name>/SKILL.md`
- Keep agent frontmatter format: `name`, `description` (with "Use during Phase X…"
  trigger language), `tools`, `model` (route: builders on cheaper model,
  reviewers/architect on strong model)

### Step 5 — Update project CLAUDE.md

Rewrite the `## AI Team` section's Agents table and Gate Skills list to reflect
what was ACTUALLY generated — never list agents that don't exist in this project.

### Step 6 — Report

```
[TEAM-GENERATOR] Team generated for <stack>:
Agents: <list>
Skills: <list>
Skipped (not needed): <list + one-word reason>
```

STOP for user review before using the generated team (client mode only;
MVP mode proceeds).

---

## Scope Rules — CRITICAL

- Write ONLY to the current project's `.claude/` — NEVER to
  `/projects/Personal/claude-ai-team/.claude/agents/` or `.claude/skills/`
  (master keeps basics + this generator only)
- Never overwrite an existing project agent/skill without showing a diff and asking
- Generated content must be project-specific — no "if Next.js do X, if RN do Y"
  branching inside generated files; the branching happens HERE, once
- New exemplar worth keeping (e.g. first Flutter team generated, quality confirmed)
  → flag: "Add to master references/ for reuse?" — requires explicit user yes,
  then copy into master `references/` (not master active skills)

---

## Gap-Fill Contract (for orchestrator)

Before any phase delegates to a role:

```
1. Does <project>/.claude/agents/<role>.md exist?
2. Do its gate skills exist in <project>/.claude/skills/?
3. Any missing → invoke team-generator for the missing pieces first
4. Then delegate
```
