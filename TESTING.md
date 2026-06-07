# TESTING

## 1. Document Status

This document describes the current testing strategy, reproducible commands, latest known local results, coverage snapshot, and test gaps for the `FundMe` project.

- Project type: learning and portfolio-scale Solidity / Foundry project
- Current commit documented: `1e2fea5`
- Last local verification documented: `2026-06-07`
- Deployment status: no public production deployment is claimed here
- Assurance status: this is not an audit report, formal verification report, or production release certification

Passing tests and high coverage should be read as engineering evidence only. They do not prove that the contracts are safe for real funds.

## 2. Testing Philosophy

The test suite is designed to protect the project's most important correctness and security properties:

- owner-only withdrawal access control
- minimum funding threshold enforcement
- ETH funding and withdrawal accounting behavior
- `receive()` and `fallback()` routing behavior
- oracle input validation through deterministic mocks
- supported and unsupported network configuration
- script-level funding and withdrawal interactions

The suite is intentionally stage-appropriate. It uses a production-grade testing lens, but it does not attempt to turn a simple FundMe tutorial project into a full production protocol test framework.

## 3. Scope

### In Scope

- `src/FundMe.sol`
- `src/PriceConverter.sol`
- `script/DeployFundMe.s.sol`
- `script/HelperConfig.s.sol`
- `script/Interactions.s.sol`
- `test/unit/FundMeTest.t.sol`
- `test/unit/PriceConverterTest.t.sol`
- `test/unit/HelperConfigTest.t.sol`
- `test/integration/FundMeTestIntegration.t.sol`
- `test/mocks/MockV3Aggregator.sol`

### Counted but Outside the Main FundMe Assurance Scope

- `test/unit/ZkSyncDevOps.t.sol`

This zkSync/devops example test is counted by a full `forge test` run, but it is not part of the main FundMe correctness or security assurance boundary.

### Out of Scope

- third-party dependency internals such as Chainlink contracts, `forge-std`, and `foundry-devops`
- live Chainlink oracle behavior
- public deployment validation
- production monitoring or incident response
- wallet, RPC provider, keystore, and user operational security
- legal, fundraising, custody, compliance, or treasury policy

## 4. Toolchain and Environment

- Toolchain: Foundry (`forge`, `cast`, `anvil`)
- Latest documented local Foundry version: `1.7.1`
- Solidity versions used by the repository: `^0.8.19` in the main project contracts and scripts; `^0.8.18` in `PriceConverter.sol`; `^0.8.0` in the mock
- Dependencies: `forge-std`, `chainlink-brownie-contracts`, `foundry-devops`
- Chainlink remapping: `@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/`
- Local tests run in Foundry's in-memory EVM and do not require a live RPC endpoint or external Anvil process
- `HelperConfig` uses `block.chainid` to select Mainnet, Sepolia, Anvil, or unsupported-chain behavior
- The Makefile reads `.env` for broadcast/deployment targets, but local unit and integration tests do not require those broadcast variables

The GitHub Actions workflow is configured to run:

```bash
forge fmt --check
forge build --sizes
forge test -vvv
```

## 5. Test Layout

| Area | File | Responsibility |
| --- | --- | --- |
| Unit | `test/unit/FundMeTest.t.sol` | Core funding, withdrawal, events, `receive()`/`fallback()`, and accounting behavior |
| Unit | `test/unit/PriceConverterTest.t.sol` | Oracle price validation, timestamp validation, decimal scaling, and ETH/USD conversion |
| Unit | `test/unit/HelperConfigTest.t.sol` | Network config branches, Anvil mock creation/reuse, and unsupported-chain handling |
| Integration | `test/integration/FundMeTestIntegration.t.sol` | Direct script helper calls for fund and withdraw against a deployed `FundMe` instance |
| Mock | `test/mocks/MockV3Aggregator.sol` | Deterministic Chainlink-compatible feed behavior for local tests |
| Auxiliary | `test/unit/ZkSyncDevOps.t.sol` | zkSync/devops example guard behavior outside the main FundMe assurance scope |

The current full Foundry run includes `40` tests across `5` suites. One counted test, `FundMeTest.testPrintStorageData`, is debug-style storage inspection and should not be treated as a behavioral or security assertion.

## 6. How to Run Tests

Recommended local checks:

```bash
forge fmt --check
forge build --sizes
forge test -vvv
forge coverage
forge snapshot
```

Useful targeted commands:

```bash
forge test --match-contract FundMeTest -vvv
forge test --match-contract PriceConverterTest -vvv
forge test --match-contract HelperConfigTest -vvv
forge test --match-contract InteractionsTest -vvv
```

Makefile shortcuts:

```bash
make all
make test
make snapshot
```

There is no confirmed `make coverage` target in the current Makefile. Use `forge coverage` directly.

## 7. Test Categories

### Unit Tests

Current unit tests cover:

