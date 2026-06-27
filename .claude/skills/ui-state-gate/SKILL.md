---
name: ui-state-gate
description: Enforced by frontend-builder on every data-displaying or input component; checked by code-reviewer and a11y-auditor. Every component must handle all five UI states — loading, error, empty, warning/partial, success — with accessibility built in.
---

# UI State Gate

Every component that fetches data, submits data, or displays dynamic content MUST handle all five states. Skipping any state is a build defect.

## The Five States

### 1. Loading
- Use shadcn `<Skeleton>` — never custom CSS shimmer/pulse animations
- Compose `<Skeleton>` elements to match the real layout's shape (columns, card grid, form fields)
- A bare `<Loader2 className="animate-spin" />` (lucide icon) is only acceptable for inline micro-actions (e.g., a button that triggers a quick action with no content area to skeleton) — never a custom `<Spinner />` component
- Container must have `aria-busy="true"` during loading
- Skeleton items should not be interactive (no focusable elements inside)

```tsx
// ✅ Correct — shadcn Skeleton
import { Skeleton } from '@/components/ui/skeleton'

<div aria-busy="true">
  <Skeleton className="h-6 w-48 mb-2" />
  <Skeleton className="h-4 w-full" />
  <Skeleton className="h-4 w-3/4" />
</div>

// ❌ Wrong — custom shimmer
<div className="animate-pulse bg-gray-200 rounded h-6 w-48" />
```

### 2. Error
- Surface a human-readable message — never "Something went wrong" alone; include what failed and whether the user can retry
- Provide a recovery action: a Retry button, a link back, or clear next steps
- Use `role="alert"` or `aria-live="assertive"` so screen readers announce it
- Never swallow errors silently (`catch (e) {}` with no UI feedback is always wrong)
- Log errors to the observability layer (server-side); never expose stack traces to the UI

### 3. Empty
- Purposeful: explain why it's empty and what the user can do (e.g., "No invoices yet. Create your first invoice →")
- Never render a blank space, a blank table, or `null` without explanation
- Empty state is a UX moment — use it to guide the user toward the next action

### 4. Warning / Partial
- When data loads but is incomplete, stale, or partially failed, surface it visibly
- Examples: "Showing cached data from 2 hours ago", "3 of 10 items failed to load"
- Do not hide partial failures behind a "success" UI

### 5. Success
- The fully loaded, fully functional state — the actual content
- Must be reachable from the loading state without requiring a page refresh

## Per-Pattern Rules

### Forms
See `form-patterns` skill. In summary: disable submit while pending, validate on blur + submit, inline field errors, server errors at form level, preserve input on failure.

### Tables / Grids / Lists
See `data-grid-patterns` skill. In summary: skeleton rows on load, purposeful empty state, inline error + retry (never blank table), independent loading for sort/filter/pagination.

### Steppers / Wizards
See `stepper-wizard-patterns` skill. In summary: per-step validation gates next, back never loses data, progress persisted, review step before final submit.

## Accessibility Requirements (all states)

- **Loading**: `aria-busy="true"` on the container; skeleton items non-focusable
- **Error**: `role="alert"` or `aria-live="assertive"`; focus moves to error on appearance if replacing content
- **Empty**: announced to screen readers (in the DOM, not only visually)
- **Async updates**: `aria-live="polite"` on regions that update without navigation
- **Forms**: all errors associated with inputs via `aria-describedby`

## Definition of Done

A component passes the UI State Gate when:
- [ ] All five states are implemented and render correctly
- [ ] Loading state uses layout-matching skeleton with `aria-busy`
- [ ] Error state has a message + recovery action + `role="alert"`
- [ ] Empty state has explanatory text + next-action link/button
- [ ] Partial/warning state is surfaced if the data source can return partial results
- [ ] Success state renders the full content
- [ ] All states are keyboard-reachable and screen-reader-announced
- [ ] Typecheck passes
