-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean:; forge clean

# Remove modules
remove:; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install chainaccelorg/foundry-devops@0.0.11 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install transmissions11/solmate@v6 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test:; forge test

format:; forge fmt

anvil:; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Ethereum Mainnet
testForkMainnet:
	@forge test --fork-url $(MAINNET_RPC_URL)

testForkMainnetC:
	@forge coverage --fork-url $(MAINNET_RPC_URL)

testForkMainnetCR:
	@forge coverage --fork-url $(MAINNET_RPC_URL) --report lcov

# Ethereum Testnet
testForkSepolia:
	@forge test --fork-url $(SEPOLIA_RPC_URL)

testForkSepoliaC:
	@forge coverage --fork-url $(SEPOLIA_RPC_URL)

testForkSepoliaCR:
	@forge coverage --fork-url $(SEPOLIA_RPC_URL) --report lcov

# Aleph Zero Mainnet
testForkAleph:
	@forge test --fork-url $()

testForkAlephC:
	@forge coverage --fork-url $()

testForkAlephCR:
	@forge coverage --fork-url $() --report lcov

# Aleph Zero Testnet
testForkAlephT:
	@forge test --fork-url $(ALEPH_TESTNET_RPC_URL)

testForkAlephTC:
	@forge coverage --fork-url $(ALEPH_TESTNET_RPC_URL)

testForkAlephTCR:
	@forge coverage --fork-url $(ALEPH_TESTNET_RPC_URL) --report lcov

NETWORK_ARGS:= --rpc-url http://localhost:8545 --private-key $(LOCAL_PRIVATE_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS:= --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# --skip-simulation
ifeq ($(findstring --network alepht,$(ARGS)),--network alepht)
	NETWORK_ARGS:= --rpc-url $(ALEPH_TESTNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ALEPH_API_KEY) -vvvv
endif

deployAuc:
	@forge script script/DeployAuctioner.s.sol:DeployAuctioner $(NETWORK_ARGS)
