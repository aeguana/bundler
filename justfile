set dotenv-load := true

# Fire the real CircleCI pipeline (needs CIRCLE_TOKEN)
trigger project version:
    PROJECT={{project}} VERSION={{version}} ./upstream/trigger_bundler.sh

# Run the QA placeholders locally as if on the qa/ branch
qa project version:
    #!/usr/bin/env bash
    export CIRCLE_BRANCH="qa/{{project}}-{{version}}"
    ./scripts/hil_test.sh
    ./scripts/integration_tests.sh
    ./scripts/deploy.sh

# Bump a pin locally, no git
bump project version:
    sed -i.bak -E 's|^({{project}})(==?).*$|\1\2{{version}}|' manifest.toml && rm manifest.toml.bak
    @grep -E '^{{project}}==?' manifest.toml

_default:
    @just --list
