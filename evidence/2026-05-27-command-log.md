# Command Log - 2026-05-27

## Working Directory
../code/solidity/foundry-fund-me

## Git Status
On branch main
Your branch is up to date with 'origin/main'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	evidence/

nothing added to commit but untracked files present (use "git add" to track)

## Recent Commits
d69132d test: use remapped devops imports
8b4a737 chore: update local ignore rules
dceb063 test: add zksync devops guard test
e0a41e1 chore: add foundry makefile commands
fecb675 test: use interaction scripts in integration test

## Foundry Versions
forge Version: 1.7.1
Commit SHA: 4072e48705af9d93e3c0f6e29e93b5e9a40caed8
Build Timestamp: 2026-05-08T07:50:55.527285345Z (1778226655)
Build Profile: dist
anvil Version: 1.7.1
Commit SHA: 4072e48705af9d93e3c0f6e29e93b5e9a40caed8
Build Timestamp: 2026-05-08T07:50:55.527285345Z (1778226655)
Build Profile: dist
cast Version: 1.7.1
Commit SHA: 4072e48705af9d93e3c0f6e29e93b5e9a40caed8
Build Timestamp: 2026-05-08T07:50:55.527285345Z (1778226655)
Build Profile: dist

## Directory Listing
broadcast
cache
evidence
foundry.lock
foundry.toml
lib
Makefile
out
README.md
script
src
test
zkout

## Project Files
./cache/solidity-files-cache.json
./cache/test-failures
./cache/zksync-solidity-files-cache.json
./.env
./evidence/2026-05-27-command-log.md
./foundry.lock
./foundry.toml
./.gas-snapshot
./.git/COMMIT_EDITMSG
./.git/config
./.git/description
./.git/HEAD
./.gitignore
./.git/index
./.gitmodules
./.git/ORIG_HEAD
./Makefile
./README.md
./script/DeployFundMe.s.sol
./script/HelperConfig.s.sol
./script/Interactions.s.sol
./src/FundMe.sol
./src/PriceConverter.sol

## foundry.toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
    "@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/",
]

# See more config options https://github.com/foundry-rs/foundry/blob/master/crates/config/README.md#all-options

## Git Submodule Status
 5cb41fbc9b525338b6098da5ea7dd0b7e92f89e4 lib/chainlink-brownie-contracts (1.3.0)
 620536fa5277db4e3fd46772d5cbc1ea0696fb43 lib/forge-std (v1.16.1)
 efff097a87e70c3d15661c9f2a2daeae0b33d5d5 lib/foundry-devops (0.4.0)
