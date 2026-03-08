# Session 01: Scaffolding
**Date:** 2026-03-07
**Type:** Project setup (Claude Code)
**Status:** Complete

---

## Concepts explored

- Quarto book project structure
- Cross-platform installation of Zig, Quarto, and Claude Code
- The ↯ tangent motif as a structural device
- Colophon conventions for documenting toolchain versions

## What happened

Started from a blank directory containing only `sessions/session-00-planning.md` from the prior Claude.ai conversation. Handed the planning notes to Claude Code and scaffolded the full project.

### Files created

| File | Purpose |
|---|---|
| `_quarto.yml` | Quarto book config — HTML output, cosmo theme, chapter list, colophon as appendix |
| `.gitignore` | Ignores `_book/`, `.quarto/`, Zig caches |
| `chapters/00-what-this-is.qmd` | Chapter 0 — the manifesto. Voice, method, audience, narrative arc, tangent motif |
| `chapters/01-hello-zig.qmd` | Placeholder for the first real chapter |
| `chapters/colophon.qmd` | Appendix with version table and process description |

### Key decisions

- **Quarto panel-tabsets** for platform-specific install instructions (macOS/Windows/Linux tabs) — native Quarto feature, no custom code
- **Colophon as appendix** rather than inline in Chapter 0 — keeps the tangent focused on narrative, colophon handles the details
- **Tangent references colophon** with a parenthetical link for readers who want version specifics
- **Code execution strategy confirmed:** `{bash}` blocks, output frozen at render time. No WASM playground until late chapters.

### Versions locked at project start

| Tool | Version |
|---|---|
| Zig | 0.15.2 |
| Claude Code | 2.1.71 |
| Claude model | Opus 4.6 (`claude-opus-4-6`) |
| Quarto | 1.8.27 (not yet installed locally) |

## What made it into the book

- Chapter 0 in its entirety — voice, method, audience, narrative arc
- The first tangent: "↯ Starting from nothing" — meta-guide on replicating the setup
- Colophon appendix with the full toolchain table

## What didn't (and why)

- **Quarto not installed yet** — discovered it wasn't in PATH during scaffolding. Install instructions are written but the book hasn't been rendered yet. That's Session 02's problem.
- **Git repo initialized late** — the directory existed before git init. Not a problem, just noted.
- **Branch renamed** master → main after first commit.

## Observations

The first tangent works as a proof of concept for the ↯ motif. It fires immediately after the section that *explains* tangents, which is a nice structural move — "here's what a tangent is, and here's one." The tangent is also genuinely useful (install guides) rather than purely decorative, which sets the right expectation: tangents in this book earn their keep.

Chapter 0 was written *about* a process that had barely started. That constraint turned out to be productive — it forced decisions about voice and structure that might otherwise have been deferred indefinitely.
