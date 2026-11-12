# bundler

This project automates updating deployment templates `manifest.toml`
and keeps the changes tracked through a config-as-code style
canary deployment system. It is built on CICD + scripts which update
vendlive.

# Updates

A pipeline can be run to update all the submodules and gather the changes
to update pilot manifest. From this, a deployment template can be created
and a set of release notes can be made.

Once the pilot is concluded, the pilot can be "promoted" to the stable
manifest through a pipeline

The version numbers can be manually managed instead of relying on CICD.

# Including projects in the bundler

Create a deployment ssh key that lets github actions update git submodule.

1. Add the repo as a submodule at a path matching its `manifest.toml` package
   name: `git submodule add git@github.com:aeguana/<repo>.git <package>`.
2. Give the `pilot` GitHub Action read access to it. Either add one
   machine-user key to the `SUBMODULE_SSH_KEYS` secret, or create a deploy key
   per repo (`ssh-keygen -t ed25519 -C git@github.com:aeguana/<repo>.git`),
   add the public half to that repo as a read-only deploy key and append the
   private half to `SUBMODULE_SSH_KEYS`. The comment must be the repo URL so
   the agent picks the right key.

# Pilot (staging)

`just pilot` (or Run workflow on the Actions tab) starts the `pilot` action:

1. `update-manifest` checks each submodule out at its latest release tag, bumps
   its pin and opens a `pilot/staging` PR with the CHANGELOG.yaml entries as
   release notes.
2. `run-HIL-test` and `integration-tests` run against that branch.
3. `deploy-staging` waits for a reviewer to approve the `staging` environment,
   then deploys.
4. Merge the PR to promote.

One-time repo setup:

- Settings > Actions > General: allow GitHub Actions to create pull requests.
- Settings > Environments: create `staging` and add required reviewers. This is
  the approval gate.

Production is not wired up yet; it will get its own environment and gated job.
`just roundup` does step 1 locally without committing.
