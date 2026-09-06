# `projectbluefin/actions` Catalog

**Snapshot:** [`9c699818ddf1043b8f5af8b862f59f783c6c7bda`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda) (2026-09-06)

This is the complete catalog of GitHub Actions assets present in the upstream
repository at this snapshot. It distinguishes supported consumer building
blocks from Project Bluefin's own maintenance automation. A file existing in
this repository does not make it a required Finpilot feature.

The upstream [consumer contract](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/docs/consumer-contract.yml)
records the stable input surface used by external consumers. Prefer it over
copying implementation from an action.

## Consumer composite actions

These are independently callable from a job using
`uses: projectbluefin/actions/<path>@<pinned-SHA>`.

| Action | Purpose | Required inputs |
| --- | --- | --- |
| [`bootc-build/setup-runner`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/setup-runner) | Configures a bootc image-build runner: Podman, storage backend/overlay, optional tools | None |
| [`bootc-build/preflight`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/preflight) | Verifies runner and registry prerequisites before a build | `github-token` |
| [`bootc-build/dnf-cache`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/dnf-cache) | Restores or saves the DNF/Buildah cache with permission handling | `action`, `cache-name` |
| [`bootc-build/detect-changes`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/detect-changes) | Determines whether image paths changed and can compute an image-flavor matrix | None |
| [`bootc-build/validate-pr`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/validate-pr) | Runs `just check`, ShellCheck, Hadolint, and pre-commit | None |
| [`bootc-build/generate-tags`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/generate-tags) | Produces OCI tags from stream, version, flavor/kernel, and event data | `base-name`, `stream-name`, `version-label`, `event-name` |
| [`bootc-build/push-image`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/push-image) | Pushes to GHCR with retries and returns the image digest | `image-name`, `tags`, `github-token` |
| [`bootc-build/create-manifest`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/create-manifest) | Creates and pushes a multi-architecture OCI manifest index | `image-name`, `digests-json`, `tags`, `github-token` |
| [`bootc-build/sign-and-publish`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/sign-and-publish) | Signs an image; can attach SBOM and GitHub SLSA Build L2 provenance | `image`, `digest`, `github-token` |
| [`bootc-build/scan-image`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/scan-image) | Scans an OCI image for CVEs and baked-in secrets with Trivy | `github-token` |
| [`bootc-build/ghcr-cleanup`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/ghcr-cleanup) | Removes old and untagged GHCR images | `packages`, `github-token` |
| [`bootc-build/rechunk`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/rechunk) | Rechunks using `rpm-ostree compose build-chunked-oci` | `source-image` |
| [`bootc-build/chunka`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/chunka) | OCI-native rechunking with chunkah | `source-image` |
| [`bootc-build/apply-pkg-intervals`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/apply-pkg-intervals) | Adds package cadence xattrs before `chunka` packing | `source-image` |
| [`bootc-build/generate-release-notes`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/generate-release-notes) | Generates Conventional Commit notes through git-cliff | `tag`, `github-token` |
| [`bootc-build/create-release`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/bootc-build/create-release) | Creates a GitHub image release with SBOM, signature, variant, and product-card data | `sbom-path`, `tag`, `title`, `image`, `digest`, `repo`, `notable-packages`, `cert-identity-regexp`, `github-token` |

### General utilities and factory-private composites

| Action | Purpose | Intended scope |
| --- | --- | --- |
| [`actions/check-token-health`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/actions/check-token-health) | Checks token validity, scopes, and remaining API requests | Reusable utility; Finpilot has a local copy today |
| [`actions/retry`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/actions/retry) | Executes a command with configurable exponential backoff | General utility |
| [`.github/actions/install-cosign`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/actions/install-cosign) | Installs Cosign from a release asset with cache/fallback support | Factory implementation utility |
| [`.github/actions/validate-pr-title`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/actions/validate-pr-title) | Validates Conventional Commit PR titles | General policy utility |
| [`.github/actions/discord-release-notify`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/actions/discord-release-notify) | Posts a release card to Discord; no-ops without a webhook | Factory notification utility |
| [`.github/actions/render-gate-section`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/actions/render-gate-section) | Renders promotion gate status into a PR body | Factory release utility |
| [`.github/actions/render-pr-body`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/actions/render-pr-body) | Renders a promotion PR body from release facts | Factory release utility |

