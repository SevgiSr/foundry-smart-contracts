-include .env

build:; forge build # :; - type command on the same line

# : - can wrap command on multiple lines
deploy-sepolia:; forge script script/DeployFundMe.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv