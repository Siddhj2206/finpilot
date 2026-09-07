# Finpilot Actions Baseline Assessment

**Decision-ticket evidence for:** [Inventory the current shared Actions baseline](https://github.com/Siddhj2206/finpilot/issues/2)
**Upstream snapshot:** [`projectbluefin/actions@9c699818`](https://github.com/projectbluefin/actions/tree/9c699818ddf1043b8f5af8b862f59f783c6c7bda)

## Result

All ten `bootc-build` composites currently used by Finpilot exist at the
snapshot pinned in Finpilot workflows. Both used release reusable workflows
also exist. The only missing upstream dependency is the old
`reusable-design-enforcement.yml` label workflow.

Finpilot should retain its readable, single-image build caller and delegate
mechanical Renovate behavior to upstream reusable workflows. It should not
adopt the upstream factory matrix build workflow by default.

## Direct dependency matrix

| Current Finpilot use | Current upstream status | Decision |
| --- | --- | --- |
| `bootc-build/preflight` | Present; consumer-contract interface | Retain |
| `bootc-build/setup-runner` | Present; consumer-contract interface | Retain |
| `bootc-build/dnf-cache` | Present; consumer-contract interface | Retain |
| `bootc-build/detect-changes` | Present; consumer-contract interface | Retain |
| `bootc-build/validate-pr` | Present; consumer-contract interface | Retain |
| `bootc-build/generate-tags` | Present; consumer-contract interface | Retain |
| `bootc-build/chunka` | Present; consumer-contract interface | Retain behind the existing opt-in |
| `bootc-build/push-image` | Present; consumer-contract interface | Retain |
| `bootc-build/sign-and-publish` | Present; consumer-contract interface | Retain; separately decide fail-closed signing policy |
| `bootc-build/ghcr-cleanup` | Present; consumer-contract interface | Retain |
| `reusable-promote-squash.yml` | Present | Retain as the implementation basis for the required two-branch release model |
| `reusable-sync-branches.yml` | Present | Retain as the implementation basis for the required two-branch release model |
| `reusable-design-enforcement.yml` | **Absent** from the current Actions repository | Do not SHA-bump; locate the current shared lifecycle owner or raise an upstream gap |

## Replace duplicated Finpilot implementation

| Current implementation | Upstream replacement | Recommendation |
| --- | --- | --- |
| Local `check-token-health` composite and duplicated Renovate runner steps | `reusable-renovate.yml` | Replace with a thin scheduled/dispatch caller that maps `RENOVATE_TOKEN` to `renovate_token` |
| Local Node setup and `renovate-config-validator` invocation | `reusable-validate-renovate.yml` | Replace with a thin trigger-only caller |
| `nick-fields/retry` around image build | `actions/retry` | Evaluate replacement during build-workflow redesign; the upstream action has an equivalent command/backoff interface |

`reusable-renovate.yml` already owns credential-safe checkout, token-health
validation, and the pinned Renovate invocation. Moving there removes
implementation duplication without making Renovate policy less customizable:
Finpilot continues to own its Renovate configuration and trigger schedule.

## Keep external actions for now

| Dependency | Why no Actions replacement is selected now |
| --- | --- |
| `actions/checkout` | It is the standard upstream GitHub checkout action and is used by shared Actions itself. |
| `docker/login-action` | GHCR login is a narrow standard action preceding image push; no direct Project Bluefin substitute exists. |
| `Homebrew/actions/setup-homebrew` | The Brewfile validation workflow needs a Homebrew environment; no `projectbluefin/actions` equivalent exists. |
| `extractions/setup-just` | The dedicated Justfile validation workflow needs Just; no equivalent exists. |

## Interface caveat

The upstream [consumer contract](https://github.com/projectbluefin/actions/blob/9c699818ddf1043b8f5af8b862f59f783c6c7bda/docs/consumer-contract.yml)
protects named interfaces consumed by external repositories. Finpilot also
uses currently supported, but not listed, optional inputs:

- `setup-runner.native-overlay`;
- `dnf-cache.cache-bust`; and
- `sign-and-publish.certificate-identity-regexp`.

They work at this snapshot, but are not explicitly represented in that
consumer-contract file. The workflow rewrite should either avoid each input,
or ask upstream to add it to the consumer contract before treating it as a
stable template dependency.

## Rejected alternative: full reusable build migration

`reusable-build.yml` is designed for Bluefin-family flavor/architecture
matrices, scan policy, and factory stream behavior. Making it Finpilot's
default caller would expose those policy choices to every fork and obscure the
template's Containerfile/Justfile-centered single-image build path.

Finpilot should continue to compose the small upstream build actions in its
own workflow. That gives it a shallow policy surface and keeps its build
behavior inspectable, while upstream owns the difficult runner, cache, push,
signing, and tagging mechanics.
