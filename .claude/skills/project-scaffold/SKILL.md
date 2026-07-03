---
name: project-scaffold
description: >
  Bootstrap a new project with the correct stack scaffold and claude-ai-team workflow files.
  Triggered when user says "create project", "setup project", "new project named X", or
  "use claude-ai-team to setup". Detects stack from user message and runs the right init commands.
  Always installs latest versions. Never asks for confirmation before scaffolding.
---

# Project Scaffold Skill

## When to Invoke

User mentions a project name + stack + wants claude-ai-team setup. Examples:
- "new project 'Atlas', it's a Next.js app, use claude-ai-team"
- "create project XYZ react native app"
- "setup flutter project called Foo"

---

## Step 1 — Detect Stack

Parse user message for stack keyword:

| Keyword(s) | Stack |
|-----------|-------|
| `next`, `nextjs`, `next.js` | Next.js |
| `react` (no next/native) | React (Vite) |
| `react native`, `react-native`, `rn` | React Native + Expo |
| `expo` | React Native + Expo |
| `flutter` | Flutter |

If ambiguous → ask: "React (Vite SPA) or Next.js?"

---

## Step 2 — Scaffold Commands

### Next.js (App Router + shadcn)

```bash
npx create-next-app@latest <project-name> \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --use-npm

cd <project-name>

# Init shadcn with Next.js template (skips prompts, auto-configures for App Router)
npx shadcn@latest init -t next
```

**What `-t next` does:**
- Sets style: New York, base color: Zinc, CSS variables: yes
- Writes `components.json` configured for Next.js App Router
- Adds `cn` util, base CSS vars, and `@/components/ui` path automatically
- No interactive prompts — fully non-interactive

**Troubleshooting:**
- If init hangs or fails → run `npx shadcn@latest init` (interactive fallback, answer prompts manually)
- If Tailwind CSS v4 conflict → shadcn@latest supports v4 natively; ensure `globals.css` has `@import "tailwindcss"` not `@tailwind` directives
- If `components.json` already exists → add `--force` flag to overwrite

Add commonly needed shadcn components:
```bash
npx shadcn@latest add button card input label form select textarea badge avatar separator skeleton toast
```

---

### React (Vite SPA)

```bash
npm create vite@latest <project-name> -- --template react-ts

cd <project-name>
npm install

# Tailwind CSS v4
npm install tailwindcss @tailwindcss/vite

# Path alias support
npm install -D @types/node
```

Update `vite.config.ts`:
```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
})
```

Add to `src/index.css`:
```css
@import "tailwindcss";
```

---

### React Native + Expo

```bash
npx create-expo-app@latest <project-name> --template blank-typescript

cd <project-name>

# NativeWind v4
npm install nativewind tailwindcss
npx tailwindcss init

# Expo Router
npx expo install expo-router react-native-safe-area-context react-native-screens \
  expo-linking expo-constants expo-status-bar

# Common extras
npx expo install expo-image expo-font expo-splash-screen
npm install react-native-reanimated react-native-gesture-handler
```

Update `babel.config.js`:
```js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: ['nativewind/babel'],
  };
};
```

Update `tailwind.config.js`:
```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,jsx,ts,tsx}', './components/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: { extend: {} },
  plugins: [],
};
```

Add `app/_layout.tsx` as entry with `<Stack>` from expo-router.

---

### Flutter

```bash
flutter create <project_name>
cd <project_name>
flutter pub get
```

Add common packages to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^14.0.0       # navigation
  flutter_riverpod: ^2.6.0 # state management
  dio: ^5.7.0               # HTTP client
  shared_preferences: ^2.3.0
  flutter_svg: ^2.0.0
```

```bash
flutter pub get
flutter run
```

---

## Step 3 — Copy claude-ai-team Workflow Files (basics only)

After scaffold, copy these from `/projects/Personal/claude-ai-team` into the new project root:

```bash
# From master repo — basics + team-generator (with its references/ exemplars,
# so runtime gap-fill works without the master repo).
cp /projects/Personal/claude-ai-team/orchestrator.md <project-name>/orchestrator.md
mkdir -p <project-name>/.claude/agents <project-name>/.claude/skills
cp /projects/Personal/claude-ai-team/.claude/agents/*.md <project-name>/.claude/agents/
for s in checkpoint coding-standards discovery-interview doc-agent skill-operator team-generator; do
  cp -r /projects/Personal/claude-ai-team/.claude/skills/$s <project-name>/.claude/skills/$s
done
cp -r /projects/Personal/claude-ai-team/specs <project-name>/specs
mkdir -p <project-name>/docs
```

Do NOT copy `project-scaffold` into the project — it runs FROM the master repo.
No stack-specific agents/skills are copied — they are GENERATED in Step 5.

---

## Step 4 — Generate CLAUDE.md

Create `CLAUDE.md` in project root with both required sections (per orchestrator `## Project CLAUDE.md Setup`):

```markdown
# CLAUDE.md

## Project: <Project Name>

**What it does:** <one paragraph — fill from user's description>
**Stack:** <detected stack>
**Key modules:** TBD — defined after PRD/SRS
**Users:** TBD — defined after PRD/SRS
**Out of scope:** TBD
**Docs:** `docs/prd.md`, `docs/architecture.md`

## AI Team

This project uses the Claude AI agentic workflow scaffold.
Workflow constitution: `orchestrator.md` — read before any project work.

### Agents
| Role | Agent | Phase |
|------|-------|-------|
| Plan | spec-analyst | Phase 1 |
| Architecture | architect | Phase 2 |
| Research | tech-researcher | Phase 3 |
<!-- filled by team-generator in Step 5 -->

### Gate Skills
<!-- filled by team-generator in Step 5 -->

### Token Efficiency
All agents use `caveman` skill (full level). ~75% token reduction on all communication.
```

---

## Step 5 — Generate the Team

Invoke the `team-generator` skill. It reads the detected stack + project
description, generates stack-matched builder/verifier agents and gate skills
into `<project-name>/.claude/`, and fills the Agents table + Gate Skills
section of the project `CLAUDE.md` with what was actually created.

---

## Step 6 — Report to User

After scaffold completes, output:

```
Project: <name>
Stack: <stack>
Location: <path>
Scaffold: done
claude-ai-team basics: copied
Team generated: <agents list> / <skills list>
CLAUDE.md: generated

Next: say "create PRD" → Flow 1, or paste existing doc → Flow 2
```

---

## Version Pinning Policy

- Never hardcode version numbers in commands (use `@latest` / `@latest` flags)
- Exception: if user specifies an exact version, use it
- Flutter: always run `flutter upgrade` advice if flutter SDK version unknown
