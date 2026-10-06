# Global Agent Instructions

Shared by Claude Code (via `CLAUDE.md` import), Codex (`AGENTS.md`),
agy / Antigravity (`~/.gemini/config/AGENTS.md`), Cursor and VS Code Copilot.

## Communication
- Reply in Traditional Chinese (zh-TW); keep code, identifiers, and commit messages in English.
- Be concise. Lead with the answer, then the reasoning if needed.

## Working style
- Read the surrounding code before editing; match its naming, structure and comment density.
- Prefer small, focused changes. Do not refactor unrelated code.
- When requirements are ambiguous and the choice matters, ask; otherwise pick the sensible default and say so.
- Never hardcode secrets. Read them from environment variables.
- Do not run destructive commands (`rm -rf`, `git push --force`, `git reset --hard`) without explicit confirmation.

## Code quality
- Python: target 3.12, type hints required; manage env/deps with `uv` (`uv sync`, `uv add`, `uv run`), format and lint with `ruff` (`ruff format` + `ruff check --fix`).
- Tests: add or update tests with every behavior change; run them before declaring done.
- Handle errors explicitly; no silent `except: pass`.

## Git
- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- Never commit to `master`/`main` directly when asked to open a PR; create a branch first.
