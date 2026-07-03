---
name: coding-standards
description: House style enforced by all builder agents (web/mobile/api — whatever team-generator created for this project) and checked by the generated code reviewer. Covers naming, file organization, server vs client boundaries, TypeScript strictness, import order, colocation, and comment policy.
---

# Coding Standards

These are the house rules. All generated code must conform. No exceptions.

## TypeScript Strictness

- **No `any`**. Use `unknown` and narrow with `typeof`/`instanceof`/zod, or define an explicit type.
- **Explicit return types** on all exported functions and server actions.
- **No non-null assertion `!`** unless the invariant is documented with a comment explaining why it's safe.
- Enable `strict: true` in `tsconfig.json`. Do not weaken any strict flags.

```ts
// Bad
export async function getUser(id: any): Promise<any> { ... }

// Good
export async function getUser(id: string): Promise<User | null> { ... }
```

## File Organization

```
src/
├── app/                        # Next.js App Router
│   ├── (auth)/                 # Route group — auth pages
│   ├── (dashboard)/            # Route group — protected pages
│   │   ├── invoices/
│   │   │   ├── page.tsx        # Page (RSC by default)
│   │   │   ├── loading.tsx     # Loading UI (skeleton)
│   │   │   ├── error.tsx       # Error boundary
│   │   │   ├── _actions.ts     # Server actions for this route
│   │   │   └── _components/    # Components used only by this route
│   │   └── layout.tsx
│   └── api/                    # Route handlers (prefer server actions)
│       └── webhooks/
├── components/
│   ├── ui/                     # shadcn/ui generated components (do not edit)
│   └── <feature>/              # Shared feature components
├── lib/
│   ├── server/                 # Server-only utilities (never imported by client)
│   │   ├── supabase.ts         # Supabase server client
│   │   └── <domain>/
│   ├── env.ts                  # Typed env access (server-only)
│   └── utils.ts                # Shared pure utilities (safe for client)
├── db/
│   ├── schema/                 # Drizzle table definitions
│   └── index.ts                # DB client
└── types/
    └── index.ts                # Shared domain types
```

## Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Components | PascalCase | `InvoiceTable`, `UserAvatar` |
| Files (components) | kebab-case | `invoice-table.tsx`, `user-avatar.tsx` |
| Files (non-component) | kebab-case | `invoice-actions.ts`, `format-currency.ts` |
| Server actions | camelCase verbs | `createInvoice`, `deleteUser` |
| DB table names | snake_case | `invoice_line_items` |
| TypeScript types/interfaces | PascalCase | `Invoice`, `LineItem` |
| Constants | SCREAMING_SNAKE | `MAX_FILE_SIZE_MB` |
| Boolean props/vars | `is`/`has`/`can` prefix | `isLoading`, `hasError`, `canEdit` |

## Server vs Client Component Boundary

Default to React Server Components (RSC). Only add `"use client"` when the component:
- Uses `useState`, `useEffect`, `useReducer`, or any other React hook
- Uses browser APIs (`window`, `document`, `localStorage`)
- Uses event handlers attached to DOM elements
- Uses a library that is client-only (e.g., charting lib, animation lib)

```tsx
// Good: stays server, fetches its own data
// app/invoices/page.tsx
export default async function InvoicesPage() {
  const invoices = await getInvoices() // server fetch
  return <InvoiceTable invoices={invoices} />
}

// Good: only the interactive part is client
// _components/invoice-table.tsx
"use client"
export function InvoiceTable({ invoices }: { invoices: Invoice[] }) { ... }
```

Never prop-drill fetched data through multiple client boundaries — the RSC should pass it directly to the nearest client component that needs it.

## Import Order

Enforce with ESLint `import/order`. Order:
1. React (`import React from 'react'`)
2. Next.js (`next/navigation`, `next/image`, etc.)
3. Third-party libraries (`zod`, `drizzle-orm`, shadcn/ui, etc.)
4. Internal absolute (`@/lib/...`, `@/components/...`, `@/db/...`, `@/types/...`)
5. Relative (`./`, `../`)

Blank line between each group.

## Colocation

- Component-specific hooks live beside the component: `invoice-table.tsx` → `use-invoice-table.ts`
- Component-specific types live in the component file or a colocated `types.ts`
- Shared utilities that 3+ modules use move to `lib/utils.ts` or `lib/<domain>.ts`
- Do not create `lib/` files for single-use utilities

## Comment Policy

Write no comments by default. Comments are for:
1. A hidden constraint not obvious from the code (external API quirk, browser bug workaround)
2. A non-obvious invariant that must be maintained
3. The "why" behind a surprising decision

Never comment:
- What the code does (the code does that)
- Who wrote it or when ("added for invoice refactor")
- TODO/FIXME (use GitHub issues)

One short line maximum. No multi-line comment blocks.

```ts
// Bad
// This function gets the user from the database
async function getUser(id: string) { ... }

// Good (the why is non-obvious)
// Supabase returns null instead of throwing for missing rows — normalize to throw here
async function getUser(id: string): Promise<User> {
  const user = await db.query.users.findFirst({ where: eq(users.id, id) })
  if (!user) throw new NotFoundError('User not found')
  return user
}
```

---

## React Native / Expo — Additional Rules

These apply to mobile-builder in addition to all rules above.

### File Organization (Expo Router)

```
app/                         # Expo Router file-based routes
├── _layout.tsx              # Root layout
├── (auth)/
│   ├── _layout.tsx
│   ├── login.tsx
│   └── register.tsx
├── (tabs)/
│   ├── _layout.tsx
│   ├── home.tsx
│   └── profile.tsx
└── [id].tsx                 # Dynamic segment

components/
├── ui/                      # Reusable primitive components
└── <feature>/               # Feature-scoped components

lib/
├── api/                     # API client functions
└── utils.ts                 # Shared utilities
```

### Naming — Mobile Specifics

| Thing | Convention | Example |
|-------|-----------|---------|
| Screens | PascalCase component, kebab file | `HomeScreen` in `home.tsx` |
| Native event handlers | `handle` prefix | `handlePress`, `handleChangeText` |
| Refs | `Ref` suffix | `inputRef`, `listRef` |

### Import Order (RN)

1. React (`import React from 'react'`)
2. React Native (`react-native`, `expo-*`)
3. Expo Router (`expo-router`)
4. Third-party (`react-native-reanimated`, `@shopify/flash-list`, etc.)
5. Internal absolute (`@/lib/...`, `@/components/...`)
6. Relative (`./`, `../`)

### Hard Rules (mobile)

- No `console.log` in committed code — use a logger utility
- No hardcoded colors (hex/rgb) in component files — NativeWind theme tokens only
- No `StyleSheet.create` where NativeWind suffices
- No `ScrollView` + `.map()` for lists with unknown/dynamic length
- `Platform.OS` checks only for genuinely different behavior (never for style differences)

---

## Checklist

### Web
- [ ] No `any` — every type is explicit
- [ ] Exported functions have explicit return types
- [ ] `"use client"` only where necessary (interactivity / browser API)
- [ ] RSC fetches its own data; no prop-drilling through client boundaries
- [ ] File and component names follow conventions
- [ ] Import order matches the 5-group rule
- [ ] Component-specific utils/hooks colocated with the component
- [ ] Comments only for non-obvious WHY — never for WHAT

### Mobile (additional)
- [ ] No `console.log` in committed code
- [ ] No hardcoded colors in component files
- [ ] No `StyleSheet.create` where NativeWind covers it
- [ ] No `ScrollView` + `.map()` for dynamic lists
- [ ] `Platform.OS` used only for behavioral differences
