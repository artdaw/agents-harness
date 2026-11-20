---
name: harness-typescript
description: Use when you write or change TypeScript code, types, or tsconfig, or fix TypeScript compiler errors.
---

# TypeScript

Applies together with the Node stack section. Run the typecheck from that section after each change.

## Compiler settings
- Read `tsconfig.json` first: `strict`, `module`, `moduleResolution`, `verbatimModuleSyntax`, `noUncheckedIndexedAccess`.
- Do not weaken `tsconfig.json` to fix an error.

## Type safety
- Do not add `any`. Use `unknown` and narrow it.
- Do not add `@ts-ignore`. If a suppression is necessary, use `@ts-expect-error` with a one-line reason.
- Avoid `as` casts and the non-null `!` operator. Narrow with checks instead. Use `satisfies` to check an object literal against a type.
- Model variants with discriminated unions. Check exhaustiveness with a `never` case in `switch`.
- Types do not exist at runtime. Validate external data (HTTP, files, env, storage, LLM output) at the boundary
  with the schema library of the project (Zod, Valibot, or other). Infer the type from the schema.

## Modules
- Follow the module system of the project (`"type"` in `package.json`, and `module` in `tsconfig.json`).
- With `verbatimModuleSyntax`, use `import type` for type-only imports.
- With Node type stripping or `erasableSyntaxOnly`, do not use `enum`, `namespace`, or parameter properties. Use union literals and `as const` objects.

## Generated code
- Do not edit generated types (OpenAPI, GraphQL, Prisma, route trees) by hand. Run the generator command of the project.
