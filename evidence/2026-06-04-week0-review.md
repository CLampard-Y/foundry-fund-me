# Week0 Review - 2026-06-04

## 1. What I planned
冻结现实，建立 SimpleStorage/FundMe 证据基线。

## 2. What I actually completed
### SimpleStorage:
- 已完成基线识别（[基础环境快照](./2026-05-27-command-log.md) + 格式检查`forge fmt --check` + [gas基线](../.gas-snapshot) + [repo-gap-list](../repo-gap-list.md)）
- 针对合约增加对应 custom errors
- 完善了测试

### FundMe
- Baseline:
    - 已完成基线识别（[基础环境快照](./2026-05-27-command-log.md) + 格式检查`forge fmt --check` + [gas基线](../.gas-snapshot) + [repo-gap-list](../repo-gap-list.md)）
- Core contract:
    - Added custom errors (owner check, invalid price feed, insufficient funds, failed ETH transfer)
    - Added events for observability (`Funded`, `Withdrawn`)
    - Refactored funder tracking (avoid duplicate funder entries while preserving cumulative funding amounts)
    - Added NatSpec for core public/external entry points and ETH flow
- Oracle / PriceConverter:
    - Documented the Chainlink price feed trust boundary and kept stale-price checks explicit.
    - Added validation for price (non-positive, missing `updatedAt`, future timestamp, stale price)
    - Added decimal normalization (18 decimals) for price
    - Added explicit lint suppressions for intentional `block.timestamp` usage and safe type casting
- Test coverage:
    - Expanded FundMe unit tests (funding, duplicate funder handling, withdrawal state reset, event emission, receive/fallback behavior, and owner-only withdrawal)
    - Added PriceConverter unit tests (valid conversions, fractional ETH conversion, zero/negative prices, stale prices, future timestamps, missing timestamps, and decimal scaling)
    - Added HelperConfig tests (unsupported chain fail-fast behavior and supported chain configuration branches)
    - Added integration tests (exercise deployment + interaction scripts through fund and withdraw flows)
- Mock improvements:
    - Improved `MockV3Aggregator` to support controlled oracle scenarios through `updateRoundData`
    - Used the mock to test (normal prices, invalid prices, stale prices, future timestamps and different decimals)
- Scripts and configuration:
    - Hardened `HelperConfig` (explicit chain-id branches and fail-fast behavior for unsupported chains)
    - Added named constants for supported chain IDs and Chainlink ETH/USD price feed addresses.
    - Added Anvil mock price feed creation and reuse logic.
    - Improved interaction scripts with target address validation (`address(0)` and no-code address checks) before fund/withdraw calls.
    - Kept interaction scripts CLI-driven so different networks can use different keystore accounts without hardcoding private keys.
- Workflow / Makefile:
    - Removed the dangerous `remove` target that deleted dependency metadata and could mutate git state.
    - Moved `all` toward a safer validation workflow (by removing dependency deletion and updates)
    - Added separate `format` and `format-check` targets.
    - Standardized deployment wallet handling through Foundry keystore accounts for Anvil, Sepolia, zkSync local, and zkSync Sepolia.
    - Aligned install dependency versions with current submodule versions.
- Current verification:
    - Verified on 2026-06-04
    - `forge fmt --check`: passed.
    - `make build`: passed.
    - `make test`: passed (40 tests passed, 0 failed)
- Known limitations / production concerns：
    - `withdraw()` still loops over all funders, which may not scale for large funder sets.
    - The contract depends on a single Chainlink- compatible ETH/USD price feed.
    - Interaction scripts remain course-friendly and still rely on recent deployment lookup.
    - No fuzz, invariant, CI, or full security notes have been added yet.

## 3. Evidence produced
- command log: 两个仓库均已完成
- gap list: 两个仓库均已完成
- test output: 两个仓库均已完成
- gas snapshot: 两个仓库均已完成
- README status: 两个仓库均已完成（其中 `FundMe` 英文主README 待完善）

## 4. Main blockers
- Blocker 1: 
- Blocker 2: 

## 5. Gate decision for June
Choose one:
- A: 两仓库 build/test 都通过，可以进入证据化清理 + 下一课程。
- B: 一个仓库通过，一个仓库失败，先修失败仓库。
- C: 两仓库都失败，6月不开新项目，进入修复周。

>已完成 A

## 6. My interpretation
> 我现在是真掌握了，还是只是跟着做过？
- 已经逐步接触，开始掌握对应的知识内容，并开始接触关注到对应的生产环境规范 (production-conscious)
- 但具体的实现代码及思路仍不熟悉，需要多次借助AI实现，仍需后续进一步加强训练使用。
