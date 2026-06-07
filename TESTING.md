# TESTING

## Purpose
This document explains the current testing strategy, verified command results, coverage snapshot, and known gaps for the `FundMe` project.

The test suite is designed to verify the core behavior of a learning and portfolio-scale Solidity / Foundry project. It is production-aware, but it is not a production release certification, audit report, or claim that the contracts are secure.

## Assurance Boundary
The current tests provide local evidence for:

- core `FundMe` funding and withdrawal behavior
- owner-only withdrawal permission
- funder accounting updates and cleanup
- `receive()` and `fallback()` routing through `fund()`
- oracle input validation through deterministic mocks
- Mainnet, Sepolia, Anvil, and unsupported-chain config branches
- direct interaction helper calls for funding and withdrawal

The current tests do not provide:

- audit-level security assurance
- formal verification
- static analysis results
- fork-test evidence against live Chainlink feeds
- staging or public deployment evidence
- production monitoring or incident response evidence

Passing tests and high coverage should be read as engineering evidence, not as proof that the system is safe for real funds.

## Production Baseline vs Current Scope
A production-grade smart contract `TESTING.md` usually documents more than unit test counts. It should connect tests to risk, environment, external dependencies, release gates, and known gaps. This project keeps that structure, but intentionally limits implementation to what is stage-appropriate for a simple FundMe contract.

| Testing Area | Production-Grade Expectation | Current Project Status | Scope Decision |
| --- | --- | --- | --- |
| Unit tests | Core functions, revert paths, permissions, events, accounting, edge cases | Implemented for the main local behavior | Keep |
| Integration tests | Script or module interactions across deployment and user flows | Partially implemented through direct script helper calls | Keep, but do not overstate |
| Mock strategy | Deterministic mocks for external dependencies with clear trust boundaries | Implemented with `MockV3Aggregator` and `HelperConfig` tests | Keep |
| Fork tests | Validate behavior against forked public networks and real deployed dependencies | Not implemented | Future work before real deployment |
| Fuzz tests | Explore wide input ranges and boundary values | Not implemented | Optional future work |
| Invariant tests | Prove system-wide properties across action sequences | Not implemented | Optional future work if accounting grows |
| Static analysis | Record Slither or similar tool results with command and date | Not implemented | Future work; useful portfolio signal |
| Formal verification | Mathematical proof for critical properties | Not implemented | Not recommended for current project size |
| Gas stress tests | Test large state growth and worst-case withdrawal cost | Not implemented | Should improve if project remains funder-array based |
| Deployment tests | Staging/public deployment checks, verification, and operational runbooks | Not implemented | Future work only if deploying |
| CI gates | Automated format, build, and test checks | Implemented through GitHub Actions | Keep |

## Test Environment
- Foundry toolchain: `forge`, `cast`, and `anvil`
- Current local evidence shows Foundry `1.7.1` for `forge`, `anvil`, and `cast`
- Foundry library stack: `forge-std`, `chainlink-brownie-contracts`, `foundry-devops`
- Local tests run in Foundry's in-memory EVM; they do not require a live RPC or an external Anvil process
- The Anvil-compatible local branch (`chainid == 31337`) is exercised through Foundry tests
- Chainlink remapping in `foundry.toml`: `@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/`
- `MockV3Aggregator` simulates Chainlink-compatible ETH/USD feeds in unit tests
- `HelperConfig` branches on `block.chainid` for Mainnet, Sepolia, Anvil, and unsupported chains
- The `Makefile` reads `.env` for broadcast targets such as `ANVIL_RPC_URL`, `ANVIL_ACCOUNT`, `SEPOLIA_RPC_URL`, `SEPOLIA_ACCOUNT`, `ETHERSCAN_API_KEY`, `ZKSYNC_LOCAL_RPC_URL`, `ZKSYNC_LOCAL_ACCOUNT`, `ZKSYNC_SEPOLIA_RPC_URL`, and `ZKSYNC_SEPOLIA_ACCOUNT`
- GitHub Actions is configured to run `forge fmt --check`, `forge build --sizes`, and `forge test -vvv`

## Commands
Recommended local checks:

```bash
forge fmt --check
forge build --sizes
forge test -vvv
forge coverage
forge snapshot
```

Makefile shortcuts:

```bash
make test
make all
make snapshot
```

`make coverage` is not confirmed in this repository because the current `Makefile` does not define that target. The confirmed coverage command is `forge coverage`.

