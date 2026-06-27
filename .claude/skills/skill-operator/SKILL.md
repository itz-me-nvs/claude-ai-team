---
name: skill-operator
description: >
  Meta-skill that detects repeated manual instruction patterns during agent work and
  proposes creating a project-local skill to capture them. Agents invoke this at the
  end of every phase. Writes skills into the current project scope only — never to the
  master claude-ai-team repo. Triggered by agents automatically or by user saying
  "create skill for this", "save this as a skill", or invoking /skill-operator.
---

# Skill Operator

## Purpose

When an agent follows a manual instruction pattern that:
- Is not covered by any existing skill in `.claude/skills/`
- Was repeated more than once in this session, OR
- The user gave as a multi-step instruction block they clearly reuse

→ Propose capturing it as a project-local skill.

---

## When Agents Must Invoke This

Every agent MUST run the **Phase-End Skill Check** before reporting phase complete:

```
Phase-End Skill Check:
1. Did I follow any multi-step instruction pattern from the user this phase?
2. Is that pattern covered by an existing skill? (check .claude/skills/)
3. If NO existing skill covers it → invoke skill-operator
```

Agents that must run this check: spec-analyst, architect, tech-researcher,
frontend-builder, mobile-builder, api-integrator, test-engineer, devops.

---

## Detection Criteria

Flag a pattern as skill-worthy if ANY of these are true:

- User gave same instruction block 2+ times in session
- User gave a sequence of 3+ steps for a non-trivial task (not just "run npm install")
- User corrected the agent mid-task with a specific process ("always do X before Y")
- Agent had to ask clarifying questions that revealed an implicit process the user expects

Do NOT flag:
- One-off task-specific decisions
- Business logic choices (those go in specs)
- Anything already in an existing skill

---

## Proposal Format

When a pattern is detected, output this block (caveman style):

```
[SKILL-OPERATOR] Repeated pattern detected: <one-line description>

Pattern summary:
- <step 1>
- <step 2>
- <step 3>

Create project skill for this? (yes / no / modify)
Skill name suggestion: `<kebab-case-name>`
```

Wait for user response before writing anything.

---

## On User Approval

### If user says "yes" or approves:

1. Determine project root (current working directory, not master repo)
2. Create skill at: `<project-root>/.claude/skills/<skill-name>/SKILL.md`
3. Write full skill content using the pattern (see Skill File Format below)
4. Confirm to user: "Skill `<name>` created at `.claude/skills/<skill-name>/SKILL.md`. Available now in this project."

### If user says "modify":
- Ask what to change, incorporate edits, then write.

### If user says "no":
- Drop it. Do not re-propose same pattern in session.

---

## Skill File Format (for generated skills)

```markdown
---
name: <kebab-case-name>
description: >
  <One sentence: what this skill does and when to use it.>
---

# <Skill Title>

## When to Invoke
<Trigger conditions — what the user says or what state the code is in>

## Process

<Numbered steps exactly as the pattern dictates>

1. <Step>
2. <Step>
3. <Step>

## Rules
- <Any specific constraints or order requirements>
- <Edge cases>

## Output
<What the agent should produce when this skill is done>
```

---

## Scope Rules — CRITICAL

- **Write ONLY to the current project's `.claude/skills/`** — never to `/projects/Personal/claude-ai-team/`
- Never overwrite an existing skill without user confirmation
- If a skill with same name exists: show diff, ask "overwrite / rename / cancel"
- Project-local skills are for this project only — patterns generic enough for all projects should be flagged separately: "This looks reusable across projects. Want to also add to master claude-ai-team repo?" (requires explicit user yes)

---

## Manual Trigger

User can invoke at any time:
- `/skill-operator` — agent reviews current session for patterns, proposes skills
- "create skill for this" — agent captures the most recent instruction block
- "save this process as a skill" — same as above
