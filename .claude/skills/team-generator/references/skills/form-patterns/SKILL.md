---
name: form-patterns
description: Enforced by frontend-builder on every form component; checked by code-reviewer and a11y-auditor. Covers submit state, validation, error display, server error surfacing, input preservation, and accessibility associations.
---

# Form Patterns

Every form in the application must follow these patterns. No exceptions.

## Submit State Management

```tsx
// Submit button must reflect pending state
<Button type="submit" disabled={isPending}>
  {isPending ? (
    <>
      <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
      Saving...
    </>
  ) : (
    'Save'
  )}
</Button>
```

- `disabled` while the action is in-flight — prevents double-submit
- Button text changes to communicate pending (not just a spinner icon)
- `aria-hidden` on decorative spinner icon

## Validation

- **On blur**: validate individual fields when the user leaves them
- **On submit**: re-validate all fields before submission
- Use React Hook Form with a zod resolver — do not write manual validation logic

```tsx
const form = useForm<FormSchema>({
  resolver: zodResolver(formSchema),
  defaultValues: { ... },
})
```

## Field-Level Error Display

- Error message appears directly below the field it belongs to
- Use shadcn/ui `<FormMessage />` or equivalent
- Associate via `aria-describedby`: the input's `id` and the error element's `id` must be linked

```tsx
<FormField
  control={form.control}
  name="email"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Email</FormLabel>
      <FormControl>
        <Input
          {...field}
          aria-describedby="email-error"
          aria-invalid={!!form.formState.errors.email}
        />
      </FormControl>
      <FormMessage id="email-error" />
    </FormItem>
  )}
/>
```

## Server Error Surfacing

Server errors must appear at the form level, not only in a toast.

```tsx
// After failed server action:
{serverError && (
  <div role="alert" className="text-destructive text-sm">
    {serverError}
  </div>
)}
```

- Toast is acceptable as a supplementary notification, never the sole channel
- The error message must persist until the user attempts another submission
- If the server returns field-level errors (e.g., "email already taken"), set them on the specific field with `form.setError('email', { message: '...' })`

## Input Preservation on Failure

- Never reset the form on server error — the user should see their input and fix the problem
- Only reset on **success** (or navigate away on success)
- Use `form.reset()` only in the success handler

```tsx
const onSubmit = async (values: FormSchema) => {
  const result = await createRecord(values)
  if (!result.success) {
    setServerError(result.error.message)
    // Do NOT call form.reset() here
    return
  }
  form.reset()
  router.push('/success')
}
```

## Accessibility Checklist

- [ ] Every input has a visible `<label>` associated via `htmlFor` / `FormLabel`
- [ ] Placeholder is supplementary only — never the sole label
- [ ] Required fields marked with `aria-required="true"` and a visible indicator
- [ ] `aria-invalid="true"` on inputs with errors
- [ ] `aria-describedby` links input to its error message element
- [ ] Server error container has `role="alert"`
- [ ] Submit button disabled and shows pending state while in-flight
- [ ] Focus returns to the form (or first error field) after a server error

## Definition of Done

- [ ] Submit button disabled + shows pending state while in-flight
- [ ] Validation on blur per field
- [ ] Validation on submit (all fields)
- [ ] Field-level errors displayed inline below each field
- [ ] Server errors displayed at form level with `role="alert"`
- [ ] User input preserved on server error
- [ ] All a11y requirements above met
- [ ] Typecheck passes
