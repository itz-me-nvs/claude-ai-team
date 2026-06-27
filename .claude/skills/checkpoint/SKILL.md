---
name: checkpoint
description: >
  Writes and compresses docs/checkpoint.md after every phase completes and after every
  agent finishes its part. Captures exact project state so a new chat session can resume
  without re-deriving context. Uses caveman-compress to minimize token cost of loading
  the checkpoint. Triggered automatically by all agents at phase/task end, or manually
  via /checkpoint.
---

# Checkpoint Skill

## Purpose

Context windows fill up. This skill writes a compressed state snapshot so any new session
can read `docs/checkpoint.md` and immediately know: what's done, what's next, what decisions
were made. Replaces re-explaining the whole project history.

---

## When to Invoke

**Automatic — every agent must call this before reporting done:**
- After completing a full phase (Phase 1 → 8)
- After each agent finishes its assigned part within a phase
  (e.g. frontend-builder done with module X, api-integrator done with route Y)

**Manual:**
- User types `/checkpoint`
- User says "save checkpoint", "update status"

---

## What to Write

Keep it minimal. Only things a fresh session can't derive from reading the code or specs.

### Template

```markdown
# Checkpoint

**Project:** <name> | **Stack:** <stack> | **Updated:** <date>

## Status
Phase <N> — <phase name> — <DONE / IN PROGRESS / BLOCKED>

## Done
- Phase 1: PRD approved (`docs/prd.md`)
- Phase 2: Architecture approved (`docs/architecture.md`, `docs/database.md`)
- Phase 3: Epics approved — EPIC-01 Auth, EPIC-02 Dashboard
- Phase 4: Features approved — FEAT-01-01, FEAT-01-02
- Phase 5: <Agent> built <module> — files: `src/...`, `src/...`
...

## In Progress
- Phase <N>: <what agent is doing> — <file or module>

## Next Action
<Exact instruction for what to do next — specific enough to act on without asking>

## Blocked / Open Questions
- <blocker or question> — waiting on: <who/what>

## Key Decisions
- <decision>: <why — one line. Only non-obvious ones not in specs/architecture.md>
- <decision>: <why>

## Files Changed This Session
- `<path>` — <one-word reason>
- `<path>` — <one-word reason>
```

### Rules for content
- **Done** section: list phases + epics/features by ID — no prose
- **Next Action**: be exact. "Run Phase 5 frontend-builder on FEAT-01-02 spec" not "continue building"
- **Key Decisions**: only things NOT in `docs/architecture.md` or specs. Skip obvious ones.
- **Files Changed**: only files written/edited this session — not all project files
- **Blocked**: leave empty if none. Never invent blockers.

---

## Write Process

1. Create `docs/` dir if missing: `mkdir -p docs`
2. Write `docs/checkpoint.md` using template above — overwrite if exists
3. Run caveman-compress on it immediately:

```bash
# Find caveman-compress scripts dir
COMPRESS_SCRIPTS=$(find ~/.claude/plugins -path "*/caveman-compress/scripts/__main__.py" | head -1 | xargs dirname | xargs dirname)
python3 -m scripts "$(pwd)/docs/checkpoint.md"
```

4. Confirm to user: "Checkpoint saved → `docs/checkpoint.md` (compressed)"

> If caveman-compress fails: save uncompressed, warn user. Do NOT block the phase.

---

## How New Session Uses Checkpoint

At start of any new session on this project:

1. Read `docs/checkpoint.md`
2. Read any referenced spec files (epics/features listed in Done)
3. Jump directly to **Next Action** — no re-deriving phase history

> New session instruction: "Read docs/checkpoint.md first, then continue from Next Action."

---

## Compression Note

`caveman-compress` overwrites the file and saves `checkpoint.md.original.md` as backup.
Compressed version uses ~60-75% fewer tokens when loaded in future sessions.
If user wants readable version: open `docs/checkpoint.md.original.md`.
