# Create Foundry keystore accounts before running deployment targets.
# Account list: 1. sepolia: account of sepolia test wallet
#               2. anvil: first default account of anvil
#               3. zksync-local: first default account of zkSync local
#               4. zksync-sepolia: account of sepolia test wallet

-include .env

.PHONY: all build format format-check test clean deploy fund install snapshot format anvil zktest zkbuild zk-anvil deploy-zk deploy-zk-sepolia withdraw update

all: clean format-check build test

# Clean the repo
clean  :; forge clean

# Install project dependencies for a fresh clone. Do not run during normal build/test.
install :; forge install cyfrin/foundry-devops@0.4.0 && forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 && forge install foundry-rs/forge-std@v1.16.1

# Update Dependencies
update:; forge update

build:; forge build

zkbuild :; forge build --zksync

test :; forge test

format :; forge fmt

format-check :; forge fmt --check

zktest :; foundryup-zksync && forge test --zksync && foundryup

snapshot :; forge snapshot

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

zk-anvil :; npx zksync-cli dev start

deploy:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)

NETWORK_ARGS := --rpc-url $(ANVIL_RPC_URL) --account $(ANVIL_ACCOUNT) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# As of writing, the Alchemy zkSync RPC URL is not working correctly 
deploy-zk:
	forge create src/FundMe.sol:FundMe --rpc-url $(ZKSYNC_LOCAL_RPC_URL) --account $(ZKSYNC_LOCAL_ACCOUNT) --constructor-args $(shell forge create test/mocks/MockV3Aggregator.sol:MockV3Aggregator --rpc-url $(ZKSYNC_LOCAL_RPC_URL) --account $(ZKSYNC_LOCAL_ACCOUNT) --constructor-args 8 200000000000 --legacy --zksync | grep "Deployed to:" | awk '{print $$3}') --legacy --zksync

deploy-zk-sepolia:
	forge create src/FundMe.sol:FundMe --rpc-url $(ZKSYNC_SEPOLIA_RPC_URL) --account $(ZKSYNC_SEPOLIA_ACCOUNT) --constructor-args 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF --legacy --zksync


fund:
	@forge script script/Interactions.s.sol:FundFundMe $(NETWORK_ARGS)

withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe $(NETWORK_ARGS)