# SECURITY_NOTES

This document records the security assumptions, risk boundaries, and known limitations of this learning and portfolio project. It is not an audit report.

The goal is to make the current security posture explicit for reviewers, interviewers, and future maintainers without claiming guarantees that the code has not earned.

## Scope

These notes cover the current repository implementation of:

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

The primary security boundary is the `FundMe` ETH funding and owner withdrawal flow. The scripts and tests are included only to describe deployment, configuration, interaction, and verification assumptions around that flow.

`test/unit/ZkSyncDevOps.t.sol` is not part of this FundMe security scope.

This document does not cover third-party dependency internals such as Chainlink contracts, `forge-std`, or `foundry-devops`, except where this project directly relies on their behavior.

Latest local verification evidence is recorded in [`evidence/2026-06-07-command-log.md`](./evidence/2026-06-07-command-log.md).

## Assets

- ETH held by the `FundMe` contract balance.
- Funder accounting state:
  - `s_addressToAmountFunded`
  - `s_isFunder`
  - `s_funders`
- Owner withdrawal authority stored as immutable `i_owner`.
- Configured Chainlink-compatible ETH/USD price feed stored as immutable `i_priceFeed`.
- Minimum funding threshold: `MINIMUM_USD = 5e18`.
- Deployment and interaction target addresses used by scripts.
- Local Anvil/mock price feed configuration used during tests and local development.

## Trust Assumptions

- The deployer is intended to become the immutable owner of `FundMe`.
- The owner account is trusted to withdraw the full contract balance at any time.
- The configured price feed address is correct for the target chain.
- The configured price feed is assumed to report the intended ETH/USD pair, not merely to implement `AggregatorV3Interface`.
- The configured price feed follows the expected `AggregatorV3Interface` behavior.
- Chainlink-compatible ETH/USD price data is relied on to enforce the USD-denominated minimum funding threshold.
- Price data within `STALE_PRICE_TIMEOUT = 3 hours` is treated as fresh enough for this learning project.
- `block.timestamp` is acceptable for hour-level stale price validation.
- The Anvil `MockV3Aggregator` is only a local/test dependency and is not a production oracle.
- The interaction scripts are expected to be run against the intended deployment address.
- The `foundry-devops` "most recent deployment" lookup is assumed to return the intended target when the script `run()` methods are used.
- Mainnet and Sepolia feed addresses are hardcoded and must be re-checked before any real deployment.
- No public deployment, verification status, or production operation is claimed in this document.

## Attack Surface

### Functions

- `fund()` accepts ETH from any caller and uses the configured price feed to enforce the minimum USD funding threshold.
- `withdraw()` transfers the full contract balance to the owner and resets funder accounting.
- `receive()` routes plain ETH transfers through `fund()`.
- `fallback()` routes ETH transfers with calldata through `fund()`.
- Getter functions expose read-only state, including owner, price feed, funder count, funder address by index, and funded amount by address.
- `PriceConverter.getPrice()` reads external oracle data and validates price positivity, update timestamp presence, future timestamps, and staleness.
- `PriceConverter.getConversionRate()` converts ETH amounts into 18-decimal USD values using the configured price feed.

### Roles

- External funders can call `fund()`, `receive()`, or `fallback()` with ETH.
- The owner can call `withdraw()` and receive the full contract balance without funder approval.
- If the owner is a contract, its receive/fallback logic is executed during withdrawal.
- The deployer controls initial owner assignment because the constructor sets `i_owner = msg.sender`.
- Script broadcasters execute deployment, funding, and withdrawal transactions through Foundry scripts.

### External Dependencies

- Chainlink-compatible ETH/USD price feed:
  - `latestRoundData()`
  - `decimals()`
  - `version()`
- `MockV3Aggregator` for local tests and Anvil configuration.
- `foundry-devops` deployment lookup in interaction script `run()` methods.
- RPC endpoints and chain IDs used by Foundry scripts and the Makefile.

### Script Interactions

- `DeployFundMe.run()` deploys `HelperConfig`, reads the active price feed, and deploys `FundMe`.
- `HelperConfig` selects Mainnet, Sepolia, or Anvil configuration based on `block.chainid`.
- `HelperConfig` deploys and reuses a local mock price feed on Anvil within a single `HelperConfig` instance.
- `FundFundMe.fundFundMe(address)` funds a provided `FundMe` target with `0.1 ether`.
- `WithdrawFundMe.withdrawFundMe(address)` calls `withdraw()` on a provided `FundMe` target.
- `FundFundMe.run()` and `WithdrawFundMe.run()` resolve a target by asking `foundry-devops` for the most recent `FundMe` deployment on the current chain.

## Implemented Mitigations

- `FundMe` constructor rejects `address(0)` as the price feed.
- `fund()` rejects ETH amounts whose converted USD value is below `MINIMUM_USD`.
- `receive()` and `fallback()` route through `fund()`, so direct ETH transfers do not bypass the minimum funding threshold.
- `withdraw()` is restricted by the `onlyOwner` modifier.
- On successful withdrawal, `withdraw()` resets tracked funder accounting before the external ETH transfer. If the transfer fails, the revert rolls back those state changes.
- ETH withdrawal uses low-level `call` and reverts if the transfer fails.
- Repeated funding from the same address accumulates the funded amount without adding duplicate entries to `s_funders`.
- `PriceConverter` rejects non-positive oracle prices.
- `PriceConverter` rejects `updatedAt == 0`.
- `PriceConverter` rejects oracle timestamps later than `block.timestamp`.
- `PriceConverter` rejects price data older than `STALE_PRICE_TIMEOUT`.
- `PriceConverter` normalizes feed decimals to 18 decimals before conversion.
- `HelperConfig` rejects unsupported chain IDs.
- `HelperConfig` performs a post-selection check that rejects `address(0)` as the active price feed.
- Anvil configuration deploys and reuses a local `MockV3Aggregator` within a single `HelperConfig` instance.
- Interaction scripts reject `address(0)` as a `FundMe` target.
- Interaction scripts reject target addresses with no contract code.
- `Funded` and `Withdrawn` events are emitted after successful fund and withdraw actions.
- Tests cover key revert paths, owner-only withdrawal, funding accounting, event emission, receive/fallback routing, oracle validation, decimal scaling, supported network configuration, unsupported chain IDs, and funding interaction target validation.

