---
name: mobile-accessibility-standards
description: >
  React Native / Expo accessibility standards for VoiceOver (iOS) and TalkBack (Android).
  Covers accessibilityRole, accessibilityLabel, accessibilityState, focus management,
  AccessibilityInfo API, touch targets, and reduced-motion.
  Invoke on every mobile UI implementation — non-negotiable baseline.
  Triggers: "mobile a11y", "RN accessibility", "VoiceOver", "TalkBack", "mobile screen reader".
---

# Mobile Accessibility Standards — React Native

All screens and components must be usable with VoiceOver (iOS) and TalkBack (Android). These are non-negotiable requirements.

---

## 1. accessibilityRole (mandatory on interactive elements)

Every touchable element must declare its role.

```tsx
// Buttons
<Pressable accessibilityRole="button" accessibilityLabel="Submit form">
  <Text>Submit</Text>
</Pressable>

// Links / navigation
<Pressable accessibilityRole="link" accessibilityLabel="Go to profile">
  <Text>Profile</Text>
</Pressable>

// Checkboxes
<Pressable
  accessibilityRole="checkbox"
  accessibilityLabel="Remember me"
  accessibilityState={{ checked: isChecked }}
>
  <Checkbox checked={isChecked} />
</Pressable>

// Images (decorative)
<Image accessibilityRole="image" accessibilityLabel="User profile photo" />
// OR — decorative only:
<Image accessible={false} importantForAccessibility="no" />

// Section headings
<Text accessibilityRole="header" className="text-2xl font-bold">
  My Orders
</Text>
```

**Role reference:**
| Element | Role |
|---------|------|
| Action buttons | `"button"` |
| Navigation items | `"link"` |
| Screen/section headings | `"header"` |
| Checkboxes | `"checkbox"` |
| Radio buttons | `"radio"` |
| Toggle/switch | `"switch"` |
| Text inputs | `"none"` (TextInput is already accessible) |
| Images with meaning | `"image"` |
| Alert/error text | `"alert"` |

---

## 2. accessibilityLabel

Every element a screen reader focuses must have a meaningful label.

```tsx
// Icon-only button — label is mandatory
<Pressable accessibilityRole="button" accessibilityLabel="Delete item">
  <Trash2 size={20} />
</Pressable>

// Image
<Image
  source={{ uri: avatarUrl }}
  accessibilityLabel={`${user.name}'s profile photo`}
/>

// Combined text elements — group them
<View accessible={true} accessibilityLabel={`Order #${order.id}, total $${order.total}, placed ${order.date}`}>
  <Text>#{order.id}</Text>
  <Text>${order.total}</Text>
  <Text>{order.date}</Text>
</View>
```

Rules:
- Label describes the **action** for buttons ("Delete", "Submit"), **content** for informational elements
- Never use "click", "tap", "button" in labels — screen readers announce the role separately
- Visible text label means `accessibilityLabel` is optional (SR reads the text child automatically)
- Icon-only: always requires `accessibilityLabel`

---

## 3. accessibilityState

Communicate dynamic state changes.

```tsx
// Disabled
<Pressable
  disabled={isLoading}
  accessibilityState={{ disabled: isLoading }}
  accessibilityLabel="Save"
>

// Selected (tabs, list items)
<Pressable
  accessibilityState={{ selected: isActive }}
  accessibilityRole="button"
>

// Expanded (accordion, dropdown)
<Pressable
  accessibilityState={{ expanded: isOpen }}
  accessibilityLabel={`${section.title}, ${isOpen ? 'collapse' : 'expand'}`}
>

// Checked
<Pressable
  accessibilityRole="checkbox"
  accessibilityState={{ checked: isChecked }}
>

// Loading / busy
<View accessibilityLiveRegion="polite" accessibilityLabel="Loading orders">
  {isLoading ? <ActivityIndicator /> : <OrderList />}
</View>
```

---

## 4. accessibilityHint

Use when the result of an action is non-obvious.

```tsx
<Pressable
  accessibilityRole="button"
  accessibilityLabel="Continue"
  accessibilityHint="Moves to step 2 of 4 in the checkout process"
>
```

Do not use hint to repeat the label. Only for non-obvious outcomes.

---

## 5. Live Regions (async updates)

Announce dynamic content changes to screen readers.

```tsx
// Polite — announces when SR is idle
<View accessibilityLiveRegion="polite">
  {statusMessage && <Text>{statusMessage}</Text>}
