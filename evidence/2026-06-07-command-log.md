# Command Log - 2026-06-07

## Working Directory

`/root/code/solidity/foundry-fund-me`

## GitHub / Commit Status

Final verification baseline:

```text
Current HEAD: 3e16ed12342da0eea34868672e26ea2f82032e59
Local origin/main: 3e16ed12342da0eea34868672e26ea2f82032e59
GitHub main: 3e16ed12342da0eea34868672e26ea2f82032e59 refs/heads/main
Latest commit: 3e16ed1 docs: sync latest verification evidence
```

Commands used:

```text
git rev-parse HEAD origin/main
git branch -vv
git ls-remote origin refs/heads/main
```

## Git Status

Observed before the final edit to this log file:

```text
## main...origin/main
?? TESTING-FACT-EXTRACTION.md
?? evidence/2026-06-06-security-notes-fact-extraction.md
```

Tracked diff status:

```text
git diff --stat
```

Result: no tracked file diff was reported before this command log was updated.

The two untracked files are local fact-extraction notes and are not part of this verification baseline.

## Recent Commits

```text
3e16ed1 docs: sync latest verification evidence
f9ba3b6 docs: update verification evidence and gap register
a8e0be9 docs: expand FundMe testing documentation
1e2fea5 docs: add FundMe testing guide
48153ea docs: document FundMe security posture
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

Commands were run against commit `3e16ed12342da0eea34868672e26ea2f82032e59`.

### `forge fmt --check`

PASS

Result: command exited successfully with no formatting diff output.

### `forge build`

PASS

Result: command exited successfully. A later `make all` run performed a clean rebuild.

### `forge test`

PASS

Result: `40` tests passed across `5` suites.

### `make all`

PASS

- `forge clean`
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

Foundry emitted the expected coverage warning that optimizer settings and `viaIR` are disabled for accurate coverage reports.

### `forge build --sizes`

PASS

Key contract size results:

- `FundMe`: runtime size `5,178 B`, runtime margin `19,398 B`
- `MockV3Aggregator`: runtime size `2,664 B`, runtime margin `21,912 B`
- `PriceConverter`: runtime size `85 B`, runtime margin `24,491 B`
- `PriceConverterHarness`: runtime size `2,251 B`, runtime margin `22,325 B`

### `forge snapshot`

PASS

Result: `40` tests passed across `5` suites. No tracked `.gas-snapshot` diff was present after the run.

## Notes

- Local `main`, local `origin/main`, and GitHub `main` all point to commit `3e16ed12342da0eea34868672e26ea2f82032e59`.
- Before this final log edit, the tracked worktree was clean and only two local fact-extraction files were untracked.
- These results are a verification snapshot, not an audit or deployment record.
- No public deployment or contract verification record is claimed by this evidence file.