## Reusable workflows

Call these at the job level using
`uses: projectbluefin/actions/.github/workflows/<file>@<pinned-SHA>`.

| Workflow | Role | Template default? |
| --- | --- | --- |
| [`reusable-build.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-build.yml) | Full flavor/matrix build, push, scan, signing, and digest output | No; powerful factory orchestration |
| [`reusable-promote-squash.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-promote-squash.yml) | Opens and gates squash promotions between source and target branches | Optional |
| [`reusable-sync-branches.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-sync-branches.yml) | Synchronizes changes from one branch to another | Optional |
| [`reusable-release-gate.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-release-gate.yml) | Performs release/promotion readiness checks | No; factory release policy |
| [`reusable-release.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-release.yml) | Creates a signed-image release and release notes | Optional |
| [`reusable-execute-release.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-execute-release.yml) | Executes the factory release process | No |
| [`reusable-release-reminder.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-release-reminder.yml) | Raises scheduled release reminders | No |
| [`reusable-renovate.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-renovate.yml) | Runs Renovate with a supplied token | Optional; Finpilot currently owns its runner |
| [`reusable-renovate-automerge.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-renovate-automerge.yml) | Applies Project Bluefin Renovate merge policy | No; policy choice |
| [`reusable-validate-renovate.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-validate-renovate.yml) | Validates Renovate configuration | Optional |
| [`reusable-vulnerability-scan.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-vulnerability-scan.yml) | Runs a matrix image vulnerability scan | Optional |
| [`reusable-pkg-cadence.yml`](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/.github/workflows/reusable-pkg-cadence.yml) | Maintains package update cadence metadata | No; needs maintained metadata and credentials |

## Upstream repository automation

These workflow files also exist upstream, but are **actions-repository or
factory operations**, not reusable consumer features:

- `actionlint.yml`, `unit-tests.yml`, `validate-renovate.yml`, and
  `consumer-validation.yml`: validate `projectbluefin/actions` itself and its
  external consumer contract.
- `dependency-review.yml`, `scorecard.yml`, and `pat-ban.yml`: supply-chain
  security controls for the actions repository.
- `factory-drift.yml`, `factory-health.yml`, `migration-test.yml`, and
  `upgrade-test.yml`: organization/factory health and migration checks.
- `ghcr-cleanup.yml`, `pkg-cadence.yml`, `promote-bluefin-stable.yml`, and
  `renovate-automerge.yml`: Project Bluefin operational workflows.
- `prune-merged-branches.yml`, `update-v1-tag.yml`, and
  `vendor-chunka-files.yml`: repository maintenance and release mechanics.

## Finpilot adoption status

Finpilot directly uses these upstream composites:

- `setup-runner`, `preflight`, `dnf-cache`, `detect-changes`, `validate-pr`,
  `generate-tags`, `chunka`, `push-image`, `sign-and-publish`, and
  `ghcr-cleanup`;
- `reusable-promote-squash.yml` and `reusable-sync-branches.yml`.

It also calls an old `reusable-design-enforcement.yml` workflow, which is
**absent from this upstream snapshot**. It is not part of this catalog and is
the first compatibility issue to resolve.

## Adoption rules

1. Use a composite action when it owns a mechanical operation shared by image
   builders.
2. Use a reusable workflow only when Finpilot intentionally adopts its policy,
   permissions, branches, and lifecycle—not merely because it reduces YAML.
3. Pin every `uses:` reference to a commit SHA and let Renovate update it.
4. Keep Finpilot's default path to build, validate, publish, and sign; make
   fleet/release-factory capabilities documented opt-ins.
