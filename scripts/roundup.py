#!/usr/bin/env python3
"""Move every submodule to its latest release tag and bump its manifest.toml pin.

The submodule path is used as the manifest package name. Release notes for each
bump (the CHANGELOG.yaml entries between the old pin and the new tag) are
written to the file given by --notes.

Usage: roundup.py [--notes release_notes.md]
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

import yaml

MANIFEST = Path("manifest.toml")
VERSION_TAG = re.compile(r"^v?(\d+(?:\.\d+)*)$")


def git(*args, cwd="."):
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True, capture_output=True, text=True
    ).stdout.strip()


def vkey(version):
    return tuple(int(p) for p in version.split("."))


def submodule_paths():
    out = git("config", "--file", ".gitmodules", "--get-regexp", r"\.path$")
    return [line.split(maxsplit=1)[1] for line in out.splitlines()]


def latest_tag(path):
    git("fetch", "--quiet", "--tags", "--force", "origin", cwd=path)
    tags = [t for t in git("tag", cwd=path).splitlines() if VERSION_TAG.match(t)]
    if not tags:
        return None
    return max(tags, key=lambda t: vkey(VERSION_TAG.match(t).group(1)))


def changelog(path, old, new):
    """CHANGELOG.yaml entries with old < version <= new, newest first."""
    file = Path(path, "CHANGELOG.yaml")
    if not file.exists():
        return []
    entries = yaml.safe_load(file.read_text()) or {}
    picked = []
    for version, entry in entries.items():
        version = str(version)
        if not VERSION_TAG.match(version):
            continue
        if old is None or vkey(old) < vkey(version) <= vkey(new):
            picked.append((version, entry or {}))
    return sorted(picked, key=lambda p: vkey(p[0]), reverse=True)


def render_entry(version, entry):
    lines = [f"#### {version}"]
    for key, value in entry.items():
        if key == "Description":
            continue
        if isinstance(value, bool):  # YAML reads "no" as False
            value = "yes" if value else "no"
        lines.append(f"- **{key}:** {' '.join(str(value).split())}")
    desc = entry.get("Description")
    if isinstance(desc, list):
        desc = "\n".join(f"- {d}" for d in desc)
    if desc:
        lines += ["", str(desc).strip()]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--notes", default="release_notes.md")
    args = parser.parse_args()

    manifest = MANIFEST.read_text()
    notes = []
    status = 0

    for path in submodule_paths():
        pin = re.compile(rf"^({re.escape(path)})(==?)(\S+)$", re.M)
        match = pin.search(manifest)
        if not match:
            print(f"error: '{path}' is not pinned in {MANIFEST}", file=sys.stderr)
            status = 1
            continue
        old = match.group(3)

        tag = latest_tag(path)
        if tag is None:
            print(f"{path}: no release tags, skipping", file=sys.stderr)
            continue
        new = VERSION_TAG.match(tag).group(1)

        if vkey(new) < vkey(old):
            print(f"{path}: pinned at {old}, ahead of latest tag {tag}; leaving it")
            continue

        git("checkout", "--quiet", tag, cwd=path)

        if new == old:
            print(f"{path}: {old} is current")
            continue

        print(f"{path}: {old} -> {new}")
        manifest = pin.sub(rf"\g<1>\g<2>{new}", manifest, count=1)
        section = [f"### {path} {old} → {new}"]
        section += [render_entry(v, e) for v, e in changelog(path, old, new)]
        notes.append("\n\n".join(section))

    MANIFEST.write_text(manifest)
    Path(args.notes).write_text("\n\n".join(notes) + "\n" if notes else "")
    return status


if __name__ == "__main__":
    sys.exit(main())
