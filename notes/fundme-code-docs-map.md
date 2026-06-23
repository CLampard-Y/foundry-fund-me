# FundMe Code-Docs Traceability Map

This note maps the project's most important security and testing claims back to concrete code, tests, and documentation. It is not a full test index. `TESTING.md` owns the complete testing strategy; this file only keeps high-signal traceability for claims that matter to security review, production boundaries, and portfolio presentation.

## Selection Principle

The map is driven by documented claims, not by the number of tests.

```text
documented claim -> code mechanism -> test evidence -> remaining limitation
```

A claim is included when it affects at least one of:

- ETH custody or movement
- access control
- oracle trust boundaries
- accounting or state transitions
- script/deployment safety boundaries
- documented production limitations
- explicit non-claims, such as no audit or no formal verification

Low-level getter tests, debug tests, duplicated happy paths, and implementation-detail checks are intentionally omitted or merged unless they support one of the above categories.

## Status Legend

| Status | Meaning |
| --- | --- |
| Covered | The behavior has direct code and test evidence in the current repository. |
| Partially covered | The core behavior is tested, but an important edge case or production concern remains open. |
| Documented gap | The risk is explicitly documented, but no dedicated test or mitigation is claimed. |
| Accepted limitation | The issue is intentionally kept for the current learning-stage scope. |
| Non-claim | The repository explicitly does not claim this assurance level. |

## Core Traceability Matrix

| ID | Security / Testing Claim | Code Evidence | Test Evidence | Documented In | Status | Why It Stays |
| --- | --- | --- | --- | --- | --- | --- |
| CDM-001 | Price feed configuration is explicit and zero-address feeds are rejected. | `src/FundMe.sol:35-40`; `script/HelperConfig.s.sol:32-48`; `script/DeployFundMe.s.sol:10-18` | `testConstructorRevertsIfPriceFeedIsZeroAddress`; `HelperConfigTest` network-branch tests | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Partially covered | This is the main oracle configuration boundary. Local tests prove config regression behavior, not live feed identity or health. |
| CDM-002 | Normal funding entry points enforce the USD minimum threshold. | `src/FundMe.sol:47-50`; `receive()` at `src/FundMe.sol:116-120`; `fallback()` at `src/FundMe.sol:110-114` | `testFundFailsWithoutEnoughETH`; `testReceiveFailsWithoutEnoughEth`; `testFallbackFailsWithoutEnoughEth`; receive/fallback success tests | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Covered | This is the core business rule: normal ETH entry paths must not bypass the minimum funding check. |
| CDM-003 | Funder accounting accumulates ETH and avoids duplicate funder entries. | `src/FundMe.sol:23-25`; update logic at `src/FundMe.sol:54-58` | `testFundUpdatesFundDataStructure`; `testSameFunderIsOnlyAddedOnce`; `testSameFunderAmountStillAccumulates` | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Covered | This protects the main accounting behavior and explains the gas-aware de-duplication design. |
| CDM-004 | Successful fund and withdraw actions emit events. | Events at `src/FundMe.sol:20-21`; emits at `src/FundMe.sol:60` and `src/FundMe.sol:95` | `testFundEmitFundedEvent`; `testWithdrawEmitWithdrawnEvent` | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Covered | Events are kept because the docs claim monitoring/indexing value. They are not treated as a security control. |
| CDM-005 | Only the owner can withdraw the full contract balance. | `onlyOwner` at `src/FundMe.sol:68-72`; `withdraw()` at `src/FundMe.sol:78-96` | `testOnlyOwnerCanWithdraw`; successful withdrawal tests | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Covered | This is the central access-control property and the main owner trust assumption. |
| CDM-006 | Withdrawal resets tracked accounting before the external ETH transfer. | Reset loop at `src/FundMe.sol:80-86`; low-level `call` at `src/FundMe.sol:90` | `testWithdrawResetsFunderAmount`; `testWithdrawFromASingleFunder`; `testWithdrawFromMultipleFunders` | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Partially covered | The CEI-style state transition is tested, but owner-as-contract and malicious/rejecting owner behavior are not adversarially tested. |
| CDM-007 | Failed low-level withdrawal transfer should revert. | `src/FundMe.sol:90-93` (`FundMe__CallFailed`) | No dedicated rejecting-owner / failed-call test | `SECURITY_NOTES.md`; `TESTING.md`; `repo-gap-list.md` FM-008 | Documented gap | This stays because it is a real funds-flow edge case and a documented missing test. |
| CDM-008 | Forced ETH can bypass `fund()`, `receive()`, and `fallback()` accounting. | Accounting only updates in `src/FundMe.sol:54-58`; withdrawal uses full `address(this).balance` at `src/FundMe.sol:88` | No dedicated forced-ETH test | `SECURITY_NOTES.md`; `TESTING.md`; `repo-gap-list.md` FM-008; `notes/fundme-interview-qna.md` Q8 | Documented gap | This is an important EVM edge case: tracked accounting is not a complete ledger of every way ETH can reach the contract. |
| CDM-009 | `withdraw()` has an unbounded linear loop over unique funders. | `src/FundMe.sol:80-85` | `testWithdrawFromMultipleFunders` covers only a small multi-funder case | `README.md`; `SECURITY_NOTES.md`; `TESTING.md`; `repo-gap-list.md` FM-006 | Accepted limitation | This is the main gas scalability limitation and should remain visible for production review. |
| CDM-010 | Oracle data is checked for non-positive price and stale/invalid timestamps. | `src/PriceConverter.sol:37-54`; `STALE_PRICE_TIMEOUT` at `src/PriceConverter.sol:16` | zero/negative price tests; stale/future/zero-`updatedAt` tests in `PriceConverterTest` | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Covered | This is the core oracle trust-boundary mitigation for the current scope. |
| CDM-011 | Feed decimals are normalized before USD conversion. | `src/PriceConverter.sol:60-63`; `_scalePriceToTargetDecimals` at `src/PriceConverter.sol:78-84`; conversion at `src/PriceConverter.sol:70-74` | 6-, 8-, and 18-decimal tests; 1 ETH and fractional ETH conversion tests | `README.md`; `SECURITY_NOTES.md`; `TESTING.md`; `notes/fundme-interview-qna.md` Q5 | Covered | This stays because fixed-point decimal mistakes are common smart contract bugs and directly affect minimum funding enforcement. |
| CDM-012 | Interaction scripts validate explicit target addresses and support fund/withdraw helpers. | `_validateFundMeAddress` at `script/Interactions.s.sol:13-22`; fund helper at `script/Interactions.s.sol:29-67`; withdraw helper at `script/Interactions.s.sol:78-85` | funding invalid-target tests; integration fund/withdraw happy path | `README.md`; `SECURITY_NOTES.md`; `TESTING.md` | Partially covered | Script safety is documented, but negative tests currently cover the funding path only, not the withdrawal helper path. |
| CDM-013 | `run()` interaction methods rely on most-recent deployment lookup. | `script/Interactions.s.sol:70-74`; `script/Interactions.s.sol:87-90` | No direct `run()` / `foundry-devops` lookup test | `README.md`; `SECURITY_NOTES.md`; `TESTING.md`; `repo-gap-list.md` FM-007 | Accepted limitation | This is an operational risk, not a core contract bug. It is acceptable for tutorial/local workflows but should be replaced by explicit targets in stricter deployments. |
| CDM-014 | Test coverage is not treated as a security proof, and advanced assurance is not claimed. | No contract mechanism; this is an assurance-boundary statement | Coverage snapshot exists, but no audit, fuzz, invariant, fork, static-analysis, or formal-verification result is claimed | `README.md`; `SECURITY_NOTES.md`; `TESTING.md`; `repo-gap-list.md` FM-002/FM-003/FM-004/FM-005; `notes/fundme-interview-qna.md` Q9 | Non-claim | This prevents overclaiming. High coverage is evidence of exercised paths, not proof of production security. |

