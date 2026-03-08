# Session 05: Word Frequency Counter, awk-lite, and Project Conventions
**Date:** 2026-03-07
**Type:** Exploration / code writing / project infrastructure
**Status:** Complete

---

## Concepts Explored

- Zig 0.15 I/O overhaul (writers need explicit buffers, no more `getStdOut()`)
- Allocators (GeneralPurposeAllocator, passing allocators to collections)
- Data structures (StringHashMap, ArrayList — now unmanaged in 0.15)
- File I/O (readToEndAlloc, openFile)
- String processing (tokenizeAny, mem.sort, slicing)
- Error handling (try, catch, error unions)
- Format printing (stdout writer, format specifiers, flush)
- Command-line argument parsing
- Hand-written recursive descent parsing (awk-lite)

## What Happened

Started with the goal of writing a non-trivial Zig program to read through — not hello world, but something that shows the landscape of the language. Chose a **word frequency counter** because it touches allocators, hash maps, file I/O, sorting, and string manipulation all in one file.

Downloaded the Complete Works of Shakespeare from Project Gutenberg (eBook #100, ~5.4 MB, 196K lines) as the test corpus. Built the word frequency counter iteratively, hitting several Zig 0.15 API changes along the way:

- `std.io.getStdOut()` → `std.fs.File.stdout().writer(&buf)` + `&writer.interface`
- `std.ArrayList` is now unmanaged (pass allocator per method call)
- Multi-byte UTF-8 fill characters in format strings cause compile errors

Added three output sections to make it interesting:
1. **Top N words (all)** — "the" wins at 25,705
2. **Top N words (skipping stopwords)** — surfaces "thou", "thy", "thee", "love", "lord"
3. **Shakespeare Spotlight** — words he invented: "assassination" (1!), "eyeball" (1!), "torture" (33), "swagger" (5)
4. **Ye Olde English** — archaic forms: "thou" (4,816), "villain" (228), "prithee" (134)

Then got excited and built **awk-lite** — a minimalistic awk-like tool in Zig. Supports `{print $N}`, `/pattern/`, NR comparisons, BEGIN/END, and `-F` delimiters. Hit a Windows/MSYS2 gotcha where `/pattern/` gets converted to a Windows path (fix: `MSYS_NO_PATHCONV=1`). Decided this is a future project to revisit, not part of ch02.

Also set up several project conventions:
- **IDEAS.md** — brain dump file for things to learn/build/explore
- **AGENTS.md** — renamed from CLAUDE.md as source of truth; CLAUDE.md is now a symlink
- **TRY IT pattern** — small scoped challenges in code and chapters
- **Memory reorganization** — split Zig 0.15 API notes into separate `zig-015-api.md`

## Files Created/Modified

| File | Purpose |
|---|---|
| `code/ch02/word_freq.zig` | Word frequency counter — the main learning artifact |
| `code/ch02/shakespeare.txt` | Complete Works of Shakespeare (Project Gutenberg #100) |
| `code/awk-lite/awk-lite.zig` | Minimalistic awk-like tool prototype (future project) |
| `IDEAS.md` | New — brain dump for future exploration |
| `AGENTS.md` | Renamed from CLAUDE.md, updated with new structure and TRY IT convention |
| `CLAUDE.md` | Now a symlink → AGENTS.md |

## Key Decisions

- **Word freq over other programs** — touches the most Zig surface area in one file (allocators, hash maps, I/O, sorting, error handling, slices)
- **Shakespeare as corpus** — non-trivial size, culturally interesting, shows real word distribution patterns
- **Shakespeare Spotlight section** — makes output interesting; shows words he coined appearing exactly once
- **Case sensitivity left as a known limitation** — "The" and "the" counted separately; noted as future improvement. Good teaching moment about the cost of case-insensitive operations in a no-GC language
- **awk-lite deferred** — fun prototype but too far ahead; captured in IDEAS.md for later
- **AGENTS.md as source of truth** — more tool-agnostic name; CLAUDE.md symlinks to it
- **TRY IT as a convention** — small challenges embedded in code; reading is learning, modifying is understanding

## Ideas Captured (in IDEAS.md)

- Build awk-lite (prototype exists at `code/awk-lite/`)
- Understand programming languages (lexing, parsing, ASTs)
- How far can you push `const`? (functional/immutable Zig)
- How far without an allocator? (stack-only programs)
- What IS allocation? (stack vs heap, syscalls, virtual memory)
- Binary types and linking (ELF, PE, static vs dynamic)
- Building CLI applications in Zig
- "Staying awake" tool using Windows API (`SetThreadExecutionState`)

## What Made It Into the Book

Nothing yet — word_freq.zig is the raw material for chapter 2. The TRY IT convention will shape how chapters are written going forward.

## What Didn't (and Why)

- **awk-lite** — too far ahead of where the book is; revisit when we've covered more Zig fundamentals
- **Case-insensitive word counting** — requires allocating lowercased copies or custom hash map; flagged as future chapter material

## Observations

- Zig 0.15's I/O overhaul is the biggest breaking change from older examples/tutorials — everything online is wrong now. The `zig-015-api.md` memory file will be essential.
- The "allocator + defer" pattern is incredibly consistent in Zig — allocate, immediately defer free. Once you see it, you see it everywhere.
- Shakespeare's complete works has 37,255 unique words and "assassination" appears exactly once. That's a great hook for the chapter.
- Windows/MSYS2 path conversion is a recurring pain point — need to remember `MSYS_NO_PATHCONV=1` for any CLI args with forward slashes.
- The IDEAS.md workflow is working well — low friction, captures thoughts without derailing the current task.
