# Session 03: Hello Zig and CI
**Date:** 2026-03-07
**Type:** Chapter writing, code execution pipeline, CI setup (Claude Code)
**Status:** Complete

---

## Concepts explored

- Writing Chapter 1 (Hello, Zig) with real executable code
- Quarto code execution via Jupyter — the Python dependency chain
- `freeze: auto` for caching execution results
- GitHub Actions workflow for Pages deployment
- Zig vs Python toolchain comparison (tangent content)

## What happened

The goal was to write Chapter 1 with a working hello world program, prove the code execution pipeline works locally, and deploy the book to GitHub Pages.

### Hello world

Created `code/ch01/hello.zig` — a minimal Zig program using `std.debug.print`. Wrote Chapter 1 content explaining `@import`, `pub fn main`, and the `.{}` anonymous struct literal. The chapter walks through what each part of the program does and why `debug.print` writes to stderr.

### The code execution saga

The plan: use Quarto's `{bash}` executable blocks to run `zig run` at render time, freeze the output, and let CI deploy without needing Zig.

What actually happened:

1. **Quarto needs Jupyter to execute code blocks.** Jupyter needs Python. Python needs packages (`pyyaml`, `nbformat`, etc.). Installed `pyyaml` globally, then hit `nbformat` missing — realized the full `jupyter` package was needed.

2. **Python environment management.** Rather than pollute the system Python, created a project-local venv with `uv venv` and `uv pip install jupyter`. Quarto didn't auto-detect the `.venv/` on Windows — needed `QUARTO_PYTHON` env var. Added a `.env` file at the project root.

3. **Bash kernel doesn't work on Windows.** The `bash_kernel` Jupyter package depends on `pexpect`, which requires Unix pseudo-terminals. Installed it, got it into the venv's kernel directory, but it couldn't actually run.

4. **The workaround.** Switched to using the `python3` kernel with a hidden cell (`#| echo: false`) that calls `subprocess.run` to invoke `zig run`. The rendered output shows the bash command and Zig output — no Python visible to the reader. Jupyter's working directory is the chapter's directory, so paths needed `../` to reach `code/`.

5. **`freeze: auto`** caches execution results in `_freeze/`, committed to git. CI renders from frozen output — no Python, no Jupyter, no Zig needed.

### GitHub Pages

Created `.github/workflows/publish.yml` using the official Quarto GitHub Actions. The workflow checks out the repo, sets up Quarto, renders from frozen results, and deploys via `actions/deploy-pages`. Requires enabling Pages with "GitHub Actions" as the source in repo settings.

### Tangents written

- **A tale of two hello worlds** (Chapter 1) — Side-by-side comparison of going from nothing to hello world in Zig (3 steps) vs modern Python with uv (9 steps). Lets the step counts speak for themselves.
- **The Python situation** (Colophon) — Documents the code execution setup: why Python is needed, why the bash kernel doesn't work on Windows, and the actual commands to reproduce the environment.

### Other fixes

- Added `.gitattributes` with `* text=auto eol=lf` to normalize line endings and eliminate CRLF warnings.

## Key decisions

- **Hidden Python cells over bash kernel.** The bash kernel is the cleaner abstraction but doesn't work on Windows. The subprocess approach is ugly in the source `.qmd` but invisible in the rendered output.
- **`freeze: auto` over executing in CI.** CI doesn't need Zig or Python — just Quarto. Execution happens locally; frozen results are committed. Trade-off: must remember to re-render locally when code changes.
- **Project-local venv over global Python packages.** `uv venv` keeps the Jupyter dependency isolated. One-time setup cost, but no system pollution.

## Files created/modified

- `code/ch01/hello.zig` — Hello world Zig program
- `chapters/01-hello-zig.qmd` — Chapter 1 with content, executable code, and tangent
- `chapters/colophon.qmd` — Updated tool table, added Python situation tangent
- `_quarto.yml` — Added `freeze: auto`
- `.github/workflows/publish.yml` — GitHub Pages deployment workflow
- `.env` — Sets `QUARTO_PYTHON` for local rendering
- `.gitignore` — Added `.venv/`
- `.gitattributes` — Normalize line endings to LF
- `_freeze/chapters/01-hello-zig/execute-results/html.json` — Frozen code output
