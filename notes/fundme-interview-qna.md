# FundMe Interview Q&A

## Q1. Why does FundMe need a price feed?
Funders fund the contract with ETH, while contract express minimum amount requirement in USD, therefore FundMe need a reliable way-ETH/USD price feed to transform ETH amount into USD amount.
## Q2. Why does the project use MockV3Aggregator in tests?
`PriceConverterTest` want to test if contract can validate price effectively (whether it is invalid, non-positive, stale, UpdatedAt is future timestamp). 
using `.updateRoundData()` in `MockV3Aggregator` allows us to modify different price feed , and make local tests deterministic, allowing the project to test oracle-dependent logic without relying on a live network
## Q3. What problem does HelperConfig solve?
According to the deployed block chain id,`HelperConfig` can chose different networkconfigs automatically, which frees us from typing network config information (e.g. RPC-URL, private-key, ...) every time we want to deploy contract, and makes contract more robust, allowing contract can deploy in different block chain without change detailed code
## Q4. Why should stale oracle prices be rejected?
Because the ETH/USD changes every minutes, stale orcle price (more than 4 hours) may contribute to wrong ETH-USD transform, leading to wrong USD balance
## Q5. Why normalize price feed decimals to 18 decimals?

## Q6. Why does withdraw reset accounting before external ETH transfer?

## Q7. Why is withdraw looping over funders a gas risk?
When the quantity of funders reach a very big number-which is normal in real production environment-looping over funders array will cost a great amount of gas, which will contribute to a gas risk
## Q8. Why can forced ETH break the accounting intuition?
Forced ETH fund don't enter contract by `fund()`, `receive()`, or `fallback()`, which means it can enter contract without satisfing the minimum USD requirement and being recored in the contract ETH balance, breaking the accounting intuition
## Q9. Why does high coverage not mean the contract is secure?
High coverage only means the tests basically cover core functions and the core functions are working correctly as we want, but it doesn't mean the contract is secure or there is no attack surface in contract
## Q10. What would be required before this contract could handle real funds?
The next improvements should focus on stronger verification and better production boundaries:
- Add fuzz tests, invariant tests, static analysis, and possibly fork or staging tests. 
- Add clearer deployment and interaction evidence, such as a verified testnet deployment, contract address, transaction hashes, and cast examples.

If moving closer to production, I would also rethink the permission and withdrawal model, such as multisig ownership, pause mechanism, refund logic, or avoiding the funder-loop gas risk. 

But for the current stage, these should remain documented future work, not immediate scope.