---
name: harness-react
description: Use when you write or change React components, hooks, or React tests, including Next.js and other React frameworks.
---

# React

Applies together with the Node and Web stack sections.

## Version and framework
- Check the React version and the framework in `package.json` first.
  React 19: `ref` is a normal prop (no `forwardRef` needed), and `use`, `useActionState`, `useOptimistic` exist. React 18 does not have them.
- If the React Compiler is enabled, do not add `useMemo`, `useCallback`, or `memo` by hand.
- Server Components (Next.js App Router and others): hooks and browser APIs work only in files with `"use client"`.
  Keep `"use client"` at the smallest component that needs it.

## Components and state
- Use function components and hooks. Follow the rules of hooks. Keep `eslint-plugin-react-hooks` errors at zero.
- Keep state minimal. Compute derived values during render. Do not copy props into state.
- Use stable, unique `key` values. Do not use the array index for lists that can reorder.

## Effects
- Do not use an effect to compute derived data or to handle an event. Do the work in render or in the event handler.
- Each effect that subscribes, sets a timer, or fetches needs a cleanup.
- List all dependencies. Do not silence the lint rule.
- Server data: use the data library of the project (TanStack Query, SWR, framework loaders). Do not add a new `fetch` in `useEffect`.

## Security and accessibility
- Do not use `dangerouslySetInnerHTML` with untrusted data. Sanitize with the library of the project if it is necessary.
- Use semantic elements. A clickable element is a `button` or `a`, not a `div`.
- Each input has a label. Images have `alt` text. Keyboard access works.

## Tests
- Use React Testing Library. Query by role and accessible name. Use `user-event` for interactions.
- Test behavior that the user sees. Do not test internal state or implementation details.
