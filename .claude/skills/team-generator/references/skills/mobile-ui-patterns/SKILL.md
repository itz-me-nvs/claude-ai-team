---
name: mobile-ui-patterns
description: >
  UI state patterns for React Native / Expo — loading skeletons, empty states, error handling,
  form patterns, gesture interactions, pull-to-refresh, and infinite scroll.
  Invoke before implementing any screen or list component in a mobile module.
  Triggers: "mobile UI", "RN screen", "mobile list", "mobile form", "pull to refresh", "mobile states".
---

# Mobile UI Patterns

## 1. Loading States

Never show a blank screen. Always provide a meaningful skeleton.

```tsx
// Skeleton using NativeWind + Animated
import Animated, { useSharedValue, useAnimatedStyle, withRepeat, withTiming } from 'react-native-reanimated'

function SkeletonBox({ className }: { className?: string }) {
  const opacity = useSharedValue(1)
  const animatedStyle = useAnimatedStyle(() => ({ opacity: opacity.value }))

  React.useEffect(() => {
    opacity.value = withRepeat(withTiming(0.4, { duration: 700 }), -1, true)
  }, [])

  return <Animated.View className={`rounded-md bg-muted ${className}`} style={animatedStyle} />
}

// Usage in screen
function CardSkeleton() {
  return (
    <View className="rounded-xl bg-card p-4 gap-3">
      <SkeletonBox className="h-4 w-3/4" />
      <SkeletonBox className="h-4 w-1/2" />
      <SkeletonBox className="h-32 w-full" />
    </View>
  )
}
```

For `ActivityIndicator` (inline micro-loads only):
```tsx
<ActivityIndicator size="small" color="#primary" />
```

---

## 2. Error States

```tsx
function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <View className="flex-1 items-center justify-center px-6 gap-4">
      <AlertCircle size={48} className="text-destructive" />
      <Text className="text-base text-foreground text-center">{message}</Text>
      <Pressable
        onPress={onRetry}
        className="rounded-lg bg-primary px-6 py-3"
        accessibilityRole="button"
        accessibilityLabel="Retry"
      >
        <Text className="text-primary-foreground font-semibold">Try Again</Text>
      </Pressable>
    </View>
  )
}
```

---

## 3. Empty States

```tsx
function EmptyState({ title, description, action }: {
  title: string
  description: string
  action?: { label: string; onPress: () => void }
}) {
  return (
    <View className="flex-1 items-center justify-center px-8 gap-3">
      <Inbox size={56} className="text-muted-foreground" />
      <Text className="text-lg font-semibold text-foreground text-center">{title}</Text>
      <Text className="text-sm text-muted-foreground text-center">{description}</Text>
      {action && (
        <Pressable
          onPress={action.onPress}
          className="mt-2 rounded-lg bg-primary px-6 py-3"
          accessibilityRole="button"
        >
          <Text className="text-primary-foreground font-semibold">{action.label}</Text>
        </Pressable>
      )}
    </View>
  )
}
```

---

## 4. FlatList with All States

```tsx
function ItemList({ items, isLoading, error, onRetry, onRefresh, isRefreshing }: Props) {
  if (isLoading) {
    return (
      <FlatList
        data={Array(5).fill(null)}
        keyExtractor={(_, i) => `skeleton-${i}`}
        renderItem={() => <CardSkeleton />}
        contentContainerClassName="gap-3 px-4 py-3"
      />
    )
  }

  if (error) {
    return <ErrorState message={error} onRetry={onRetry} />
  }

  return (
    <FlatList
      data={items}
      keyExtractor={useCallback((item: Item) => item.id, [])}
      renderItem={useCallback(({ item }) => <ItemCard item={item} />, [])}
      ListEmptyComponent={
        <EmptyState
          title="No items yet"
          description="Items you add will appear here."
        />
      }
      refreshControl={
        <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />
      }
      contentContainerClassName="gap-3 px-4 py-3"
      contentContainerStyle={{ flexGrow: 1 }}
    />
  )
}
```

---

## 5. Infinite Scroll

```tsx
<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={keyExtractor}
  onEndReached={fetchNextPage}
  onEndReachedThreshold={0.3}
  ListFooterComponent={
    isFetchingNextPage ? (
      <ActivityIndicator className="py-4" />
    ) : null
  }
/>
```

---

## 6. Forms

