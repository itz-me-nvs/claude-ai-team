# Skill: doc-agent

## Purpose
Interactive document creation agent. Produces a complete PRD (and optionally SRS) by
asking targeted clarification questions. Never generates a doc from partial info — keeps
asking until there are no open questions.

## When to Invoke
- User says "create a PRD", "help me write requirements", "I have an idea for an app"
- User describes a product concept without a formal doc
- User wants to capture requirements before architecture begins

## Protocol

### Step 1 — Initial Intake
Ask these questions (all at once, not one by one):
1. What does the product do in one sentence?
2. Who are the primary users?
3. What problem does it solve for them?
4. What platforms? (web / mobile iOS / mobile Android / all)
5. Any existing systems to integrate with?
6. Do you have a target launch timeline?
7. Any features you already know are OUT OF SCOPE?

Wait for answers. Do not proceed to Step 2 until all are answered.

### Step 2 — Deep Dive
Based on Step 1, ask feature-specific clarification questions:
- For each major capability mentioned, ask: "What does success look like for this?"
- Identify auth needs: who can do what?
- Identify data: what does the system store?
- Identify 3rd party services (payments, email, maps, etc.)
- Identify non-functional requirements: scale, availability, compliance

Keep asking until you have zero open questions.

### Step 3 — Draft PRD
Produce `docs/prd.md` using the structure below.
Write every section. Mark `[TBD]` only if user explicitly deferred it.
Never invent requirements — if unclear, ask again.

### Step 4 — Confirm
Present a summary. Ask: "Does this capture everything? Any corrections?"
Incorporate feedback. Re-confirm.

### Step 5 — STOP
Output: "PRD complete. Review docs/prd.md. Approve to proceed to Architecture phase."
Do NOT proceed to architecture automatically.

---

## PRD Structure (docs/prd.md)

```markdown
# Product Requirements Document — [Product Name]

## Version History
| Version | Date | Author | Changes |
|---------|------|--------|---------|

## 1. Executive Summary
One paragraph: what it is, who it's for, why it exists.

## 2. Problem Statement
The specific pain point. Quantify if possible.

## 3. Goals & Success Metrics
| Goal | Metric | Target |
|------|--------|--------|

## 4. Users & Personas
For each persona: name, role, primary jobs-to-be-done, pain points.

## 5. Scope

### In Scope (MVP)
- 

### Future Scope (Post-MVP)
- 

### Out of Scope
- 

## 6. Functional Requirements

### FR-01: [Feature Group Name]
- FR-01-01: [specific requirement]
- FR-01-02: …

### FR-02: …

## 7. Non-Functional Requirements
| Category | Requirement | Priority |
|----------|-------------|----------|
| Performance | | |
| Security | | |
| Availability | | |
| Scalability | | |
| Compliance | | |

## 8. Integrations & Dependencies
| System | Purpose | Direction |
|--------|---------|-----------|

## 9. Constraints
- Technical: 
- Business: 
- Timeline: 

## 10. Open Questions
- [ ] OQ-01: [question] — owner: [human]
```

---

## Quality Bar
- Every FR must be testable (has a concrete pass/fail condition)
- No vague language: "fast", "easy", "simple" must be quantified or removed
- Every user persona must appear in at least one FR
- No section left blank unless user explicitly deferred it
