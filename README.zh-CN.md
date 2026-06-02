# Foundry FundMe

[![CI](https://github.com/CLampard-Y/foundry-fund-me/actions/workflows/test.yml/badge.svg)](https://github.com/CLampard-Y/foundry-fund-me/actions/workflows/test.yml)
[![Built with Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1F.svg)](https://book.getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](./README.md) | 中文

> 英文版 README 入口已预留。当前中文版是本项目的主要说明文档；英文版后续应按本文档同步，而不是继续保留默认 Foundry 模板。

## 项目概述

`Foundry FundMe` 是一个基于 Foundry 的 Solidity 工程样板。用户可以向 `FundMe` 合约发送 ETH，合约通过 Chainlink ETH/USD Price Feed 将 ETH 换算为 USD 计价，并要求单次 funding 满足最低美元价值。合约 owner 可以提取合约内全部 ETH，并清理 funder 相关状态。

本项目来自 Cyfrin Updraft Foundry FundMe 学习路径，但已经在课程基础上加入更接近 production-aware 的工程处理。当前定位是学习项目与小型合约工程样板，不是可直接用于真实资金募资的生产协议。

当前已实现的工程化改进包括：

- Chainlink Data Feeds ETH/USD 价格换算
- 本地 Anvil 使用 mock price feed
- custom errors 替代 revert string
- events 记录关键资金行为
- private state + explicit getters 控制外部访问面
- funder 数组去重，避免同一地址重复进入 funder list
- owner withdraw 后清理 funding amount 与去重状态
- `PriceConverter` 支持 stale price 检查与动态 decimals 缩放
- `HelperConfig` 对 unsupported chain 使用 fail-fast 行为
- interaction scripts 对目标合约地址执行基础校验
- unit、integration、config、oracle boundary 测试覆盖核心路径

## 项目状态

| 项目 | 当前状态 |
| --- | --- |
| 合约开发 | 核心功能已完成 |
| 本地验证 | `forge fmt --check`、`forge build --sizes`、`forge test` 通过 |
| CI | GitHub Actions 已配置 |
| NatSpec | 待系统化补充 |
| Makefile | 待生产化清理；当前不建议依赖 `make all` / `make remove` |
| 部署状态 | 未在本文档中声明任何已完成的 public network deployment |
| 合约验证 | 未在本文档中声明 Etherscan verification |
| 安全审计 | 未审计，不应直接用于真实资金场景 |

## 合约与脚本结构

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `src/FundMe.sol` | 核心合约 | 接收 ETH、记录 funder、限制最低 USD 金额、owner 提现 |
| `src/PriceConverter.sol` | Library | 读取 Chainlink price feed，检查价格有效性，并完成 ETH/USD 换算 |
| `script/HelperConfig.s.sol` | 配置脚本 | 根据 chain id 返回对应 price feed；本地链部署 mock |
| `script/DeployFundMe.s.sol` | 部署脚本 | 读取网络配置并部署 `FundMe` |
| `script/Interactions.s.sol` | 交互脚本 | 脚本化执行 fund 和 withdraw |
| `test/mocks/MockV3Aggregator.sol` | Mock | 模拟 Chainlink `AggregatorV3Interface`，用于本地测试 |
| `test/unit/*.t.sol` | Unit tests | 覆盖 `FundMe`、`PriceConverter`、`HelperConfig` 等核心行为 |
| `test/integration/*.t.sol` | Integration tests | 覆盖部署脚本与交互脚本组合路径 |

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

## 技术栈

- Solidity `^0.8.19`
- Foundry (`forge`, `cast`, `anvil`)
- Chainlink Data Feeds
- `forge-std`
- `foundry-devops`
- GitHub Actions CI

## 网络配置

`HelperConfig` 根据当前 `block.chainid` 选择 price feed：

| Network | Chain ID | Price Feed |
| --- | ---: | --- |
| Ethereum Mainnet | `1` | Chainlink ETH/USD |
| Sepolia | `11155111` | Chainlink ETH/USD |
| Anvil Local | `31337` | `MockV3Aggregator` |

如果当前 chain id 不在支持范围内，`HelperConfig` 会直接 revert，而不是返回 `address(0)` 后再让部署流程在更深层失败。

> 注意：Mainnet 与 Sepolia price feed 地址是当前代码中的硬编码配置。正式部署前应再次核对 Chainlink 官方 feed registry / feed address，并确认目标网络是否需要额外的 oracle 风险处理。

## 生产化设计考虑

本项目使用的是 production-grade lens, stage-appropriate implementation：对资金流、oracle、配置和测试保持生产化意识，但不为学习项目强行引入复杂治理、proxy、完整 DeFi accounting 或过度抽象。

### State Encapsulation

核心状态变量使用 `private`，并通过 getter 暴露必要只读信息。这可以避免把内部命名和存储结构直接暴露为公共 ABI，也让未来调整 storage layout 时更可控。

### Custom Errors

合约使用 custom errors 代替字符串型 revert，例如：

- `FundMe__NotOwner`
- `FundMe__InvalidPriceFeed`
- `FundMe__NotEnoughFunds`
- `FundMe__CallFailed`
- `PriceConverter__InvalidPrice`
- `PriceConverter__StalePrice`

这种方式通常比 revert string 更节省 gas，也更适合在测试中使用 selector 精确断言。

### Events

合约在关键资金行为发生时 emit event：

- `Funded(address indexed funder, uint256 amount)`
- `Withdrawn(address indexed owner, uint256 amount)`

events 用于链下索引、前端展示、监控和审计追踪。它们不能替代合约状态，也不应被当作链上权限或 accounting 的来源。

### Funding Accounting

`fund()` 会累计同一 funder 的 funding amount，但只会把该地址加入 `s_funders` 一次。这样可以避免重复 funder 让 `withdraw()` 清理循环膨胀，同时保留每个地址的累计 funding 记录。

### Withdraw Flow

`withdraw()` 采用 only-owner 权限控制，并在外部 ETH transfer 前先清理 funder 状态。当前实现适合小规模学习项目；如果 funder 数量过大，遍历清理仍然存在 gas limit 风险。

### Price Feed Checks

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

这可以降低脚本误操作到空地址或普通 EOA 的风险。当前脚本仍默认依赖 `foundry-devops` 的 most recent deployment；真实多环境部署中应进一步使用显式地址、环境隔离和部署记录审查。

## 测试与验证

### 本地验证命令

```bash
forge fmt --check
forge build --sizes
forge test
```

### 当前验证快照

以下结果为本地环境在 `2026-06-02` 的验证快照：

```text
forge fmt --check: passed
forge build --sizes: passed
forge test: 40 tests passed, 0 failed, 0 skipped
```

测试套件明细：

```text
Ran 5 test suites:
- ZkSyncDevOps: 1 passed
- HelperConfigTest: 5 passed
- PriceConverterTest: 10 passed
- InteractionsTest: 3 passed
- FundMeTest: 21 passed

40 tests passed, 0 failed, 0 skipped
```

> 当前 README 不声明 coverage percentage、formal verification 或 audit 结论。若后续运行 `forge coverage`、Slither 或其他安全工具，应将结果单独记录并注明日期与命令。

### 测试覆盖范围

| 测试文件 | 覆盖重点 |
| --- | --- |
| `FundMeTest.t.sol` | fund、withdraw、权限、events、receive/fallback、funder 去重、状态清理 |
| `PriceConverterTest.t.sol` | 价格为 0、负数、stale price、future timestamp、decimals 缩放、ETH/USD 换算 |
| `HelperConfigTest.t.sol` | Sepolia/Mainnet/Anvil 配置、unsupported chain revert、Anvil mock 复用 |
| `FundMeTestIntegration.t.sol` | 部署脚本 + interaction scripts 的完整路径 |
| `ZkSyncDevOps.t.sol` | zkSync 相关 devops 行为示例 |

### 合约大小

`forge build --sizes` 当前核心输出：

| Contract | Runtime Size (B) | Initcode Size (B) |
| --- | ---: | ---: |
| `FundMe` | 5,178 | 5,629 |
| `MockV3Aggregator` | 2,664 | 3,365 |
| `PriceConverter` | 85 | 160 |

## 如何在本地运行

当前建议优先使用原生 Foundry 命令。Makefile 仍处于待清理状态，尤其不建议在清理前运行 `make all` 或 `make remove`。

### 安装依赖

如果仓库已经包含 submodule：

```bash
git submodule update --init --recursive
```

如果需要重新安装 Foundry 依赖，请先确认 `foundry.lock`、`.gitmodules` 与课程/项目要求的版本一致。

### 编译

```bash
forge build
```

### 格式检查

```bash
forge fmt --check
```

### 测试

```bash
forge test
```

如需更详细的 trace：

```bash
forge test -vvv
```

### 启动本地 Anvil

```bash
anvil
```

### 本地部署

```bash
forge script script/DeployFundMe.s.sol:DeployFundMe \
  --rpc-url http://localhost:8545 \
  --private-key <anvil-private-key> \
  --broadcast
```

`<anvil-private-key>` 只能使用本地 Anvil 测试私钥，不应使用真实钱包私钥。

### 使用交互脚本

Fund：

```bash
forge script script/Interactions.s.sol:FundFundMe \
  --rpc-url http://localhost:8545 \
  --private-key <private-key> \
  --broadcast
```

Withdraw：

```bash
forge script script/Interactions.s.sol:WithdrawFundMe \
  --rpc-url http://localhost:8545 \
  --private-key <private-key> \
  --broadcast
```

正式网络交互前，应优先使用 Foundry keystore `--account`，并确认 `foundry-devops` 找到的 deployment address 与目标合约一致。

## 环境变量

`.env` 已加入 `.gitignore`，不要提交真实私钥、RPC URL 密钥或 Etherscan API Key。

常见字段：

| 字段 | 说明 |
| --- | --- |
| `SEPOLIA_RPC_URL` | Sepolia RPC URL |
| `MAINNET_RPC_URL` | Mainnet RPC URL，用于 fork 测试或只读验证 |
| `ETHERSCAN_API_KEY` | Etherscan verification API key |
| `ACCOUNT` | Foundry keystore account 名称 |

推荐优先使用 Foundry keystore，而不是在 `.env` 中保存明文私钥：

```bash
cast wallet import <account-name> --interactive
```

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

## 安全假设与项目边界

本项目已经加入多项生产化考虑，但仍然是学习项目和小型工程样板，不应直接作为生产募资协议使用。

### 当前安全假设

- Chainlink price feed 地址配置正确
- Price feed 数据在 `STALE_PRICE_TIMEOUT` 内被视为新鲜
- `block.timestamp` 只用于小时级 stale price 检查，不用于秒级安全边界
- 当前部署目标主要是 Anvil、Sepolia、Ethereum Mainnet
- 当前没有处理 L2 sequencer uptime feed
- owner 地址可信，且 owner 私钥/keystore 由部署者安全管理

### 已知限制

- `withdraw()` 需要遍历 `s_funders`，funder 数量过大时存在 gas limit 风险
- owner 是单点控制，没有 owner transfer 或多签治理
- 当前没有 pause / emergency stop 机制
- 不支持 ERC20 funding
- 不支持 partial withdraw
- 不支持用户主动 claim / refund
- 当前 interaction scripts 默认使用 `foundry-devops` 的 most recent deployment，生产多环境部署中应谨慎使用
- 当前仍存在学习阶段注释，后续应在 NatSpec 与 README 完成后统一清理

### 不应过度声明的内容

本项目当前不声明：

- 已完成安全审计
- 已完成 formal verification
- 已完成 mainnet deployment
- 已完成 Etherscan verification
- 支持真实募资、托管、退款或合规流程
- 支持 ZK proof、RWA tokenization 或完整 DeFi accounting

## 待完善占位

### NatSpec 文档

> 待补充。

当前核心合约尚未完成系统化 NatSpec。后续完成后，建议在本节补充：

- `fund()` 的行为说明、revert 条件和 event
- `withdraw()` 的权限、资金流和状态清理逻辑
- `receive()` / `fallback()` 的调用路径
- `PriceConverter.getPrice()` 的 oracle 安全假设
- `PriceConverter.getConversionRate()` 的 decimals 与精度处理
- `HelperConfig` 的网络选择和 fail-fast 行为

### Makefile 优化

> 待补充。

当前 README 以原生 Foundry 命令为准。后续 Makefile 优化完成后，建议在本节补充：

- `make check`：统一执行 fmt/build/test
- `make build`
- `make test`
- `make test-verbose`
- `make snapshot`
- `make coverage`
- `make deploy`
- `make fund`
- `make withdraw`
- 各 network 参数和 account / keystore 使用方式

同时建议删除或隔离具有破坏性的维护命令，尤其是当前 `make remove` 与依赖它的 `make all`。生产化 Makefile 不应默认执行删除依赖、重建 `.gitmodules` 或自动创建 Git commit 的操作。

## 后续计划

- 完成核心合约 NatSpec
- 优化 Makefile 和命令入口
- 清理学习阶段残留注释
- 根据本文档补充英文版 README
- 引入更系统的 gas snapshot 管理
- 可选运行并记录 `forge coverage`
- 可选引入 Slither 等静态分析工具
- 可选引入 fuzz testing / invariant testing，重点验证 funding accounting 与 withdraw state cleanup

## 项目定位

本项目适合作为 Solidity + Foundry + Chainlink Data Feeds 的完整学习项目和小型合约工程样板。它展示了从基础课程代码逐步提升到更高工程质量的过程，包括测试增强、mock 改进、配置健壮性、脚本校验和文档化。

它不应被视为完整生产募资协议。若用于真实资金场景，还需要进一步完成安全审计、权限治理、运维流程、L2 oracle 风险处理、更严格的部署管理和更完整的用户资金生命周期设计。

## English Summary

This project is a production-aware Foundry learning project for an ETH-based funding contract. It includes Chainlink price conversion, local mocks, custom errors, events, fail-fast network configuration, interaction script validation, and a focused test suite. It is not audited and should not be used as a real fundraising protocol without further security review, deployment controls, and operational hardening.
