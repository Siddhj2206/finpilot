---
name: ci
description: >-
  GitHub Actions, Renovate, the two-branch release model, signing, and
  promotion. Use when changing workflows, dependency policy, or releasing.
---

# CI

## Workflows

| Workflow | Trigger | Does |
|---|---|---|
| `build-image.yml` | push to `main` or `stable`, dispatch | Builds, signs, and pushes the image. |
| `execute-release.yml` | push to `stable` | Promotes the candidate digest. Does not rebuild. |
| `promote-main-to-stable.yml` | daily schedule, dispatch | Opens the squash promotion PR. |
| `sync-stable-to-main.yml` | push to `stable` | Merges `stable` hotfixes back into `main`. |
| `pr-validation.yml` | pull request | The `validate` check: shellcheck and hadolint. |
| `validate-brewfiles.yml` | pull request | Brewfiles, without evaluating them. |
| `validate-flatpaks.yml` | pull request | Flatpak preinstall files against Flathub. |
| `validate-justfiles.yml` | pull request | `just check`. |
| `validate-renovate.yml` | pull request | Renovate config. |
| `unit-tests.yml` | push, pull request | The bats suite. |
| `renovate.yml` | schedule, config change | Runs Renovate. |
| `clean.yml` | schedule | Deletes images older than 90 days. |

Most are thin callers of reusable workflows in `projectbluefin/actions`.

## The release model

`main` publishes `:stable-testing`; `stable` publishes `:stable`. Promotion is a
squash PR from `main` to `stable`, and it promotes the digest `main` already
built rather than rebuilding.

The gate verifies the candidate digest's cosign signature. It runs no
end-to-end tests, so `release/ready` means signed and unmodified, not
functionally validated.

## Signing

Keyless OIDC via Cosign. There are no keys to generate or store; the workflow
needs `id-token: write` and `packages: write`. Unsigned images fail the promotion
gate.

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/OWNER/REPO/.github/workflows/" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/OWNER/REPO:stable
```

## Renovate

Self-hosted through `projectbluefin/actions`, running every six hours. It pins
GitHub Actions to SHAs and updates image digests. The policy lives in
`.github/renovate.json`: updates below a major automerge once checks pass;
majors wait for a pull request.

Renovate needs the `RENOVATE_TOKEN` secret and auto-merge enabled. Both are
onboarding steps.

## Making a change

1. Open a pull request against `main`.
2. Wait for `validate` and the image build.
3. Merge. `main` publishes `:stable-testing`.
4. Review and merge the promotion PR to publish `:stable`.
