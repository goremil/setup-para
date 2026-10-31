# setup-para

The PARA skeleton of the knowledge vault and the taxonomy of kinds shared with the home directory, with the home-manager module that seeds it.

Status: v0.3: the spec, its checks, the home-manager module with the rules for work and boards, and `para-check`.

## The spec

`para.nix` holds the data, and `lib/para.nix` checks it when the flake is evaluated: a wrong value stops the evaluation with the name it is about. The flake exports the checked spec as `lib.para`.

| Section | What it holds | Checked |
| --- | --- | --- |
| `roles` | The PARA roles, each with its definition | a lowercase camelCase name, a non-empty definition; each role has exactly one folder |
| `folders` | The vault's top-level folders, with `role` and `lint` (the markdownlint profile: `agent`, `forge`, `hybrid` or `off`) | the name is `NN_Name`, numbers are unique, the role and the profile are known, no other fields |
| `kinds` | The kinds of content a folder of the home directory can hold | a lowercase camelCase name, a non-empty definition |
| `ideaStatus` | The maturity of an idea, in order: a list of `{ name; meaning; }`, each meaning with its exit criterion | a lowercase camelCase name used once, a non-empty meaning, no other fields |
| `content` | What a visible file in a PARA folder may be: `formats` maps an extension to its class (`note`, `illustration`, `raster`, `page` or `asset`), `rasterKiB` limits a raster illustration | an extension is lowercase without the dot, the class is known, the limit a positive integer, no other fields |

Folders are numbered in tens by the flow (inbox, ideas, projects, areas, resources, archive), so a new folder fits in without renumbering; `99_Scratchpad` sits outside the flow. A folder names a role; a folder of the home directory names a kind of content, and the PARA notes that point at an item give it its role.

## The module

`homeModules.default` applies the spec to a vault in home-manager. A flake that builds a home-manager configuration takes the repository as an input and imports the module:

```nix
inputs.setup-para = {
  url = "git+https://github.com/goremil/setup-para";
  inputs.home-manager.follows = "home-manager";
};

# in the home-manager modules
imports = [ inputs.setup-para.homeModules.default ];
```

Then the vault is described in the home configuration:

```nix
setup.para = {
  enable = true;
  vault = "Knowledge";  # relative to the home directory, the default
  lint.enable = true;   # the default
  check = {
    enable = true;
    vendored = [ "20_Projects/prior-art/" ];  # copies, text of any kind
  };
};
```

- An activation step creates the missing folders, and the vault's `AGENTS.md` once: its prose from `module/agents-vault.md`, with tables of the folders and the idea statuses from the spec, and the rules for work: boards in the Obsidian Kanban format, named `*.kanban.md`, closed cards archived and the knowledge they produced distilled. It never overwrites anything, so the seeded `AGENTS.md` is edited by hand from then on. No `INDEX.md` is seeded: a folder gets one when it has something to add.
- `lint.enable`: each folder's `.markdownlint-cli2.jsonc` is a store link to the profile its spec names, from `setup-base`, so a new profile arrives with a switch. A file already at that path is not replaced: home-manager stops, or moves it aside when `home-manager.backupFileExtension` is set.
- `check.enable`: `para-check` and a weekly user timer (Monday 10:30) that sends one notification when the vault differs from the spec, with the report in `~/.local/state/para-check/report.md`.

## para-check

```sh
para-check                                  # the live vault, ~/Knowledge by default
para-check --vault DIR --report FILE        # another vault; a Markdown report
para-check --repo --vendored PREFIX ...     # the files git sees, from the vault's root
```

It reports, never fixes, and exits 1 when it finds something. Findings: a folder of the spec that is missing, a visible folder the spec does not list (`unknown`), a file in a PARA folder that is not a content format, a binary where only text belongs, a raster illustration over the limit, a page (`.html`) without a Content-Security-Policy that forbids every request and allows no web address, an idea note without a `**Status:**` from `ideaStatus` (the notes named in capitals, such as `INDEX.md`, are not ideas), and a folder's lint config that is not the link to its profile. `--repo` is the vault's own `repo-check` and CI: it checks the files git sees, a file still encrypted by git-crypt by its name only, and leaves out what only the live tree shows (missing folders, the untracked lint links). The flake exports it as `packages.para-check`, with this spec built in.

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
