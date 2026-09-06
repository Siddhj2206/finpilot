# Issue tracker: GitHub

Issues and Wayfinder decision tickets for this fork live in
[`siddhj2206/finpilot`](https://github.com/siddhj2206/finpilot/issues). Use the
GitHub CLI with `--repo siddhj2206/finpilot` for all operations.

## Conventions

- Create an issue with `gh issue create`; use a heredoc for a multi-line body.
- Read an issue with `gh issue view <number> --comments`.
- List issues with `gh issue list --state open`.
- Comment with `gh issue comment <number> --body "..."`.
- Apply/remove labels with `gh issue edit <number> --add-label "..."` and
  `--remove-label "..."`.
- Close with `gh issue close <number> --comment "..."`.

## Pull requests as a triage surface

**PRs as a request surface: no.**

External pull requests do not enter the issue-triage flow. A PR remains a
review surface for a scoped implementation issue.

## Wayfinding operations

Wayfinder uses one map issue labelled `wayfinder:map` and child decision issues
labelled one of `wayfinder:research`, `wayfinder:prototype`,
`wayfinder:grilling`, or `wayfinder:task`.

- Create the map with `gh issue create --label wayfinder:map`.
- Create child tickets first, then attach them using GitHub sub-issues.
- Express blockers with GitHub issue dependencies. If dependencies are
  unavailable, put `Blocked by: #<number>` at the beginning of the ticket.
- Claim a ticket before work by assigning it to the driving developer.
- Resolve a ticket with a decision comment, close it, then link its one-line
  result from the map's `Decisions so far` section.

## Temporary configuration

This file and the related Matt Pocock skill configuration are temporary working
material for the Finpilot rewrite. Remove them before proposing the rewrite
upstream unless Project Bluefin explicitly adopts the convention.
