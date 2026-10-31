# Knowledge vault

Notes and the management of work, organized by PARA. The work itself (code, media, other heavy files) lives in the home directory; notes point at it, and a heavy item keeps its place while its role changes.

Seeded by `setup-para` from its spec; edited by hand from then on.

## Folders

Numbered in tens by the flow, so a new folder fits in without renumbering. A folder names a role; an item takes the role of the folder it is in, and moves on as its role changes.

@FOLDERS@

## Ideas

One note per idea, with one of these statuses:

@IDEAS@

## Work and boards

A board is the to-do list of a project or an area; there is no other list format.

- **Where.** A small project or a simple area is one board file, `20_Projects/<name>.kanban.md` or `30_Areas/<name>.kanban.md`; a larger one is a folder with `<name>.kanban.md` and the notes its cards link to. Board files, and only they, end in `.kanban.md`.
- **Format.** The Obsidian Kanban plugin's: front matter `kanban-plugin: board`; the columns `## Backlog`, `## In Progress` (an optional work-in-progress limit in the heading, `## In Progress (3)`) and `## Done`; a card is `- [ ] …`, its further lines indented with 4 spaces; the plugin's settings block at the end. Edited as a board in Obsidian; elsewhere a board is plain Markdown.
- **Cards.** Short: a bold title with its id, the next step, tags nested with a slash, a link to the note that holds a longer plan: `**K001 Title.** Next: … #p/high #waits/user [plan](…)`. Links are relative Markdown links. Counts are never written; the plugin and the generated view derive them.
- **Project or area.** A card goes to a project when it has a goal and an end, to an area when it is standing work with no end date.
- **Kept current.** When a matter moves or closes, its card is edited at once, in the same change.
- **Closed cards.** A project keeps its closed cards in `Done` while it runs. An area's closed card moves at once to the year's archive board, `90_Archive/done-<year>.kanban.md`, into the column named after the area, with the date it closed and a link to its result (a commit, a note); a reopened card moves back.
- **Closing a project.** First distil it: lessons and findings to `40_Resources` or an area's notes, open cards to the area it feeds. Then the whole project, its board with its `Done`, moves to `90_Archive`.
- **Records and knowledge.** The archive keeps the record, by origin and unmaintained; knowledge a card produced goes where it is looked for (a topic note in `40_Resources`, an area's note, a repository's docs), and the archived card links to it.
- **`now.md`.** The vault's root may hold `now.md`, a view generated from the boards and ignored by git; it is never edited by hand.

## Rules for agents

- Write only inside the folders above: create and edit notes there, and keep each folder's `INDEX.md` current where one exists.
- Moving a note between folders needs the user's confirmation; so does deleting anything. Exception: moving a closed card of an area to the archive board, and back when it reopens, needs none (closing the card is the decision).
- Do not rewrite an idea's core or change its status without asking.
- An `INDEX.md` adds only what a listing does not (R-index-01); a folder with nothing to add has none (R-index-03).
- The markdownlint config of each folder is managed by `setup-para`; do not edit it.

## Deviations

Departures from the `setup-base` rule core, one row each (R-rules-03).

| Rule | What differs | Reason | Since | Decision |
| --- | --- | --- | --- | --- |
