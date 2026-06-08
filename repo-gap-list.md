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

| ID | Gap | Evidence | Severity | Status | Next Action |
| --- | --- | --- | --- | --- | --- |
| FM-001 | No public deployment or verification record | `README.md` and `SECURITY_NOTES.md` explicitly state that no public deployment or verification is claimed | Medium | Open | Deploy to a staging network first, verify on an explorer, and record the address, tx hash, and verification status |
| FM-002 | No audit or formal verification evidence | `README.md` and `SECURITY_NOTES.md` explicitly state that the repo is not audited and has no formal verification claim | High | Open | Obtain an external review or formal verification before treating the contract as real-funds infrastructure |
| FM-003 | No fork or staging tests against live Chainlink feeds | `TESTING.md` states that no fork tests are currently claimed | Medium | Open | Add pinned fork tests for feed identity, decimals, freshness, and network-specific behavior |
| FM-004 | No fuzz or invariant test suite | `TESTING.md` states that no fuzz or invariant tests are currently claimed | Medium | Open | Add fuzz and invariant coverage for funding amounts, accounting consistency, and oracle edge cases |
| FM-005 | No static-analysis result is recorded | `SECURITY_NOTES.md` and `TESTING.md` state that no Slither, Aderyn, Mythril, or similar result is currently claimed | Low-Med | Open | Run static analysis, record the exact command and tool version, and document any accepted findings |
| FM-006 | `withdraw()` still scales linearly with the number of unique funders | `src/FundMe.sol` loops over all funders and `SECURITY_NOTES.md` documents the block-gas-limit risk | Medium | Accepted | Keep it as a documented limitation for the current tutorial scope; redesign accounting if the contract ever needs larger-scale usage |
| FM-007 | Interaction scripts still depend on the most recent deployment lookup | `script/Interactions.s.sol` uses `DevOpsTools.get_most_recent_deployment()` in `run()` | Medium | Open | Make the target address explicit, or add an environment-specific deployment registry and selection flow |
| FM-008 | No dedicated adversarial edge-case tests for forced ETH or failed owner withdrawal | `SECURITY_NOTES.md` marks forced ETH and rejecting-owner / malicious-owner behavior as not covered | Medium | Open | Add tests for force-sent ETH, rejecting-owner withdrawal, and failed transfer paths |
| FM-009 | No explicit deployment and oracle verification checklist | `README.md` and `SECURITY_NOTES.md` mention manual feed checks, but there is no dedicated runbook | Low-Med | Planned | Add a `DEPLOYMENT.md` or checklist covering feed address, chain id, decimals, explorer verification, and post-deploy smoke tests |

## Decision

- Usable as a learning and portfolio baseline: yes
- Ready for real funds without more work: no
- Main remaining work is operational confidence, live-network validation, and adversarial test coverage
