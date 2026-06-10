# FEAT-XX-XX — [Feature Name]

## Metadata
| Field | Value |
|-------|-------|
| Epic | EPIC-XX — [Epic Name] |
| Status | `draft` \| `approved` \| `in-progress` \| `done` |
| Priority | P0 / P1 / P2 |
| Estimated effort | S / M / L |
| Assigned agents | frontend-builder, api-integrator, test-engineer |

---

## 1. User Stories

```
As a [role], I want [action] so that [outcome].
```

- US-01: As a …
- US-02: As a …

---

## 2. Acceptance Criteria

### US-01
- [ ] AC-01: Given … When … Then …
- [ ] AC-02: …

### US-02
- [ ] AC-01: …

---

## 3. Data Model Delta

> Only list changes from current schema. If no change, write "No schema change."

```sql
-- New table / column / index
```

Drizzle schema snippet:
```typescript
// 
```

---

## 4. API Contract

### Endpoint: `METHOD /path`
**Request:**
```typescript
// body type
```
**Response (200):**
```typescript
// response type
```
**Errors:**
| Status | Code | Condition |
|--------|------|-----------|
| 400 | VALIDATION_ERROR | |
| 401 | UNAUTHORIZED | |
| 404 | NOT_FOUND | |

---

## 5. UI States

> For each screen/component involved, list every state.

### [Screen / Component Name]
| State | Trigger | What renders |
|-------|---------|--------------|
| idle | initial load | … |
| loading | fetch starts | skeleton / spinner |
| success | fetch completes | data |
| empty | data = [] | empty state message |
| error | fetch fails | error message + retry |

---

## 6. Edge Cases & Validation Rules

- EC-01: [describe edge case and expected behavior]
- EC-02: …

---

## 7. Test Coverage Requirements

| Type | Minimum | Notes |
|------|---------|-------|
| Unit | 80% | business logic functions |
| Integration | key paths | API routes with real DB |
| E2E | happy path + 1 error | Playwright |

---

## 8. Implementation Notes

> Constraints, gotchas, or pre-decisions the agent must follow. Not optional.

- 

---

## 9. Out of Scope

> Explicitly list what this feature does NOT cover to prevent scope creep.

- 

---

## 10. Open Questions

- [ ] OQ-01: [question] — owner: [human/agent]
