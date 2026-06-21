# FundMe 5-Minute Explanation

## 1. What is this project?
This is a course-based FundMe project extended with stage-appropriate production-aware improvements, including deterministic mocks, network-aware configuration, interaction scripts, expanded tests and security notes, but NOT production-ready.
The core contract is [FundMe](../src/FundMe.sol). users fund the contract with ETH. The contract uses a Chainlink-compatible ETH/USD price feed only to check whether the ETH sent meets the minimum USD requirement. The contract stores ETH (NOT USD), and only the owner can withdraw (`withdraw()`) the accumulated ETH.

## 2. What problem does it solve?
FundMe models a compact ETH funding workflow where users send ETH, but the minimum contribution is defined in USD. 

This creates a practical oracle boundary: the contract must use a Chainlink-compatible ETH/USD price feed to calculate a USD-denominated value before accepting funds.

Beyond that, the project covers basic funder accounting, owner-only withdrawal, deterministic local mocks, network-aware configuration, interaction scripts, and risk-based tests. 

The goal is not to claim production readiness, but to show how a simple funding contract can be made more testable, reviewable, and security-aware.

## 3. Main contract flow
- (1) Users **send** ETH to contract through `fund()`, `receive()` or `fallback()`.
- (2) The contract calculates the USD-denominated value of `msg.value` using a Chainlink-compatible ETH/USD price feed.
- (3) (If the value is high enough) The contract **records** the funder and the ETH amount funded.
- (4) The owner can **withdraw** the contract's entire ETH balance by `withdraw()`

## 4. Oracle and price conversion
[PriceConverter](../src/PriceConverter.sol) reads `latestRoundData()` from a Chainlink-compatible ETH/USD price feed, rejects invalid prices (including non-positive prices, missing, stale, or future timestamp), then normalizes the feed decimals to 18 decimals before calculating the USD-denominated value.

## 5. Testing strategy
The tests are designed around risk boundaries:
- funding threshold
- owner-only withdrawal
- oracle data validation
- funder accounting
- receive/fallback behavior
- config selection
- script-level interactions

The project also records coverage as engineering evidence, but it does not treat coverage as proof of security or audit. Current known gaps include no fuzz testing, no invariant testing, no public deployment verification, and no external audit.
## 6. Security assumptions and known limitations
This project is designed as a learning/portfolio project with production awareness, but don't treat it as production-ready.

The main trust assumptions are:

（1）The owner is a trusted single point of control, because only the owner can withdraw the full ETH balance.

（2）The oracle is still a trust boundary: the contract validates non-positive and stale data, but it still relies on the configured feed being the intended ETH/USD feed for the target chain.

（3）The project runs within a limited learning scope. The tests and coverage are evidence of review effort, not a substitute for an audit or formal verification.

The main limitations are also clear:
- `withdraw()` loops over all unique funders, so large funder lists can create a gas scalability risk.
- There is no refund flow, no pause/emergency stop, and no ownership transfer mechanism.
- The contract records normal funding through `fund()`, `receive()`, and `fallback()`, but tracked accounting is not a complete ledger of every way ETH can reach the contract.
- `withdraw()` follows a CEI-style flow by resetting accounting before transferring ETH, but a production review would still test owner-as-contract and withdrawal failure behavior.

So the security position is not “secure” or “production-ready.” A better description is: the project documents key risks, implements basic mitigations, and clearly states what is not covered yet.
## 7. What I improved beyond the course baseline
Compared with the basic course version, I tried to make the project more production-aware:

- Improved error handling, event emission, state visibility, funder tracking, and oracle boundary checks such as invalid price, stale price, and decimals normalization.
- Expanded the project evidence: README, TESTING, SECURITY_NOTES, repo-gap-list, command logs, Makefile workflow, and broader tests. 

The main improvement is not that the project became production-ready, but that it became more reviewable, reproducible, and explainable.
## 8. What I would improve next
The next improvements should focus on stronger verification and better production boundaries:
- Add fuzz tests, invariant tests, static analysis, and possibly fork or staging tests. 
- Add clearer deployment and interaction evidence, such as a verified testnet deployment, contract address, transaction hashes, and cast examples.

If moving closer to production, I would also rethink the permission and withdrawal model, such as multisig ownership, pause mechanism, refund logic, or avoiding the funder-loop gas risk. 

But for the current stage, these should remain documented future work, not immediate scope.
