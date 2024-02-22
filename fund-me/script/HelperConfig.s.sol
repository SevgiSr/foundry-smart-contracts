// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// 1. Deploy mocks when we're on local anvil chain
// 2. Keep track of contract addresses accross different chains<

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we're on local anvil, we deploy mocks
    // Otherwise, grab the existing address from the live network

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        // forge test --fork-url $SEPOLIA_RPC_URL
        // correctly returns sepolia address
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    struct NetworkConfig {
        address priceFeed;
    }

    ///// whether we fork sepolia or mainnet and deploy contracts locally,
    // or we actually deploy it on live testnet networks, these will return correct addresses ///////
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return config;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory config = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return config;
    }

    // can't be pure because were using vm
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // if u already deployed mocks u dont wanna redeploy
        // u need to check if it's unset
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // if we don't want to fork networks or deploy live,
        // and we want > forge test to work
        // we need to use local anvil network
        // for that we need to deploy mocks, since external contracts dont exist in anvil
        // 1. Deploy the mocks
        // 2. Return the mock addresses

        vm.startBroadcast();
        // deploy mock
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory config = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return config;

        // > forge test
        // passes!
    }
}
