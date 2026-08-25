# bundler

Holds `manifest.toml`, the pinned package set for a release bundle. Upstream
project repos trigger this repo's CircleCI pipeline when they publish, and it
opens a QA PR bumping the pin.

```
upstream repo publishes v1.8.3
        │  CircleCI API trigger (project, version)
        ▼
  1. update-manifest      cut qa/<project>-<version> off main, bump the pin,
                          push, open a PR into main
  2. hold-for-qa          manual approval gate — click it in CircleCI
  3. fake-test-and-deploy placeholder test + deploy script
        │
        ▼
  merge the PR to promote
```

## Setup

In this repo: a CircleCI context `bundler-github` holding `GITHUB_TOKEN`
(repo scope) — used to push the QA branch and open the PR.

In each upstream repo: copy `upstream/trigger_bundler.sh` into `scripts/`, call
it from a tag-filtered job, and give that job a context holding `CIRCLE_TOKEN`.
Set `PACKAGE` in that job if the repo name differs from the manifest name.

## By hand

```sh
just trigger sandenvendo 1.8.3      # fire the pipeline
just fake-deploy sandenvendo 1.8.3  # run the placeholder QA script
just bump sandenvendo 1.8.3         # just edit the manifest
```

`scripts/fake_test_and_deploy.sh` stands in until the real tooling is ready. It
takes `<project> <version>` and fails the job on a non-zero exit — keep that
interface and the pipeline needs no changes.