- constructor rejection for a zero price feed
- owner initialization
- minimum USD constant
- price feed version getter
- funding below the minimum threshold reverting
- funding accounting updates
- duplicate funder prevention
- cumulative funding from repeated funders
- funder array tracking
- owner-only withdrawal
- withdrawal balance transfer and accounting reset
- successful `Funded` and `Withdrawn` event emission
- `receive()` and `fallback()` routing through `fund()`
- oracle price positivity checks
- oracle timestamp freshness checks
- feed decimal normalization to 18 decimals
- supported and unsupported network config branches
- Anvil mock creation and reuse within a single `HelperConfig` instance

### Integration and Script Tests

Current integration tests cover:

- deploying a `FundMe` instance through `DeployFundMe`
- funding a provided `FundMe` address through `FundFundMe.fundFundMe(address)`
- withdrawing through `WithdrawFundMe.withdrawFundMe(address)`
- rejecting zero-address and no-code targets for the funding interaction path

The current integration tests call script helper functions directly. They do not fully exercise CLI broadcast behavior, account selection, RPC configuration, block explorer verification, or the `foundry-devops` most-recent-deployment lookup used by `run()`.

### Fork Tests

No fork tests are currently claimed.

Fork tests would be required before treating Mainnet or Sepolia oracle behavior as verified. Useful future fork checks include feed address identity, feed pair, decimals, positive latest round data, and stale-data behavior against a pinned block.

### Fuzz Tests

No fuzz tests are currently claimed.

Useful future fuzz targets include funding amounts, repeated funders, oracle prices, feed decimals, and timestamp edge cases.

### Invariant Tests

No invariant tests are currently claimed.

Useful future invariants should be designed carefully. For example, `contract balance == sum of tracked funder accounting` is not always valid because ETH can be force-sent to the contract without calling `fund()`, `receive()`, or `fallback()`.

### Static Analysis

No Slither, Aderyn, Mythril, Echidna, or similar static-analysis result is currently claimed.

If static analysis is added later, this document should record the exact command, date, tool version, result, and any accepted findings.

### Formal Verification or Symbolic Testing

No formal verification or symbolic testing is currently claimed.

This is not recommended as a near-term priority for the current simple FundMe scope, but it may become relevant for larger accounting-heavy, upgradeable, oracle-heavy, or ZK verifier projects.

### Gas and Performance Testing

`forge snapshot` passed in the latest documented local run on `2026-06-07` and refreshed `.gas-snapshot` with the current full test suite.

The key gas scalability concern is `FundMe.withdraw()`, which loops over all unique funders. The current tests cover withdrawal with multiple funders, but they do not stress worst-case funder-array growth or prove production scalability.

## 8. Security-Critical Test Matrix

| Security Property or Requirement | Status | Evidence | Remaining Gap / Scope Note |
| --- | --- | --- | --- |
| Constructor rejects a zero price feed | Covered | `FundMeTest.testConstructorRevertsIfPriceFeedIsZeroAddress` | Covered for current scope |
| Funding below minimum USD reverts | Covered | `FundMeTest.testFundFailsWithoutEnoughETH` | Fuzzed boundary values not implemented |
| `receive()` and `fallback()` enforce the same minimum funding path | Covered | `testReceiveFailsWithoutEnoughEth`, `testFallbackFailsWithoutEnoughEth` | Forced ETH can still bypass function execution |
| Successful funding updates sender accounting | Covered | `testFundUpdatesFundDataStructure` | Covered for current scope |
| Repeated funders are not duplicated | Covered | `testSameFunderIsOnlyAddedOnce` | Large-scale gas stress not implemented |
| Repeated funding accumulates amount | Covered | `testSameFunderAmountStillAccumulates` | Covered for current scope |
| Only owner can withdraw | Covered | `testOnlyOwnerCanWithdraw` | No multisig or ownership transfer flow exists |
| Withdrawal transfers balance and resets accounting | Covered | `testWithdrawResetsFunderAmount`, `testWithdrawFromASingleFunder`, `testWithdrawFromMultipleFunders` | Invariant tests not implemented |
| Successful fund and withdraw emit events | Covered | `testFundEmitFundedEvent`, `testWithdrawEmitWithdrawnEvent` | Covered for current scope |
| Failed ETH transfer during withdrawal reverts | Not covered | `FundMe__CallFailed` exists in code | Dedicated rejecting-owner contract test missing |
| Forced ETH accounting boundary is understood | Not covered | Documented gap only | Dedicated forced-ETH test missing |
| Oracle rejects zero or negative prices | Covered | `PriceConverterTest.testGetPriceRevertsIfPriceIsZero`, `testGetPriceRevertsIfPriceIsNegative` | Fork tests not implemented |
| Oracle rejects stale or invalid timestamps | Covered | `testGetPriceRevertsIfPriceIsStale`, `testGetPriceRevertsIfUpdatedAtIsInFuture`, `testGetPriceRevertsIfUpdatedAtIsZero` | L2 sequencer checks not implemented |
| Oracle decimals normalize to 18 decimals | Covered | 6-, 8-, and 18-decimal feed tests | Extremely unusual feed decimals not stress-tested |
| Network config selects expected hardcoded feed addresses | Covered as config regression | `HelperConfigTest` Mainnet and Sepolia cases | Not a live Chainlink address validation |
| Unsupported chain IDs fail fast | Covered | `HelperConfigTest.testRevertsOnUnsupportedChainId` | Covered for current scope |
| Funding interaction rejects invalid target | Covered | zero-address and no-code target tests for `FundFundMe` | Same negative cases not directly tested for `WithdrawFundMe` |
| Interaction `run()` targets intended deployment | Not covered | No direct test for `run()` lookup | `foundry-devops` most-recent-deployment lookup remains an operational script risk |

