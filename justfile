set dotenv-load := true

# Run the QA placeholders locally
qa:
    ./scripts/hil_test.sh
    ./scripts/integration_tests.sh
    ./scripts/deploy.sh

# Bump a pin locally, no git
bump project version:
    sed -i.bak -E 's|^({{project}})(==?).*$|\1\2{{version}}|' manifest.toml && rm manifest.toml.bak
    @grep -E '^{{project}}==?' manifest.toml

# Move submodules to their latest tags and bump their pins, no git commit
roundup:
    ./scripts/roundup.py --notes /dev/stdout

# Run the pilot GitHub Action: roundup PR, QA tests, gated staging deploy (needs gh)
pilot:
    gh workflow run pilot.yml --ref main
    @echo "Started. Approve the staging deploy at https://github.com/aeguana/bundler/actions/workflows/pilot.yml"

_default:
    @just --list
