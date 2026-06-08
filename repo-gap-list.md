# Repo Gap List - 2026-06-07

## Scope
This document is a production-aware gap register for the current `Foundry FundMe` repository. It records what has been verified locally, what is still open, and which limitations are intentionally accepted for the current stage.

It is not an audit report, a deployment record, or a claim of production readiness.

## Verification Baseline

| Item | Result |
| --- | --- |
| Latest local verification date | `2026-06-07` |
| `make all` | PASS, `40` tests / `5` suites |
| `forge coverage` | PASS, `90.97%` lines, `90.44%` statements, `90.00%` branches, `88.57%` funcs |
| `forge build --sizes` | PASS |
| `forge snapshot` | PASS |

## Status Legend

- `Open` = not addressed yet
- `Accepted` = intentionally kept as a documented limitation for this stage
- `Planned` = queued for a later iteration

## Confirmed Evidence

- Latest command log: [`evidence/2026-06-07-command-log.md`](./evidence/2026-06-07-command-log.md)
- Latest test output: `make all`, `forge coverage`, `forge build --sizes`, `forge snapshot`

## Gaps
`Open`
- Real lackage
- Haven decieded how to deal with
- Cant stay on `Open` for long

`Planned`
- Decied to deal with rencently (1-2 weeks)
- Have clear deliverables

`Accepted`
- Accepted in current project scope
- Not intend to deal with unless project goal upgrades

`Backlog`
- Valueable but not in current project scope
- Deal with when learning relative theme

`Closed`
- Done and evidence exists

| ID | Gap | Evidence | Severity | Status | Next Action |
| --- | --- | --- | --- | --- | --- |
| FM-001 | No public deployment or verification record | `README.md` and `SECURITY_NOTES.md` explicitly state that no public deployment or verification is claimed | Medium | Backlog/Planned | Deploy to a staging network first, verify on an explorer, and record the address, tx hash, and verification status |
| FM-002 | No audit or formal verification evidence | `README.md` and `SECURITY_NOTES.md` explicitly state that the repo is not audited and has no formal verification claim | High | Accepted | Keep this as an explicit non-claim for the learning project; require external review or formal verification only before any real-funds use |
| FM-003 | No fork or staging tests against live Chainlink feeds | `TESTING.md` states that no fork tests are currently claimed | Medium | Backlog | Add pinned fork tests later when practicing live-oracle integration; cover feed identity, decimals, freshness, and network-specific behavior |
| FM-004 | No fuzz or invariant test suite | `TESTING.md` states that no fuzz or invariant tests are currently claimed | Medium | Backlog | Revisit after the current FundMe evidence baseline; possible future coverage: funding amount boundaries, accounting consistency, and oracle edge cases |
| FM-005 | No static-analysis result is recorded | `SECURITY_NOTES.md` and `TESTING.md` state that no Slither, Aderyn, Mythril, or similar result is currently claimed | Low-Med | Planned | Run one lightweight static-analysis tool, record the exact command, version, output path, and accepted findings; do not treat the result as an audit |
| FM-006 | `withdraw()` still scales linearly with the number of unique funders | `src/FundMe.sol` loops over all funders and `SECURITY_NOTES.md` documents the block-gas-limit risk | Medium | Accepted | Keep it as a documented limitation for the current tutorial scope; redesign accounting only if the contract is reframed for larger-scale or real-funds usage |
| FM-007 | Interaction scripts still depend on the most recent deployment lookup | `script/Interactions.s.sol` uses `DevOpsTools.get_most_recent_deployment()` in `run()` | Medium | Accepted | Keep this for the current local/tutorial workflow; use explicit target addresses or an environment-specific deployment registry only in a multi-network deployment workflow |
| FM-008 | No dedicated adversarial edge-case tests for forced ETH or failed owner withdrawal | `SECURITY_NOTES.md` marks forced ETH and rejecting-owner / malicious-owner behavior as not covered | Medium | Planned | Add focused tests for force-sent ETH and failed withdrawal paths; document whether each behavior is mitigated, accepted, or only observable |
| FM-009 | No explicit deployment and oracle verification checklist | `README.md` and `SECURITY_NOTES.md` mention manual feed checks, but there is no dedicated runbook | Low-Med | Backlog | Add `DEPLOYMENT.md` when a public/staging deployment is planned; include chain id, feed address, decimals, explorer verification, and post-deploy smoke tests |

**FM-005**:
Dont have to use Slither, Aderyn, Mythril together, use one for now.
Checkout list: `evidence/2026-xx-xx-static-analysis.md`
Record:
```text
tool:
version:
command:
result:
findings:
accepted findings:
false positives:
follow-up:
```

**FM-008**:
Most worthy one
- Serve directly to `SECURITY_NOTES.md`
- Dont rely on outside network
- Can increase your understanding of the edge of EVM
- Can transform into interview description
- More sutible for current stage than `public deployment`, `fork test`, `formal verification`
Forced ETH is especially important: 
even if your contract doesn't have a proper receive/fallback path, others might force ETH into the contract through `selfdestruct` or similar means, causing `address(this).balance` to be inconsistent with internal accounting. You don't necessarily have to "fix" it, but it's best to test and document it.
Dont expand `FM-008` into a whole security test, 2-3 small tests is enough:
- 1. force ETH into FundMe and verify accounting assumptions
- 2. owner is a rejecting contract and withdraw reverts
- 3. failed low-level call path is covered if current design allows it
(If accomplish no.2 or 3 need to change deploy ownership or test constructure largly, then stop, turn it into `Backlog`)


## Decision

- Usable as a learning and portfolio baseline: yes
- Ready for real funds without more work: no
- Main remaining work is operational confidence, live-network validation, and adversarial test coverage
