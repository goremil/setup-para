{
  description = "The PARA skeleton of the knowledge vault and the taxonomy of kinds shared with the home directory, with the home-manager module that seeds it.";

  # The managed set: check tools, repo-check, hooks' commands, formatter and
  # checks. `nix flake update base` brings a new version; flake.lock pins it.
  inputs.base.url = "git+https://github.com/goremil/setup-base";

  outputs = { self, base }: base.lib.mkRepo { inherit self; };
}