## Latest Local Verification
Last rechecked locally on `2026-06-07`:

| Command | Result |
| --- | --- |
| `forge fmt --check` | Passed |
| `forge build --sizes` | Passed |
| `forge test -vvv` | Passed: `40 tests passed, 0 failed, 0 skipped` across `5` suites |
| `forge coverage` | Passed: total coverage `90.97%` lines, `90.44%` statements, `90.00%` branches, `88.57%` funcs |

`forge snapshot` is available through the Makefile, but this document does not claim a latest snapshot result.

## Test Suite Inventory
| Suite | File | Purpose | Confirmed Count |
| --- | --- | --- | ---: |
| `FundMeTest` | `test/unit/FundMeTest.t.sol` | Core funding, withdrawal, events, receive/fallback routing, and accounting behavior | 21 |
| `PriceConverterTest` | `test/unit/PriceConverterTest.t.sol` | Oracle validation, decimal scaling, and ETH/USD conversion | 10 |
| `HelperConfigTest` | `test/unit/HelperConfigTest.t.sol` | Chain ID selection, Anvil mock creation, mock reuse, and unsupported-chain handling | 5 |
| `InteractionsTest` | `test/integration/FundMeTestIntegration.t.sol` | Direct script helper calls for fund and withdraw against a deployed `FundMe` instance | 3 |
| `ZkSyncDevOps` | `test/unit/ZkSyncDevOps.t.sol` | zkSync / devops example guard behavior | 1 |

The current suite count is `40` tests total. One counted test, `FundMeTest.testPrintStorageData`, is debug-style storage inspection with console output; it is useful for learning but should not be treated as a behavioral or security assertion.

`ZkSyncDevOps` is counted in the total Foundry run, but it is outside the main `FundMe` assurance scope.

## Risk-to-Test Matrix
| Risk or Requirement | Current Coverage | Evidence | Remaining Gap / Scope Note |
| --- | --- | --- | --- |
| Constructor should reject missing oracle address | Covered | `FundMeTest.testConstructorRevertsIfPriceFeedIsZeroAddress` | Covered for current scope |
| Funding below minimum USD should revert | Covered | `testFundFailsWithoutEnoughETH` | Fuzzing boundary values not implemented |
| Direct ETH transfer should not bypass minimum funding rule | Covered | `testReceiveFailsWithoutEnoughEth`, `testFallbackFailsWithoutEnoughEth` | Covered for current scope |
| Funding should update sender accounting | Covered | `testFundUpdatesFundDataStructure` | Covered for current scope |
| Repeated funders should not duplicate array entries | Covered | `testSameFunderIsOnlyAddedOnce` | Large-scale gas stress not implemented |
| Repeated funding should accumulate amount | Covered | `testSameFunderAmountStillAccumulates` | Covered for current scope |
| Withdrawal should be owner-only | Covered | `testOnlyOwnerCanWithdraw` | Multi-owner or ownership transfer not applicable |
| Withdrawal should reset accounting and contract balance | Covered | `testWithdrawResetsFunderAmount`, `testWithdrawFromASingleFunder`, `testWithdrawFromMultipleFunders` | Invariant tests not implemented |
| Successful fund and withdraw should emit events | Covered | `testFundEmitFundedEvent`, `testWithdrawEmitWithdrawnEvent` | Covered for current scope |
| Failed ETH transfer during withdrawal should revert | Not directly covered | `FundMe__CallFailed` exists | Dedicated negative test missing |
| Oracle should reject zero or negative prices | Covered | `PriceConverterTest.testGetPriceRevertsIfPriceIsZero`, `testGetPriceRevertsIfPriceIsNegative` | Fork tests not implemented |
| Oracle should reject stale or invalid timestamps | Covered | `testGetPriceRevertsIfPriceIsStale`, `testGetPriceRevertsIfUpdatedAtIsInFuture`, `testGetPriceRevertsIfUpdatedAtIsZero` | L2 sequencer checks not implemented |
| Oracle decimals should normalize to 18 decimals | Covered | 6/8/18-decimal feed tests | More exotic decimals not tested |
| Network config should select expected feed addresses | Covered as config regression | Mainnet, Sepolia, and Anvil `HelperConfigTest` cases | Not a live Chainlink address validation |
| Unsupported chain IDs should fail fast | Covered | `HelperConfigTest.testRevertsOnUnsupportedChainId` | Covered for current scope |
| Interaction helper should reject invalid fund target | Partially covered | zero address and no-code target for `FundFundMe` | Same negative cases not directly tested for `WithdrawFundMe` |
| Interaction `run()` should target intended deployment | Not directly covered | No direct test for `run()` lookup | `foundry-devops` recent-deployment lookup remains a script risk |

