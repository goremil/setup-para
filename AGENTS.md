# AGENTS.md

Instructions for any agent, human or AI, working in this repository.

## What this repository is

The PARA skeleton of the knowledge vault and the taxonomy of kinds shared with the home directory, with the home-manager module that seeds it. See [README.md](README.md).

## Rules

- The rule core of `setup-base` applies; a departure from it is recorded under "Deviations" below.
- This repository is public. Nothing personal goes in: no names of hosts, people or private repositories, no paths into a user's home directory.
- `repo-check` passes before a commit; the pre-commit hook runs it.

## Layout

| Path | Content |
| --- | --- |
| `flake.nix` | Dev shell, `formatter` and `checks` from `setup-base`; `lib.para`, `homeModules.default`; the checks `para`, `para-rejects` and `module` |
| `para.nix` | The spec: roles, folders, kinds, idea statuses |
| `lib/para.nix` | Checks the spec at evaluation |
| `module/` | `homeModules.default`: seeds the folders and the vault's `AGENTS.md` (prose in `agents-vault.md`), links each folder's lint config |
| `.githooks/` | pre-commit (`repo-check`) and commit-msg, in the dev shell |
| `.markdownlint-cli2.jsonc` | Lint profile, linked by the dev shell; untracked |
| `REUSE.toml`, `LICENSES/` | Licence of each path |
| `.forgejo/workflows/` | CI: `repo-check -v` on every push |
| `.copier-answers.yml` | Template answers for `copier update`; not edited |

## Deviations

Departures from the `setup-base` rule core, one row each (R-rules-03). A deviation not listed here is a mistake, not a decision; `repo-check` checks each row and asks for the departures it can see.

| Rule | What differs | Reason | Since | Decision |
| --- | --- | --- | --- | --- |
