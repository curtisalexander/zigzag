# Session 07: Scratch code organization and Zig printing basics
**Date:** 2026-03-08
**Type:** Mini-session / housekeeping / Q&A
**Status:** Complete

---

## Concepts Explored

- Organizing scratch/exploration code alongside chapter examples
- Stub functions in Zig (`@panic("todo")`, `unreachable`, `_ = param`)
- `std.debug.print` (stderr, no `try`) vs `std.io.getStdOut().writer()` (stdout, needs `try`)

## What Happened

Quick session while reviewing ch02 draft. Three questions came up:

1. **Where should scratch code live?** Decision: just put `.zig` files directly in `code/ch02/` alongside `word_freq.zig`. Name them by what you're exploring (`const_vs_var.zig`, `defer_order.zig`, etc.). No special scratch folder needed — the chapter directory is already scoped. Delete throwaway files later; promote interesting ones into the book.

2. **How to write stub functions that type-check?** Use `@panic("todo")` as the body. It's `noreturn`, so it satisfies any return type. Use `_ = param;` to suppress unused parameter errors. `unreachable` also works but has different semantics (asserts the path is impossible).

3. **stdout vs stderr for printing?** `std.debug.print` writes to stderr and doesn't need `try` — fine for scratch code. `std.io.getStdOut().writer().print()` writes to stdout but requires `try`. For throwaway exploration, `std.debug.print` is easiest. For book examples and "real" output, use stdout.

## Key Decisions

- Scratch code goes in `code/chNN/` — no separate scratch directory
- After exploring, review what's worth keeping: fold into the chapter, turn into TRY IT boxes, promote to a new chapter, or delete

## What Could Make It into the Book

- The stdout vs stderr distinction is a natural tangent in ch02 or wherever `std.debug.print` first appears
- Stub function pattern (`@panic("todo")`) is a practical tip worth mentioning when functions come up

## Observations

- These micro-sessions are useful — not everything needs to be a deep dive
