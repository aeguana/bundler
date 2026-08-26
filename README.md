# bundler

Holds `manifest.toml`, the pinned package set for a release bundle. Upstream
project repos trigger this repo's CircleCI pipeline when they publish, and it
opens a QA PR bumping the pin.

```
upstream repo publishes v1.8.3
        │  CircleCI API trigger (project, version)
        ▼
  open-qa-pr pipeline
    update-manifest    cut qa/<project>-<version> off main, bump the pin,
                       push, open a PR into main
        │  pushing the branch starts a second pipeline
        ▼
  qa-checks pipeline   (runs on the qa/ branch, so it shows on the PR)
    run-HIL-test ────────┐
    integration-tests ───┼──> deploy
    hold-for-manual-test ┘
        │
        ▼
  merge the PR to promote
```

The split is deliberate: the checks run against the `qa/` branch rather than as
part of the upstream trigger, so GitHub reports them on the PR and you can get
at the logs from there.

## Setup

In this repo: a CircleCI context `bundler-github` holding `GITHUB_TOKEN`
(repo scope) — used to push the QA branch and open the PR.

In each upstream repo: copy `upstream/trigger_bundler.sh` into `scripts/`, call
it from a tag-filtered job, and give that job a context holding `CIRCLE_TOKEN`.
Set `PACKAGE` in that job if the repo name differs from the manifest name.

## Hooks

```sh
pip install pre-commit && pre-commit install
```

Runs shellcheck over the scripts, validates `manifest.toml` pins, and catches
stray whitespace, missing newlines and committed keys.

## By hand

```sh
just trigger sandenvendo 1.8.3      # fire the pipeline
just qa sandenvendo 1.8.3           # run the QA placeholders locally
just bump sandenvendo 1.8.3         # just edit the manifest
```

`hil_test.sh`, `integration_tests.sh` and `deploy.sh` are placeholders. Each
sources `qa_context.sh` for `PROJECT`/`VERSION` (parsed from the branch name)
and fails its job on a non-zero exit — keep that and the pipeline needs no
changes when the real tooling lands.
