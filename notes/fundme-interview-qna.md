# FundMe Interview Q&A

## Q1. Why does FundMe need a price feed?
>FundMe accepts ETH, while the minimum contribution threshold is denominated in USD. The ETH/USD price feed converts `msg.value` into an 18-decimal USD value so the contract can enforce a stable economic threshold. This feed is an external trust boundary, so invalid or stale oracle data must be rejected.

## Q2. Why does the project use MockV3Aggregator in tests?
>We use `MockV3Aggregator` to control oracle responses locally (answer, updatedAt, decimals, etc.), so that we can test invalid price, stale, future or zero timestamp cases, decimal scaling instead of relying on live network (e.g. Chainlink feed) data, which will change over time, making the tests unstable.

## Q3. What problem does HelperConfig solve? 
>`HelperConfig` centralizes network-specific contract addresses, especially the ETH/USD price feed (chooses price feed according to `block.chainid`, fails fast when chainid is not supported), and provides a deterministic mock feed for local Anvil tests.

>Important boundary: `HelperConfig` does not manage RPC URLs, private keys, or deployment records. Those details are still handled by `.env`, `Makefile`, `CLI args`, `Foundry account` or separate deployment documentation.

## Q4. Why should stale oracle prices be rejected?
>Because the ETH/USD price changes over time, stale oracle price (older than 3 hours) may make the USD-denominated minimum funding check economically incorrect.

## Q5. Why normalize price feed decimals to 18 decimals?
>ETH amounts are represented in wei, where 1 ETH equals 1e18 wei, and MINIMUM_USD is stored as 5e18 (18 decimals), however, Chainlink-compatible price feeds may use different decimals (6, 8 or 18). Without decimal normalization, the conversion of USD value could be overestimated or underestimated.

## Q6. Why does withdraw reset accounting before external ETH transfer?
>`withdraw()` resets funder accounting first, then transfers ETH to owner by `call`, which is a `Checks-Effects-Interactions` (CEI) aware pattern. If `call` fails, the entire transaction will revert, and the state changes are rolled back.

## Q7. Why is withdraw looping over funders a gas risk?
>The risk is not immediate in a small demo, but in a production system an unbounded loop over a user-controlled set of unique funders can eventually make `withdraw()` too expensive or impossible to execute within the block gas limit.

## Q8. Why can forced ETH break the accounting intuition?
>Forced ETH fund doesn't enter contract by `fund()`, `receive()`, or `fallback()`, which means it can enter contract and increase `address(this).balance` without satisfying the minimum USD requirement (bypass) and without updating funder accounting. As a result, the contract balance may become greater than the sum of tracked funder contributions.

## Q9. Why does high coverage not mean the contract is secure?
>High coverage only means the tests executed most lines or branches. It does not prove that the right properties were tested, that edge cases were exhausted, or that the contract has no attack surface. Coverage is useful evidence, but it is not a substitute for adversarial testing, static analysis, formal verification, or audit review.

## Q10. What would be required before this contract could be considered for handling real funds?
>Before this contract could be considered for real funds, it would need stronger verification, clearer operational controls, and design-level risk decisions.
- Verification: fuzz tests, invariant tests, static analysis, fork/staging tests, and external review.
- Operations: deployment records, verified contract addresses, monitoring, incident response, and safer key management.
- Design: multisig ownership, explicit refund policy, pause/emergency controls, bounded withdrawal design, and documented oracle/feed assumptions.

>For the current learning-stage scope, these are better documented as future production concerns rather than all implemented immediately.
