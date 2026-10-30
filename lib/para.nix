# lib.para: the spec in para.nix with every value checked at evaluation. A
# wrong value stops the evaluation with the name it is about;
# builtins.toJSON forces the whole check.
spec:
let
  inherit (builtins)
    attrNames
    attrValues
    concatStringsSep
    elem
    filter
    hasAttr
    isAttrs
    isInt
    isList
    isString
    length
    map
    mapAttrs
    match
    substring
    ;

  lints = [
    "agent"
    "forge"
    "hybrid"
    "off"
  ];
  sections = [
    "roles"
    "folders"
    "kinds"
    "ideaStatus"
    "content"
  ];
  classes = [
    "note"
    "illustration"
    "raster"
    "page"
    "asset"
  ];
  fields = [
    "role"
    "lint"
  ];

  fail = name: msg: throw "para.nix: ${name}: ${msg}";
  count = x: xs: length (filter (y: y == x) xs);

  # A lowercase camelCase name with a non-empty definition.
  definition =
    section: name: text:
    if !(isString text) || text == "" then
      fail "${section}.${name}" "the definition must be a non-empty string"
    else if match "[a-z][a-zA-Z]*" name == null then
      fail "${section}.${name}" "a name is lowercase camelCase"
    else
      text;
  definitions = section: mapAttrs (definition section) spec.${section};

  roles = definitions "roles";

  folder =
    name: f:
    let
      unknown = filter (k: !elem k fields) (attrNames f);
      number = substring 0 2 name;
    in
    if match "[0-9]{2}_[A-Z][A-Za-z]*" name == null then
      fail name "a folder name is NN_Name"
    else if unknown != [ ] then
      fail name "unknown field ${concatStringsSep ", " unknown}"
    else if !(f ? role) || !(hasAttr f.role roles) then
      fail name "missing or unknown role"
    else if !(f ? lint) || !elem f.lint lints then
      fail name "lint is one of ${concatStringsSep ", " lints}"
    else if count number (map (substring 0 2) (attrNames spec.folders)) > 1 then
      fail name "number ${number} is used twice"
    else
      f;

  folders = mapAttrs folder spec.folders;
  usedRoles = map (f: f.role) (attrValues folders);
  unfolded = filter (r: count r usedRoles != 1) (attrNames roles);

  unknownSections = filter (s: !elem s sections) (attrNames spec);
  missingSections = filter (
    s: !(spec ? ${s}) || !(if s == "ideaStatus" then isList spec.${s} else isAttrs spec.${s})
  ) sections;

  # content: { formats = { EXT = CLASS; }; rasterKiB = N; }, nothing else.
  content =
    let
      c = spec.content;
      format =
        ext: class:
        if match "[a-z0-9]+" ext == null then
          fail "content.formats.${ext}" "an extension is lowercase, without the dot"
        else if !elem class classes then
          fail "content.formats.${ext}" "the class is one of ${concatStringsSep ", " classes}"
        else
          class;
    in
    if
      attrNames c != [
        "formats"
        "rasterKiB"
      ]
    then
      fail "content" "content is { formats; rasterKiB; }"
    else if !(isAttrs c.formats) || c.formats == { } then
      fail "content.formats" "a non-empty attribute set"
    else if !(isInt c.rasterKiB) || c.rasterKiB < 1 then
      fail "content.rasterKiB" "a positive integer"
    else
      c // { formats = mapAttrs format c.formats; };

  # ideaStatus: an ordered list of { name; meaning; }, names unique.
  statuses = map (
    st:
    if
      !(isAttrs st)
      ||
        attrNames st != [
          "meaning"
          "name"
        ]
    then
      fail "ideaStatus" "each status is { name; meaning; }"
    else if count st.name (map (x: x.name or null) spec.ideaStatus) > 1 then
      fail "ideaStatus.${st.name}" "the name is used twice"
    else
      st // { meaning = definition "ideaStatus" st.name st.meaning; }
  ) spec.ideaStatus;
in
if unknownSections != [ ] then
  fail "spec" "unknown section ${concatStringsSep ", " unknownSections}"
else if missingSections != [ ] then
  fail "spec" "missing or malformed section ${concatStringsSep ", " missingSections} (ideaStatus is a list, the others attribute sets)"
else if unfolded != [ ] then
  fail "roles" "each role needs exactly one folder: ${concatStringsSep ", " unfolded}"
else
  {
    inherit roles folders;
    kinds = definitions "kinds";
    ideaStatus = statuses;
    inherit content;
  }
