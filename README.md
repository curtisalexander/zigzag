# ZigZag: Learning Zig through conversation

An anti-textbook about learning [Zig](https://ziglang.org/) in public, through AI dialogue. Written by someone who doesn't know Zig — and that's the point.

## What this is

ZigZag is a [Quarto](https://quarto.org/) book that documents the process of learning Zig from scratch via conversations with an AI coding agent ([Claude Code](https://claude.com/product/claude-code)). The confusion, the tangents, and the wrong turns stay in. The zigzag is the path.

**Target audience:** Python/JS developers who are curious about systems programming but don't want to pretend they already know what a linker does.

## Project structure

```
_quarto.yml          # Quarto book configuration
chapters/*.qmd       # Book chapters
code/chNN/           # Zig projects, organized by chapter
sessions/            # Raw AI conversation logs
```

## Reading the book

The rendered book lives at: *coming soon*

Or build it locally:

```bash
quarto render        # outputs to _book/
quarto preview       # live-reload dev server
```

## Prerequisites (for following along)

- [Zig](https://ziglang.org/download/) — single binary, no dependencies
- [Quarto](https://quarto.org/docs/get-started/) — only needed if building the book
- A terminal and a willingness to be confused

## License

Code (`code/` directory) is [MIT](https://opensource.org/licenses/MIT). Book text (chapters, session logs, and all other prose) is [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See [LICENSE](LICENSE) for details.
