---
name: data-grid-patterns
description: Enforced by frontend-builder on every table, grid, or list component; checked by code-reviewer, a11y-auditor, and perf-auditor. Covers skeleton loading, empty/error states, filter/sort/pagination loading, virtualization thresholds, and keyboard navigation.
---

# Data Grid / Table / List Patterns

Every table, grid, or list that displays dynamic data must follow these patterns.

## Loading State — Skeleton Rows

Do NOT use a full-page spinner for table loading. Use skeleton rows.

```tsx
if (isLoading) {
  return (
    <Table aria-busy="true" aria-label="Loading invoices">
      <TableHeader>...</TableHeader>
      <TableBody>
        {Array.from({ length: 5 }).map((_, i) => (
          <TableRow key={i}>
            <TableCell><Skeleton className="h-4 w-32" /></TableCell>
            <TableCell><Skeleton className="h-4 w-20" /></TableCell>
            <TableCell><Skeleton className="h-4 w-16" /></TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}
```

- Skeleton rows must match the real column count and approximate column widths
- Table container has `aria-busy="true"` during loading
- Number of skeleton rows: match the page size or use 5–10 as default

## Empty State

Never render a blank table or empty `<tbody>`. Replace it with an intentional empty state.

```tsx
if (data.length === 0) {
  return (
    <div className="flex flex-col items-center gap-4 py-16 text-center">
      <FileX className="h-12 w-12 text-muted-foreground" aria-hidden="true" />
      <div>
        <p className="font-medium">No invoices yet</p>
        <p className="text-muted-foreground text-sm">Create your first invoice to get started</p>
      </div>
      <Button asChild>
        <Link href="/invoices/new">Create Invoice</Link>
      </Button>
    </div>
  )
}
```

- Icon is decorative (`aria-hidden="true"`)
- Primary message explains why it's empty
- Next-action button or link guides the user forward

## Error State — Inline with Retry

Never render a blank table on error. Show an error banner inside the table container with a retry action.

```tsx
if (error) {
  return (
    <div role="alert" className="rounded-md border border-destructive/50 bg-destructive/10 p-6 text-center">
      <p className="font-medium text-destructive">Failed to load invoices</p>
      <p className="text-muted-foreground text-sm mt-1">{error.message}</p>
      <Button variant="outline" onClick={refetch} className="mt-4">
        Try again
      </Button>
    </div>
  )
}
```

- `role="alert"` on the container
- Human-readable error message — not a raw error code
- Retry button calls the same fetch again

## Sort / Filter / Pagination — Independent Loading State

When the user sorts, filters, or paginates, do NOT remount the full skeleton. Show a subtle loading overlay on the existing data.

```tsx
<div className="relative">
  {isFetching && (
    <div
      className="absolute inset-0 bg-background/60 flex items-center justify-center z-10"
      aria-label="Updating results"
      aria-live="polite"
    >
      <Loader2 className="h-6 w-6 animate-spin" />
    </div>
  )}
  <Table aria-busy={isFetching}>
    ...existing rows...
  </Table>
</div>
```

- Distinction: `isLoading` (first load, no data) → full skeleton; `isFetching` (refetch with existing data) → overlay
- `aria-live="polite"` announces the update to screen readers without interrupting
- Disable sort/filter controls while fetching to prevent rapid re-queues

## Virtualization

If the list can exceed 200 items in a single render (no server-side pagination), virtualize it.

- Use `@tanstack/react-virtual` (per architecture decision)
- Alternatively, implement server-side pagination before reaching this limit
- Do not virtualize paginated tables — only unbounded lists

```tsx
// Only when list is unbounded
const rowVirtualizer = useVirtualizer({
  count: data.length,
  getScrollElement: () => scrollRef.current,
  estimateSize: () => 56, // row height in px
})
```

## Keyboard Navigation

- Table rows with actions must be keyboard-reachable
- Row-level actions (edit, delete) must be reachable without a mouse
- Use `tabIndex={0}` on interactive rows with `onKeyDown` for Enter/Space
- Action buttons within rows must be in the natural tab order

## Accessibility Checklist

- [ ] `<table>`, `<thead>`, `<tbody>`, `<th>`, `<td>` used (not div-grid) for tabular data
- [ ] `<th>` has `scope="col"` or `scope="row"`
- [ ] `aria-sort` on sortable column headers
- [ ] `aria-label` or `aria-labelledby` on the table
- [ ] `aria-busy="true"` during loading
- [ ] `role="alert"` on error state
- [ ] Empty state in DOM (not CSS-hidden)

## Definition of Done

- [ ] First load renders skeleton rows matching column layout
- [ ] Empty state renders with icon + message + next action
- [ ] Error state renders inline with `role="alert"` + retry button
- [ ] Sort/filter/pagination show overlay loading (not full remount)
- [ ] Virtualization implemented if list is unbounded and may exceed 200 items
- [ ] All rows and row actions keyboard-accessible
- [ ] A11y checklist above complete
- [ ] Typecheck passes