## Mock, HelperConfig, and Oracle Strategy
`MockV3Aggregator` gives tests deterministic control over oracle behavior. The suite uses `updateRoundData()` to simulate zero, negative, stale, future, and zero-`updatedAt` rounds without depending on a live Chainlink feed.

`HelperConfig` is the network switchboard. It selects Mainnet, Sepolia, or Anvil by `block.chainid`, deploys a mock feed on Anvil once, and reuses that mock inside the same helper instance. This keeps local tests predictable while still exercising config branch logic.

Mainnet and Sepolia feed addresses are hardcoded in the current configuration. Tests cover them as config regression checks only. They are not live oracle checks and do not replace revalidation against official Chainlink sources before any real deployment.

The oracle trust boundary is external to this project: `FundMe` trusts the configured Chainlink-compatible feed address and `PriceConverter` validates the returned price and timestamp before using it for USD threshold checks.

## Coverage Snapshot
Latest confirmed local coverage snapshot was produced with `forge coverage` on `2026-06-07`. An older historical snapshot also exists in `repo-gap-list.md`; this section uses the current local result.

| File | % Lines | % Statements | % Branches | % Funcs |
| --- | ---: | ---: | ---: | ---: |
| `script/DeployFundMe.s.sol` | 100.00% (8/8) | 100.00% (10/10) | 100.00% (0/0) | 100.00% (1/1) |
| `script/HelperConfig.s.sol` | 95.83% (23/24) | 95.00% (19/20) | 87.50% (7/8) | 100.00% (5/5) |
| `script/Interactions.s.sol` | 72.73% (16/22) | 68.42% (13/19) | 100.00% (2/2) | 60.00% (3/5) |
| `src/FundMe.sol` | 97.78% (44/45) | 97.37% (37/38) | 80.00% (4/5) | 100.00% (13/13) |
| `src/PriceConverter.sol` | 94.44% (17/18) | 89.29% (25/28) | 100.00% (5/5) | 100.00% (3/3) |
| `test/mocks/MockV3Aggregator.sol` | 82.61% (19/23) | 88.24% (15/17) | 100.00% (0/0) | 66.67% (4/6) |
| `test/unit/PriceConverterTest.t.sol` | 100.00% (4/4) | 100.00% (4/4) | 100.00% (0/0) | 100.00% (2/2) |
| **Total** | **90.97% (131/144)** | **90.44% (123/136)** | **90.00% (18/20)** | **88.57% (31/35)** |

Coverage is a test signal, not a security proof. Foundry also reports executed mock and harness contracts under `test/`, so these rows should not be read as production contract coverage. Coverage does not replace audit, formal verification, static analysis, or gas profiling.

## Current Gaps
These are worth tracking now because they relate directly to the current codebase:

- Dedicated negative test for `FundMe__CallFailed`: not confirmed
- Dedicated invalid-target tests for `WithdrawFundMe.withdrawFundMe(address)`: not confirmed
- Direct coverage of `Interactions.s.sol` `run()` / `foundry-devops` recent-deployment lookup: not confirmed
- Gas stress test for large funder arrays: not confirmed
- `FundMeTest.testPrintStorageData` is debug-style and should be removed or converted into a focused assertion if kept

## Future Work
These are production-style improvements, but they are not required for the current learning-stage FundMe scope:

- Fuzz tests for funding amounts, repeated funders, and conversion boundaries
- Invariant tests for accounting cleanup after withdrawal
- Fork tests against live or forked Chainlink feeds before any real deployment
- Static analysis results such as `Slither`; `Mythril` or `Echidna` only if they add useful signal
- Staging tests, deployment verification, and operational runbooks before public deployment
- L2 sequencer uptime handling if the contract is deployed on L2 networks
- Formal verification only if the project scope grows beyond a simple learning contract

## Non-Claims
- Passing tests do not imply the contract is secure.
- Coverage does not replace audit, formal verification, or production monitoring.
- This project is not production-ready.
- No public deployment, Etherscan verification, or staging validation is claimed here.
- No fuzz, invariant, fork, static-analysis, or formal-verification result is claimed here.
