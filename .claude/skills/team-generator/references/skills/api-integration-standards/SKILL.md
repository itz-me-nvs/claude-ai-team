---
name: api-integration-standards
description: Enforced by api-integrator on all server actions, route handlers, and third-party integrations; checked by code-reviewer and security-auditor. Covers typed I/O with zod, consistent error shapes, error surfacing, retries, timeouts, idempotency, and auth requirements.
---

# API Integration Standards

All server actions, route handlers, and third-party integrations must follow these standards.

## Typed I/O — Zod at Every Boundary

Every server action and route handler validates its inputs with zod before any logic runs.

```ts
import { z } from 'zod'

const createInvoiceSchema = z.object({
  clientId: z.string().uuid(),
  amount: z.number().positive(),
  dueDate: z.string().datetime(),
  lineItems: z.array(z.object({
    description: z.string().min(1).max(500),
    quantity: z.number().positive().int(),
    unitPrice: z.number().positive(),
  })).min(1),
})

export async function createInvoice(input: unknown): Promise<ActionResult<Invoice>> {
  const parsed = createInvoiceSchema.safeParse(input)
  if (!parsed.success) {
    return { success: false, error: { code: 'VALIDATION_ERROR', message: 'Invalid input', fields: formatZodErrors(parsed.error) } }
  }
  // proceed with parsed.data (typed)
}
```

Output types are always explicit — never `any` or implicit inferred return.

## Consistent Error Shape

All server actions return this shape. UI code can rely on it unconditionally.

```ts
// Success
type ActionSuccess<T> = { success: true; data: T }

// Failure
type ActionError = {
  success: false
  error: {
    code: string          // machine-readable: 'VALIDATION_ERROR' | 'NOT_FOUND' | 'UNAUTHORIZED' | 'INTERNAL'
    message: string       // human-readable, safe to display
    fields?: Record<string, string>  // field-level errors for form binding
  }
}

type ActionResult<T> = ActionSuccess<T> | ActionError
```

Never throw exceptions to the UI layer — catch internally and return the error shape.

```ts
export async function createInvoice(input: unknown): Promise<ActionResult<Invoice>> {
  try {
    // ... logic
    return { success: true, data: invoice }
  } catch (err) {
    console.error('[createInvoice]', err) // server log only
    return { success: false, error: { code: 'INTERNAL', message: 'Failed to create invoice. Please try again.' } }
  }
}
```

## Loading / Error Surfacing to UI

Server actions must return enough context for the UI to show the right state:

- **Field errors** (`fields` map) → UI calls `form.setError(field, { message })` per field
- **Form-level errors** (no `fields`) → UI renders a `role="alert"` error banner
- **Success** → UI navigates, resets form, or updates optimistic state

See `form-patterns` and `ui-state-gate` for the UI side of this contract.

## Retries & Timeouts (External HTTP Calls)

All calls to third-party services must have timeouts. Retries for transient failures are expected.

```ts
async function fetchWithRetry(url: string, options: RequestInit, maxAttempts = 3): Promise<Response> {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const response = await fetch(url, {
      ...options,
      signal: AbortSignal.timeout(10_000), // 10 second timeout per attempt
    })
    if (response.ok || attempt === maxAttempts) return response
    if (response.status >= 500 || response.status === 429) {
      await new Promise(r => setTimeout(r, Math.min(1000 * 2 ** attempt, 10_000)))
      continue
    }
    return response // 4xx client errors: don't retry
  }
  throw new Error('Unreachable')
}
```

- Timeout: 10 seconds default; reduce for latency-sensitive paths
- Retries: 3 attempts with exponential backoff for 5xx and 429
- Do NOT retry 4xx (client errors) — fix the request instead
- Surface 429 to the UI: "Service temporarily unavailable. Try again in a moment."

## Idempotency

For operations that must not run twice (payments, email sends, webhook acknowledgements):

- Include an idempotency key in the request (UUID generated client-side, stored in session/DB)
- Check if the operation was already completed before executing
- Return the existing result if already done

```ts
const idempotencyKey = crypto.randomUUID() // generated once, stored in form state
await stripe.paymentIntents.create({ amount, currency, idempotencyKey })
```

## Auth on Every Action/Route

Auth check must be the first thing in every server action and route handler — before validation, before DB access.

```ts
export async function deleteInvoice(id: string): Promise<ActionResult<void>> {
  const { user } = await getServerSession() // or Supabase auth.getUser()
  if (!user) {
    return { success: false, error: { code: 'UNAUTHORIZED', message: 'You must be signed in.' } }
  }
  // proceed
}
```

## Rate Limit Handling

- Respect `Retry-After` headers from third-party APIs
- Surface rate limit errors clearly to the UI (not as generic "something went wrong")
- For our own API routes, apply rate limiting with `upstash/ratelimit` or equivalent per architecture

## No Secrets Client-Side

- `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, `RESEND_API_KEY` — server-only, never `NEXT_PUBLIC_`
- Never pass secret values through server actions back to the client — only return what the UI needs
- Use `lib/env.ts` for typed env access:

```ts
// lib/env.ts (server-only)
export const env = {
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY!,
  stripeSecretKey: process.env.STRIPE_SECRET_KEY!,
} as const
```

## Checklist

- [ ] Every input validated with zod before logic
- [ ] Return type is explicit `ActionResult<T>`
- [ ] No `any` in input or output types
- [ ] All errors caught and returned as typed error shape (no unhandled throw)
- [ ] Auth check is first line of every action/route
- [ ] External HTTP calls have timeout + retry
- [ ] Idempotency keys used for non-idempotent external mutations
- [ ] No secrets in client-accessible code
- [ ] Rate limit errors surfaced clearly to UI
