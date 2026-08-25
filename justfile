set dotenv-load := true

# Fire the real CircleCI pipeline (needs CIRCLE_TOKEN)
trigger project version:
    PROJECT={{project}} VERSION={{version}} ./upstream/trigger_bundler.sh

# Run the placeholder QA script against the working tree
fake-deploy project version:
    ./scripts/fake_test_and_deploy.sh {{project}} {{version}}

# Bump a pin locally, no git
bump project version:
    sed -i.bak -E 's|^({{project}})(==?).*$|\1\2{{version}}|' manifest.toml && rm manifest.toml.bak
    @grep -E '^{{project}}==?' manifest.toml

_default:
    @just --list
