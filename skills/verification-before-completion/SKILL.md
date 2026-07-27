---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing without having run the proving command in this same message - the claim must ship together with the command output that proves it
---

# Verification Before Completion

**Core principle:** claim and evidence ship together, in the same message.

## The Gate

Before stating that something passes / builds / is fixed:

1. Name the command that proves it
2. Run it fresh and in full
3. Read the output and the exit code
4. State the claim **with** that output — or state the actual status instead

If the proving command hasn't run in this message, the claim doesn't ship.

## What proves what

| Claim | Proof | Not proof |
|-------|-------|-----------|
| Tests pass | test command output, 0 failures | a previous run, "should pass" |
| Linter clean | linter output, 0 errors | partial check |
| Build succeeds | build command, exit 0 | linter passed |
| Bug fixed | original symptom retested, passes | code changed |
| Regression test works | red-green cycle run | test passes once |
| Requirements met | line-by-line checklist against the spec | tests passing |
| Subagent reported DONE | one integration run in the main loop | the subagent's summary |

## Reporting

- Tests failed → say so, with the output.
- Step skipped → say that.
- Done and proved → state it plainly, no hedging, no "should" / "probably" / "seems to".

## Scope — where this does NOT apply

This is a gate on **claims**, not a mandate to re-do work:

- Don't re-run a command that already ran in this message just to "be sure".
- Don't spawn a subagent to verify — verification lives in the main loop.
- Don't re-audit statements that were already accurate.
- Work that produced no verifiable claim needs no verification pass.
