---
name: mobile-security-standards
description: >
  React Native / Expo security standards enforced by mobile-builder on all mobile code;
  checked by mobile-auditor and security-auditor for mobile modules. Covers secure token
  storage (expo-secure-store), secrets in app config, EXPO_PUBLIC_ env rules, deep-link
  validation, network security, auth session handling, sensitive-screen protection,
  WebView hardening, and OWASP MASVS alignment. Invoke on every mobile implementation
  slice that touches auth, storage, networking, deep links, or user data.
  Triggers: "mobile security", "RN security", "secure storage", "token storage",
  "deep link security", "MASVS", "mobile auth".
---

# Mobile Security Standards

All React Native / Expo code must meet these requirements. Violations are Critical findings.
Aligned with OWASP MASVS (Mobile Application Security Verification Standard).

## 1. Secure Storage — Never AsyncStorage for Secrets

AsyncStorage is plaintext on disk. Any secret in it is readable on a rooted/jailbroken device or from a device backup.

| Data | Storage |
|------|---------|
| Auth tokens, refresh tokens, session keys | `expo-secure-store` (Keychain/Keystore) |
| Biometric-gated secrets | `expo-secure-store` with `requireAuthentication: true` |
| User preferences, cache, non-sensitive state | AsyncStorage / MMKV fine |
| PII (email, phone) at rest | Prefer server-side; if cached locally, SecureStore |

```ts
// lib/secure-storage.ts
import * as SecureStore from 'expo-secure-store'

export async function saveToken(key: string, value: string) {
  await SecureStore.setItemAsync(key, value, {
    keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
  })
}
```

Supabase auth on mobile: pass a SecureStore adapter, never the default AsyncStorage:

```ts
import { createClient } from '@supabase/supabase-js'
import * as SecureStore from 'expo-secure-store'

const SecureStoreAdapter = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
}

export const supabase = createClient(url, anonKey, {
  auth: { storage: SecureStoreAdapter, autoRefreshToken: true, persistSession: true },
})
```

Note: SecureStore has a ~2KB value limit per key. Large sessions: encrypt with a SecureStore-held key, store ciphertext in AsyncStorage (`aes-js` / `expo-crypto` pattern).

## 2. Secrets & Environment Variables

- **`EXPO_PUBLIC_*` vars are compiled into the JS bundle** — extractable from any distributed app binary. Only truly public values (Supabase URL, anon key, analytics write key).
- No server secrets in the app, ever: no service-role keys, no Stripe secret keys, no admin API tokens. If a flow needs a secret, it goes through your backend.
- No secrets in `app.json` / `app.config.ts` `extra` — that config ships in the bundle too.
- EAS builds: secrets used at build time go in EAS Secrets (`eas secret:create`), not committed `.env`.
- `.env*` files gitignored except `.env.example`.

```bash
# Audit: what leaks into the bundle
grep -rn "EXPO_PUBLIC_" .env* app.config.* app.json
```

## 3. Network Security

- HTTPS only. No `http://` endpoints in production code. Expo blocks cleartext by default (ATS on iOS, `usesCleartextTraffic=false` on Android) — never override for production.
- Auth token sent via `Authorization` header, never in URL query params (URLs land in logs/analytics).
- Certificate pinning: consider for high-value targets (fintech, health). `expo-build-properties` + native pinning config. Document the rotation plan before enabling — pinning with no rotation plan bricks the app when certs rotate.
- Never log request/response bodies containing tokens or PII — including to Sentry/analytics breadcrumbs.

## 4. Deep Links & App Links

Deep links are attacker-controllable input. Any app can register the same custom scheme (`myapp://`).

- Validate and sanitize all deep-link params before use — treat like untrusted user input.
- Never perform privileged actions (delete, pay, share) directly from a deep-link param without an in-app confirmation step.
- Auth screens: if a deep link carries a `redirect`/`next` param, allowlist internal routes only.
- Prefer verified links for auth flows: iOS Universal Links + Android App Links (verified domain) over custom schemes.
- Auth callback (magic link / OAuth): validate the token server-side via Supabase `exchangeCodeForSession` — never trust link contents alone.

```ts
// Expo Router deep-link param validation
const params = useLocalSearchParams()
const id = z.string().uuid().safeParse(params.id)
if (!id.success) return <Redirect href="/" />
```

## 5. Authentication & Session

- Auth state from Supabase session, never from a locally cached "isLoggedIn" flag alone.
- Protected route groups in Expo Router: gate `(app)` group on session in root layout; redirect to `(auth)` when absent.
- Sign-out must clear SecureStore tokens AND call `supabase.auth.signOut()` (revokes refresh token server-side).
- Biometrics (`expo-local-authentication`) are a local convenience gate, not authentication — server auth still comes from the token. Never mint a session from a biometric result alone.
- Token refresh: rely on `autoRefreshToken`; wire `AppState` listener to `startAutoRefresh`/`stopAutoRefresh` per Supabase RN docs.

## 6. Sensitive Screen Protection

For screens showing payment data, health data, or other sensitive PII:

- Hide content in app switcher / prevent screenshots: `expo-screen-capture` (`preventScreenCaptureAsync`) on those screens; release on blur.
- Mask sensitive fields by default (card numbers, tokens) with explicit reveal action.
- `secureTextEntry` on password inputs; `autoComplete`/`textContentType` set correctly so password managers work (users pick weaker passwords otherwise).
- Clear sensitive state on unmount; don't keep decrypted secrets in global stores longer than needed.

## 7. WebView Hardening

Avoid WebView where possible. When required (`react-native-webview`):

- Load only allowlisted origins: set `originWhitelist`, validate `source.uri`.
- `javaScriptEnabled` only if the page needs it; never inject user-controlled strings via `injectedJavaScript`.
- Validate all `onMessage` payloads with zod — the page is untrusted input.
- Never expose tokens to the WebView via URL or injected globals.

## 8. Platform & Build Hygiene

- No `console.log` of user data in committed code; strip logs in production builds (`babel-plugin-transform-remove-console` or guard on `__DEV__`).
- Root/jailbreak detection: only for high-risk apps (fintech/health) — it's friction, not a security boundary. If required, `jail-monkey` or Play Integrity API, and degrade gracefully.
- OTA updates (expo-updates / EAS Update): updates are code-signed by EAS; do not disable signature verification. Treat update channel access as a production credential.
- Keep Expo SDK current — SDK upgrades carry native security patches. Don't ship on an SDK version past its support window.
- `npx expo-doctor` and `npm audit` in CI; fail on high/critical CVEs.

## 9. Data Minimization

- Request permissions (camera, location, contacts) lazily, at point of use, with pre-permission rationale UI.
- Collect only what the feature needs; no location tracking "for later".
- User deletion flow must clear local SecureStore/AsyncStorage data, not just the server account.

## Audit Checklist (used by mobile-auditor / security-auditor)

- [ ] No tokens/secrets in AsyncStorage — SecureStore adapter wired into Supabase client
- [ ] No server secrets in `EXPO_PUBLIC_*`, `app.json`, or `app.config.ts`
- [ ] All endpoints HTTPS; no cleartext overrides
- [ ] Tokens in headers, never URLs; never logged
- [ ] Deep-link params validated (zod) before use; redirect params allowlisted
- [ ] Protected route groups gated on real session, not cached flag
- [ ] Sign-out clears SecureStore + server-side revocation
- [ ] Sensitive screens: screenshot prevention + field masking where spec requires
- [ ] WebView (if any): origin allowlist, validated `onMessage`, no token exposure
- [ ] No `console.log` of user data; logs stripped in production
- [ ] Permissions requested at point of use only
