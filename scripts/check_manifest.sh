#!/usr/bin/env bash
# Fail if any manifest.toml pin is malformed or listed twice.
set -euo pipefail

MANIFEST="${1:-manifest.toml}"
status=0

# Everything that isn't blank, a comment or the [packages] header must look
# like name==version (or name=version, which some entries use).
bad=$(grep -nvE '^\s*(#.*|\[.*\]|[A-Za-z0-9._-]+==?[^ ]+)?\s*$' "${MANIFEST}" || true)
if [ -n "${bad}" ]; then
  echo "${MANIFEST}: cannot parse:" >&2
  # shellcheck disable=SC2001  # per-line prefix, not a glob substitution
  echo "${bad}" | sed 's/^/  /' >&2
  status=1
fi

dupes=$(sed -nE 's/^([A-Za-z0-9._-]+)==?.*/\1/p' "${MANIFEST}" | sort | uniq -d)
if [ -n "${dupes}" ]; then
  echo "${MANIFEST}: pinned more than once:" >&2
  # shellcheck disable=SC2001  # per-line prefix, not a glob substitution
  echo "${dupes}" | sed 's/^/  /' >&2
  status=1
fi

if [ "${status}" -eq 0 ]; then
  echo "$(grep -cE '^[A-Za-z0-9._-]+==?' "${MANIFEST}") pins OK"
fi
exit "${status}"
