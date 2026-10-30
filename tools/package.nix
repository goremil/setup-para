# para-check as packages: `unwrapped` takes the spec from --spec or
# PARA_CHECK_SPEC only (the tests use it); `para-check` defaults to the spec of
# this flake, as JSON, and to `lint`, a map of folder -> profile file, when the
# module passes one.
{
  pkgs,
  para,
  lint ? null,
}:
let
  unwrapped = pkgs.writers.writePython3Bin "para-check" {
    flakeIgnore = [
      "E501"
      "W503" # ruff format breaks before a binary operator
    ];
  } (builtins.readFile ./para-check.py);
  json = pkgs.writeText "para.json" (builtins.toJSON para);
  lintJson = pkgs.writeText "para-lint.json" (builtins.toJSON lint);
in
{
  inherit unwrapped json;
  para-check = pkgs.writeShellScriptBin "para-check" ''
    export PARA_CHECK_SPEC="''${PARA_CHECK_SPEC:-${json}}"
    ${pkgs.lib.optionalString (
      lint != null
    ) ''export PARA_CHECK_LINT="''${PARA_CHECK_LINT:-${lintJson}}"''}
    export PATH="${pkgs.git}/bin:$PATH"
    exec ${unwrapped}/bin/para-check "$@"
  '';
}
