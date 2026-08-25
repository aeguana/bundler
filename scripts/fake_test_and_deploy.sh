#!/usr/bin/env bash
# Placeholder for the real QA test + deployment run. Sits behind the manual
# approval gate. Swap the body out when the real tooling lands; the pipeline
# only depends on the two arguments and a non-zero exit on failure.
set -euo pipefail

PROJECT="${1:?usage: fake_test_and_deploy.sh <project> <version>}"
VERSION="${2:?usage: fake_test_and_deploy.sh <project> <version>}"

step() { printf '\n==> %s\n' "$1"; }

step "QA run for ${PROJECT} ${VERSION} on $(git rev-parse --abbrev-ref HEAD)"
grep -E "^[A-Za-z0-9._-]+==?" manifest.toml | sed 's/^/  /'

step "Fake test suite"
for suite in unit integration smoke; do
  echo "  [PASS] ${suite} (fake)"
done

step "Fake deployment"
# Uncommented `<env>: <id>` entries under deployment_templates.yaml are targets.
grep -E '^\s+(staging|production):\s*[0-9]+' deployment_templates.yaml \
  | tr -d ' ' \
  | while IFS=: read -r env id; do
      echo "  [FAKE] deploy ${PROJECT}==${VERSION} -> ${env} (template ${id})"
    done

step "Done"
echo "Fake QA passed for ${PROJECT} ${VERSION}. Merge the PR to promote."
