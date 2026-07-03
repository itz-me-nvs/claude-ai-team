---
name: accessibility-standards
description: WCAG 2.2 AA baseline enforced by frontend-builder on all UI; checked by a11y-auditor. Covers semantic HTML, keyboard access, focus management, ARIA, labels, color contrast, reduced-motion, and touch target sizes. This is the reference document for what a11y-auditor checks against.
---

# Accessibility Standards — WCAG 2.2 AA Baseline

All UI components must meet WCAG 2.2 Level AA. These are non-negotiable requirements, not suggestions.

## 1. Semantic HTML First (WCAG 1.3.1)

Use native HTML elements before reaching for ARIA. Native elements have built-in keyboard behavior, roles, and states that ARIA must replicate manually.

| Do | Don't |
|----|-------|
| `<button>` | `<div role="button" onClick tabIndex={0}>` |
| `<nav>` | `<div role="navigation">` |
| `<h1>`–`<h6>` | `<div className="text-2xl font-bold">` |
| `<ul><li>` | `<div><div>` for lists |
| `<table><th><td>` | CSS grids for tabular data |
| `<form>` | `<div>` for form containers |
| `<fieldset><legend>` | Unlabeled groups of related inputs |

Heading hierarchy must be logical (h1 → h2 → h3, no skipping).

## 2. Keyboard Accessibility (WCAG 2.1.1)

- Every interactive element reachable and operable via keyboard alone
- Tab moves focus forward; Shift+Tab moves backward
- Enter/Space activates buttons and checkboxes
- Arrow keys navigate within widgets (menus, tabs, sliders, radio groups)
- Escape closes modals, dropdowns, and tooltips

Custom widgets must implement the correct [ARIA keyboard patterns](https://www.w3.org/WAI/ARIA/apg/patterns/):
- Combobox: arrow keys navigate options, Enter selects, Escape closes
- Tabs: arrow keys switch tabs (not Tab key, which moves to panel content)
- Modal dialog: Tab cycles within, Escape closes, focus returns to trigger

## 3. Focus Management (WCAG 2.4.3, 2.4.7)

**Visible focus**: Never `outline: none` without a custom replacement. The focused element must be visually distinct.

```css
/* Tailwind: use focus-visible ring, not focus */
className="focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
```

**Focus trapping**: Modal/dialog must trap focus. Tab from last element wraps to first; Shift+Tab from first wraps to last.

**Focus restoration**: When a modal or panel closes, focus returns to the element that triggered it.

**Step/route transitions**: On step change in a wizard, move focus to the new step's heading or first input. On route change, move focus to `<main>` or page heading.

```tsx
// After step transition
stepHeadingRef.current?.focus()
```

## 4. ARIA — Only Where Needed (WCAG 4.1.2)

ARIA augments HTML — it does not fix bad HTML. First, use the correct native element. Then, add ARIA if the semantics are still insufficient.

**Required ARIA patterns:**

```tsx
// Async content updates
<div aria-live="polite" aria-atomic="true">
  {statusMessage}
</div>

// Errors (immediate announcement)
<div role="alert">
  {errorMessage}
</div>

// Loading state on container
<div aria-busy={isLoading} aria-label="Loading invoices">
  ...
</div>

// Icon-only button
<button aria-label="Delete invoice">
  <Trash2 aria-hidden="true" />
</button>

// Toggle button
<button aria-expanded={isOpen} aria-controls="dropdown-id">
  Options
</button>
<div id="dropdown-id" hidden={!isOpen}>...</div>

// Invalid input
<input
  aria-invalid={!!error}
  aria-describedby={error ? 'field-error' : undefined}
/>
<p id="field-error" role="alert">{error}</p>
```

**Never:**
- `aria-label` on an element that already has a visible text label
- `role` on a native element that already has the correct implicit role
- `aria-hidden="true"` on focusable elements

## 5. Labels & Associations (WCAG 1.3.1, 2.4.6)

- Every input has a visible `<label>` with `htmlFor` matching the input's `id`
- Placeholder text is supplementary — never a replacement for a label
- Required fields: mark with `aria-required="true"` AND a visible indicator (asterisk + legend explaining it)
- Group of related inputs: wrap in `<fieldset>` with `<legend>`

## 6. Color & Contrast (WCAG 1.4.1, 1.4.3)

- Normal text: 4.5:1 contrast ratio minimum against its background
- Large text (18px+ regular or 14px+ bold): 3:1 minimum
- UI components and state indicators: 3:1 minimum
- **Color alone must not convey meaning**: errors use icon + text + color; success uses icon + text + color

Flag in code review: any `text-red-*` / `border-red-*` used as the sole error indicator without a text label or icon.

## 7. Reduced Motion (WCAG 2.3.3)

All animations and transitions must respect the user's motion preference.

```tsx
// Tailwind
className="transition-all duration-300 motion-reduce:transition-none motion-reduce:duration-0"

// CSS
@media (prefers-reduced-motion: reduce) {
  .animated { animation: none; transition: none; }
}
```

Disable: auto-playing carousels, parallax, large-scale motion. Keep: opacity fades (not position-based), single-frame icon swaps.

## 8. Touch Target Size (WCAG 2.5.8)

- Minimum: 24×24 CSS px for any interactive target
- Preferred for primary actions: 44×44 CSS px
- If a target is smaller than 44×44, ensure adequate spacing around it (no other targets within 24px)

```tsx
// Minimum for icon buttons in dense UIs
className="h-8 w-8 flex items-center justify-center"

// Preferred for primary actions
className="h-11 px-8"
```

## Audit Checklist (used by a11y-auditor)

- [ ] Native HTML used for all standard elements (no div-soup)
- [ ] All interactive elements keyboard-reachable and operable
- [ ] Focus visible on all interactive elements
- [ ] Focus managed on route/step changes and modal open/close
- [ ] ARIA used correctly and only where needed
- [ ] `aria-live`/`role="alert"` on all async state regions
- [ ] All inputs have associated visible labels
- [ ] Required fields marked visually and with `aria-required`
- [ ] Color not the sole indicator of meaning
- [ ] Animations respect `prefers-reduced-motion`
- [ ] Interactive targets ≥24×24px
