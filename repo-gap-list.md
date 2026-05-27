# Repo Gap List - 2026-05-27

## Repo : Foundry Fund Me

### Current status
#### `forge fmt --check`
status: PASS
command:
```
forge fmt --check
echo "exit code: $?"
```
output:
```
exit code: 0
```
#### `forge build -vvv`
status: PASS
command:
```
forge clean
forge build -vvv
```
output:
```
[⠊] Compiling...
[⠃] Compiling 23 files with Solc 0.8.19
[⠊] Solc 0.8.19 finished in 1.83s
Compiler run successful!
warning[unsafe-typecast]: typecasts that can truncate values should be checked
   ╭▸ test/mocks/MockV3Aggregator.sol:67:13
```
#### `forge test -vvv`
status: PASS
Test count: 1 + 1 + 11 = 13
#### `forge coverage`
status: PASS
output:
```
╭---------------------------------+-----------------+-----------------+---------------+----------------╮
| File                            | % Lines         | % Statements    | % Branches    | % Funcs        |
+======================================================================================================+
| script/DeployFundMe.s.sol       | 100.00% (7/7)   | 100.00% (9/9)   | 100.00% (0/0) | 100.00% (1/1)  |
|---------------------------------+-----------------+-----------------+---------------+----------------|
| script/HelperConfig.s.sol       | 57.14% (12/21)  | 61.11% (11/18)  | 25.00% (1/4)  | 50.00% (2/4)   |
|---------------------------------+-----------------+-----------------+---------------+----------------|
| script/Interactions.s.sol       | 62.50% (10/16)  | 57.14% (8/14)   | 100.00% (0/0) | 50.00% (2/4)   |
|---------------------------------+-----------------+-----------------+---------------+----------------|
| src/FundMe.sol                  | 90.00% (36/40)  | 94.12% (32/34)  | 71.43% (5/7)  | 83.33% (10/12) |
|---------------------------------+-----------------+-----------------+---------------+----------------|
| src/PriceConverter.sol          | 100.00% (8/8)   | 100.00% (9/9)   | 50.00% (1/2)  | 100.00% (2/2)  |
|---------------------------------+-----------------+-----------------+---------------+----------------|
| test/mocks/MockV3Aggregator.sol | 52.17% (12/23)  | 52.94% (9/17)   | 100.00% (0/0) | 50.00% (3/6)   |
|---------------------------------+-----------------+-----------------+---------------+----------------|
| Total                           | 73.91% (85/115) | 77.23% (78/101) | 53.85% (7/13) | 68.97% (20/29) |
╰---------------------------------+-----------------+-----------------+---------------+----------------╯
```
### Confirmed evidence
- Latest test output path:
- Latest command log:
- Latest commit hash:

### Gaps
| ID | Gap | Evidence | Severity | Owner | Next Action |
|---|---|---|---|---|---|
| None | 例如：测试失败 / 依赖缺失 / README缺失 | command log section | High/Med/Low | Me/Codex | 记录/修复/推迟 |

### Decision
- Can this repo be used as a baseline? yes
- Can we move to next course/project based on this repo? yes