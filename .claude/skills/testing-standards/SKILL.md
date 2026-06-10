---
name: testing-standards
description: Enforced by test-engineer on all test files; checked by code-reviewer. Covers what must be tested (happy/error/empty/edge), unit vs integration vs e2e split, coverage bar, test naming, no flaky patterns, and Vitest + Playwright conventions.
---

# Testing Standards

Every module must have meaningful tests. "The tests exist" is not sufficient — they must cover real behavior.

## What Must Be Tested

For every module, tests must cover:

| Path | Description |
|------|-------------|
| Happy path | Correct output for valid, expected input |
| Error path | Every error branch — invalid input, DB error, auth failure, network error |
| Empty/boundary | Empty arrays, zero quantities, null/undefined inputs, min/max values |
| Edge cases | Explicitly listed acceptance criteria from `docs/` |

For UI components specifically:
- Loading state renders skeleton / loading indicator
- Error state renders error message + retry action
- Empty state renders with next-action
- Async transitions (loading → success, loading → error)

## Test Split

```
Unit (Vitest)         → Pure functions, utilities, formatters, validators
Integration (Vitest)  → Components with testing-library, server actions with real-ish deps
E2E (Playwright)      → Full user flows in a real browser
```

Rule of thumb: test behavior at the lowest level that catches the bug. Don't default to e2e for logic that can be covered by a unit test.

## Coverage Bar

- Server actions and utility functions: **80% line coverage minimum**
- UI components: **meaningful behavior tests** (no coverage number for components — quality over percentage)
- Coverage is a floor, not a goal. 80% with meaningful tests beats 95% with `expect(true).toBe(true)`.

## Test Naming

```ts
// Pattern: it('should <behavior> when <condition>')
it('should return VALIDATION_ERROR when email is missing')
it('should disable submit button while form is pending')
it('should show skeleton rows while invoices are loading')
it('should surface server error at form level when action fails')
it('should preserve input values after a failed submission')
```

Describe blocks group by feature or component:

```ts
describe('InvoiceForm', () => {
  describe('submission', () => {
    it('should disable submit button while pending', ...)
    it('should show server error when action fails', ...)
    it('should reset form on success', ...)
  })
  describe('validation', () => {
    it('should show field error on blur when amount is negative', ...)
  })
})
```

## No Flaky Patterns

- No `setTimeout` or `sleep` in tests — use Playwright's `waitFor*` or Vitest's `vi.useFakeTimers()`
- No real network calls in unit/integration tests — mock at the fetch or Supabase client boundary
- No shared mutable state between tests — use `beforeEach` to reset
- No `Math.random()` or `Date.now()` without mocking — use `vi.setSystemTime()` / fixed seed

## Vitest Conventions

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, userEvent } from '@testing-library/react'

// Prefer userEvent over fireEvent for realistic interaction
const user = userEvent.setup()
await user.click(button)
await user.type(input, 'hello')

// Mock server actions
vi.mock('@/app/invoices/_actions', () => ({
  createInvoice: vi.fn(),
}))

// Reset mocks between tests
beforeEach(() => {
  vi.clearAllMocks()
})

// Assert on behavior, not implementation
expect(screen.getByRole('alert')).toHaveTextContent('Failed to save')
expect(screen.getByRole('button', { name: /save/i })).toBeDisabled()
```

Test file location: colocate with source.
```
src/app/invoices/_components/invoice-form.tsx
src/app/invoices/_components/invoice-form.test.tsx  ← here
```

## Playwright Conventions

```ts
import { test, expect } from '@playwright/test'

test('should create an invoice and redirect to invoice detail', async ({ page }) => {
  await page.goto('/invoices/new')
  await page.getByLabel('Client').selectOption('Acme Corp')
  await page.getByLabel('Amount').fill('1500')
  await page.getByRole('button', { name: 'Save Invoice' }).click()
  await expect(page).toHaveURL(/\/invoices\/[a-z0-9-]+/)
  await expect(page.getByRole('heading', { name: 'Invoice' })).toBeVisible()
})
```

- E2E tests live in `e2e/<module>/`
- Use a test DB or Supabase local — never hit production
- `page.getByRole` and `page.getByLabel` over CSS selectors — more resilient to UI changes
- Each test is independent — use `test.beforeEach` to seed DB state, not shared state

## What Is NOT Acceptable

- A test that only checks "it renders without crashing" (`expect(container).toBeTruthy()`)
- A test that only checks component snapshot without asserting anything meaningful
- Deleting a failing test instead of fixing the code
- Empty `it('...')` blocks (pending tests without bodies)
- Testing implementation details (internal state, private methods, component internals)

## Definition of Done

- [ ] Happy path test passes
- [ ] Error path tests cover every error branch in server actions
- [ ] Empty/boundary cases covered
- [ ] Edge cases from spec covered
- [ ] UI loading/error/empty states have assertions
- [ ] No `setTimeout`/`sleep` in tests
- [ ] No real network calls in unit/integration tests
- [ ] All tests pass (`vitest run` / `playwright test`)
- [ ] 80% line coverage on server actions and utilities
