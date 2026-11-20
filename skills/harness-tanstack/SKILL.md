---
name: harness-tanstack
description: Use when you write or change code that uses TanStack Query, Router, Start, Table, Form, or Virtual.
---

# TanStack

Check which TanStack packages and versions the project uses. Read the docs for that version.

## Query (v5)
- Use the object signature: `useQuery({ queryKey, queryFn })`.
- v5 names: `gcTime` (v4 `cacheTime`), `isPending` (v4 `isLoading` for "no data yet"), `placeholderData: keepPreviousData` (v4 `keepPreviousData: true`).
  `useQuery` has no `onSuccess`, `onError`, or `onSettled` callbacks in v5.
- The query key is an array. It includes every variable that `queryFn` uses. Use the key factory of the project if it has one.
- `queryFn` must throw on failure. `fetch` does not throw on 4xx and 5xx. Check `response.ok`.
- Do not copy query data into `useState`. Read it from the query.
- After a mutation, invalidate the related queries: `queryClient.invalidateQueries({ queryKey })`.
  Optimistic update: save the old data in `onMutate` and roll back in `onError`.
- `staleTime` is 0 by default. Set it on purpose when data does not change often.
- SSR: create one `QueryClient` per request. Never share it between users.
- Use `@tanstack/eslint-plugin-query` if the project has it.

## Router and Start
- Do not edit the generated route tree (`routeTree.gen.ts`). The plugin or CLI generates it.
- Validate search params with `validateSearch` and a schema.
- Load route data in `loader` or with Query in the loader. Do not fetch in `useEffect`.
- Server functions run on the server. Validate their input. Check authorization in each one.

## Table
- Keep `data` and `columns` references stable (`useMemo` or module scope). New references on each render cause re-render loops.
- For server-side data, set `manualPagination`, `manualSorting`, or `manualFiltering`.

## Virtual
- The scroll container needs a fixed height and `overflow: auto`.
- Use `measureElement` for rows of different heights.

## Tests
- Create a new `QueryClient` per test with `retry: false`.