## 9. Mocks, Fixtures, and Test Data

`MockV3Aggregator` gives local tests deterministic control over Chainlink-compatible oracle behavior. The suite uses `updateRoundData()` to simulate zero, negative, stale, future, and zero-`updatedAt` rounds without depending on live Chainlink infrastructure.

`HelperConfig` is the network switchboard. It selects Mainnet, Sepolia, or Anvil by `block.chainid`, deploys a local mock feed for Anvil, and reuses that mock within the same `HelperConfig` instance.

Mainnet and Sepolia feed addresses are tested only as configuration regression checks. These tests do not prove that the live addresses are correct, current, healthy, or safe for deployment. Any real deployment would need an explicit feed identity check against trusted Chainlink documentation and a live or forked network.

## 10. Coverage Snapshot

Latest documented local coverage result was produced with `forge coverage` on `2026-06-07`.

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

Coverage is a test signal, not a security proof. Foundry reports executed mocks and harnesses under `test/`, so coverage rows should not be interpreted as production-contract-only assurance. Coverage does not replace audit, formal verification, static analysis, fork testing, or gas stress testing.

## 11. Latest Results

Latest documented local results:

| Command | Result | Notes |
| --- | --- | --- |
| `forge fmt --check` | Passed | Latest documented run on `2026-06-07` |
| `forge build --sizes` | Passed | Latest documented run on `2026-06-07` |
| `forge test -vvv` | Passed | `40` tests passed, `0` failed, `0` skipped across `5` suites |
| `forge coverage` | Passed | Total coverage: `90.97%` lines, `90.44%` statements, `90.00%` branches, `88.57%` funcs |
| `forge snapshot` | Passed | `40` tests passed, `0` failed, `0` skipped across `5` suites |

If code or tests change after this document is updated, rerun the relevant commands before treating these results as current.

## 12. CI Requirements

The current GitHub Actions workflow runs on push, pull request, and manual dispatch. It checks:

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

Production-grade projects would normally expand CI with some combination of coverage, gas snapshots, static analysis, fork tests, fuzz tests, invariant tests, and nightly jobs. This project currently keeps CI limited to the core Foundry checks.

## 13. Known Test Gaps

These gaps are relevant to the current codebase:

- no dedicated negative test for `FundMe__CallFailed`
- no dedicated forced-ETH accounting test
- no dedicated malicious-owner or reentrant-owner contract test
- no dedicated invalid-target tests for `WithdrawFundMe.withdrawFundMe(address)`
- no direct coverage of `Interactions.s.sol` `run()` or the `foundry-devops` most-recent-deployment lookup
- no gas stress test for large `s_funders` arrays
- no fork tests against live or forked Chainlink feeds
- no fuzz tests
- no invariant tests
- no static-analysis result
- no formal verification result
- `FundMeTest.testPrintStorageData` is debug-style and should be removed or converted into a focused assertion if kept long term

## 14. Future Testing Improvements

These improvements are production-style next steps, but they are not required for the current learning-stage FundMe scope:

- add a rejecting-owner contract test for failed withdrawal calls
- add a forced-ETH test to document that tracked funder accounting is not a complete ledger of all ETH that can reach the contract
- add invalid-target tests for `WithdrawFundMe.withdrawFundMe(address)`
- add fuzz tests for funding amounts, repeated funders, conversion boundaries, oracle prices, decimals, and timestamps
- add invariant tests around withdrawal cleanup and funder accounting boundaries
- add gas stress tests for large funder arrays
- add fork tests for real Chainlink feed assumptions before any public deployment
- add Slither or Aderyn and record exact commands, versions, and findings
- add deployment smoke tests, block explorer verification checks, and operational runbooks before any public deployment
- add L2 sequencer uptime tests if L2 deployment becomes part of the project scope

## 15. Non-Claims

- Passing tests do not imply that the contract is secure.
- Coverage does not replace audit, formal verification, static analysis, fork testing, or production monitoring.
- This project is not production-ready.
- No public deployment, Etherscan verification, or staging validation is claimed here.
- No fuzz, invariant, fork, static-analysis, or formal-verification result is claimed here.
