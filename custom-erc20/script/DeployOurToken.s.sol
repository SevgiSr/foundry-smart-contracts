// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// we dont need helperConfig
// our token is the same no matter what network
// theres no special contract we need to interact with

import {Script} from "forge-std/Script.sol";
import {OurToken} from "../src/OurToken.sol";

contract DeployOurToken is Script {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    function run() external returns (OurToken) {
        vm.startBroadcast();
        OurToken token = new OurToken(INITIAL_SUPPLY);
        vm.stopBroadcast();
        return token;
    }
}
