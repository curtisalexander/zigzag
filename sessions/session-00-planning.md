# Session 00: Project Planning
**Date:** 2026-03-07  
**Type:** Planning session (Claude.ai chat → Claude Code handoff)  
**Status:** Complete — ready to scaffold

---

## What We Decided

### Project Identity

| Field | Value |
|---|---|
| **Title** | ZigZag |
| **Subtitle** | Learning Zig through conversation |
| **Tagline** | Learning Zig is rarely a straight line |
| **Format** | Open source, free online book (Quarto) |
| **Repo style** | Public GitHub + rendered site |

---

### The Concept

ZigZag is a book about learning Zig in public — written *through* the learning process rather than after it. The author learns Zig via AI-assisted dialogue (reverse-Socratic method), and those sessions become the raw material for the book.

The key insight: most programming books are written by experts who've forgotten what confusion feels like. ZigZag captures the confusion deliberately. The stumbling blocks *are* the content.

**The method:**
1. Explore a Zig concept through conversation with an AI coding agent
2. Write and run code, hit confusion, ask questions
3. AI summarizes what was discovered — the aha moments, the gotchas, the mental models
4. That summary becomes a draft chapter or section
5. Author refines with their own voice and adds exercises

---

### Author Background

- Languages: Python, JS (primary), some Rust experience
- Rust background shapes the book's angle — Zig will feel *familiar but different*, and that tension is a narrative thread
- Quarto: RMarkdown experience (close enough)
- Target reader: **Python/JS developer, Rust-curious** — exactly the author six months ago

---

### Voice & Style

- **Anti-textbook textbook** — honest, wandering, occasionally philosophically unhinged
- Tangents are **celebrated, not apologized for**
- Marked with ↯ symbol and given full treatment as named sections or interlude chapters
- Conversational, first-person, shows the mess of real learning
- Inspired by: learning in public, Socratic dialogue, the idea that the process is the content

**Example tangents planned:**
- Greek dialogues and the Socratic method (inevitable given the project's DNA)
- Philosophy of documentation
- Whatever else naturally emerges

**What it is NOT:**
- DFW-style footnotes (tempting but exhausting in a technical book)
- Pretentious about its own method — the Socratic angle shows, doesn't announce itself

---

### Structure

```
zigzag/
├── _quarto.yml              # book config
├── README.md                # project philosophy
├── chapters/
│   ├── 00-what-this-is.qmd  # the manifesto
│   ├── 01-hello-zig.qmd
│   └── ...
├── code/                    # real Zig projects, one per chapter
│   ├── ch01/
│   └── ch02/
└── sessions/                # raw AI session logs
    ├── session-00-planning.md   ← this file
    └── session-01-hello-zig.md
```

---

### Code Execution Strategy

**v1 (now):** Shell execution blocks in Quarto

```markdown
```zig
const std = @import("std");
pub fn main() void {
    std.debug.print("Hello, Zig!\n", .{});
}
```

```{bash}
zig run code/ch01/hello.zig
```
```

Output is captured at render time and frozen in the HTML. Readers see real output without installing anything. Simple, works today.

**v2 (late chapters):** WASM playground — compile Zig to WASM, inject a CodeMirror editor + Run button into the rendered HTML. Deferred deliberately because:
- Building it *is* a major Zig learning project
- It becomes the book's climactic final chapter
- The book ends by improving itself

---

### Narrative Arc

| Phase | Content | Execution |
|---|---|---|
| Early chapters | Basic Zig, syntax, types, memory model | Local, bash blocks |
| Middle chapters | Real growing projects, build system, idioms | Local, real `code/` projects |
| Late chapters | Zig → WASM, Quarto extension, live playground | The book's final project |

The arc is self-referential: **the last project improves the book you are reading.**

---

### Session Logging Convention

Each working session gets a markdown file in `sessions/`:

```markdown
## Session: [Topic]
**Date:** ...
**Concepts explored:** ...
**Key confusions & resolutions:** ...
**Code written:** [links to files]
**What made it into the book:** ...
**What didn't (and why):** ...
```

Sessions are the "director's commentary" — readers can see the messy exploration behind the clean chapters. They model *how to learn*, not just what was learned.

---

### Naming Rationale

We went through many candidates:
- *Zig in the Open*, *Zero to Zig*, *Zig as You Go*, *The Zig Diaries*, *Zig Zag*...

**ZigZag won because:**
- Memorable, pronounceable, natural
- Zig is in the name without forcing it
- Captures the non-linear learning path
- Works as a URL
- Slightly cheeky without being try-hard
- The subtitle (*Learning Zig through conversation*) quietly signals the AI dialogue and Socratic method without being pretentious about it

---

## First Tasks for Claude Code

1. Scaffold the full ZigZag project structure
2. Write `chapters/00-what-this-is.qmd` — the manifesto chapter that:
   - Captures the voice
   - Explains the method honestly
   - Introduces the ↯ tangent motif
   - Sets up the narrative arc
   - Does NOT over-explain or get precious about the Socratic angle

---

## Prompt to Paste into Claude Code

```
I'm starting a Quarto book project. Here's everything decided so far:

PROJECT: ZigZag
SUBTITLE: Learning Zig through conversation
TAGLINE: Learning Zig is rarely a straight line

CONCEPT:
- Open source, free online book
- Learning Zig in public via AI-assisted reverse-Socratic dialogue
- The conversation sessions ARE the book's raw material
- Author background: Python/JS + some Rust, RMarkdown experience

STRUCTURE:
- sessions/ folder: raw AI conversation logs
- chapters/ as .qmd files
- code/ for actual Zig projects per chapter
- Execution via {bash} blocks, output frozen at render time
- WASM playground deferred to late chapters (a major project in itself)

VOICE & STYLE:
- Anti-textbook textbook
- Honest, wandering, occasionally philosophically unhinged
- Tangents are celebrated, not apologized for
- Marked tangent sections (↯) for digressions like Greek dialogues, 
  philosophy of documentation, etc.
- Target reader: Python/JS dev, Rust-curious

NARRATIVE ARC:
- Early: local Zig execution, basic concepts
- Middle: real growing projects
- Late: compile to WASM, build the book's own playground
- The book becomes self-referential — final project improves the book itself

FIRST TASK:
Please scaffold the full ZigZag project structure and write Chapter 0 — 
the "what this book is and how it was made" manifesto. Chapter 0 should 
capture the voice, explain the method, introduce the tangent motif (↯), 
and set up the narrative arc. Do NOT over-explain the Socratic angle — 
let the method show rather than announce itself.
```
