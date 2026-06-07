# Command Log - 2026-06-07

## Working Directory

`/root/code/solidity/foundry-fund-me`

## Git Status

On branch main
Your branch is ahead of `origin/main` by 1 commit.
  (use `git push` to publish your local commits)

Changes not staged for commit:
  (use `git add <file>...` to update what will be committed)
	modified:   README.md
	modified:   README.zh-CN.md
	modified:   SECURITY_NOTES.md
	modified:   TESTING.md
	modified:   repo-gap-list.md

Untracked files:
  (use `git add <file>...` to include in what will be committed)
	TESTING-FACT-EXTRACTION.md
	evidence/2026-06-06-security-notes-fact-extraction.md

no changes added to commit (use "git add" and/or "git commit -a")

## Recent Commits

```text
f9ba3b6 docs: update verification evidence and gap register
a8e0be9 docs: expand FundMe testing documentation
1e2fea5 docs: add FundMe testing guide
48153ea docs: document FundMe security posture
d2c0071 docs: replace default README with project guide
```

## Foundry Versions

```text
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
```

## Directory Listing

```text
.agents
broadcast
cache
.codex
.env
evidence
foundry.lock
foundry.toml
.gas-snapshot
.git
.github
.gitignore
.gitmodules
lib
Makefile
out
README.md
README.zh-CN.md
remappings.txt
repo-gap-list.md
script
SECURITY_NOTES.md
src
test
TESTING-FACT-EXTRACTION.md
TESTING.md
.vscode
zkout
```

## Project Files

```text
./.env
./foundry.lock
./foundry.toml
./.gas-snapshot
./.gitignore
./.gitmodules
./Makefile
./README.md
./README.zh-CN.md
./remappings.txt
./repo-gap-list.md
./SECURITY_NOTES.md
./TESTING-FACT-EXTRACTION.md
./TESTING.md
```

## foundry.toml

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
    "@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/",
]

# See more config options https://github.com/foundry-rs/foundry/blob/master/crates/config/README.md#all-options
```

## Git Submodule Status

```text
 5cb41fbc9b525338b6098da5ea7dd0b7e92f89e4 lib/chainlink-brownie-contracts (1.3.0)
 620536fa5277db4e3fd46772d5cbc1ea0696fb43 lib/forge-std (v1.16.1)
 efff097a87e70c3d15661c9f2a2daeae0b33d5d5 lib/foundry-devops (0.4.0)
```

## Verification Results

### `make all`

PASS

- `forge fmt --check`
- `forge build`
- `forge test`

Result: `40` tests passed across `5` suites.

### `forge coverage`

PASS

- Lines: `90.97%`
- Statements: `90.44%`
- Branches: `90.00%`
- Functions: `88.57%`

### `forge build --sizes`

PASS

### `forge snapshot`

PASS

## Notes

- The current repository state includes local worktree changes outside this log.
- These results are a verification snapshot, not an audit or deployment record.

