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
      repo = base.lib.mkRepo {
        inherit self;
        features = [ "python" ];
      };
      para = import ./lib/para.nix (import ./para.nix);
      inherit (base.inputs.nixpkgs) lib;
    in
    repo
    // {
      # The checked spec, for setup-home (the kinds) and setup-nixos.
      lib = { inherit para; };

      homeModules.default = import ./module { inherit para base; };

      # para-check with this spec, for the vault's repo-check (T6-m).
      packages = lib.mapAttrs (
        system: _:
        let
          pc = import ./tools/package.nix {
            pkgs = base.inputs.nixpkgs.legacyPackages.${system};
            inherit para;
          };
        in
        {
          inherit (pc) para-check;
          default = pc.para-check;
        }
      ) repo.checks;

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
            "content with another field" = good // {
              content = good.content // {
                images = [ ];
              };
            };
            "extension with a dot" = good // {
              content = good.content // {
                formats.".pdf" = "note";
              };
            };
            "unknown content class" = good // {
              content = good.content // {
                formats = good.content.formats // {
                  pdf = "document";
                };
              };
            };
            "raster limit not positive" = good // {
              content = good.content // {
                rasterKiB = 0;
              };
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
                  setup.para = {
                    enable = true;
                    check = {
                      enable = true;
                      vendored = [ "20_Projects/vend/" ];
                    };
                  };
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
          # para-check on a test vault: a clean one passes in both modes, then
          # each finding is planted once and reported.
          para-check =
            let
              pc = import ./tools/package.nix { inherit pkgs para; };
              lintMap = pkgs.writeText "lint.json" (
                builtins.toJSON {
                  "10_Ideas" = "${pkgs.writeText "profile" "{}"}";
                  "20_Projects" = "${pkgs.writeText "profile" "{}"}";
                }
              );
            in
            pkgs.runCommand "para-check"
              {
                nativeBuildInputs = [
                  pc.unwrapped
                  pkgs.git
                ];
              }
              ''
                export PARA_CHECK_SPEC=${pc.json} HOME="$TMPDIR"
                mkdir v && cd v
                mkdir ${lib.concatStringsSep " " (lib.attrNames para.folders)}
                csp='<meta http-equiv="Content-Security-Policy" content="default-src '"'"'none'"'"'">'
                printf '# A\n\n**Captured:** 2026-10-30 · **Status:** seed\n' > 10_Ideas/a.md
                echo '# Ideas' > 10_Ideas/INDEX.md
                echo '<svg/>' > 20_Projects/p.svg
                echo "$csp" > 40_Resources/page.html
                mkdir 20_Projects/vend && echo 'print(1)' > 20_Projects/vend/tool.py
                printf 'x\0y' > .hidden-binary-in-tree
                git init -q && git add -A
                ! para-check --repo --vendored 20_Projects/vend/ > out
                grep -q 'binary: .hidden-binary-in-tree' out
                git rm -q --cached .hidden-binary-in-tree && rm .hidden-binary-in-tree
                para-check --repo --vendored 20_Projects/vend/
                para-check --vault . --vendored 20_Projects/vend/

                printf '# B\n\n**Status:** maybe\n' > 10_Ideas/b.md
                echo '# C' > 10_Ideas/c.md
                echo x > 20_Projects/x.pdf
                mkdir Stuff && echo x > Stuff/n.md
                head -c 600000 /dev/zero | tr '\0' x > 30_Areas/big.png
                echo '<p>no policy</p>' > 40_Resources/bare.html
                printf 'a\0b' > 40_Resources/bin.md
                rmdir 99_Scratchpad
                ln -s ${pkgs.writeText "profile" "{}"} 10_Ideas/.markdownlint-cli2.jsonc
                echo '{}' > 20_Projects/.markdownlint-cli2.jsonc
                ! para-check --vault . --vendored 20_Projects/vend/ --lint ${lintMap} --report "$TMPDIR/r.md" > out
                cat out
                for want in \
                  'status: 10_Ideas/b.md: status `maybe`' \
                  'status: 10_Ideas/c.md: no' \
                  'format: 20_Projects/x.pdf' \
                  'unknown: Stuff/n.md' \
                  'unknown: Stuff: a visible folder' \
                  'size: 30_Areas/big.png' \
                  'csp: 40_Resources/bare.html: no Content-Security-Policy' \
                  'binary: 40_Resources/bin.md' \
                  'missing: 99_Scratchpad' \
                  'lint: 20_Projects/.markdownlint-cli2.jsonc: not the link'; do
                  grep -qF "$want" out || { echo "missing finding: $want"; exit 1; }
                done
                test "$(wc -l < out)" -eq 10
                grep -qF '| missing | `99_Scratchpad` |' "$TMPDIR/r.md"
                touch $out
              '';
          # module: the folders are seeded in flow order, AGENTS.md once, and
          # each folder links the profile its spec names.
          module = pkgs.runCommand "module" { nativeBuildInputs = [ pkgs.jq ]; } ''
            grep -qF 'mkdir -p "/home/test/Knowledge/10_Ideas"' ${home}/activate
            agents=$(grep -o '/nix/store/[^ ]*-AGENTS.md' ${home}/activate | head -1)
            grep -qF '| `90_Archive` | Inactive material' "$agents"
            grep -qF '## Work and boards' "$agents"
            grep -qF 'Not linted. |' "$agents"
            grep -qF '| `seed` | A hunch' "$agents"
            test "$(grep -o '^| `[a-z]*` | [A-Z]' "$agents" | cut -d'`' -f2 | tr '\n' ' ')" = "seed exploring shaped promoted dropped "
            ! grep -q '@[A-Z]*@' "$agents"
            cfg=${home}/home-files/Knowledge
            jq -e '.config.default == false' $cfg/90_Archive/.markdownlint-cli2.jsonc
            jq -e '.config["no-alerts"] == false and .config.MD033 != false' $cfg/20_Projects/.markdownlint-cli2.jsonc
            test $(ls -A $cfg | wc -l) -eq 7
            units=${home}/home-files/.config/systemd/user
            grep -qF "OnCalendar=Mon 10:30" $units/para-check-report.timer
            report=$(grep -o "/nix/store/[^ ]*/bin/para-check-report" $units/para-check-report.service)
            grep -qF -- "--vendored=20_Projects/vend/" "$report"
            test -x ${home}/home-path/bin/para-check
            touch $out
          '';
        }
      ) repo.checks;
    };
}
