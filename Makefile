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
# ifeq ($(findstring --network alepht,$(ARGS)),--network alepht)
# 	NETWORK_ARGS:= --rpc-url $(ALEPH_TESTNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ALEPH_API_KEY) -vvvv
# endif

ifeq ($(findstring --network alepht,$(ARGS)),--network alepht)
	NETWORK_ARGS:= --rpc-url $(ALEPH_TESTNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout --verifier-url $(ALEPHT_VERIFIER_URL)
endif

# Using Foundry Keystore '--account defaultKey --sender 0x000' where 0x000 is wallet public key
ifeq ($(findstring --network test,$(ARGS)),--network test)
	NETWORK_ARGS:= --rpc-url $(ALEPH_TESTNET_RPC_URL) --account defaultKey --sender 0x000 --broadcast --verify --verifier blockscout --verifier-url $(ALEPHT_VERIFIER_URL)
endif

# MANUAL DEPLOY WITHOUT SCRIPT
# RUN IN ORDER !!!
deployGovernorAlephT:
	@forge create Governor $(NETWORK_ARGS)

deployAuctionerAlephT:
	@forge create AuctionerDev $(NETWORK_ARGS) --constructor-args $(FOUNDATION) $(GOVERNOR_ADDRESS)

verifyGovernor:
	@forge verify-contract $(GOVERNOR_ADDRESS) Governor --chain-id=2039 --verifier-url=$(ALEPHT_VERIFIER_URL) --verifier blockscout

verifyAuctioner:
	@forge verify-contract $(AUCTIONER_ADDRESS) AuctionerDev --chain-id 2039 --verifier-url $(ALEPHT_VERIFIER_URL) --verifier blockscout

# AUTOMATED DEPLOYMENT
deployPiecesMarketSepolia:
	@forge script script/DeployPiecesMarket.s.sol:DeployPiecesMarket $(NETWORK_ARGS)

deployPiecesMarketDevSepolia:
	@forge script script/DeployPiecesMarketDev.s.sol:DeployPiecesMarketDev $(NETWORK_ARGS)

deployPiecesMarketAlephT:
	@forge script script/DeployPiecesMarket.s.sol:DeployPiecesMarket $(NETWORK_ARGS)

deployPiecesMarketDevAlephT:
	@forge script script/DeployPiecesMarketDev.s.sol:DeployPiecesMarketDev $(NETWORK_ARGS)

# INTERACTIONS

# Update Params To Make Proper Calls
AUCTIONER:= 0x5B4C3787A12e2Ee9Ad1890065e1111ea213eb37b

create:
	@forge script script/Interactions.s.sol:Create $(NETWORK_ARGS) --sig "run(address)" $(AUCTIONER)

# MOCK TRANSACTIONS SCRIPTS
mockPiecesMarketTxAlephT:
	@forge script script/MockPiecesMarket.s.sol:MockPiecesMarket $(NETWORK_ARGS)

# MOCK TRANSACTIONS SCRIPTS

mockPhase1:
	@forge script script/MockPiecesMarket.s.sol:Phase1 $(NETWORK_ARGS)

mockPhase2:
	@forge script script/MockPiecesMarket.s.sol:Phase2 $(NETWORK_ARGS)

mockPhase3:
	@forge script script/MockPiecesMarket.s.sol:Phase3 $(NETWORK_ARGS)

mockPhase4:
	@forge script script/MockPiecesMarket.s.sol:Phase4 $(NETWORK_ARGS)

mockPhase5:
	@forge script script/MockPiecesMarket.s.sol:Phase5 $(NETWORK_ARGS)

mockPhase6:
	@forge script script/MockPiecesMarket.s.sol:Phase6 $(NETWORK_ARGS)

mockPhase7:
	@forge script script/MockPiecesMarket.s.sol:Phase7 $(NETWORK_ARGS)

mockPhase8:
	@forge script script/MockPiecesMarket.s.sol:Phase8 $(NETWORK_ARGS)

mockPhase9:
	@forge script script/MockPiecesMarket.s.sol:Phase9 $(NETWORK_ARGS)
