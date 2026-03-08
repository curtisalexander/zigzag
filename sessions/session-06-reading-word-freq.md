# Session 06: Reading word_freq.zig — Part 1
**Date:** 2026-03-08
**Type:** Exploration / reading code / Q&A
**Status:** In progress — more of word_freq.zig to read

---

## Concepts Explored

- `const` vs `var` — immutability as default
- `pub fn main() !void` — public visibility, entry points, error unions
- Error propagation in the type system (comparison with C, Python, Go, Rust)
- Allocator setup — why GPA is `var` but the allocator interface is `const`
- Pointers vs fat pointers (slices carry length, interfaces carry vtable)
- Interfaces in Zig — vtable dispatch, same idea as Rust's `dyn Trait`
- `defer` — cleanup pattern, block scoping
- Allocator landscape — GPA, Arena, FixedBuffer, c_allocator
- Odin comparisons — `defer`, explicit allocators, shared philosophy

## What Happened

Sat down to read `word_freq.zig` line by line, asking questions as they came up. This wasn't writing code — it was reading code and building mental models.

Started with `const` vs `var` (straightforward), then hit `var gpa` — why does the allocator need to be mutable? That opened the door to: what's an interface, what's a fat pointer, what's a vtable, and why is `const allocator = gpa.allocator()` valid when the GPA it points to is `var`.

The fat pointer explanation clicked when connecting it to slices — `[]const u8` is already a fat pointer (address + length), the allocator interface is just a different flavor (address + vtable).

The `!void` discussion led to comparing error handling across languages — C's ignorable return codes, Python's invisible exceptions, Go's discardable err, vs Zig and Rust putting errors in the type system. Key insight: you can *read* Zig code and see every error path.

`defer` was immediately appreciated — the author has Odin experience and recognized the pattern. The block-scoping subtlety (defer runs when the enclosing block exits, not just the function) was a good callout.

Decided to add Odin comparisons as a recurring thread throughout the book — not forced "vs" sections, but natural asides where the languages make similar or different choices.

## Files Created/Modified

| File | Purpose |
|---|---|
| `chapters/02-word-freq.qmd` | Chapter 2 draft — first pass through word_freq.zig concepts |
| `sessions/session-06-reading-word-freq.md` | This file |
| `IDEAS.md` | Added: Odin comparisons, pointers-from-scratch exploration |
| `_quarto.yml` | Added chapter 2 to book |

## Key Decisions

- **Chapter 2 is a "reading" chapter** — the code was already written in session 05; this chapter is about reading it and asking questions
- **Part 1 of word_freq** — only covers the top half (signature, allocator, const/var, defer). Tokenization, hash maps, sorting, comptime stopwords will come in a continuation
- **Odin comparisons as recurring thread** — added to IDEAS.md under Big Picture

## Ideas Captured (in IDEAS.md)

- Odin comparisons throughout the book (defer, error handling, generics)
- Pointers from scratch — early chapter, slow/methodical, print addresses, draw boxes

## What Made It Into the Book

- Chapter 2 first draft covering: `pub`, `!void`, `const` vs `var`, allocators, interfaces, fat pointers, `defer`
- Error handling comparison table (C, Python, Go, Rust, Zig)
- Allocator comparison table
- Two tangent sections: error propagation in the type system, pointers and fat pointers

## What Didn't (and Why)

- **Tokenization, hash maps, sorting, format strings, comptime stopwords** — deferred to a continuation session. The chapter was already substantial and these deserve their own treatment.
- **Actual Odin code comparisons** — noted as future thread, not started yet

## Observations

- The "reading code" format works well for this book — it models how to learn from existing code, which is a skill most books don't teach.
- The fat pointer concept was the biggest "aha" — connecting slices (which feel natural) to interfaces (which feel abstract) via the same underlying mechanism.
- The business card metaphor for `const allocator` pointing to `var gpa` landed well.
- This chapter will likely be split or extended — there's too much in word_freq.zig for one chapter, but the Q&A format makes it natural to serialize across sessions.
