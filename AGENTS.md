# ZigZag — Project Context for Claude Code

## What this is

A Quarto book called **"ZigZag: Learning Zig through conversation"** — an anti-textbook where the author (Curtis Alexander, GitHub: curtisalexander) learns Zig in public via AI dialogue. The confusion is the content. Target readers: Python/JS devs, Rust-curious.

## Project structure

```
zigzag/
├── AGENTS.md                 # Project instructions (this file)
├── CLAUDE.md                 # Symlink → AGENTS.md
├── IDEAS.md                  # Brain dump: things to learn/build/explore
├── index.qmd                 # Chapter 0 (Quarto requires home page at root)
├── chapters/*.qmd            # Book chapters
├── code/chNN/                # Zig code examples, one dir per chapter
├── code/awk-lite/            # awk-lite: minimalistic awk in Zig
├── sessions/                 # Raw AI conversation logs (director's commentary)
├── images/                   # WebP images (logo.webp, socrates.webp)
├── scripts/resize-images.py  # PEP 723 image resizer (run with `uv run`)
├── _quarto.yml               # Book config
├── styles.css                # Custom styles (tangent sections)
├── .env                      # QUARTO_PYTHON path (Windows-specific)
└── _freeze/                  # Frozen execution results (committed to git)
```

## Writing workflow

### How a chapter gets made

1. **Conversation** — Have a Claude Code session exploring a Zig concept
2. **Session log** — Save the conversation as `sessions/session-NN-topic.md` using the template (see session-00-planning.md for the template)
3. **Chapter draft** — Polish the interesting parts into `chapters/NN-slug.qmd`
4. **Code examples** — Working Zig files go in `code/chNN/`
5. **Register chapter** — Add the `.qmd` to `_quarto.yml` chapter list
6. **Render** — `quarto preview` for live dev, `quarto render` for full build

### Session log template

Each session file includes: date, session type, status, concepts explored, what happened (narrative), files created/modified, key decisions, what made it into the book, what didn't (and why), observations.

## Code execution pattern

Chapters show code and output using this two-cell pattern:

1. **Display cell** — Shows the Zig source:
   ````
   ```{.zig filename="code/chNN/example.zig"}
   // zig code here
   ```
   ````

2. **Hidden execution cell** — Runs it via Python/subprocess:
   ````
   ```{python}
   #| echo: false
   import subprocess
   result = subprocess.run(["zig", "run", "code/chNN/example.zig"], capture_output=True, text=True)
   print(result.stdout)
   if result.stderr:
       print(result.stderr)
   ```
   ````

Output is frozen at render time (`freeze: auto` in `_quarto.yml`). Frozen results live in `_freeze/` and are committed to git so CI doesn't need Zig or Python installed.

## Tangent pattern (↯)

Tangents are a core narrative device, not apologies. Use native HTML:

```html
<details class="tangent">
<summary>![](images/socrates.webp){.tangent-icon} ↯ Title here</summary>

Content here (blank line after summary tag is required for markdown rendering).

</details>
```

- Add `open` attribute on the **first** tangent in a chapter
- Socrates icon + gold left border (styled in styles.css)

## Local development

```bash
# First time setup
uv venv
uv pip install jupyter

# Dev loop (live reload)
export QUARTO_PYTHON=".venv/Scripts/python.exe"   # Windows
quarto preview

# Full render
quarto render
```

The `.env` file persists `QUARTO_PYTHON` for convenience.

## CI/CD

GitHub Actions (`.github/workflows/publish.yml`) renders from frozen results and deploys to GitHub Pages. No Zig/Python/Jupyter needed in CI.

## Image conventions

- All images are WebP, live in `images/`
- Resize with `uv run scripts/resize-images.py`
- Logo: `images/logo.webp`, Socrates icon: `images/socrates.webp`

## TRY IT pattern

Small, scoped challenges embedded in code and chapters. Reading is learning; modifying is understanding.

Guidelines:
- **Small** — one concept, a few lines of code. Not "rewrite the program."
- **Hint, don't hand-hold** — point to the relevant section, don't give the answer.
- **Expected output** — so the reader knows if they got it right.
- **Not everywhere** — only where there's a natural "now you try" moment.

In Zig source files, use a comment box:
```zig
// ┌─────────────────────────────────────────────────────────────────┐
// │ TRY IT: Description of the challenge.                          │
// │                                                                 │
// │ Hints and guidance here.                                        │
// │                                                                 │
// │ Expected output: ...                                            │
// └─────────────────────────────────────────────────────────────────┘
```

In `.qmd` chapters, use a callout block (TBD — decide on styling when we get there).

## Style & voice

- Anti-textbook: honest, wandering, shows confusion deliberately
- The zigzag learning path is intentional
- Session logs model *how to learn*, chapters are polished extracts
- Readers can compare raw sessions to finished chapters
