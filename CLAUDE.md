# claude-ai-team

Reusable AI agentic workflow scaffold for building end-to-end applications.

## What This Repo Is
Master template for spec-driven development using Claude agents.
Copy scaffold into new project, follow workflow.

## Key Files
- `orchestrator.md` — full agent team workflow constitution (read before any project work)
- `specs/templates/` — epic + feature spec templates
- `docs/` — project docs (prd, architecture, api, database, deployment)
- `specs/epics/` — approved epic specs
- `specs/features/` — approved feature specs
- `.claude/agents/` — specialist agent definitions
- `.claude/skills/` — gate skills builders must invoke

## How to Start a Project
1. Read `orchestrator.md` fully before proceeding
2. Flow 1 (no doc yet): say "create PRD" → doc-agent skill kicks in
3. Flow 2 (have doc): paste/reference PRD/SRS → Phase 2 begins

## Stack
- Web: Next.js 15 (App Router), React, TypeScript, Tailwind CSS v4, shadcn/ui
- Mobile: React Native, Expo (SDK 52+), NativeWind v4, Expo Router
- Backend: Node.js (Next.js API routes or standalone)
- Database: Supabase (Postgres), Drizzle ORM
- Auth: Supabase Auth

## Master Repo Path
`/projects/Personal/claude-ai-team` — sync improvements back here after every project.