---
name: security-standards
description: Enforced by api-integrator on all server-side code; checked by security-auditor. Covers auth/authorization at every boundary, input validation, secrets handling, Supabase RLS, XSS/injection prevention, file uploads, and dependency hygiene. This is the reference document for what security-auditor checks against.
---

# Security Standards

All server-side code must meet these requirements. Violations are Critical findings.

## 1. Authentication & Authorization — First, Always

Auth check is the first line of every server action and route handler. No exceptions.

```ts
// Server action
export async function deleteInvoice(id: string): Promise<ActionResult<void>> {
  // Step 1: auth
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) {
    return { success: false, error: { code: 'UNAUTHORIZED', message: 'Authentication required.' } }
  }

  // Step 2: ownership/authorization
  const invoice = await db.query.invoices.findFirst({
    where: and(eq(invoices.id, id), eq(invoices.userId, user.id)), // ownership check
  })
  if (!invoice) {
    return { success: false, error: { code: 'NOT_FOUND', message: 'Invoice not found.' } }
  }

  // Step 3: logic
  await db.delete(invoices).where(eq(invoices.id, id))
  return { success: true, data: undefined }
}
```

Rules:
- Never trust a client-supplied user ID — always derive from the server session
- Ownership check (user can only access their own data) is mandatory for user-scoped resources
- Role-based access: if the spec defines roles (admin, member, viewer), enforce the required role explicitly

## 2. Input Validation at Every Boundary

Every server action, route handler, and webhook handler validates all inputs with zod before any processing.

```ts
const schema = z.object({
  amount: z.number().positive().max(1_000_000),
  currency: z.enum(['USD', 'EUR', 'GBP']),
  description: z.string().min(1).max(1000).trim(),
})

const parsed = schema.safeParse(rawInput)
if (!parsed.success) return validationError(parsed.error)
```

- Validate at the entry point — do not pass raw input down and validate later
- `safeParse` not `parse` — handle the error shape explicitly
- Validate webhook payloads (including signature verification before parsing body)

## 3. Secrets & Environment Variables

| Rule | Detail |
|------|--------|
| No `NEXT_PUBLIC_` on secrets | `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, `RESEND_API_KEY` — server-only |
| No hardcoded secrets | No API keys, tokens, or passwords in source code or git history |
| Typed env access | Use `lib/env.ts` — fail fast at startup if a required env var is missing |
| No secrets in logs | Never `console.log(req.headers)`, never log full request bodies containing tokens |
| `.env.local` not committed | `.gitignore` must exclude all `.env*` files except `.env.example` |

```ts
// lib/env.ts — server-only (import only from server files)
import { z } from 'zod'

const envSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
})

export const env = envSchema.parse(process.env)
```

## 4. Injection Prevention

**SQL injection**: Drizzle ORM parameterizes all queries. Never build SQL strings manually.

```ts
// Never
await db.execute(sql`SELECT * FROM users WHERE email = '${email}'`) // WRONG

// Always
await db.query.users.findFirst({ where: eq(users.email, email) }) // correct
```

**NoSQL injection**: Not applicable (Drizzle/SQL), but sanitize any dynamic query filters.

**Command injection**: Never `exec`, `spawn`, or `eval` with user-supplied data.

**SSRF**: If constructing URLs from user input for outbound HTTP calls, validate against an allowlist of allowed hosts:

```ts
const ALLOWED_WEBHOOK_HOSTS = ['hooks.stripe.com', 'api.sendgrid.com']
const url = new URL(userSuppliedUrl)
if (!ALLOWED_WEBHOOK_HOSTS.includes(url.hostname)) {
  throw new Error('Disallowed webhook host')
}
```

## 5. XSS Prevention

- React escapes JSX content by default — do not bypass this
- `dangerouslySetInnerHTML` is banned unless the content is sanitized with DOMPurify server-side
- Never render user-supplied URLs in `href` without validation — check for `javascript:` scheme:

```ts
function isSafeUrl(url: string): boolean {
  try {
    const parsed = new URL(url)
    return ['https:', 'http:'].includes(parsed.protocol)
  } catch {
    return false
  }
}
```

## 6. Supabase RLS

- RLS is a defense-in-depth layer, not the primary authorization mechanism — enforce auth in code first
- Every table accessed by users must have RLS policies enabled
- Use the anon/user Supabase client for user operations; service role key only for admin/background tasks
- Never create a server action that uses the service role key to bypass RLS for user-facing operations

```ts
// lib/server/supabase.ts
import { createServerClient } from '@supabase/ssr'
// cookies() call — user context, respects RLS
export function createClient() { ... }

// lib/server/supabase-admin.ts
import { createClient } from '@supabase/supabase-js'
// service role — bypasses RLS, use only for admin tasks
export const supabaseAdmin = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY)
```

## 7. File Uploads

- Validate MIME type server-side (not just file extension — extensions are user-controlled)
- Enforce file size limits server-side
- Store in Supabase Storage — never write to local disk in serverless environments
- Generate a random storage key — do not use the original filename (path traversal risk)

```ts
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'application/pdf']
if (!ALLOWED_TYPES.includes(file.type)) {
  return { success: false, error: { code: 'INVALID_FILE_TYPE', message: 'Only JPEG, PNG, and PDF files are allowed.' } }
}
if (file.size > 10 * 1024 * 1024) { // 10MB
  return { success: false, error: { code: 'FILE_TOO_LARGE', message: 'File must be under 10MB.' } }
}
const storageKey = `${user.id}/${crypto.randomUUID()}`
```

## 8. Open Redirects

Never redirect to a user-supplied URL without validation:

```ts
// After login, validate the ?next= param
const next = searchParams.get('next') ?? '/dashboard'
const safeNext = next.startsWith('/') && !next.startsWith('//') ? next : '/dashboard'
redirect(safeNext)
```

## 9. Dependency Hygiene

- Run `npm audit` / `pnpm audit` in CI — fail on high/critical CVEs
- Do not add dependencies with no maintenance activity in 12+ months unless there is no alternative
- Pin direct dependencies; let the lockfile manage transitive versions

## Audit Checklist (used by security-auditor)

- [ ] Auth check is first in every server action and route handler
- [ ] Ownership check prevents cross-user data access
- [ ] All inputs validated with zod before any processing
- [ ] No server-only secrets with `NEXT_PUBLIC_` prefix
- [ ] No hardcoded credentials in source
- [ ] Drizzle ORM used for all DB queries (no raw string SQL with user data)
- [ ] No `dangerouslySetInnerHTML` with unsanitized user content
- [ ] User-supplied URLs validated before redirect or outbound fetch
- [ ] File uploads: MIME type + size validated server-side
- [ ] Supabase service role used only for admin tasks
- [ ] RLS enabled on all user-scoped tables
