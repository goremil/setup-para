# Knowledge vault

Notes and the management of work, organized by PARA. The work itself (code, media, other heavy files) lives in the home directory; notes point at it, and a heavy item keeps its place while its role changes.

Seeded by `setup-para` from its spec; edited by hand from then on.

## Folders

Numbered in tens by the flow, so a new folder fits in without renumbering. A folder names a role; an item takes the role of the folder it is in, and moves on as its role changes.

@FOLDERS@

## Ideas

One note per idea, with one of these statuses:

@IDEAS@

## Rules for agents

- Write only inside the folders above: create and edit notes there, and keep each folder's `INDEX.md` current where one exists.
- Moving a note between folders needs the user's confirmation; so does deleting anything.
- Do not rewrite an idea's core or change its status without asking.
- An `INDEX.md` adds only what a listing does not (R-index-01); a folder with nothing to add has none (R-index-03).
- The markdownlint config of each folder is managed by `setup-para`; do not edit it.

## Deviations

Departures from the `setup-base` rule core, one row each (R-rules-03).

| Rule | What differs | Reason | Since | Decision |
| --- | --- | --- | --- | --- |