## Merged or Omitted Items

| Item | Decision | Reason |
| --- | --- | --- |
| Separate `receive()` and `fallback()` rows | Merged into CDM-002 | They support the same claim: normal ETH entry points route through the minimum funding check. |
| Separate funding update, duplicate funder, and accumulation rows | Merged into CDM-003 | These tests all support one accounting claim: tracked funder state is updated correctly without duplicate funder entries. |
| Separate single-funder and multi-funder withdrawal rows | Merged into CDM-006 and CDM-009 | Normal withdrawal behavior belongs to CEI/accounting cleanup; large-scale gas risk is tracked separately as a limitation. |
| `PriceConverter` conversion-only tests | Merged into CDM-011 | Conversion correctness is relevant because of decimal normalization and minimum funding enforcement, not as an isolated getter-style claim. |
| `MockV3Aggregator` standalone row | Merged into CDM-001 and CDM-010 | The mock matters as evidence for config and oracle validation. It does not need a separate headline unless this becomes a mock-design document. |
| `DeployFundMe` standalone row | Merged into CDM-001 | Deployment wiring is part of the price feed configuration boundary. |
| Integration script happy-path row | Merged into CDM-012 | The helper happy path supports script boundary evidence, but does not need a separate row from target validation. |
| `testPriceFeedVersionIsAccurate` | Omitted | It is a regression check for current mock/mainnet feed versions, but it is not a strong production safety claim. Feed identity and health require operational or fork validation. |
| Getter-only tests such as owner/minimum getters | Omitted | Getter tests are useful, but they do not independently support a high-priority security or production-boundary claim. |
| `testPrintStorageData` | Omitted from the main matrix | It is a debug/learning test using `vm.load()` and `console.log`, not a behavioral security assertion. |
| `test/unit/ZkSyncDevOps.t.sol` | Omitted | It is outside the main FundMe security assurance scope documented in `SECURITY_NOTES.md` and `TESTING.md`. |

## Review Notes

- The strongest current evidence is around normal funding, owner-only withdrawal, accounting cleanup, oracle validation, decimal normalization, and basic script validation.
- The highest-value missing tests are still forced ETH accounting and failed withdrawal to a rejecting owner, matching `repo-gap-list.md` FM-008.
- This file should stay smaller than `TESTING.md`. If a future entry does not map a documented safety claim or production boundary, it probably belongs in `TESTING.md` instead.
