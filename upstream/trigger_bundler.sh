#!/usr/bin/env bash
# Drop into a project repo. Asks bundler to open a QA PR pinning this project
# to the version just published. Needs CIRCLE_TOKEN in the calling job.
set -euo pipefail

PROJECT="${PROJECT:-${CIRCLE_PROJECT_REPONAME:?PROJECT is not set}}"
VERSION="${VERSION:-${CIRCLE_TAG:?VERSION is not set}}"
PACKAGE="${PACKAGE:-$PROJECT}"    # set only if the manifest name differs
BUNDLER="${BUNDLER:-gh/aeguana/bundler}"

echo "Triggering ${BUNDLER}: ${PROJECT} ${VERSION#v}"
# branch: main so the QA branch is always cut from bundler's main.
curl --silent --show-error --fail \
  -X POST "https://circleci.com/api/v2/project/${BUNDLER}/pipeline" \
  -H "Circle-Token: ${CIRCLE_TOKEN:?CIRCLE_TOKEN is not set}" \
  -H "Content-Type: application/json" \
  -d "{\"branch\":\"main\",\"parameters\":{
        \"project\":\"${PROJECT}\",
        \"version\":\"${VERSION#v}\",
        \"package\":\"${PACKAGE}\"}}"
