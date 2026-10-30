"""para-check: compare the vault with the PARA spec (T6-l, T6-m).

Reports, never fixes. Two modes:

    para-check --repo [--vendored PREFIX ...]       the files git sees, from
                                                    the vault's root (repo-check, CI)
    para-check [--vault DIR] [--report FILE]        the live tree (the weekly report)

Findings:
  missing  a folder of the spec that is not there (live tree only)
  unknown  a visible folder at the top that the spec does not list
  format   a file in a PARA folder that is not a content format
  binary   a binary file where only text belongs
  size     a raster illustration over the limit
  csp      a page without a Content-Security-Policy that forbids every request
  status   an idea note without a status from the spec
  lint     a folder's lint config that is not the link to its profile
           (live tree only, when the module manages them)

A file still encrypted by git-crypt (a clone without the key, CI) is checked
by its name only. Vendored copies are text of any kind.

Exit status: 0 nothing found, 1 findings, 2 usage error.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_SPEC = os.environ.get("PARA_CHECK_SPEC", "")
DEFAULT_LINT = os.environ.get("PARA_CHECK_LINT", "")
GIT_CRYPT_HEADER = b"\0GITCRYPT\0"
LINT_CONFIG = ".markdownlint-cli2.jsonc"
META = re.compile(r"<meta\b[^>]*>", re.I)
CSP_CONTENT = re.compile(r"\bcontent\s*=\s*(\"[^\"]*\"|'[^']*')", re.I)
STATUS = re.compile(r"\*\*Status:\*\*\s*([a-z]+)")
NOT_AN_IDEA = re.compile(r"^[A-Z]+\.md$")  # INDEX.md, README.md, TEMPLATE.md


def hidden(path: str) -> bool:
    return any(part.startswith(".") for part in path.split("/"))


def git_files() -> list[str]:
    """The files repo-check sees: tracked, and untracked but not ignored."""
    out = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        capture_output=True,
        check=True,
    ).stdout.decode()
    return [f for f in out.split("\0") if f and Path(f).is_file()]


def tree_files() -> list[str]:
    """The visible files of the live tree; hidden folders are not entered."""
    found = []
    for root, dirs, files in os.walk("."):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for f in files:
            path = os.path.relpath(os.path.join(root, f))
            if not hidden(path) and os.path.isfile(path):
                found.append(path)
    return sorted(found)


def head(path: str, size: int) -> bytes:
    with open(path, "rb") as f:
        return f.read(size)


def is_locked(path: str) -> bool:
    return head(path, len(GIT_CRYPT_HEADER)) == GIT_CRYPT_HEADER


def is_binary(path: str) -> bool:
    """Like git: a NUL byte in the first 8000 bytes marks a file as binary."""
    return b"\0" in head(path, 8000)


def csp_problem(path: str) -> str | None:
    """A page must forbid every request it does not allow, and allow no web address."""
    text = Path(path).read_text(encoding="utf-8", errors="replace")
    for meta in META.findall(text):
        if "content-security-policy" not in meta.lower():
            continue
        content = CSP_CONTENT.search(meta)
        policy = content.group(1)[1:-1].lower() if content else ""
        if "default-src 'none'" not in policy:
            return "its Content-Security-Policy lacks default-src 'none'"
        if "connect-src" in policy:
            return "its Content-Security-Policy allows connect-src"
        if re.search(r"https?:|wss?:|\*", policy):
            return "its Content-Security-Policy allows a web address"
        return None
    return "no Content-Security-Policy <meta> element"


def status_problem(path: str, statuses: list[str]) -> str | None:
    lines = Path(path).read_text(encoding="utf-8", errors="replace").splitlines()
    for line in lines[:10]:
        m = STATUS.search(line)
        if m:
            if m.group(1) in statuses:
                return None
            return f"status `{m.group(1)}` is not one of {', '.join(statuses)}"
    return "no **Status:** line near the top"


def file_problems(path: str, spec: dict, vendored: tuple[str, ...]):
    folders = spec["folders"]
    formats = spec["content"]["formats"]
    limit = spec["content"]["rasterKiB"] * 1024
    ideas = next(n for n, f in folders.items() if f["role"] == "ideas")
    statuses = [s["name"] for s in spec["ideaStatus"]]
    top = path.split("/")[0]
    visible = not hidden(path)
    locked = is_locked(path)

    if visible and "/" in path and top not in folders:
        yield "unknown", path, f"in `{top}/`, which is not a folder of the spec"
        return
    if not visible or "/" not in path or path.startswith(vendored):
        if is_binary(path) and not locked and not path.startswith(".git-crypt/"):
            yield "binary", path, "binary file outside the content"
        return

    ext = Path(path).suffix.lower().lstrip(".")
    kind = formats.get(ext)
    if kind is None:
        yield "format", path, f"not a content format (.{ext or 'no extension'})"
    elif locked:
        return
    elif kind == "raster":
        size = os.path.getsize(path)
        if size > limit:
            yield (
                "size",
                path,
                f"{size // 1024} KiB, over the {limit // 1024} KiB limit",
            )
    elif is_binary(path):
        yield "binary", path, "binary"
    elif kind == "page":
        problem = csp_problem(path)
        if problem:
            yield "csp", path, problem
    if (
        kind == "note"
        and not locked
        and os.path.dirname(path) == ideas
        and not NOT_AN_IDEA.match(os.path.basename(path))
        and path.endswith(".md")
    ):
        problem = status_problem(path, statuses)
        if problem:
            yield "status", path, problem


def tree_problems(spec: dict, lint: dict):
    """What only the live tree shows: missing folders and the lint links."""
    for name in spec["folders"]:
        if not os.path.isdir(name):
            yield "missing", name, "a folder of the spec, not there"
    with os.scandir(".") as it:
        for d in it:
            if (
                d.is_dir()
                and not d.name.startswith(".")
                and d.name not in spec["folders"]
            ):
                yield "unknown", d.name, "a visible folder the spec does not list"
    for name, want in lint.items():
        path = os.path.join(name, LINT_CONFIG)
        if not os.path.islink(path):
            yield "lint", path, "not the link to its profile (edited or missing)"
        elif os.path.realpath(path) != os.path.realpath(want):
            yield "lint", path, "links to another profile than the spec names"


def report(found: list[tuple[str, str, str]], vault: str) -> str:
    lines = [f"# para-check: {vault}", ""]
    if not found:
        lines.append("Nothing found: the vault matches the spec.")
    else:
        lines += ["| Finding | Path | Meaning |", "| --- | --- | --- |"]
        lines += [f"| {k} | `{p}` | {m} |" for k, p, m in found]
    return "\n".join(lines) + "\n"


def load(path: str, what: str, p: argparse.ArgumentParser) -> dict:
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError) as e:
        p.error(f"cannot read the {what} {path}: {e}")


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("--spec", default=DEFAULT_SPEC, help="the spec as JSON")
    p.add_argument(
        "--lint", default=DEFAULT_LINT, help="folder -> profile file, as JSON"
    )
    p.add_argument(
        "--repo", action="store_true", help="the files git sees, from the vault's root"
    )
    p.add_argument("--vault", default=os.path.expanduser("~/Knowledge"))
    p.add_argument(
        "--vendored",
        action="extend",
        nargs="+",
        default=[],
        help="path prefixes of vendored copies",
    )
    p.add_argument("--report", help="write a Markdown report to this file")
    a = p.parse_args()
    if not a.spec:
        p.error("no --spec and no PARA_CHECK_SPEC")
    spec = load(a.spec, "spec", p)
    lint = load(a.lint, "lint map", p) if a.lint and not a.repo else {}
    report_file = os.path.abspath(a.report) if a.report else None

    vault = os.getcwd() if a.repo else os.path.abspath(a.vault)
    try:
        os.chdir(vault)
    except OSError as e:
        p.error(f"cannot enter the vault {vault}: {e}")
    files = git_files() if a.repo else tree_files()
    vendored = tuple(a.vendored)
    found = [x for f in files for x in file_problems(f, spec, vendored)]
    if not a.repo:
        found += tree_problems(spec, lint)
    found.sort()

    if report_file:
        os.makedirs(os.path.dirname(report_file), exist_ok=True)
        with open(report_file, "w", encoding="utf-8") as f:
            f.write(report(found, vault))
    for k, path, m in found:
        print(f"para-check: {k}: {path}: {m}")
    if found:
        print(f"para-check: {len(found)} findings", file=sys.stderr)
        return 1
    locked = sum(is_locked(f) for f in files)
    tail = (
        f", {locked} locked by git-crypt (only their names checked)" if locked else ""
    )
    print(f"    {len(files)} files checked{tail}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
