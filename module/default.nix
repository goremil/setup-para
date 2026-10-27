# homeModules.default: applies the PARA spec to the vault in home-manager.
#
# - An activation step creates the missing folders and, once, the vault's
#   AGENTS.md from agents-vault.md plus tables of the folders and the idea
#   statuses (T6-d); it never overwrites anything. No INDEX.md is seeded
#   (T6-k).
# - setup.para.lint: each folder's .markdownlint-cli2.jsonc, linked from the
#   store to the profile its spec names (T6-c), so a new profile arrives with
#   a switch.
{ para, base }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.setup.para;
  inherit (para) folders roles ideaStatus;
  names = lib.attrNames folders; # NN_Name sorts in flow order

  folderRow =
    name:
    let
      f = folders.${name};
    in
    "| `${name}` | ${roles.${f.role}}${lib.optionalString (f.lint == "off") " Not linted."} |";
  statusRow = st: "| `${st.name}` | ${st.meaning} |";
  table = header: rows: lib.concatStringsSep "\n" ([ header ] ++ [ "| --- | --- |" ] ++ rows);

  agentsFile = pkgs.writeText "AGENTS.md" (
    builtins.replaceStrings
      [ "@FOLDERS@" "@IDEAS@" ]
      [
        (table "| Folder | Role |" (map folderRow names))
        (table "| Status | Meaning |" (map statusRow ideaStatus))
      ]
      (builtins.readFile ./agents-vault.md)
  );

  vault = "${config.home.homeDirectory}/${cfg.vault}";
in
{
  options.setup.para = {
    enable = lib.mkEnableOption "the PARA skeleton of the vault from setup-para";
    vault = lib.mkOption {
      type = lib.types.str;
      default = "Knowledge";
      description = "The vault, relative to the home directory.";
    };
    lint.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether each folder gets its managed markdownlint config.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.activation.setupParaSeed = config.lib.dag.entryAfter [ "writeBoundary" ] (
          lib.concatMapStrings (name: ''
            if [ ! -e "${vault}/${name}" ]; then
              run mkdir -p "${vault}/${name}"
            fi
          '') names
          + ''
            if [ ! -e "${vault}/AGENTS.md" ]; then
              run install -m 0644 ${agentsFile} "${vault}/AGENTS.md"
            fi
          ''
        );
      }
      (lib.mkIf cfg.lint.enable {
        home.file = lib.listToAttrs (
          map (
            name:
            lib.nameValuePair "${cfg.vault}/${name}/.markdownlint-cli2.jsonc" {
              source = "${
                base.lib.markdownlint.config pkgs { profile = folders.${name}.lint; }
              }/.markdownlint-cli2.jsonc";
            }
          ) names
        );
      })
    ]
  );
}
