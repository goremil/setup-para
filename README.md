# setup-para

The PARA skeleton of the knowledge vault and the taxonomy of kinds shared with the home directory, with the home-manager module that seeds it.

Status: just created from the `setup-base` template.

See [AGENTS.md](AGENTS.md) for how to work in this repository.

## Development

```sh
nix develop             # every check tool; enables the git hooks
repo-check              # every check, one report; -v for each output
nix fmt -- <files>      # format Nix files
nix flake update base   # the next version of the managed set
```

## Licence

Code, build definitions and configuration are under GPL-3.0-only, documentation under CC-BY-SA-4.0. `REUSE.toml` maps each path to its licence, and `reuse lint` checks it.
