---
name: stepper-wizard-patterns
description: Enforced by frontend-builder on every multi-step form or wizard flow; checked by code-reviewer and a11y-auditor. Covers step validation, data preservation, progress persistence, progress indicators, review steps, and per-step async state handling.
---

# Stepper / Wizard Patterns

Every multi-step form or wizard must follow these patterns.

## Step Validation Gate

"Next" is disabled until the current step is valid. Never allow advancing with invalid data.

```tsx
const canAdvance = await form.trigger(currentStepFields)
if (!canAdvance) return // do not advance

// Or with a disabled button:
<Button
  onClick={handleNext}
  disabled={!form.formState.isValid || isPending}
>
  Next
</Button>
```

- Use `form.trigger(fieldNames)` to validate only the current step's fields on "Next"
- Show field errors inline (see `form-patterns`) when the user tries to advance with errors
- The final "Submit" button triggers full-form validation

## Back Never Loses Data

The "Back" button must never clear or reset fields from the current or any previous step.

```tsx
// State lives at the wizard level, not per-step
const [formData, setFormData] = useState<Partial<WizardSchema>>({})

// On step completion, merge (not replace)
const handleStepComplete = (stepData: Partial<WizardSchema>) => {
  setFormData(prev => ({ ...prev, ...stepData }))
  setCurrentStep(prev => prev + 1)
}

// On back
const handleBack = () => {
  setCurrentStep(prev => prev - 1)
  // formData unchanged — previous step pre-fills from formData
}
```

- Each step reads its default values from the shared `formData` state
- Going back pre-fills the previous step's form with the already-entered values

## Progress Persistence Across Refresh

Persist wizard progress to prevent loss on accidental refresh.

- **Default**: use URL search params (`?step=2`) for the current step — free, linkable, back-button compatible
- **With form data**: use `sessionStorage` for draft data (not `localStorage` — clears on tab close)
- **With server draft**: save progress server-side (preferred for complex/long wizards) and restore on mount

```tsx
// URL-based step persistence
const searchParams = useSearchParams()
const router = useRouter()
const currentStep = parseInt(searchParams.get('step') ?? '1')

const goToStep = (step: number) => {
  const params = new URLSearchParams(searchParams)
  params.set('step', String(step))
  router.replace(`?${params.toString()}`)
}
```

## Progress Indicator

Every wizard must show a clear progress indicator.

```tsx
// Minimum: step count
<p aria-live="polite" aria-atomic="true">
  Step {currentStep} of {totalSteps}: {stepTitle}
</p>

// Required: visual step indicator using shadcn primitives only — no custom step components
<StepIndicator
  steps={steps}
  currentStep={currentStep}
  aria-label="Checkout progress"
/>
```

- `aria-live="polite"` + `aria-atomic="true"` on the step counter so screen readers announce step changes
- Completed steps should be visually distinct from upcoming steps
- Do not rely on color alone to show completion state

## Final Review Step

Before the final submission, always show a review step summarizing the user's input.

```tsx
// Last step before submit
<ReviewStep data={formData}>
  <dl>
    {Object.entries(formData).map(([key, value]) => (
      <div key={key}>
        <dt>{fieldLabels[key]}</dt>
        <dd>{String(value)}</dd>
      </div>
    ))}
  </dl>
  <Button type="submit" disabled={isPending}>
    {isPending ? 'Submitting...' : 'Confirm and Submit'}
  </Button>
</ReviewStep>
```

- User can go back from the review step to edit any section
- Review step is read-only — no editing inline (go back to edit)
- Submit button on review step handles the final server action with full form data

## Per-Step Async State Handling

Each step that performs an async operation (save draft, validate server-side, fetch options) handles its own loading/error states.

```tsx
// Step with async validation
{isValidating && <Loader2 className="animate-spin" aria-label="Validating..." />}
{stepError && (
  <div role="alert" className="text-destructive text-sm">
    {stepError}
  </div>
)}
```

- Never block all steps behind a single global loading state if only one step is async
- Error from one step must not silently carry over to the next

## Accessibility Checklist

- [ ] Step counter has `aria-live="polite"` + `aria-atomic="true"`
- [ ] Navigation buttons (Next/Back) have descriptive labels
- [ ] Focus moves to the top of the new step content on step transition (use `ref.focus()`)
- [ ] Errors on "Next" attempt are announced via `role="alert"`
- [ ] Review step content uses semantic `<dl>/<dt>/<dd>` or equivalent structured markup

## Definition of Done

- [ ] "Next" validates current step fields and blocks advancement on error
- [ ] "Back" preserves all entered data
- [ ] Progress persists across page refresh (URL params or sessionStorage)
- [ ] Progress indicator shows current step, total steps, and step title
- [ ] Final review step present before submission
- [ ] Each step handles its own loading/error states
- [ ] A11y checklist above complete
- [ ] Typecheck passes
