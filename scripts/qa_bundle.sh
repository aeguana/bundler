#!/usr/bin/env bash
# Cut qa/<project>-<version> off main, bump the pin in manifest.toml, push it
# and open a PR into main. Run by CircleCI when an upstream repo publishes.
#
# Needs GITHUB_TOKEN (repo scope). Usage: qa_bundle.sh <project> <version> [package]
set -euo pipefail

PROJECT="${1:?usage: qa_bundle.sh <project> <version> [package]}"
VERSION="${2:?usage: qa_bundle.sh <project> <version> [package]}"
VERSION="${VERSION#v}"
PACKAGE="${3:-}"; PACKAGE="${PACKAGE:-$PROJECT}"   # manifest name, if it differs from the repo name
BRANCH="qa/${PROJECT}-${VERSION}"
REPO="${GITHUB_REPO:-aeguana/bundler}"

grep -qE "^${PACKAGE}==?" manifest.toml \
  || { echo "error: '${PACKAGE}' is not pinned in manifest.toml" >&2; exit 1; }

git config user.name "circleci-bundler"
git config user.email "devops@boostinc.com"
git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.git"

# Always cut from origin/main so the PR is a clean diff against main.
git fetch --quiet origin main
git checkout -B "${BRANCH}" origin/main

# Keeps whichever operator the line already uses (== or =).
sed -i.bak -E "s|^(${PACKAGE})(==?).*$|\1\2${VERSION}|" manifest.toml && rm manifest.toml.bak
grep -E "^${PACKAGE}==?" manifest.toml

if git diff --quiet -- manifest.toml; then
  echo "${PACKAGE} already at ${VERSION}; pushing branch as-is."
else
  git commit -qam "qa: bump ${PACKAGE} to ${VERSION}"
fi
git push --force-with-lease origin "${BRANCH}"

curl --silent --show-error \
  -X POST "https://api.github.com/repos/${REPO}/pulls" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -d "{\"title\":\"qa: bump ${PACKAGE} to ${VERSION}\",
       \"head\":\"${BRANCH}\",\"base\":\"main\",
       \"body\":\"Triggered by an upstream build of ${PROJECT} ${VERSION}.\n\nApprove the hold-for-qa gate to run the QA tests and deployment.\"}" \
  | grep -E '"html_url"|"message"' | head -1