```tsx
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email('Enter a valid email'),
  password: z.string().min(8, 'At least 8 characters'),
})

function LoginForm({ onSubmit }: { onSubmit: (data: z.infer<typeof schema>) => Promise<void> }) {
  const { control, handleSubmit, formState: { errors, isSubmitting } } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '' },
  })

  return (
    <KeyboardAvoidingView
      className="flex-1"
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView keyboardShouldPersistTaps="handled" contentContainerClassName="px-4 gap-4">
        <Controller
          control={control}
          name="email"
          render={({ field: { onChange, onBlur, value } }) => (
            <View className="gap-1">
              <Text className="text-sm font-medium text-foreground">Email</Text>
              <TextInput
                className={`h-12 rounded-lg border px-4 text-foreground bg-background ${
                  errors.email ? 'border-destructive' : 'border-border'
                }`}
                onChangeText={onChange}
                onBlur={onBlur}
                value={value}
                keyboardType="email-address"
                autoCapitalize="none"
                autoComplete="email"
                accessibilityLabel="Email"
                accessibilityHint="Enter your email address"
              />
              {errors.email && (
                <Text
                  className="text-xs text-destructive"
                  accessibilityRole="alert"
                >
                  {errors.email.message}
                </Text>
              )}
            </View>
          )}
        />

        <Pressable
          onPress={handleSubmit(onSubmit)}
          disabled={isSubmitting}
          className="h-12 rounded-lg bg-primary items-center justify-center disabled:opacity-60"
          accessibilityRole="button"
          accessibilityLabel={isSubmitting ? 'Signing in...' : 'Sign In'}
          accessibilityState={{ disabled: isSubmitting }}
        >
          {isSubmitting ? (
            <ActivityIndicator color="white" />
          ) : (
            <Text className="text-base font-semibold text-primary-foreground">Sign In</Text>
          )}
        </Pressable>
      </ScrollView>
    </KeyboardAvoidingView>
  )
}
```

### Form Rules
- Disable submit while pending
- Field-level errors directly below each field
- Server errors shown at form level (not toast-only)
- Preserve user input on server error — never reset on failure
- `autoComplete`, `autoCapitalize`, `keyboardType` on every TextInput
- `returnKeyType="next"` + `onSubmitEditing` to chain fields

---

## 7. Pull-to-Refresh

```tsx
const [isRefreshing, setIsRefreshing] = useState(false)

const onRefresh = useCallback(async () => {
  setIsRefreshing(true)
  await refetch()
  setIsRefreshing(false)
}, [refetch])

<FlatList
  refreshControl={
    <RefreshControl
      refreshing={isRefreshing}
      onRefresh={onRefresh}
      tintColor="#primary"    // iOS
      colors={['#primary']}   // Android
    />
  }
/>
```

---

## 8. Gestures (Swipe to Delete / Action)

```tsx
import { Swipeable } from 'react-native-gesture-handler'

function SwipeableItem({ item, onDelete }: Props) {
  const renderRightActions = useCallback(() => (
    <Pressable
      onPress={() => onDelete(item.id)}
      className="bg-destructive w-20 items-center justify-center rounded-r-xl"
      accessibilityRole="button"
      accessibilityLabel={`Delete ${item.title}`}
    >
      <Trash2 size={20} color="white" />
    </Pressable>
  ), [item.id, item.title, onDelete])

  return (
    <Swipeable renderRightActions={renderRightActions}>
      <ItemCard item={item} />
    </Swipeable>
  )
}
```

---

## 9. Bottom Sheet / Modal

```tsx
import BottomSheet, { BottomSheetView } from '@gorhom/bottom-sheet'

const snapPoints = useMemo(() => ['25%', '50%', '75%'], [])
const bottomSheetRef = useRef<BottomSheet>(null)

<BottomSheet
  ref={bottomSheetRef}
  index={-1}
  snapPoints={snapPoints}
  enablePanDownToClose
  backdropComponent={BottomSheetBackdrop}
>
  <BottomSheetView className="px-4 pb-8">
    {/* content */}
  </BottomSheetView>
</BottomSheet>
```

---

## Checklist

- [ ] Loading state: skeleton (not blank screen, not lone spinner)
- [ ] Error state: message + retry action
- [ ] Empty state: context-aware message + next action
- [ ] Lists use FlatList/FlashList (not ScrollView + map)
- [ ] renderItem and keyExtractor wrapped in useCallback
- [ ] Forms use react-hook-form + zod
- [ ] Submit button disabled + shows indicator when pending
- [ ] Server errors shown at form level
- [ ] Pull-to-refresh on all list screens
- [ ] Infinite scroll on paginated lists
