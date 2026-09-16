# Triage Labels

The temporary Matt Pocock skill configuration uses its default triage labels:

| Skill role | GitHub label | Meaning |
| --- | --- | --- |
| `needs-triage` | `needs-triage` | Maintainer evaluation is needed |
| `needs-info` | `needs-info` | Waiting for reporter information |
| `ready-for-agent` | `ready-for-agent` | Fully specified AFK-agent work |
| `ready-for-human` | `ready-for-human` | Requires human implementation |
| `wontfix` | `wontfix` | Intentionally not actioned |

These labels are not replacements for the repository's Project Bluefin workflow
labels (`1-triage`, `2-discussing`, `3-human-queue`, `3-clanker-queue`,
`4-review`, `blocked`, and `hold`). The shared Project Bluefin lifecycle is the
authority for normal repository work; the temporary labels exist only to make
the installed planning skills operable during this rewrite.

Remove this file and its temporary labels before an upstream PR unless that
project adopts them deliberately.
