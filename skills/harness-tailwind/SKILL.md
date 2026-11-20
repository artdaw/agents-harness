---
name: harness-tailwind
description: Use when you write or change Tailwind CSS classes, theme tokens, or Tailwind config.
---

# Tailwind CSS

Applies together with the Web stack section. Check the Tailwind version in `package.json` first.

## v3 and v4 differences
- v4 config is CSS-first: tokens in `@theme`, custom utilities in `@utility`, variants in `@custom-variant`. v3 uses `tailwind.config.js`.
- v4 renamed utilities. In v4 use: `shadow-xs` (v3 `shadow-sm`), `shadow-sm` (v3 `shadow`), `rounded-sm` (v3 `rounded`),
  `outline-hidden` (v3 `outline-none`), `shrink-*` and `grow-*` (v3 `flex-shrink-*`, `flex-grow-*`).
- v4 removed `bg-opacity-*` and similar. Use the opacity modifier: `bg-black/50`.
- v4 `ring` is 1px (v3: 3px). The default border color is `currentColor`.
- CSS variable in a class: v4 `bg-(--brand)`, v3 `bg-[--brand]`. Important modifier: v4 `bg-red-500!`, v3 `!bg-red-500`.
- Do not mix v3 and v4 syntax.

## Classes
- Write full class names in source. Do not build them with string concatenation (`bg-${color}-500`). The scanner does not find them.
  Map values to full class names instead.
- Use theme tokens. Use arbitrary values (`w-[37px]`) only when no token fits.
- Merge conditional classes with the helper of the project (`cn`, `clsx`, `tailwind-merge`). Do not add a new helper.
- Use `@apply` only where the project already does.
- If the Prettier Tailwind plugin is configured, let it sort the classes.

## Accessibility
- Do not remove the focus outline without a visible replacement. Use `focus-visible:` styles.
- Keep text contrast at WCAG AA or better.
- Use `sr-only` for text that only screen readers need. Use `motion-reduce:` for large animations.
