# Ideas

Things to learn, build, or explore in Zig. Not a backlog — a brain dump.
Fire off an idea anytime; it lands here.

---

## Projects

- **Build a small awk-like tool in Zig.** Understand how awk actually works under the hood — the pattern/action model, field splitting, the implicit main loop over lines. What would it take to implement a subset of awk in Zig? Touches: file I/O, string parsing, maybe even a small expression evaluator. Way down the line. *A rough v1 prototype exists at `code/awk-lite/` — supports `{print $N}`, `/pattern/`, `NR` filters, `BEGIN/END`, `-F` delimiter. Needs revisiting and polish.*

## Big picture

- **Understand how programming languages work.** Lexing, parsing, ASTs, code generation — the whole pipeline. Building the awk tool (above) could be a vehicle for this. Or maybe a tiny expression language in Zig as a stepping stone.

## Language concepts to explore

- **What IS allocation?** Stack vs. heap — what's actually happening? When we call an allocator, what syscall fires? (`mmap`? `sbrk`? `VirtualAlloc` on Windows?) Why do languages hide this? Why does Zig NOT hide it? What does the OS actually do when you say "give me memory"? Virtual memory, pages, the whole story. This is foundational — understand this and the allocator stuff clicks.

- **How far can you get without an allocator?** Can you write useful programs using only stack memory and comptime-known sizes? Where does Zig force you to allocate? (Variable-length input? Data structures? Strings?) Pairs nicely with the `const` question — both are about finding the walls.

- **How far can we push `const`?** What happens if you try to write Zig with zero `var` — pure immutable, functional-style? Where does the language force you into mutability? (Iterators? Allocators? I/O?) Could be a fun experiment: take a small program and try to eliminate every `var`. See where Zig says "no."

- **Binary types and linking.** What's an ELF? PE? Mach-O? What does a linker actually do? Static vs. dynamic linking — why does Zig default to static? What's in a `.o` file? How does `zig build-exe` turn source into a running program? Zig bundles its own linker (LLD) — why?

- **"Staying awake" tool using the Windows API.** Call `SetThreadExecutionState` from Zig to prevent the machine from sleeping. Have done this in other languages before — how does Zig's FFI / Windows API interop work? Zig can call C directly with no bindings — does that extend to Win32? Good excuse to learn `@cImport`, extern functions, and Zig's cross-compilation story.

- **Building CLI applications in Zig.** Arg parsing, stdin/stdout/stderr, exit codes, piping, signal handling. How does Zig compare to Python's `argparse` or Rust's `clap`? Is there a community library or do you roll your own? The awk-lite prototype is a start — what would a polished CLI look like?

## Questions to answer

## Things that confused me
