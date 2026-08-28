---
name: writing-pr-descriptions
description: Use when asked to write, draft, or update a pull request description, or when a feature branch has been committed and pushed and is ready for someone to open a PR
---

# Writing PR Descriptions

## Overview

A PR description answers what the diff cannot: what it cost, what changed, what a
reviewer pays for getting it wrong, and how you know it works. GitHub renders the
file list; you supply the facts. It opens with three lines anyone in the company
can act on, and everything after them is a table, so the reviewer scans instead
of reads.

## Gather the facts first

Never write from memory or from a summary of earlier work.

1. **Diff against the merge-base**, not the base tip:
   `git diff $(git merge-base origin/<base> HEAD) HEAD --stat -M`
   The base has moved; its tip reports other people's commits as yours. `-M`
   renders moves as renames.
2. **Re-run the gates** and keep the real output. Verification quotes what you
   ran, not what you recall.
3. **Read the actual new symbols** — routes, field names and json tags, migration
   filenames, test names, subtest counts. Every name must match the code.

## The lead

Three lines of prose before the first heading, in this order. Each is one
sentence of 30 words or fewer — count them. They are the only prose in the
document; everything after them is a table.

| Line | Carries | Rule |
|---|---|---|
| verdict | what a customer experienced, in one line | a branch with no customer-visible change says exactly that |
| price | the cost in the reader's units — money charged, product given away, tickets, trust | "nobody knows how many, and that is the finding" is a legitimate price |
| call | the one decision this PR needs from a person, or `No call needed` | what the reviewer must decide, not a gap you already closed |

An identifier earns a place in the lead only where the reader must act on it, and
is glossed in the same sentence: `past_due` alone is not a price; "billed as
failed (`past_due`)" is.

**REQUIRED SUB-SKILL:** when the call is a business tradeoff rather than a
technical one, use explaining-in-plain-terms to write these three lines.

## The shape

Emit these sections in this order. Each section is the table named here.

| Section | Columns | Rows |
|---|---|---|
| lead | three lines of prose, no heading | `verdict`, `price`, `call` |
| `## Description` | `Question \| Answer` | `What ships`, `Before`, `Why now` |
| `## Description` | `Ships together \| Because` | one per thing — only when the branch ships more than one |
| `### <contract surface>` | `Fact \| Value \| Why it matters` | one table per surface |
| `## Tests` | `Test \| Subtests \| Catches` | one per test |
| `## Verification` | fenced block, `command` then real outcome | one per gate |
| `## Notes for review` | `Kind \| Note \| Impact` | one per note |

Verification is a fenced block rather than a table because commands contain `|`,
which breaks markdown cells.

### Cell contract

**Every cell is 15 words or fewer.** Count them. A cell with more to say becomes
two rows, never a longer cell — splitting keeps the content and drops the prose.
A `Why it matters` that is already obvious from `Value` stays empty.

| Instead of one 40-word cell | Two rows |
|---|---|
| `Not unit-testable against a mock. Hand-verified on dev MariaDB (133 rows): EXPLAIN confirms the full scan, and all 4 medians match a hand walk (odd n=23 rank 12 = 39s; even n=10 ranks 5-6 = 32.5s).` | `median SQL \| not mockable \| hand-verified, 133 rows` + `EXPLAIN \| full scan confirmed \| 4 medians match a hand walk` |

Facts go in `Value`, consequences in `Why it matters`, and nothing at all between
the tables.

### `### <contract surface>`

One subsection per **contract surface** — a stored field, an endpoint, a response
shape, a shared module. A surface is something a caller can observe. It is not a
file and not a layer: one surface normally spans migration, model, repo, biz,
handler and route, and gets **one** subsection, not six.

`Why it matters` is where the reviewer's real risk lives — the reserved word that
must stay quoted, the soft-delete guard, why NULL and not empty string, why the
list path and the detail path resolve one field differently.

### `## Tests`

`Catches` names the bug the test fails on. A test that exists to pin wiring a
mocked test cannot see says so — that is the one a reviewer would otherwise
delete as redundant.

No test runner for this surface? Say so in one row, then one row per manual or
browser check you performed.

### `## Verification`

```
go build ./...                     clean
npx tsc --noEmit                   exit 0
npx eslint <16 changed files>      1 error, pre-existing
```

Every line is something you ran on this branch. Keep a pre-existing failure, with
the evidence that it is pre-existing (present at the merge-base, or reproduced
with your changes stashed) — an unexplained failure reads as yours. Could not run
a gate? Write that, not a plausible result.

### `## Notes for review`

`Kind` is one of: `deploy order`, `gap`, `conflict`, `diff reading`.

| Kind | What it carries |
|---|---|
| `deploy order` | which side ships first, and what breaks if it does not |
| `gap` | what you chose not to close, and why. A gap you name is a decision; the same gap found by a reviewer is a defect |
| `conflict` | open PRs touching these files |
| `diff reading` | anything that makes the diff read wrong, e.g. renames needing `-M` |

## Quick reference

| Reviewer question | Section |
|---|---|
| What did this cost, and what must I decide? | the lead |
| Why does this exist? | `## Description` |
| What can callers now observe? | `### <surface>`, `Value` |
| What breaks if I get it wrong? | `### <surface>`, `Why it matters` |
| Is it covered? | `## Tests` |
| Did you actually run it? | `## Verification` |
| What bites me on merge? | `## Notes for review` |

## Common mistakes

| Mistake | Fix |
|---|---|
| A paragraph between two tables | Move it into a row, or cut it |
| Opening with `## Description` | The lead comes first; a reviewer who owns the money may read only those three lines |
| A price written as internal state (`past_due`, `mode=payment`) | Say what the customer was charged or lost, then gloss the identifier |
| A cell running four sentences | Split into rows; one sentence each |
| `Why it matters` restating `Value` | Empty the cell |
| Sections named after layers (Schema, Model, Repo, Handler) | Name them after contract surfaces; one surface spans all those layers |
| A row per changed file | Delete them. The diff lists files; spend rows on consequences |
| "All tests pass" | Name each command and its real output |
| Verification written from memory | Re-run the gates, paste the outcome |
| Stat taken from `git diff origin/main` | Use the merge-base; the tip has moved |

## Delivery

Anything longer than a couple of tables goes in a file the user can copy
verbatim, not rendered chat prose. Prefer a gitignored path so the description
does not land in the diff it describes.

Writing the description is not opening the PR. Stop at the file and report where
it is.