## Known Risks and Limitations

- `withdraw()` loops over all unique funders. A large number of funders can make withdrawal exceed the block gas limit. This is accepted for the current small learning project, but it would need a different accounting or withdrawal design before handling large-scale usage.
- The owner is a single point of control and can withdraw the full contract balance at any time. This is simple and appropriate for the current tutorial-sized contract, but it is not a trust-minimized fundraising, escrow, or refund design.
- There is no ownership transfer mechanism. If the owner key is lost or compromised, the contract has no built-in recovery path.
- If the owner address is a contract that rejects ETH, `withdraw()` will revert. There is no alternate withdrawal recipient or recovery path.
- If the owner is a contract, its receive/fallback logic can execute during `withdraw()`. The current state reset happens before the external call and failed calls revert, but there is no explicit reentrancy guard or malicious-owner test in this repository.
- There is no pause or emergency stop mechanism. This is intentionally not added at this stage to avoid increasing admin complexity in a small learning project.
- There is no refund or user-initiated withdrawal flow. Funders cannot reclaim funds from the contract through the current implementation.
- There is no partial withdrawal flow. The owner withdrawal function transfers the full contract balance.
- The contract supports only native ETH funding. ERC20 funding and token-specific accounting are outside the current scope.
- ETH can be force-sent to the contract without calling `fund()`, `receive()`, or `fallback()`. In that case, contract balance can exceed tracked funder accounting and the minimum funding threshold is bypassed for that forced ETH.
- Oracle trust remains a core dependency. Incorrect, delayed, unavailable, or manipulated oracle data can affect minimum funding enforcement.
- A nonzero contract address is not enough to prove the configured oracle reports the intended ETH/USD pair. Feed identity, network, decimals, and freshness assumptions must be checked operationally before any real deployment.
- L2 sequencer uptime handling is not implemented. This matters for L2 deployments but is outside the current ETH/Sepolia/Anvil-focused scope.
- The stale price timeout is a project-level parameter, not a complete oracle risk model.
- `PriceConverter` does not check `answeredInRound` or `roundId`. Current validation focuses on price positivity and timestamp freshness.
- `PriceConverter` assumes sane feed decimals. Extremely unusual or malicious feed decimal settings are outside the current project model.
- Anvil mock price feed reuse is limited to a single `HelperConfig` instance. Separate script runs can deploy separate local mocks.
- Interaction script `run()` methods may interact with an unintended contract if the "most recent deployment" is not the intended target in a multi-deployment environment.
- Script-side broadcaster balance checks are commented out and are not currently implemented.
- `WithdrawFundMe.withdrawFundMe(address)` uses the same address validation helper as the funding interaction, but invalid-target tests currently cover the funding interaction path only.
- RPC configuration, account selection, keystore usage, and environment variables remain operational concerns outside the Solidity contract.
- Public deployment, contract verification, monitoring, alerting, and incident response are not implemented in this repository.

## Not Covered

- No audit.
- No formal verification.
- No fuzz testing is currently claimed for this repository.
- No invariant testing is currently claimed for this repository.
- No dedicated forced-ETH accounting test is currently claimed for this repository.
- No dedicated malicious-owner or reentrant-owner test is currently claimed for this repository.
- No mainnet deployment is currently claimed.
- No public production deployment is currently claimed.
- No Etherscan or block explorer verification is currently claimed.
- No Slither result is currently claimed.
- No Mythril result is currently claimed.
- No Echidna result is currently claimed.
- No production incident response process.
- No production key management policy.
- No oracle failover strategy.
- No L2 sequencer uptime integration.
- No real fundraising, custody, refund, compliance, or treasury policy.

## Future Improvements

The following items are possible improvements, but they are not implemented in the current repository:

- Add fuzz tests for funding amounts, price feed decimals, and oracle timestamp edge cases.
- Add invariant tests for accounting consistency between funder state and contract balance.
- Add a forced-ETH test and document that tracked funder accounting is not a complete ledger of all ETH that can reach the contract.
- Add withdrawal failure and malicious-owner contract tests if owner-as-contract behavior becomes relevant to the project.
- Add static analysis with Slither and record the exact command and findings.
- Add a withdrawal design that avoids looping over an unbounded funder list.
- Add owner transfer or two-step ownership transfer if ownership recovery becomes part of the project scope.
- Add multisig-based ownership for any real deployment scenario.
- Add explicit deployment address management instead of relying only on most-recent-deployment lookup.
- Add explicit oracle feed identity checks to the deployment checklist, including chain ID, feed pair, feed address, decimals, and expected version.
- Add script-side broadcaster balance checks before funding transactions.
- Add invalid-target tests for `WithdrawFundMe.withdrawFundMe(address)` if script test coverage is expanded.
- Add L2 sequencer uptime checks before supporting L2 deployments.
- Add a deployment checklist covering oracle address verification, chain ID confirmation, block explorer verification, and post-deployment smoke tests.
- Add monitoring notes for `Funded`, `Withdrawn`, oracle failures, and unexpected reverts.

## Non-Claims

- This project is not audited.
- This project is not production-ready.
- This project should not be used to manage real funds without further review.
