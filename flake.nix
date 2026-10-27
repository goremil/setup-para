{
  description = "The PARA skeleton of the knowledge vault and the taxonomy of kinds shared with the home directory, with the home-manager module that seeds it.";

  # The managed set: check tools, repo-check, hooks' commands, formatter and
  # checks. `nix flake update base` brings a new version; flake.lock pins it.
  inputs = {
    base.url = "git+https://github.com/goremil/setup-base";
    # Only for the module check; setup-nixos uses its own home-manager.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "base/nixpkgs";
    };
  };

  outputs =
    {
      self,
      base,
      home-manager,
    }:
    let
      repo = base.lib.mkRepo { inherit self; };
      para = import ./lib/para.nix (import ./para.nix);
      inherit (base.inputs.nixpkgs) lib;
    in
    repo
    // {
      # The checked spec, for setup-home (the kinds) and setup-nixos.
      lib = { inherit para; };

      homeModules.default = import ./module { inherit para base; };

      # para: building the JSON evaluates every value, so a wrong value fails
      # `nix flake check`. para-rejects: specs that must not evaluate. module:
      # homeModules.default applied to a test home.
      checks = lib.mapAttrs (
        system: checks:
        let
          pkgs = base.inputs.nixpkgs.legacyPackages.${system};
          rejects = spec: !(builtins.tryEval (builtins.toJSON (import ./lib/para.nix spec))).success;
          good = import ./para.nix;
          with' = folders: good // { inherit folders; };
          bad = {
            "unknown section" = good // {
              tags = { };
            };
            "missing section" = removeAttrs good [ "kinds" ];
            "empty definition" = good // {
              kinds = good.kinds // {
                map = "";
              };
            };
            "name not camelCase" = good // {
              kinds = good.kinds // {
                Map = "Maps.";
              };
            };
            "folder name not NN_Name" = with' (
              removeAttrs good.folders [ "10_Ideas" ]
              // {
                "10-ideas" = good.folders."10_Ideas";
              }
            );
            "unknown field" = with' (
              good.folders
              // {
                "10_Ideas" = good.folders."10_Ideas" // {
                  colour = "red";
                };
              }
            );
            "unknown role" = with' (
              good.folders
              // {
                "10_Ideas" = good.folders."10_Ideas" // {
                  role = "someday";
                };
              }
            );
            "unknown lint profile" = with' (
              good.folders
              // {
                "10_Ideas" = good.folders."10_Ideas" // {
                  lint = "strict";
                };
              }
            );
            "number used twice" = with' (
              good.folders
              // {
                "10_Notes" = good.folders."10_Ideas";
              }
            );
            "role without a folder" = with' (removeAttrs good.folders [ "10_Ideas" ]);
            "status not a list" = good // {
              ideaStatus.seed = "A hunch.";
            };
            "status with another field" = good // {
              ideaStatus = good.ideaStatus ++ [
                {
                  name = "parked";
                  meaning = "On hold.";
                  since = "2026";
                }
              ];
            };
            "status name used twice" = good // {
              ideaStatus = good.ideaStatus ++ [ (builtins.head good.ideaStatus) ];
            };
            "status with an empty meaning" = good // {
              ideaStatus = good.ideaStatus ++ [
                {
                  name = "parked";
                  meaning = "";
                }
              ];
            };
          };
          accepted = lib.filter (name: !rejects bad.${name}) (lib.attrNames bad);
          home =
            (home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                self.homeModules.default
                {
                  home = {
                    username = "test";
                    homeDirectory = "/home/test";
                    stateVersion = "26.05";
                    enableNixpkgsReleaseCheck = false; # master on nixpkgs 26.05
                  };
                  setup.para.enable = true;
                }
              ];
            }).activationPackage;
        in
        checks
        // {
          para = pkgs.writeText "para.json" (builtins.toJSON para);
          para-rejects =
            assert lib.assertMsg (
              accepted == [ ]
            ) "lib/para.nix accepts: ${lib.concatStringsSep "; " accepted}";
            pkgs.runCommand "para-rejects" { } "touch $out";
          # module: the folders are seeded in flow order, AGENTS.md once, and
          # each folder links the profile its spec names.
          module = pkgs.runCommand "module" { nativeBuildInputs = [ pkgs.jq ]; } ''
            grep -qF 'mkdir -p "/home/test/Knowledge/10_Ideas"' ${home}/activate
            agents=$(grep -o '/nix/store/[^ ]*-AGENTS.md' ${home}/activate | head -1)
            grep -qF '| `90_Archive` | Superseded' "$agents"
            grep -qF 'Not linted. |' "$agents"
            grep -qF '| `seed` | A hunch' "$agents"
            test "$(grep -o '^| `[a-z]*` | [A-Z]' "$agents" | cut -d'`' -f2 | tr '\n' ' ')" = "seed exploring shaped promoted dropped "
            ! grep -q '@[A-Z]*@' "$agents"
            cfg=${home}/home-files/Knowledge
            jq -e '.config.default == false' $cfg/90_Archive/.markdownlint-cli2.jsonc
            jq -e '.config["no-alerts"] == false and .config.MD033 != false' $cfg/20_Projects/.markdownlint-cli2.jsonc
            test $(ls -A $cfg | wc -l) -eq 7
            touch $out
          '';
        }
      ) repo.checks;
    };
}
