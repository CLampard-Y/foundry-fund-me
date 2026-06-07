# Foundry FundMe

[![CI](https://github.com/CLampard-Y/foundry-fund-me/actions/workflows/test.yml/badge.svg)](https://github.com/CLampard-Y/foundry-fund-me/actions/workflows/test.yml)
[![Built with Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1F.svg)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](./README.md) | 中文

> 英文版 README 入口已预留。当前中文版是本项目的主要说明文档；后续英文版应按本文档同步，而不是继续保留默认 Foundry 模板。

## 项目概述

`Foundry FundMe` 是一个基于 Foundry 的 Solidity 工程项目。用户可以向 `FundMe` 合约发送 ETH，合约通过 Chainlink-compatible ETH/USD price feed 将 ETH 换算为 USD 价值，并要求单次 funding 满足最低美元金额。合约 owner 可以提取合约内全部 ETH，并清理 funder accounting state。

本项目来自 Cyfrin Updraft Foundry FundMe 学习路径，但已经在课程代码基础上补充了更接近 production-aware 的工程处理，包括 oracle boundary checks、custom errors、events、private state + getters、funder 去重、脚本地址校验、配置 fail-fast、单元测试与集成测试扩展、NatSpec 和 Makefile 命令入口。

当前定位：

- 适合作为 Solidity / Foundry / Chainlink Data Feeds 的学习项目和 portfolio 展示项目。
- 展示从课程代码逐步提升到更高工程质量的过程。
- 不应被视为可直接承载真实资金的生产募资协议。

## 项目状态

| 项目 | 当前状态 |
| --- | --- |
| 合约开发 | 核心功能已完成 |
| 本地验证 | `make all`、`forge build --sizes`、`forge coverage`、`forge snapshot` 已在本地通过；见 [`evidence/2026-06-07-command-log.md`](./evidence/2026-06-07-command-log.md) |
| CI | GitHub Actions 已配置 |
| NatSpec | 核心合约与 `PriceConverter` 已补充，脚本/配置仍可继续完善 |
| Makefile | 已完成主要安全清理，支持 fmt/build/test/deploy/fund/withdraw 等入口 |
| 部署状态 | 未在本文档中声明任何已完成的 public network deployment |
| 合约验证 | 未在本文档中声明 Etherscan verification |
| 安全审计 | 未审计，不应直接用于真实资金场景 |

## 这个项目展示了什么

| 能力点 | 对应实现 |
| --- | --- |
| Solidity contract design | `FundMe` 的 funding、withdraw、receive/fallback、getter API |
| Oracle-aware engineering | `PriceConverter` 对 Chainlink-compatible feed 做价格有效性和 stale check |
| Foundry testing | unit、integration、mock、revert、event、state cleanup、config tests |
| Script workflow | deployment script 与 interaction scripts |
| Environment separation | Mainnet / Sepolia / Anvil 配置分支，本地链使用 mock price feed |
| Gas-aware basics | custom errors、immutable、constant、funder 去重、withdraw 中缓存数组长度 |
| Documentation | 中文 README、核心 NatSpec、CI 与验证快照 |

## 项目结构

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
└── README.zh-CN.md
```

## 合约与脚本说明

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `src/FundMe.sol` | 核心合约 | 接收 ETH、记录 funder、限制最低 USD 金额、owner 提现 |
| `src/PriceConverter.sol` | Library | 读取 Chainlink-compatible price feed，检查价格有效性，并完成 ETH/USD 换算 |
| `script/HelperConfig.s.sol` | 配置脚本 | 根据 chain id 返回 price feed；Anvil 本地链部署并复用 mock |
| `script/DeployFundMe.s.sol` | 部署脚本 | 读取网络配置并部署 `FundMe` |
| `script/Interactions.s.sol` | 交互脚本 | 脚本化执行 fund 和 withdraw，并校验目标合约地址 |
| `test/mocks/MockV3Aggregator.sol` | Mock | 模拟 Chainlink `AggregatorV3Interface`，用于本地测试 |

## 核心功能

| 功能 | 说明 |
| --- | --- |
| `fund()` | 用户发送 ETH；合约检查其 USD 价值是否达到最低要求 |
| `withdraw()` | 仅 owner 可调用；提取合约全部 ETH，并清理 funder 状态 |
| `receive()` | 直接向合约转 ETH 时自动进入 `fund()` 逻辑 |
| `fallback()` | 带 calldata 向合约转 ETH 时自动进入 `fund()` 逻辑 |
| `getVersion()` | 返回当前 price feed 的版本 |
| getter functions | 对 private state 提供只读访问 |

当前最低 funding 金额：

```text
MINIMUM_USD = 5e18
```

项目内部将 USD 金额统一处理为 18 decimals，以便和 wei 精度对齐。

## 网络配置

`HelperConfig` 根据当前 `block.chainid` 选择 price feed：

| Network | Chain ID | Price Feed |
| --- | ---: | --- |
| Ethereum Mainnet | `1` | Chainlink ETH/USD |
| Sepolia | `11155111` | Chainlink ETH/USD |
| Anvil Local | `31337` | `MockV3Aggregator` |

如果当前 chain id 不在支持范围内，`HelperConfig` 会直接 revert，而不是返回 `address(0)` 后让部署流程在更深层失败。

> Mainnet 与 Sepolia price feed 地址来自当前代码中的硬编码配置。正式部署前应再次核对 Chainlink 官方 feed address，并根据目标网络评估 oracle 风险，例如 stale data、feed decimals、L2 sequencer uptime feed 等。

## Production-Aware 设计

本项目采用的标准是：production-grade lens, stage-appropriate implementation。也就是用生产环境视角审查 correctness、security、testing、maintainability 和 gas，但不为学习项目强行引入复杂治理、proxy、完整 DeFi accounting 或过度抽象。

### State Encapsulation

核心状态变量使用 `private`，并通过 explicit getter 暴露必要只读信息。这避免把内部命名和 storage layout 直接暴露为公共 ABI，也让未来调整实现时更可控。

### Custom Errors

合约使用 custom errors 代替字符串型 revert：

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

custom errors 通常比 revert string 更节省 gas，也更适合在 Foundry 测试中使用 selector 精确断言。

### Events

合约在关键资金行为发生时 emit event：

```solidity
event Funded(address indexed funder, uint256 amount);
event Withdrawn(address indexed owner, uint256 amount);
```

events 用于链下索引、前端展示、监控和审计追踪。它们不能替代链上状态，也不应被当作权限判断或 accounting 的唯一来源。

### Funding Accounting

`fund()` 会累计同一 funder 的 funding amount，但只会把该地址加入 `s_funders` 一次。这样可以避免同一地址重复 funding 导致 `withdraw()` 清理循环不必要膨胀，同时保留每个地址的累计 funding 记录。

### Withdraw Flow

`withdraw()` 只允许 owner 调用，并在外部 ETH transfer 前先清理 funder 状态，符合 CEI pattern 的基本思路。当前实现适合小规模学习项目；如果 funder 数量很大，遍历清理仍然存在 gas limit 风险。

### Oracle Boundary Checks

`PriceConverter` 不直接信任 `latestRoundData()` 的返回值，而是检查：

- price 是否大于 0
- `updatedAt` 是否为 0
- `updatedAt` 是否在未来
- 价格是否超过 stale timeout
- price feed decimals 是否需要缩放到 18 decimals

当前 stale timeout：

```text
STALE_PRICE_TIMEOUT = 3 hours
```

`block.timestamp` 只用于小时级 stale price 检查，不用于秒级安全边界。

### Interaction Script Validation

`Interactions.s.sol` 在执行 fund / withdraw 前检查目标地址：

- 不能是 `address(0)`
- 必须包含合约代码

这可以降低脚本误操作到空地址或 EOA 的风险。当前脚本仍默认依赖 `foundry-devops` 的 most recent deployment；真实多环境部署中应进一步使用显式地址、环境隔离和部署记录审查。

### NatSpec

`FundMe` 和 `PriceConverter` 已补充核心 NatSpec，用于说明行为、revert 条件、oracle 假设和返回值。后续仍可继续补强 `HelperConfig`、`DeployFundMe` 和 `Interactions` 的 NatSpec，使脚本层文档也和合约层保持一致。

## 技术栈

- Solidity `^0.8.19`
- Foundry (`forge`, `cast`, `anvil`)
- Chainlink Data Feeds
- `forge-std`
- `foundry-devops`
- GitHub Actions CI

## 快速开始

### 1. 安装 Foundry

请先安装 Foundry：

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. 拉取依赖

如果仓库已经包含 submodule：

```bash
git submodule update --init --recursive
```

如果是 fresh clone 并需要重新安装依赖，可以使用：

```bash
make install
```

`make install` 会写入依赖目录，适合 fresh clone 或依赖缺失时使用，不建议作为日常 build/test 命令反复运行。

### 3. 运行完整本地检查

```bash
make all
```

`make all` 当前会执行：

```text
forge clean
forge fmt --check
forge build
forge test
```

### 4. 单独运行常用命令

```bash
make format-check
make build
make test
forge build --sizes
forge test -vvv
```

### 5. 启动本地 Anvil

```bash
make anvil
```

## Makefile 命令

| 命令 | 说明 |
| --- | --- |
| `make all` | 清理后执行 fmt check、build、test |
| `make clean` | 执行 `forge clean` |
| `make format` | 执行 `forge fmt` |
| `make format-check` | 执行 `forge fmt --check` |
| `make build` | 执行 `forge build` |
| `make test` | 执行 `forge test` |
| `make snapshot` | 执行 `forge snapshot` |
| `make anvil` | 使用固定 mnemonic 启动本地 Anvil |
| `make deploy` | 按 `NETWORK_ARGS` 部署 `FundMe` |
| `make fund` | 执行 `FundFundMe` interaction script |
| `make withdraw` | 执行 `WithdrawFundMe` interaction script |
| `make deploy-zk` | zkSync local 部署示例 |
| `make deploy-zk-sepolia` | zkSync Sepolia 部署示例 |
| `make zktest` | 切换到 foundry-zksync 后运行 zkSync test，再切回 Foundry |

> `make zktest` 会切换本地 Foundry toolchain；运行前应确认你理解 `foundryup-zksync` 和 `foundryup` 对本机环境的影响。

## 部署与交互

### 本地部署

先在独立终端启动 Anvil：

```bash
make anvil
```

确认 `.env` 中存在本地网络参数，例如：

```bash
ANVIL_RPC_URL=http://localhost:8545
ANVIL_ACCOUNT=anvil
```

然后部署：

```bash
make deploy
```

### Sepolia 部署

`.env` 中需要配置：

```bash
SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
SEPOLIA_ACCOUNT=<your-foundry-keystore-account>
ETHERSCAN_API_KEY=<your-etherscan-api-key>
```

部署：

```bash
make deploy ARGS="--network sepolia"
```

### Fund

```bash
make fund
```

Sepolia：

```bash
make fund ARGS="--network sepolia"
```

### Withdraw

```bash
make withdraw
```

Sepolia：

```bash
make withdraw ARGS="--network sepolia"
```

> Public network 部署和交互建议使用 Foundry keystore `--account`，不要在命令行或 `.env` 中使用明文 private key。

## 环境变量与密钥管理

`.env` 已加入 `.gitignore`。不要提交真实私钥、RPC URL 密钥或 Etherscan API Key。

当前 Makefile 常用字段：

| 字段 | 说明 |
| --- | --- |
| `ANVIL_RPC_URL` | Anvil RPC URL，通常是 `http://localhost:8545` |
| `ANVIL_ACCOUNT` | Foundry keystore 中的本地 account 名称 |
| `SEPOLIA_RPC_URL` | Sepolia RPC URL |
| `SEPOLIA_ACCOUNT` | Foundry keystore 中的 Sepolia account 名称 |
| `ETHERSCAN_API_KEY` | Etherscan verification API key |
| `ZKSYNC_LOCAL_RPC_URL` | zkSync local RPC URL |
| `ZKSYNC_LOCAL_ACCOUNT` | zkSync local account 名称 |
| `ZKSYNC_SEPOLIA_RPC_URL` | zkSync Sepolia RPC URL |
| `ZKSYNC_SEPOLIA_ACCOUNT` | zkSync Sepolia account 名称 |

推荐使用 Foundry keystore：

```bash
cast wallet import <account-name> --interactive
```

## 测试与验证

### 当前验证快照

最新本地快照：[`evidence/2026-06-07-command-log.md`](./evidence/2026-06-07-command-log.md)

以下结果为本地环境验证快照：

```text
2026-06-07:
- make all: passed
- forge build --sizes: passed
- forge coverage: passed
- forge snapshot: passed
```

`make all` 测试结果：

```text
Ran 5 test suites:
- ZkSyncDevOps: 1 passed
- HelperConfigTest: 5 passed
- PriceConverterTest: 10 passed
- InteractionsTest: 3 passed
- FundMeTest: 21 passed

40 tests passed, 0 failed, 0 skipped
```

### 测试覆盖范围

| 测试文件 | 覆盖重点 |
| --- | --- |
| `test/unit/FundMeTest.t.sol` | fund、withdraw、权限、events、receive/fallback、funder 去重、状态清理 |
| `test/unit/PriceConverterTest.t.sol` | 价格为 0、负数、stale price、future timestamp、decimals 缩放、ETH/USD 换算 |
| `test/unit/HelperConfigTest.t.sol` | Sepolia/Mainnet/Anvil 配置、unsupported chain revert、Anvil mock 复用 |
| `test/integration/FundMeTestIntegration.t.sol` | 部署脚本 + interaction scripts 的完整路径 |
| `test/unit/ZkSyncDevOps.t.sol` | zkSync 相关 devops 行为示例 |

### Coverage Snapshot

以下结果来自 `2026-06-07` 本地运行的 `forge coverage`：

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

> Foundry 在生成 coverage report 时会为了统计准确性禁用 optimizer 和 `viaIR`。Coverage 是测试覆盖信号，不等同于安全审计、formal verification 或 gas profile。

### 合约大小

`forge build --sizes` 当前核心输出：

| Contract | Runtime Size (B) | Initcode Size (B) |
| --- | ---: | ---: |
| `FundMe` | 5,178 | 5,629 |
| `MockV3Aggregator` | 2,664 | 3,365 |
| `PriceConverter` | 85 | 160 |
| `PriceConverterHarness` | 2,251 | 2,279 |

> 当前 README 不声明 formal verification 或 audit 结论。若后续运行 Slither 或其他安全工具，应将结果单独记录并注明日期与命令。

## CI

仓库包含 GitHub Actions workflow：

```text
.github/workflows/test.yml
```

CI 当前执行：

- `forge fmt --check`
- `forge build --sizes`
- `forge test -vvv`

CI 不依赖真实私钥或 RPC secret，主要用于验证本地单元测试、集成测试和编译质量。

## 安全假设

当前合约的安全边界建立在以下假设上：

- Chainlink-compatible price feed 地址配置正确。
- Price feed 数据在 `STALE_PRICE_TIMEOUT` 内被视为新鲜。
- `block.timestamp` 只用于小时级 stale price 检查，不用于秒级安全边界。
- 当前部署目标主要是 Anvil、Sepolia、Ethereum Mainnet。
- 当前没有处理 L2 sequencer uptime feed。
- owner 地址可信，且 owner 私钥或 keystore 由部署者安全管理。
- interaction scripts 找到的 most recent deployment 是当前想要操作的目标合约。

## 已知限制

本项目已经加入多项 production-aware 改进，但仍然不是完整生产募资协议：

- `withdraw()` 需要遍历 `s_funders`，funder 数量过大时存在 gas limit 风险。
- owner 是单点控制，没有 owner transfer、multisig 或治理机制。
- 当前没有 pause / emergency stop。
- 不支持 ERC20 funding。
- 不支持 partial withdraw。
- 不支持用户主动 claim / refund。
- 当前 interaction scripts 默认使用 `foundry-devops` 的 most recent deployment，生产多环境部署中应谨慎使用。
- `HelperConfig`、`DeployFundMe`、`Interactions` 的 NatSpec 仍可继续补强。
- 当前仍存在少量学习阶段注释，后续可在文档稳定后统一清理。

## 不应过度声明的内容

本项目当前不声明：

- 已完成安全审计
- 已完成 formal verification
- 已完成 mainnet deployment
- 已完成 Etherscan verification
- 支持真实募资、托管、退款或合规流程
- 支持 ZK proof、RWA tokenization 或完整 DeFi accounting

## 后续计划

优先级较高：

- 将英文版 `README.md` 按中文版同步，替换默认 Foundry 模板。
- 补充 `HelperConfig`、`DeployFundMe`、`Interactions` 的 NatSpec。
- 清理学习阶段残留注释，保留必要的安全边界和设计注释。
- 增加 `.env.example`，明确 keystore account 与 RPC 变量命名。
- 定期更新 `forge coverage` 快照，避免 README 与测试状态脱节。

可选提升：

- 引入 Slither 等静态分析工具，并记录结果。
- 引入更系统的 gas snapshot 管理。
- 根据需要加入 fuzz testing / invariant testing，重点验证 funding accounting 与 withdraw state cleanup。
- 将 deployment records、public deployment、Etherscan verification 单独整理成 evidence 文档。

## 项目定位

本项目适合作为 Solidity + Foundry + Chainlink Data Feeds 的完整学习项目和小型合约工程样板。它展示了从基础课程代码逐步提升到更高工程质量的过程，包括测试增强、mock 改进、配置健壮性、脚本校验、NatSpec、Makefile 和文档化。

它不应被视为完整生产募资协议。若用于真实资金场景，还需要进一步完成安全审计、权限治理、运维流程、L2 oracle 风险处理、更严格的部署管理和更完整的用户资金生命周期设计。

## English Summary

This project is a production-aware Foundry learning project for an ETH-based funding contract. It includes Chainlink-compatible price conversion, local mocks, custom errors, events, fail-fast network configuration, interaction script validation, NatSpec documentation, Makefile command gateways, and a focused test suite. It is not audited and should not be used as a real fundraising protocol without further security review, deployment controls, and operational hardening.
