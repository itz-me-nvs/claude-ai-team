---
name: mobile-builder-standards
description: >
  Technical standards for mobile-builder agent in Phase 5 of the claude-ai-team workflow.
  Covers Expo project setup, NativeWind v4 config, Expo Router navigation, platform-specific
  rules, image handling, and animation standards.
  Invoke at the start of every mobile implementation slice — before writing any screen or component code.
  Triggers: "mobile build", "Phase 5 mobile", "implement screen", "build RN component", "Expo implementation".
---

# Mobile Builder Standards

Stack: **React Native + Expo (SDK 52+) + TypeScript + NativeWind v4 + Expo Router**

---

## Step 1 — Project Setup Check

```bash
# Check Expo version
cat package.json | grep '"expo"'

# Check NativeWind installed
cat package.json | grep nativewind

# Check Expo Router
cat package.json | grep expo-router
```

### New Expo Project
```bash
npx create-expo-app@latest my-app --template blank-typescript
cd my-app
npx expo install nativewind tailwindcss expo-router
```

### NativeWind v4 Config

`tailwind.config.js`:
```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        primary: '#your-brand-color',
        // Add design tokens here
      },
    },
  },
  plugins: [],
}
```

`babel.config.js`:
```js
module.exports = function (api) {
  api.cache(true)
  return {
    presets: [
      ['babel-preset-expo', { jsxImportSource: 'nativewind' }],
      'nativewind/babel',
    ],
  }
}
```

`global.css` (import in root `_layout.tsx`):
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

`metro.config.js`:
```js
const { getDefaultConfig } = require('expo/metro-config')
const { withNativeWind } = require('nativewind/metro')

const config = getDefaultConfig(__dirname)
module.exports = withNativeWind(config, { input: './global.css' })
```

Root `app/_layout.tsx`:
```tsx
import '../global.css'
import { Stack } from 'expo-router'

export default function RootLayout() {
  return <Stack />
}
```

---

## Step 2 — Expo Router Navigation

File-based routing. Every file in `app/` is a route.

```
app/
├── _layout.tsx          # Root layout (Stack / Tabs)
├── index.tsx            # / (home)
├── (auth)/
│   ├── _layout.tsx      # Auth stack
│   ├── login.tsx        # /login
│   └── register.tsx     # /register
├── (tabs)/
│   ├── _layout.tsx      # Tab bar layout
│   ├── home.tsx         # /home tab
│   └── profile.tsx      # /profile tab
└── modal.tsx            # Modal screen
```

### Typed Navigation
```tsx
import { router, Link, useLocalSearchParams } from 'expo-router'

// Navigate
router.push('/profile')
router.replace('/(auth)/login')
router.back()

// Link component
<Link href="/profile">Profile</Link>

// Typed params
const { id } = useLocalSearchParams<{ id: string }>()
```

### Tab Layout
```tsx
import { Tabs } from 'expo-router'
import { Home, User } from 'lucide-react-native'

export default function TabLayout() {
  return (
    <Tabs screenOptions={{ tabBarActiveTintColor: '#primary' }}>
      <Tabs.Screen
        name="home"
        options={{ title: 'Home', tabBarIcon: ({ color }) => <Home color={color} size={24} /> }}
      />
      <Tabs.Screen
        name="profile"
        options={{ title: 'Profile', tabBarIcon: ({ color }) => <User color={color} size={24} /> }}
      />
    </Tabs>
  )
}
```

---

## Step 3 — Core Component Rules

### Safe Area (mandatory on every root screen)
```tsx
import { SafeAreaView } from 'react-native-safe-area-context'

export default function HomeScreen() {
  return (
    <SafeAreaView className="flex-1 bg-background">
      {/* content */}
    </SafeAreaView>
  )
}
```

### Keyboard Avoidance (mandatory on all forms)
```tsx
import { KeyboardAvoidingView, Platform, ScrollView } from 'react-native'

<KeyboardAvoidingView
  className="flex-1"
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
>
  <ScrollView keyboardShouldPersistTaps="handled">
    {/* form fields */}
  </ScrollView>
</KeyboardAvoidingView>
```

### Lists (FlatList / FlashList)
```tsx
import { FlatList } from 'react-native'
// OR for large lists:
import { FlashList } from '@shopify/flash-list'

const renderItem = useCallback(({ item }: { item: MyItem }) => (
  <MyItemCard item={item} />
), [])

const keyExtractor = useCallback((item: MyItem) => item.id, [])

<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={keyExtractor}
  contentContainerStyle={{ paddingBottom: 16 }}
  ListEmptyComponent={<EmptyState />}
/>
```

### Images
```tsx
import { Image } from 'expo-image'

<Image
  source={{ uri: imageUrl }}
  className="h-48 w-full"
  contentFit="cover"
  transition={200}
  placeholder={blurhash}
/>
```

---

## Step 4 — Animations

```tsx
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  FadeIn,
  FadeOut,
} from 'react-native-reanimated'

// Layout animation (auto-animate layout changes)
<Animated.View entering={FadeIn} exiting={FadeOut}>
  {content}
</Animated.View>

// Gesture-driven animation
const offset = useSharedValue(0)
const animatedStyle = useAnimatedStyle(() => ({
  transform: [{ translateX: offset.value }],
}))
```

Never use `Animated` from `react-native` for complex or gesture-driven animations — use `react-native-reanimated`.

---

## Step 5 — NativeWind Class Patterns

```tsx
// Layout
className="flex-1 flex-row items-center justify-between px-4 py-3"

// Typography
className="text-base font-medium text-foreground"
className="text-sm text-muted-foreground"

// Cards
className="rounded-xl bg-card p-4 shadow-sm"

// Buttons
className="h-12 rounded-lg bg-primary items-center justify-center px-6"
className="text-base font-semibold text-primary-foreground"

// Platform variants
className="pt-4 ios:pt-6 android:pt-3"
```

---

## Hard Rules

- Never `StyleSheet.create` for styling that NativeWind covers
- Never hardcode hex/rgb colors — use NativeWind theme tokens
- Never `ScrollView` + `.map()` for dynamic lists with unknown length
- Never `console.log` in committed code
- `SafeAreaView` on every root screen — no exceptions
- `KeyboardAvoidingView` on every form screen — no exceptions
- No `any` TypeScript types
