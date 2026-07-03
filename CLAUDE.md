# claude-ai-team

Reusable AI agentic workflow scaffold for building end-to-end applications.

## What This Repo Is
Master template for spec-driven development using Claude agents.
Copy basics into new project → `team-generator` creates stack-matched agents/skills there.
No preset stack-specific agents or skills ship with the scaffold.

## Key Files
- `orchestrator.md` — full agent team workflow constitution (read before any project work)
- `specs/templates/` — epic + feature + impl-plan + change + bug templates
- `docs/` — project docs (prd, architecture, api, database, deployment)
- `specs/epics/` — approved epic specs
- `specs/features/` — approved feature specs
- `.claude/agents/` — preset stack-agnostic agents ONLY (spec-analyst, architect, tech-researcher)
- `.claude/skills/` — preset workflow skills ONLY (project-scaffold, team-generator, doc-agent, discovery-interview, checkpoint, skill-operator, coding-standards)
- `.claude/skills/team-generator/references/` — exemplar agents/skills (Next.js + RN/Expo). NOT active — team-generator adapts them per project. New proven stack exemplars get added here.

## How Agents/Skills Work (Dynamic Team)
Builders, test engineer, verifiers, devops, and stack standards skills are NOT preset.
`team-generator` creates them in the target project's `.claude/` — matched to that
project's stack — at setup (Flow 0) or on demand whenever a needed role is missing
(gap-fill: e.g. about to commit, no reviewer exists → generate one, then run it).

## How to Start a Project
1. Read `orchestrator.md` fully before proceeding
2. Flow 0 (new project): "setup project X, [stack] app" → project-scaffold + team-generator
3. Flow 1 (no doc yet): say "create PRD" → doc-agent skill kicks in
4. Flow 2 (have doc): paste/reference PRD/SRS → Phase 2 begins

## Stack
No fixed stack — detected per project, team generated to match.
Reference exemplars written against: Next.js 15 (App Router) + Tailwind v4 + shadcn/ui,
React Native + Expo + NativeWind v4, Supabase + Drizzle.

## Master Repo Path
`/projects/Personal/claude-ai-team` — sync improvements back here after every project.
Stack-specific improvements go to `team-generator/references/`, never to active `.claude/agents|skills`.
