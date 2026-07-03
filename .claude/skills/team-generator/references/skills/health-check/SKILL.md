---
name: health-check
description: >
  Post-build health check for full-stack projects built with the claude-ai-team workflow.
  Verifies frontend and backend are both running correctly after Phase 8 (Ship) completes.
  Use when the user says "health check", "check the app is healthy", "verify frontend and backend",
  "run health check", "is the app working?", "check after deploy", or "post-deploy verification".
  Covers: server reachability, HTTP status codes, API routes, Supabase connectivity,
  environment variables, build output, TypeScript compilation, and key page rendering.
---

# Health Check

Post-deployment health verification for Next.js + Supabase stack.

## What Gets Checked

**Frontend**
- Dev/prod server responds (HTTP 200 on `/`)
- Key pages render without 500 errors
- TypeScript compilation clean (`tsc --noEmit`)
- Build output exists (`.next/` for Next.js)

**Backend / API**
- API routes respond (HTTP 200 or expected status)
- Supabase connection live (ping via REST or client)
- Required env vars present (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, etc.)
- No unhandled server errors in recent logs

## Workflow

### Step 1 — Discover project structure
```bash
# Find server start command
cat package.json | grep -E '"dev"|"start"|"build"'
# Find API routes
find . -path "*/app/api/*/route.ts" -o -path "*/pages/api/*.ts" | head -20
# Find env file
ls -la .env* 2>/dev/null
```

### Step 2 — Run automated checks
Execute `scripts/health_check.sh` from the skill. Pass the base URL as `$1` (default: `http://localhost:3000`).

```bash
bash ~/.claude/skills/health-check/scripts/health_check.sh http://localhost:3000
```

### Step 3 — Check TypeScript + build
```bash
npx tsc --noEmit 2>&1 | tail -20
ls -la .next/ 2>/dev/null || echo "No build output — run next build"
```

### Step 4 — Verify Supabase
```bash
# Confirm env vars set
grep -E "SUPABASE_URL|SUPABASE_ANON_KEY|SUPABASE_SERVICE" .env* 2>/dev/null | sed 's/=.*/=<set>/'
```
If vars missing → flag Critical. If set → test connectivity via curl against the Supabase REST endpoint.

### Step 5 — Report

Produce a table:

| Check | Status | Notes |
|-------|--------|-------|
| Frontend `/` | ✅ 200 / ❌ ERR | |
| API `/api/health` | ✅ 200 / ❌ ERR | |
| TypeScript | ✅ Clean / ❌ N errors | |
| Supabase env | ✅ Set / ❌ Missing | list missing vars |
| Supabase ping | ✅ OK / ❌ ERR | |
| Build output | ✅ Exists / ⚠️ Missing | |

Severity:
- **Critical** — server down, Supabase unreachable, missing env vars, TS errors > 0
- **Warning** — build output missing (dev-only context), slow response (>2s)
- **OK** — all checks pass

## Adapting to Non-Default Ports / Monorepos
- Frontend on different port → detect from `package.json` scripts or ask user
- Separate backend service → run checks against both URLs
- Mobile (Expo) → skip frontend HTTP checks; verify API + Supabase only

## See `scripts/health_check.sh`

Automated curl-based HTTP checks for frontend pages and API routes.
