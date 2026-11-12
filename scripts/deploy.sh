#!/usr/bin/env bash
# Placeholder deployment. Runs once HIL, integration and the manual gate are
# all green. Replace the body when the real deploy tooling is ready.
#
# Usage: deploy.sh [staging|production]   (default: staging)
set -euo pipefail

ENVIRONMENT="${1:-staging}"
case "${ENVIRONMENT}" in
  staging) ;;
  production) echo "error: production deploys are not enabled yet" >&2; exit 1 ;;
  *) echo "error: unknown environment '${ENVIRONMENT}'" >&2; exit 1 ;;
esac

echo "Deployed to ${ENVIRONMENT} (fake). Merge the PR to promote."
