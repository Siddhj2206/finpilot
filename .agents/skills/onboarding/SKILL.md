---
name: onboarding
description: >-
  Bootstrap a new image from this template: rename the project, enable
  Actions and Renovate, protect the branch, and reach a first green build.
  Use when forking the template or when setup has stalled.
---

# Onboarding

Take a fresh fork from "Use this template" to a green build on `main`.

Every step below has two routes: a `gh` command and a GitHub-website route. They
do the same thing, so pick one per step. Substitute your own `{owner}/{repo}`
throughout.

## Before you start

- You need **admin** on the repository for every step.
- For the `gh` route, `gh auth login` as that admin.
- Creating the Renovate token is the one step with no shortcut, because only you
  can mint a personal access token.

## 1. Rename the project

See the Quick start in [README.md](../../../README.md#quick-start). Three identity
sites, and `just test-contract` fails when they disagree.

## 2. Enable Actions

- **`gh`** — `gh api -X PUT repos/{owner}/{repo}/actions/permissions -F enabled=true -f allowed_actions=all`
- **Website** — Settings → Actions → General → Actions permissions → "Allow all
  actions and reusable workflows". Then open the Actions tab and accept the
  enable prompt.

## 3. Allow auto-merge

Renovate's automerge depends on it.

- **`gh`** — `gh api -X PATCH repos/{owner}/{repo} -F allow_auto_merge=true`
- **Website** — Settings → General → Pull Requests → "Allow auto-merge".

## 4. Workflow permissions

- **`gh`** — `gh api -X PUT repos/{owner}/{repo}/actions/permissions/workflow -f default_workflow_permissions=write -f can_approve_pull_request_reviews=true`
- **Website** — Settings → Actions → General → Workflow permissions → "Read and
  write permissions", and tick "Allow GitHub Actions to create and approve pull
  requests".

The second flag is what lets the promotion workflow approve the check runs
GitHub holds for its own pull request.

## 5. Create the Renovate token

The one step with no shortcut.

1. Create a classic personal access token with the `repo` and `workflow` scopes.
2. **`gh`** — `gh secret set RENOVATE_TOKEN --repo {owner}/{repo}` (prompts for
   the value).
   **Website** — Settings → Secrets and variables → Actions → New repository
   secret, named `RENOVATE_TOKEN`.

## 6. Create `stable`

Promotion opens a pull request *into* `stable`, so the branch has to exist.

- **`git`** — `git push origin main:stable`
- **`gh`** — `gh api -X POST repos/{owner}/{repo}/git/refs -f ref=refs/heads/stable -f sha="$(gh api repos/{owner}/{repo}/git/ref/heads/main --jq .object.sha)"`
- **Website** — Branches → New branch.

## 7. Protect `main`

Require the `validate` check.

```bash
gh api -X PUT repos/{owner}/{repo}/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": {"strict": false, "contexts": ["validate"]},
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
JSON
```

**Website** — Settings → Branches → Add branch protection rule, pattern `main`,
tick "Require status checks to pass", and select `validate`.

Requiring a pull request is optional. The template's convention is that `main`
takes no direct pushes, but the setting does not enforce it.

## 8. Protect `stable`

The same check, and **zero** required approvals so promotion merges as soon as
checks pass. Use the same call against `stable`, with:

```json
"required_pull_request_reviews": {"required_approving_review_count": 0}
```

**Website** — the same screen, pattern `stable`.

## 9. Restrict `stable` to squash merges

```bash
gh api -X POST repos/{owner}/{repo}/rulesets --input - <<'JSON'
{
  "name": "stable — squash-only promotion",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["refs/heads/stable"], "exclude": []}},
  "rules": [{"type": "pull_request", "parameters": {
    "allowed_merge_methods": ["squash"],
    "required_approving_review_count": 0,
    "dismiss_stale_reviews_on_push": false,
    "require_code_owner_review": false,
    "require_last_push_approval": false,
    "required_review_thread_resolution": false
  }}]
}
JSON
```

**Website** — Settings → Rules → Rulesets → New branch ruleset.

## 10. Create the labels

The release gate applies `release/ready` and `release/blocked`, and the shared
label workflow uses the lifecycle set. A missing label makes those steps fail.

- **`gh`** — `gh label create <name> --repo {owner}/{repo} --color <hex> --force`
- **Website** — Issues → Labels → New label.

Required: `release/ready` `0e8a16`, `release/blocked` `b60205`, and the lifecycle
set `1-triage` `FBCA04`, `2-discussing` `D876E3`, `3-human-queue` `1D76DB`,
`3-clanker-queue` `0E8A16`, `4-review` `0052CC`, `blocked` `B60205`, `hold`
`6E7781`.

Optional: `area/ci`, `kind/bug`, `priority/p1` (all `ededed`), and GitHub's
defaults.

## 11. Enable issues

- **`gh`** — `gh api -X PATCH repos/{owner}/{repo} -F has_issues=true`
- **Website** — Settings → General → Features → Issues.

## Verify

```bash
gh api repos/{owner}/{repo} --jq '{auto_merge: .allow_auto_merge, issues: .has_issues}'
gh api repos/{owner}/{repo}/actions/permissions
gh api repos/{owner}/{repo}/actions/permissions/workflow
gh api repos/{owner}/{repo}/branches --jq '.[].name'
gh api repos/{owner}/{repo}/branches/main/protection --jq '.required_status_checks.contexts'
gh api repos/{owner}/{repo}/branches/stable/protection --jq '.required_status_checks.contexts'
gh api repos/{owner}/{repo}/rulesets --jq '.[].name'
gh secret list --repo {owner}/{repo}
```

Done when `main` and `stable` both exist and both require `validate`, the squash
ruleset is active, `RENOVATE_TOKEN` is set, and a push to `main` produces a green
`Build and Push Image` run and a `:stable-testing` image.

## Failure modes

- **The first build never starts** — Actions were never enabled (step 2).
- **Renovate opens no pull requests** — the token is missing or lacks the
  `workflow` scope (step 5).
- **The promotion PR never opens** — `stable` does not exist (step 6).
- **The promotion PR cannot merge** — `stable` requires an approval, or the
  check name is not exactly `validate` (steps 7–8).
- **The promotion PR is merged by hand** — expected on a personal repository. A
  merge queue needs an organization, so enrollment is off.