</View>

// Assertive — interrupts (use sparingly: only for errors or critical alerts)
<View accessibilityLiveRegion="assertive">
  {errorMessage && (
    <Text accessibilityRole="alert" className="text-destructive">
      {errorMessage}
    </Text>
  )}
</View>
```

---

## 6. Focus Management

```tsx
import { AccessibilityInfo, findNodeHandle } from 'react-native'

// Move focus to a specific element (modal open, step change, screen mount)
const headingRef = useRef<View>(null)

useEffect(() => {
  const handle = findNodeHandle(headingRef.current)
  if (handle) {
    AccessibilityInfo.setAccessibilityFocus(handle)
  }
}, [])

<View ref={headingRef} accessible={true} accessibilityRole="header">
  <Text className="text-xl font-bold">Checkout — Step 2</Text>
</View>
```

When to move focus:
- Modal or bottom sheet opens → focus first element inside
- Wizard step changes → focus step heading or first input
- Error appears after form submit → focus error summary
- Screen mounts after navigation → focus page heading

---

## 7. AccessibilityInfo API

```tsx
import { AccessibilityInfo } from 'react-native'

// Check if screen reader is running
const [isScreenReaderEnabled, setIsScreenReaderEnabled] = useState(false)

useEffect(() => {
  AccessibilityInfo.isScreenReaderEnabled().then(setIsScreenReaderEnabled)
  const sub = AccessibilityInfo.addEventListener('screenReaderChanged', setIsScreenReaderEnabled)
  return () => sub.remove()
}, [])

// Announce a message programmatically (e.g. after an async action)
AccessibilityInfo.announceForAccessibility('Your order has been placed.')
```

---

## 8. Touch Target Size

Minimum 44×44 CSS points on iOS; 48×48 dp on Android. Use the larger (44pt) as your baseline.

```tsx
// Primary actions
className="h-12 w-12 items-center justify-center"  // 48pt — preferred

// Dense UI (icon buttons in toolbars)
className="h-11 w-11 items-center justify-center"  // 44pt — minimum

// If visually smaller, use hitSlop
<Pressable hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}>
  <Icon size={20} />
</Pressable>
```

Never render interactive targets smaller than 44×44 without `hitSlop` compensation.

---

## 9. Reduced Motion

```tsx
import { AccessibilityInfo } from 'react-native'
import { useReducedMotion } from 'react-native-reanimated'

// react-native-reanimated hook
function AnimatedCard() {
  const reduceMotion = useReducedMotion()

  const entering = reduceMotion ? undefined : FadeInDown.duration(300)

  return (
    <Animated.View entering={entering}>
      {/* content */}
    </Animated.View>
  )
}
```

Disable position-based animations when reduce-motion is on. Opacity fades are acceptable.

---

## 10. Text Input Accessibility

```tsx
<TextInput
  accessible={true}
  accessibilityLabel="Email address"
  accessibilityHint="Enter the email you used to register"
  placeholder="you@example.com"
  // Functional attributes
  keyboardType="email-address"
  autoCapitalize="none"
  autoComplete="email"
  autoCorrect={false}
  returnKeyType="next"
  onSubmitEditing={() => passwordRef.current?.focus()}
/>
```

Rules:
- Every TextInput needs `accessibilityLabel` (visible label element above it is NOT automatically associated in RN)
- `keyboardType` and `autoComplete` always set — helps SR users and everyone
- Chain fields with `returnKeyType` + `onSubmitEditing`

---

## Audit Checklist (used by mobile-auditor)

- [ ] All Pressable/TouchableOpacity have `accessibilityRole`
- [ ] All Pressable/TouchableOpacity have `accessibilityLabel` (or visible text child)
- [ ] Icon-only touchables always have `accessibilityLabel`
- [ ] `accessibilityState` set for disabled/selected/checked/expanded elements
- [ ] `accessibilityLiveRegion` on async-updating containers
- [ ] Errors use `accessibilityRole="alert"` or `accessibilityLiveRegion="assertive"`
- [ ] Focus managed on modal open, step change, and error appearance
- [ ] All TextInputs have `accessibilityLabel`
- [ ] Touch targets ≥44×44pt (or `hitSlop` compensation)
- [ ] Animations respect reduced-motion preference
- [ ] Decorative images use `accessible={false}` or `importantForAccessibility="no"`
