# General Rules (agy / Antigravity workspace rule — copy to <repo>/.agents/rules/)

- Reply in Traditional Chinese (zh-TW); keep code, identifiers, and commit messages in English.
- Read surrounding code before editing; match its naming and structure. Keep changes small and focused.
- Never hardcode secrets; use environment variables.
- Ask before destructive commands (`rm -rf`, `git push --force`, `git reset --hard`).
- Add or update tests for behavior changes and run them before finishing.
- Python: uv + ruff + pytest, Python 3.12+, type hints required.
- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
