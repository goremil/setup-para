# setup-para

The PARA skeleton of the knowledge vault and the taxonomy of kinds shared with the home directory, with the home-manager module that seeds it.

Status: v0.1 in progress: the spec, its checks and the home-manager module.

## The spec

`para.nix` holds the data, and `lib/para.nix` checks it when the flake is evaluated: a wrong value stops the evaluation with the name it is about. The flake exports the checked spec as `lib.para`.

| Section | What it holds | Checked |
| --- | --- | --- |
| `roles` | The PARA roles, each with its definition | a lowercase camelCase name, a non-empty definition; each role has exactly one folder |
| `folders` | The vault's top-level folders, with `role` and `lint` (the markdownlint profile: `agent`, `forge`, `hybrid` or `off`) | the name is `NN_Name`, numbers are unique, the role and the profile are known, no other fields |
| `kinds` | The kinds of content a folder of the home directory can hold | a lowercase camelCase name, a non-empty definition |
| `ideaStatus` | The maturity of an idea, in order: a list of `{ name; meaning; }`, each meaning with its exit criterion | a lowercase camelCase name used once, a non-empty meaning, no other fields |

Folders are numbered in tens by the flow (inbox, ideas, projects, areas, resources, archive), so a new folder fits in without renumbering; `99_Scratchpad` sits outside the flow. A folder names a role; a folder of the home directory names a kind of content, and the PARA notes that point at an item give it its role.

## The module

`homeModules.default` applies the spec to a vault in home-manager:

```nix
setup.para = {
  enable = true;
  vault = "Knowledge";  # relative to the home directory, the default
  lint.enable = true;   # the default
};
```

- An activation step creates the missing folders, and the vault's `AGENTS.md` once: its prose from `module/agents-vault.md`, with tables of the folders and the idea statuses from the spec. It never overwrites anything, so the seeded `AGENTS.md` is edited by hand from then on. No `INDEX.md` is seeded: a folder gets one when it has something to add.
- `lint.enable`: each folder's `.markdownlint-cli2.jsonc` is a store link to the profile its spec names, from `setup-base`, so a new profile arrives with a switch. A file already at that path is not replaced: home-manager stops, or moves it aside when `home-manager.backupFileExtension` is set.

See [AGENTS.md](AGENTS.md) for how to work in this repository.

## Development

```sh
nix develop             # every check tool; enables the git hooks
repo-check              # every check, one report; -v for each output
nix fmt                 # treefmt: nixfmt, shfmt, and ruff with the python profile
nix flake update base   # the next version of the managed set
```

## Licence

Code, build definitions and configuration are under GPL-3.0-only, documentation under CC-BY-SA-4.0. `REUSE.toml` maps each path to its licence, and `reuse lint` checks it.
