# Foundry FundMe

[![CI](https://github.com/CLampard-Y/foundry-fund-me/actions/workflows/test.yml/badge.svg)](https://github.com/CLampard-Y/foundry-fund-me/actions/workflows/test.yml)
[![Built with Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1F.svg)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

English | [中文](./README.zh-CN.md)

## Overview

`Foundry FundMe` is a production-aware Solidity and Foundry learning project for an ETH-based funding contract. Users can fund the `FundMe` contract with ETH, while the contract uses a Chainlink-compatible ETH/USD price feed to enforce a minimum funding threshold denominated in USD. The contract owner can withdraw the full contract balance and reset the funder accounting state.

This project is based on the Cyfrin Updraft Foundry FundMe course, but it has been extended beyond the baseline tutorial implementation with stronger engineering practices: oracle boundary checks, custom errors, events, private state with explicit getters, funder de-duplication, fail-fast network configuration, interaction script validation, expanded unit and integration tests, NatSpec documentation, and a safer Makefile workflow.

This repository is intended as a learning project and portfolio-quality Foundry example. It is not an audited fundraising protocol and should not be used to manage real funds without further security review and operational hardening.

## Project Status

| Area | Status |
| --- | --- |
| Contract development | Core functionality completed |
| Local verification | `make all`, `forge build --sizes`, and `forge coverage` passed |
| CI | GitHub Actions configured |
| NatSpec | Core contract and `PriceConverter` documented; scripts/config can be improved further |
| Makefile | Main cleanup completed; supports fmt/build/test/deploy/fund/withdraw workflows |
| Public deployment | No public network deployment is claimed in this README |
| Contract verification | No Etherscan verification is claimed in this README |
| Security audit | Not audited; not suitable for real fundraising use |

## What This Project Demonstrates

| Area | Implementation |
| --- | --- |
| Solidity contract design | Funding flow, owner withdrawal, receive/fallback routing, getter API |
| Oracle-aware engineering | Chainlink-compatible price validation, stale price checks, decimal scaling |
| Foundry testing | Unit tests, integration tests, mocks, revert assertions, event checks, state cleanup tests |
| Script workflow | Deployment script and interaction scripts for fund/withdraw actions |
| Environment separation | Mainnet, Sepolia, and Anvil configuration paths; local mock price feed |
| Gas-aware basics | Custom errors, `immutable`, `constant`, funder de-duplication, cached loop length |
| Documentation | English/Chinese README, core NatSpec, CI, verification and coverage snapshots |

## Project Structure

```text
.
├── src/
│   ├── FundMe.sol
│   └── PriceConverter.sol
├── script/
│   ├── DeployFundMe.s.sol
│   ├── HelperConfig.s.sol
│   └── Interactions.s.sol
├── test/
│   ├── unit/
│   │   ├── FundMeTest.t.sol
│   │   ├── PriceConverterTest.t.sol
│   │   ├── HelperConfigTest.t.sol
│   │   └── ZkSyncDevOps.t.sol
│   ├── integration/
│   │   └── FundMeTestIntegration.t.sol
│   └── mocks/
│       └── MockV3Aggregator.sol
├── Makefile
├── foundry.toml
├── README.md
└── README.zh-CN.md
```

## Contracts and Scripts

| File | Type | Purpose |
| --- | --- | --- |
| `src/FundMe.sol` | Core contract | Accepts ETH, tracks funders, enforces a minimum USD funding threshold, and allows owner withdrawal |
| `src/PriceConverter.sol` | Library | Reads a Chainlink-compatible price feed, validates oracle data, and converts ETH amounts to USD value |
| `script/HelperConfig.s.sol` | Configuration script | Selects the correct price feed by chain id; deploys and reuses a mock feed on Anvil |
| `script/DeployFundMe.s.sol` | Deployment script | Reads active network configuration and deploys `FundMe` |
| `script/Interactions.s.sol` | Interaction scripts | Funds and withdraws from the most recent deployment, with basic target address validation |
| `test/mocks/MockV3Aggregator.sol` | Mock | Simulates Chainlink `AggregatorV3Interface` for local tests |

## Core Functionality

| Functionality | Description |
| --- | --- |
| `fund()` | Accepts ETH only if its USD value meets the minimum threshold |
| `withdraw()` | Allows only the owner to withdraw the full balance and reset funder state |
| `receive()` | Routes plain ETH transfers through `fund()` |
| `fallback()` | Routes ETH transfers with calldata through `fund()` |
| `getVersion()` | Returns the configured price feed version |
| Getter functions | Expose read-only access to private state |

Minimum funding threshold:

```text
MINIMUM_USD = 5e18
```

USD values are normalized to 18 decimals to align with wei-based ETH accounting.

## Network Configuration

`HelperConfig` selects the active price feed based on `block.chainid`:

| Network | Chain ID | Price Feed |
| --- | ---: | --- |
| Ethereum Mainnet | `1` | Chainlink ETH/USD |
| Sepolia | `11155111` | Chainlink ETH/USD |
| Anvil Local | `31337` | `MockV3Aggregator` |

Unsupported chain ids revert immediately instead of returning `address(0)` and allowing the deployment flow to fail later.

> Mainnet and Sepolia feed addresses are hardcoded in the current configuration. Before any real deployment, verify the target feed address against official Chainlink documentation and reassess oracle-specific risks such as stale data, feed decimals, and L2 sequencer uptime checks.

## Production-Aware Design

This project follows a production-grade lens with stage-appropriate implementation. The goal is to practice correctness, security, testing, maintainability, and gas awareness without over-engineering a small learning project with governance, proxies, or full DeFi accounting.

### State Encapsulation

Core state variables are private and exposed through explicit getter functions. This avoids exposing internal naming and storage layout directly through public state variable getters.

### Custom Errors

The contracts use custom errors instead of revert strings:

```text
FundMe__NotOwner
FundMe__InvalidPriceFeed
FundMe__NotEnoughFunds
FundMe__CallFailed
PriceConverter__InvalidPrice
PriceConverter__StalePrice
HelperConfig__UnsupportedChainId
HelperConfig__InvalidPriceFeed
```

Custom errors reduce gas costs and make selector-based revert assertions cleaner in Foundry tests.

### Events

The core contract emits events for important fund flows:

```solidity
event Funded(address indexed funder, uint256 amount);
event Withdrawn(address indexed owner, uint256 amount);
```

Events are useful for off-chain indexing, monitoring, frontends, and audit trails. They are not a substitute for on-chain state or access control.

### Funding Accounting

Repeated funding from the same address increases that address's funded amount, but the address is only added to `s_funders` once. This keeps the cleanup loop from growing unnecessarily when a single address funds multiple times.

### Withdraw Flow

`withdraw()` is owner-only and clears funder state before sending ETH out of the contract, following the basic checks-effects-interactions pattern. This design is appropriate for this small project, but the loop over funders can still become a gas limit risk at large scale.

### Oracle Boundary Checks

`PriceConverter` does not blindly trust `latestRoundData()`. It checks:

- price must be positive
- `updatedAt` must not be zero
- `updatedAt` must not be in the future
- price data must not exceed the stale timeout
- feed decimals must be normalized to 18 decimals

Current stale timeout:

```text
STALE_PRICE_TIMEOUT = 3 hours
```

`block.timestamp` is used only for hour-level stale price validation, not for second-level security decisions.

### Interaction Script Validation

Before funding or withdrawing, `Interactions.s.sol` verifies that the target address:

- is not `address(0)`
- contains contract code

This reduces the chance of accidentally interacting with a zero address or an EOA. The scripts still rely on `foundry-devops` most recent deployment lookup, which should be treated carefully in multi-environment production workflows.

### NatSpec

`FundMe` and `PriceConverter` include core NatSpec documentation for behavior, revert conditions, oracle assumptions, and return values. `HelperConfig`, `DeployFundMe`, and `Interactions` can still be documented further.

## Tech Stack

- Solidity `^0.8.19`
- Foundry (`forge`, `cast`, `anvil`)
- Chainlink Data Feeds
- `forge-std`
- `foundry-devops`
- GitHub Actions CI

## Quick Start

### 1. Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Install Dependencies

If submodules are already tracked:

```bash
git submodule update --init --recursive
```

For a fresh clone or missing dependencies:

```bash
make install
```

`make install` writes dependency directories and is intended for initial setup, not day-to-day build/test runs.

### 3. Run the Full Local Check

```bash
make all
```

Current `make all` flow:

```text
forge clean
forge fmt --check
forge build
forge test
```

### 4. Run Common Commands Individually

```bash
make format-check
make build
make test
forge build --sizes
forge test -vvv
```

### 5. Start Local Anvil

```bash
make anvil
```

## Makefile Commands

| Command | Description |
| --- | --- |
| `make all` | Cleans the project, checks formatting, builds, and runs tests |
| `make clean` | Runs `forge clean` |
| `make format` | Runs `forge fmt` |
| `make format-check` | Runs `forge fmt --check` |
| `make build` | Runs `forge build` |
| `make test` | Runs `forge test` |
| `make snapshot` | Runs `forge snapshot` |
| `make anvil` | Starts Anvil with a fixed local mnemonic |
| `make deploy` | Deploys `FundMe` using `NETWORK_ARGS` |
| `make fund` | Runs the `FundFundMe` interaction script |
| `make withdraw` | Runs the `WithdrawFundMe` interaction script |
| `make deploy-zk` | Example zkSync local deployment target |
| `make deploy-zk-sepolia` | Example zkSync Sepolia deployment target |
| `make zktest` | Switches to foundry-zksync, runs zkSync tests, then switches back |

> `make zktest` changes the local Foundry toolchain through `foundryup-zksync` and `foundryup`. Run it only when you intend to work with the zkSync-specific flow.

## Deployment and Interactions

### Local Deployment

Start Anvil in a separate terminal:

```bash
make anvil
```

Configure local values in `.env`:

```bash
ANVIL_RPC_URL=http://localhost:8545
ANVIL_ACCOUNT=anvil
```

Deploy:

```bash
make deploy
```

### Sepolia Deployment

Configure:

```bash
SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
SEPOLIA_ACCOUNT=<your-foundry-keystore-account>
ETHERSCAN_API_KEY=<your-etherscan-api-key>
```

Deploy:

```bash
make deploy ARGS="--network sepolia"
```

### Fund

```bash
make fund
```

Sepolia:

```bash
make fund ARGS="--network sepolia"
```

### Withdraw

```bash
make withdraw
```

Sepolia:

```bash
make withdraw ARGS="--network sepolia"
```

> For public networks, prefer Foundry keystore accounts through `--account`. Do not pass real private keys directly in shell commands or commit them to `.env`.

## Environment Variables and Keystore Management

`.env` is ignored by git. Do not commit private keys, RPC secrets, or Etherscan API keys.

Common Makefile variables:

| Variable | Description |
| --- | --- |
| `ANVIL_RPC_URL` | Local Anvil RPC URL, usually `http://localhost:8545` |
| `ANVIL_ACCOUNT` | Local Foundry keystore account name |
| `SEPOLIA_RPC_URL` | Sepolia RPC URL |
| `SEPOLIA_ACCOUNT` | Sepolia Foundry keystore account name |
| `ETHERSCAN_API_KEY` | Etherscan verification API key |
| `ZKSYNC_LOCAL_RPC_URL` | zkSync local RPC URL |
| `ZKSYNC_LOCAL_ACCOUNT` | zkSync local account name |
| `ZKSYNC_SEPOLIA_RPC_URL` | zkSync Sepolia RPC URL |
| `ZKSYNC_SEPOLIA_ACCOUNT` | zkSync Sepolia account name |

Recommended keystore setup:

```bash
cast wallet import <account-name> --interactive
```

## Testing and Verification

### Current Verification Snapshot

Local verification history:

```text
2026-06-03:
- make all: passed
- forge build --sizes: passed

2026-06-04:
- forge coverage: passed
```

`make all` test result:

```text
Ran 5 test suites:
- ZkSyncDevOps: 1 passed
- HelperConfigTest: 5 passed
- PriceConverterTest: 10 passed
- InteractionsTest: 3 passed
- FundMeTest: 21 passed

40 tests passed, 0 failed, 0 skipped
```

### Test Coverage Scope

| Test file | Focus |
| --- | --- |
| `test/unit/FundMeTest.t.sol` | Funding, withdrawal, permissions, events, receive/fallback behavior, funder de-duplication, state cleanup |
| `test/unit/PriceConverterTest.t.sol` | Zero/negative prices, stale data, future timestamps, decimal scaling, ETH/USD conversion |
| `test/unit/HelperConfigTest.t.sol` | Sepolia/Mainnet/Anvil config, unsupported chain revert, Anvil mock reuse |
| `test/integration/FundMeTestIntegration.t.sol` | Deployment script plus interaction script workflow |
| `test/unit/ZkSyncDevOps.t.sol` | zkSync devops behavior example |

### Coverage Snapshot

Result from local `forge coverage` on `2026-06-04`:

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

> Foundry disables optimizer settings and `viaIR` for more accurate coverage reporting. Coverage is a test signal, not a substitute for an audit, formal verification, or gas profiling.

### Contract Size

Current `forge build --sizes` core output:

| Contract | Runtime Size (B) | Initcode Size (B) |
| --- | ---: | ---: |
| `FundMe` | 5,178 | 5,629 |
| `MockV3Aggregator` | 2,664 | 3,365 |
| `PriceConverter` | 85 | 160 |
| `PriceConverterHarness` | 2,251 | 2,279 |

> This README does not claim formal verification or audit results. If Slither or other security tooling is added later, results should be recorded with command, date, and scope.

## CI

GitHub Actions workflow:

```text
.github/workflows/test.yml
```

Current CI steps:

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

CI does not require private keys or RPC secrets. It focuses on local compilation, formatting, and test correctness.

## Security Assumptions

The current design assumes:

- The configured Chainlink-compatible price feed address is correct.
- Price data within `STALE_PRICE_TIMEOUT` is considered fresh.
- `block.timestamp` is only used for hour-level stale price checks.
- Supported deployment targets are Anvil, Sepolia, and Ethereum Mainnet.
- L2 sequencer uptime feeds are not currently handled.
- The owner account is trusted and its keystore/private key is managed securely.
- The most recent deployment returned by the interaction scripts is the intended target contract.

## Known Limitations

This project includes several production-aware improvements, but it is still not a production fundraising protocol:

- `withdraw()` loops over `s_funders`, which can become a gas limit risk with many funders.
- The owner is a single point of control; there is no ownership transfer, multisig, or governance mechanism.
- There is no pause or emergency stop mechanism.
- ERC20 funding is not supported.
- Partial withdrawals are not supported.
- User-initiated claim/refund flows are not supported.
- Interaction scripts rely on the most recent deployment lookup from `foundry-devops`.
- NatSpec for `HelperConfig`, `DeployFundMe`, and `Interactions` can be improved further.
- Some learning-stage comments remain and can be cleaned up once the documentation is stable.

## Non-Claims

This project does not claim:

- completed security audit
- completed formal verification
- completed mainnet deployment
- completed Etherscan verification
- support for real fundraising, custody, refunds, or compliance workflows
- support for ZK proofs, RWA tokenization, or full DeFi accounting

## Roadmap

Higher priority:

- Keep the English and Chinese READMEs in sync.
- Add NatSpec to `HelperConfig`, `DeployFundMe`, and `Interactions`.
- Remove leftover learning comments while keeping useful security and design notes.
- Add `.env.example` with expected keystore account and RPC variable names.
- Keep the `forge coverage` snapshot up to date.

Optional improvements:

- Add Slither or similar static analysis tooling and record results.
- Improve gas snapshot tracking.
- Add fuzz or invariant tests around funding accounting and withdrawal cleanup if the project scope grows.
- Move deployment records, public deployment notes, and Etherscan verification evidence into dedicated evidence files.

## Project Positioning

This repository is a complete Solidity + Foundry + Chainlink Data Feeds learning project and a compact smart contract engineering sample. It demonstrates how a tutorial contract can be improved through stronger tests, better mocks, safer configuration, script validation, NatSpec, Makefile workflows, CI, and documentation.

It should not be treated as a complete production fundraising protocol. Real fund management would require a broader security review, better operational controls, governance or multisig considerations, L2-specific oracle risk handling, stricter deployment management, and a more complete user fund lifecycle.
